class List < ActiveRecord::Base
  belongs_to :board
  belongs_to :label

  enum list_type: { label: 0, backlog: 1, done: 2 }

  validates :board, :list_type, :position, presence: true
  validates :label, presence: true, if: :label?
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
