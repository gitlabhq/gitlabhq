# frozen_string_literal: true

class ResourceMilestoneEvent < ResourceTimeboxEvent
  belongs_to :milestone

  scope :include_relations, -> { includes(:user, milestone: [:project, :group]) }
  scope :aliased_for_timebox_report, -> do
    select("'timebox' AS event_type", "id", "created_at", "milestone_id AS value", "action", "issue_id")
  end

  # state is used for issue and merge request states.
  enum state: Issue.available_states.merge(MergeRequest.available_states)

  def milestone_title
    milestone&.title
  end

  def milestone_parent
    milestone&.parent
  end

  def synthetic_note_class
    MilestoneNote
  end
end
