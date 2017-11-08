class EpicIssue < ActiveRecord::Base
  validates :epic, :issue, presence: true
  validates :issue, uniqueness: true

  belongs_to :epic
  belongs_to :issue
end
