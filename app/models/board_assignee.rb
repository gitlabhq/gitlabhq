class BoardAssignee < ActiveRecord::Base
  belongs_to :board
  belongs_to :assignee, class_name: 'User'

  validates :board, presence: true
  validates :assignee, presence: true
end
