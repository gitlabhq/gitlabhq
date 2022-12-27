# frozen_string_literal: true

class ResourceLabelEventPolicy < ResourceEventPolicy
  condition(:can_read_label) { @subject.label_id.nil? || can?(:read_label, @subject.label) }

  rule { can_read_label }.policy do
    enable :read_label
  end

  rule { can_read_label & can_read_issuable }.policy do
    enable :read_resource_label_event
    enable :read_note
  end
end
