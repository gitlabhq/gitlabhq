# frozen_string_literal: true

class List < ApplicationRecord
  include Importable

  belongs_to :board
  belongs_to :label
  has_many :list_user_preferences

  enum list_type: { backlog: 0, label: 1, closed: 2, assignee: 3, milestone: 4 }

  validates :board, :list_type, presence: true, unless: :importing?
  validates :label, :position, presence: true, if: :label?
  validates :label_id, uniqueness: { scope: :board_id }, if: :label?
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, if: :movable?

  before_destroy :can_be_destroyed

  scope :destroyable, -> { where(list_type: list_types.slice(*destroyable_types).values) }
  scope :movable, -> { where(list_type: list_types.slice(*movable_types).values) }

  scope :preload_associations, -> (user) do
    preload(:board, label: :priorities)
      .with_preferences_for(user)
  end

  scope :ordered, -> { order(:list_type, :position) }

  # Loads list with preferences for given user
  # if preferences exists for user or not
  scope :with_preferences_for, -> (user) do
    return unless user

    includes(:list_user_preferences).where(list_user_preferences: { user_id: [user.id, nil] })
  end

  alias_method :preferences, :list_user_preferences

  class << self
    def destroyable_types
      [:label]
    end

    def movable_types
      [:label]
    end
  end

  def preferences_for(user)
    return preferences.build unless user

    if preferences.loaded?
      preloaded_preferences_for(user)
    else
      preferences.find_or_initialize_by(user: user)
    end
  end

  def preloaded_preferences_for(user)
    user_preferences =
      preferences.find do |preference|
        preference.user_id == user.id
      end

    user_preferences || preferences.build(user: user)
  end

  def update_preferences_for(user, preferences = {})
    return unless user

    preferences_for(user).update(preferences)
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
      json[:collapsed] = false

      if options.key?(:collapsed)
        preferences = preferences_for(options[:current_user])

        json[:collapsed] = preferences.collapsed?
      end

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
    throw(:abort) unless destroyable?
  end
end
