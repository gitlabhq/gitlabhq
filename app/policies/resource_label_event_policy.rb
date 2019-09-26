# frozen_string_literal: true

class ResourceLabelEventPolicy < BasePolicy
  condition(:can_read_label) { @subject.label_id.nil? || can?(:read_label, @subject.label) }
  condition(:can_read_issuable) { can?(:"read_#{@subject.issuable.to_ability_name}", @subject.issuable) }

  rule { can_read_label }.policy do
    enable :read_label
  end

  rule { can_read_label & can_read_issuable }.policy do
    enable :read_resource_label_event
  end
end
