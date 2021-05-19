# frozen_string_literal: true

module IssuableCollections
  extend ActiveSupport::Concern
  include PaginatedCollection
  include SortingHelper
  include SortingPreference
  include Gitlab::Utils::StrongMemoize

  included do
    helper_method :finder
  end

  private

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def set_issuables_index
    @issuables = issuables_collection

    unless pagination_disabled?
      set_pagination

      return if redirect_out_of_range(@issuables, @total_pages)
    end

    if params[:label_name].present? && @project
      labels_params = { project_id: @project.id, title: params[:label_name] }
      @labels = LabelsFinder.new(current_user, labels_params).execute
    end

    @users = []
    if params[:assignee_id].present?
      assignee = User.find_by_id(params[:assignee_id])
      @users.push(assignee) if assignee
    end

    if params[:author_id].present?
      author = User.find_by_id(params[:author_id])
      @users.push(author) if author
    end
  end

  def set_pagination
    row_count = finder.row_count

    @issuables          = @issuables.page(params[:page])
    @issuables          = per_page_for_relative_position if params[:sort] == 'relative_position'
    @issuables          = @issuables.without_count if row_count == -1
    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issuables).data
    @total_pages        = page_count_for_relation(@issuables, row_count)
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def pagination_disabled?
    false
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def issuables_collection
    finder.execute.preload(preload_for_collection)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def page_count_for_relation(relation, row_count)
    limit = relation.limit_value.to_f

    return 1 if limit == 0
    return (params[:page] || 1).to_i + 1 if row_count == -1

    (row_count.to_f / limit).ceil
  end

  # manual / relative_position sorting allows for 100 items on the page
  def per_page_for_relative_position
    @issuables.per(100) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def issuable_finder_for(finder_class)
    finder_class.new(current_user, finder_options)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def finder_options
    strong_memoize(:finder_options) do
      params[:state] = default_state if params[:state].blank?

      options = {
        scope: params[:scope],
        state: params[:state],
        confidential: Gitlab::Utils.to_boolean(params[:confidential]),
        sort: set_sort_order
      }

      # Used by view to highlight active option
      @sort = options[:sort]

      # When a user looks for an exact iid, we do not filter by search but only by iid
      if params[:search] =~ /^#(?<iid>\d+)\z/
        options[:iids] = Regexp.last_match[:iid]
        params[:search] = nil
      end

      if @project
        options[:project_id] = @project.id
        options[:attempt_project_search_optimizations] = true
      elsif @group
        options[:group_id] = @group.id
        options[:include_subgroups] = true
        options[:attempt_group_search_optimizations] = true
      end

      params.permit(finder_type.valid_params).merge(options)
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def default_state
    'opened'
  end

  def legacy_sort_cookie_name
    'issuable_sort'
  end

  def default_sort_order
    case params[:state]
    when 'opened', 'all'    then sort_value_created_date
    when 'merged', 'closed' then sort_value_recently_updated
    else sort_value_created_date
    end
  end

  def finder
    @finder ||= issuable_finder_for(finder_type)
  end

  def collection_type
    @collection_type ||= if finder_type <= IssuesFinder
                           'Issue'
                         elsif finder_type <= MergeRequestsFinder
                           'MergeRequest'
                         end
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def preload_for_collection
    common_attributes = [:author, :assignees, :labels, :milestone]
    @preload_for_collection ||= case collection_type
                                when 'Issue'
                                  common_attributes + [:project, project: :namespace]
                                when 'MergeRequest'
                                  common_attributes + [
                                    :target_project, :latest_merge_request_diff, :approvals, :approved_by_users, :reviewers,
                                    source_project: :route, head_pipeline: :project, target_project: :namespace
                                  ]
                                end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end

IssuableCollections.prepend_mod_with('IssuableCollections')
