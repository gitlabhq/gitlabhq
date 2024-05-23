# frozen_string_literal: true

class ResourceMilestoneEvent < ResourceTimeboxEvent
  include EachBatch
  include Import::HasImportSource
  include IgnorableColumns

  ignore_column :imported, remove_with: '17.2', remove_after: '2024-07-22'

  belongs_to :milestone

  scope :include_relations, -> { includes(:user, milestone: [:project, :group]) }

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

ResourceMilestoneEvent.prepend_mod
