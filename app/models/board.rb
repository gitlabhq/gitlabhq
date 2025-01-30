# frozen_string_literal: true

class Board < ApplicationRecord
  include EachBatch

  RECENT_BOARDS_SIZE = 4

  belongs_to :group
  belongs_to :project

  has_many :lists, -> { ordered }, dependent: :delete_all, inverse_of: :board # rubocop:disable Cop/ActiveRecordDependent
  has_many :destroyable_lists, -> { destroyable.ordered }, class_name: "List", inverse_of: :board

  validates :name, presence: true
  validates :project, presence: true, if: :project_needed?
  validates :group, presence: true, unless: :project
  validates :group, absence: {
    message: ->(_object, _data) { _("can't be specified if a project was already provided") }
  }, if: :project

  scope :with_associations, -> { preload(:destroyable_lists) }

  # Sort by case-insensitive name, then ascending ids. This ensures that we will always
  # get the same list/first board no matter how many other boards are named the same
  scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc).order(id: :asc) }
  scope :first_board, -> { where(id: order_by_name_asc.limit(1).select(:id)) }

  def project_needed?
    !group
  end

  def resource_parent
    @resource_parent ||= group || project
  end

  def group_board?
    group_id.present?
  end

  def project_board?
    project_id.present?
  end

  def scoped?
    false
  end

  def self.to_type
    name.demodulize
  end

  def to_type
    self.class.to_type
  end

  def disabled_for?(current_user)
    namespace = group_board? ? resource_parent.root_ancestor : resource_parent.root_namespace

    namespace.issue_repositioning_disabled? || !Ability.allowed?(current_user, :create_non_backlog_issues, self)
  end
end

Board.prepend_mod_with('Board')
