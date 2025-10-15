# frozen_string_literal: true

# Mixin for resolving merge requests. All arguments must be in forms
# that `MergeRequestsFinder` can handle, so you may need to use aliasing.
module ResolvesMergeRequests
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize
  prepend ::MergeRequests::LookAheadPreloads

  NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc
    popularity_asc popularity_desc
    label_priority_asc label_priority_desc
    milestone_due_asc milestone_due_desc].freeze

  included do
    type Types::MergeRequestType, null: true
  end

  def resolve_with_lookahead(**args)
    if args[:group_id]
      args[:group_id] = ::GitlabSchema.parse_gid(args[:group_id], expected_type: ::Group).model_id
      args[:include_subgroups] = true
    end

    validate_blob_path!(args)
    validate_closed_range!(args)

    rewrite_param_name(args, :reviewer_wildcard_id, :reviewer_id)
    rewrite_param_name(args, :assignee_wildcard_id, :assignee_id)

    mr_finder = MergeRequestsFinder.new(current_user, prepare_finder_params(args.compact))
    finder = Gitlab::Graphql::Loaders::IssuableLoader.new(mr_parent, mr_finder)

    merge_requests = select_result(finder.batching_find_all { |query| apply_lookahead(query) })

    if non_stable_cursor_sort?(args[:sort])
      # Certain complex sorts are not supported by the stable cursor pagination yet.
      # In these cases, we use offset pagination, so we return the correct connection.
      offset_pagination(merge_requests)
    else
      merge_requests
    end
  end

  def ready?(**args)
    return early_return if no_results_possible?(args)

    super
  end

  def early_return
    [false, single? ? nil : MergeRequest.none]
  end

  private

  def prepare_finder_params(args)
    args
  end

  def mr_parent
    project
  end

  def rewrite_param_name(params, old_name, new_name)
    params[new_name] = params.delete(old_name) if params && params[old_name].present?
  end

  def validate_blob_path!(args)
    return if args[:blob_path].blank?

    required_fields = {
      target_branch: 'targetBranches',
      state: 'state',
      created_after: 'createdAfter'
    }

    required_fields.each do |key, field_name|
      if args[key].blank?
        raise Gitlab::Graphql::Errors::ArgumentError, "#{field_name} field must be specified to filter by blobPath"
      end
    end

    # It's limited for performance reasons
    created_after = args[:created_after].to_datetime
    return if created_after.after?(30.days.ago)

    raise Gitlab::Graphql::Errors::ArgumentError,
      'createdAfter must be within the last 30 days to filter by blobPath'
  end

  def validate_closed_range!(args)
    closed_after = args[:closed_after]
    closed_before = args[:closed_before]

    return if closed_after.nil? && closed_before.nil?

    if closed_after.nil? || closed_before.nil?
      raise Gitlab::Graphql::Errors::ArgumentError,
        'You must provide both closedAfter and closedBefore.'
    end

    if closed_before < closed_after
      raise Gitlab::Graphql::Errors::ArgumentError,
        'closedBefore must be on or after closedAfter.'
    end

    return unless (closed_before - closed_after) > 2.years

    raise Gitlab::Graphql::Errors::ArgumentError,
      'Time between closedAfter and closedBefore must be 2 years or less.'
  end

  def non_stable_cursor_sort?(sort)
    NON_STABLE_CURSOR_SORTS.include?(sort)
  end

  def resource_parent
    # The project could have been loaded in batch by `BatchLoader`.
    # At this point we need the `id` of the project to query for issues, so
    # make sure it's loaded and not `nil` before continuing.
    object.respond_to?(:sync) ? object.sync : object
  end
  strong_memoize_attr :resource_parent
end

ResolvesMergeRequests.prepend_mod
