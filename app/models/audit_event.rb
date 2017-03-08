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
    self.user.try(:name) || details[:author_name]
  end
end
