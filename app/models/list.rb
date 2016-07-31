class List < ActiveRecord::Base
  belongs_to :board
  belongs_to :label

  enum list_type: { backlog: 0, label: 1, done: 2 }

  validates :board, :list_type, presence: true
  validates :label, :position, presence: true, if: :label?
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :label?

  delegate :name, to: :label, allow_nil: true, prefix: true

  before_destroy :can_be_destroyed, unless: :label?

  def title
    label? ? label_name : list_type.humanize
  end

  private

  def can_be_destroyed
    false
  end
end
