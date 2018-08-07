# frozen_string_literal: true

class List < ActiveRecord::Base
  prepend ::EE::List

  belongs_to :board
  belongs_to :label

  enum list_type: { backlog: 0, label: 1, closed: 2, assignee: 3, milestone: 4 }

  validates :board, :list_type, presence: true
  validates :label, :position, presence: true, if: :label?
  validates :label_id, uniqueness: { scope: :board_id }, if: :label?
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :movable?

  before_destroy :can_be_destroyed

  scope :destroyable, -> { where(list_type: list_types.slice(*destroyable_types).values) }
  scope :movable, -> { where(list_type: list_types.slice(*movable_types).values) }

  class << self
    def destroyable_types
      [:label]
    end

    def movable_types
      [:label]
    end
  end

  def destroyable?
    self.class.destroyable_types.include?(list_type&.to_sym)
  end

  def movable?
    self.class.movable_types.include?(list_type&.to_sym)
  end

  def title
    label? ? label.name : list_type.humanize
  end

  def as_json(options = {})
    super(options).tap do |json|
      if options.key?(:label)
        json[:label] = label.as_json(
          project: board.project,
          only: [:id, :title, :description, :color],
          methods: [:text_color]
        )
      end
    end
  end

  private

  def can_be_destroyed
    destroyable?
  end
end
