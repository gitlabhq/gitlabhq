# == Schema Information
#
# Table name: audit_events
#
#  id          :integer          not null, primary key
#  author_id   :integer          not null
#  type        :string(255)      not null
#  entity_id   :integer          not null
#  entity_type :string(255)      not null
#  details     :text
#  created_at  :datetime
#  updated_at  :datetime
#

class AuditEvent < ActiveRecord::Base
  serialize :details, Hash

  belongs_to :user, foreign_key: :author_id

  validates :author_id, presence: true
  validates :entity_id, presence: true
  validates :entity_type, presence: true

  after_initialize :initialize_details

  def initialize_details
    self.details = {} if details.nil?
  end

  def author_name
    self.user.name
  end
end
