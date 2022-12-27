# frozen_string_literal: true

class ResourceEventPolicy < BasePolicy
  condition(:can_read_issuable) { can?(:"read_#{@subject.issuable.to_ability_name}", @subject.issuable) }
end
