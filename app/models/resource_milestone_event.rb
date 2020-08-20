# frozen_string_literal: true

class ResourceMilestoneEvent < ResourceTimeboxEvent
  include IgnorableColumns

  belongs_to :milestone

  scope :include_relations, -> { includes(:user, milestone: [:project, :group]) }

  # state is used for issue and merge request states.
  enum state: Issue.available_states.merge(MergeRequest.available_states)

  ignore_columns %i[reference reference_html cached_markdown_version], remove_with: '13.1', remove_after: '2020-06-22'

  def milestone_title
    milestone&.title
  end

  def milestone_parent
    milestone&.parent
  end
end
