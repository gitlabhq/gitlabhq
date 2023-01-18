# frozen_string_literal: true

class ResourceStateEventPolicy < ResourceEventPolicy
  condition(:can_read_issuable) { can?(:"read_#{@subject.issuable.to_ability_name}", @subject.issuable) }

  rule { can_read_issuable }.policy do
    enable :read_resource_state_event
    enable :read_note
  end
end
