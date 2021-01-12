# frozen_string_literal: true

class List < ApplicationRecord
  include Boards::Listable
  include Importable

  belongs_to :board
  belongs_to :label
  has_many :list_user_preferences

  enum list_type: { backlog: 0, label: 1, closed: 2, assignee: 3, milestone: 4, iteration: 5 }

  validates :board, :list_type, presence: true, unless: :importing?
  validates :label_id, uniqueness: { scope: :board_id }, if: :label?

  scope :preload_associated_models, -> { preload(:board, label: :priorities) }

  alias_method :preferences, :list_user_preferences

  class << self
    def preload_preferences_for_user(lists, user)
      return unless user

      lists.each { |list| list.preferences_for(user) }
    end
  end

  def preferences_for(user)
    return preferences.build unless user

    BatchLoader.for(list_id: id, user_id: user.id).batch(default_value: preferences.build(user: user)) do |items, loader|
      list_ids = items.map { |i| i[:list_id] }
      user_ids = items.map { |i| i[:user_id] }

      ListUserPreference.where(list_id: list_ids.uniq, user_id: user_ids.uniq).find_each do |preference|
        loader.call({ list_id: preference.list_id, user_id: preference.user_id }, preference)
      end
    end
  end

  def update_preferences_for(user, preferences = {})
    return unless user

    preferences_for(user).update(preferences)
  end

  def collapsed?(user)
    preferences = preferences_for(user)

    preferences.collapsed?
  end

  def as_json(options = {})
    super(options).tap do |json|
      json[:collapsed] = false

      if options.key?(:collapsed)
        json[:collapsed] = collapsed?(options[:current_user])
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
end

List.prepend_if_ee('::EE::List')
