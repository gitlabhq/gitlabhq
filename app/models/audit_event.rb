class AuditEvent < ActiveRecord::Base
  serialize :details, Hash # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user, foreign_key: :author_id

  validates :author_id, presence: true
  validates :entity_id, presence: true
  validates :entity_type, presence: true

  after_initialize :initialize_details

  def author_name
    details[:author_name].blank? ? user&.name : details[:author_name]
  end

  def initialize_details
    self.details = {} if details.nil?
  end

  def present
    AuditEventPresenter.new(self)
  end
end
