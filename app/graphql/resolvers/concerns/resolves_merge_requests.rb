# frozen_string_literal: true

# Mixin for resolving merge requests. All arguments must be in forms
# that `MergeRequestsFinder` can handle, so you may need to use aliasing.
module ResolvesMergeRequests
  extend ActiveSupport::Concern
  include LooksAhead

  included do
    type Types::MergeRequestType, null: true
  end

  def resolve_with_lookahead(**args)
    mr_finder = MergeRequestsFinder.new(current_user, args.compact)
    finder = Gitlab::Graphql::Loaders::IssuableLoader.new(project, mr_finder)

    select_result(finder.batching_find_all { |query| apply_lookahead(query) })
  end

  def ready?(**args)
    return early_return if no_results_possible?(args)

    super
  end

  def early_return
    [false, single? ? nil : MergeRequest.none]
  end

  private

  def unconditional_includes
    [:target_project]
  end

  def preloads
    {
      assignees: [:assignees],
      labels: [:labels],
      author: [:author],
      milestone: [:milestone],
      head_pipeline: [:merge_request_diff, { head_pipeline: [:merge_request] }]
    }
  end
end
