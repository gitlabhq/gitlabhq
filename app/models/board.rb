# frozen_string_literal: true

class Board < ApplicationRecord
  belongs_to :group
  belongs_to :project

  has_many :lists, -> { ordered }, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :destroyable_lists, -> { destroyable.ordered }, class_name: "List"

  validates :project, presence: true, if: :project_needed?
  validates :group, presence: true, unless: :project

  scope :with_associations, -> { preload(:destroyable_lists) }

  # Sort by case-insensitive name, then ascending ids. This ensures that we will always
  # get the same list/first board no matter how many other boards are named the same
  scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc).order(id: :asc) }
  scope :first_board, -> { where(id: self.order_by_name_asc.limit(1).select(:id)) }

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

  def backlog_list
    lists.merge(List.backlog).take
  end

  def closed_list
    lists.merge(List.closed).take
  end

  def scoped?
    false
  end
end

Board.prepend_if_ee('EE::Board')
