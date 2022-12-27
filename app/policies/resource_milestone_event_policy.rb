# frozen_string_literal: true

class ResourceMilestoneEventPolicy < ResourceEventPolicy
  condition(:can_read_milestone) { @subject.milestone_id.nil? || can?(:read_milestone, @subject.milestone) }

  rule { can_read_milestone }.policy do
    enable :read_milestone
  end

  rule { can_read_milestone & can_read_issuable }.policy do
    enable :read_resource_milestone_event
    enable :read_note
  end
end
