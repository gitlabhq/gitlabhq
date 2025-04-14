# frozen_string_literal: true

class List < ApplicationRecord
  include Boards::Listable
  include Importable

  belongs_to :board
  belongs_to :label
  belongs_to :group
  belongs_to :project

  has_many :list_user_preferences

  enum list_type: { backlog: 0, label: 1, closed: 2, assignee: 3, milestone: 4, iteration: 5 }

  validates :board, :list_type, presence: true, unless: :importing?
  validates :label_id, uniqueness: { scope: :board_id }, if: :label?
  validates :group, presence: true, unless: :project
  validates :project, presence: true, unless: :group
  validates :group, absence: {
    message: ->(_object, _data) { _("can't be specified if a project was already provided") }
  }, if: :project

  before_validation :ensure_group_or_project

  scope :preload_associated_models, -> { preload(:board, label: :priorities) }

  alias_method :preferences, :list_user_preferences

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

  private

  def ensure_group_or_project
    self.group_id = board&.group_id
    self.project_id = board&.project_id
  end
end

List.prepend_mod
