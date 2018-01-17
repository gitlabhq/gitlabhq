class EpicIssue < ActiveRecord::Base
  include RelativePositioning

  validates :epic, :issue, presence: true
  validates :issue, uniqueness: true

  belongs_to :epic
  belongs_to :issue

  alias_attribute :parent_ids, :epic_id

  scope :in_epic, ->(epic_id) { where(epic_id: epic_id) }

  class << self
    alias_method :in_parents, :in_epic
  end
end
