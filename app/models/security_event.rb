# == Schema Information
#
# Table name: audit_events
#
#  id          :integer          not null, primary key
#  author_id   :integer          not null
#  type        :string           not null
#  entity_id   :integer          not null
#  entity_type :string           not null
#  details     :text
#  created_at  :datetime
#  updated_at  :datetime
#

class SecurityEvent < AuditEvent
end
