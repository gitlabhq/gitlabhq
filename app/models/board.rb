# frozen_string_literal: true

class Board < ApplicationRecord
  belongs_to :group
  belongs_to :project

  has_many :lists, -> { ordered }, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
  has_many :destroyable_lists, -> { destroyable.ordered }, class_name: "List"

  validates :project, presence: true, if: :project_needed?
  validates :group, presence: true, unless: :project

  scope :with_associations, -> { preload(:destroyable_lists) }

  def project_needed?
    !group
  end

  def parent
    @parent ||= group || project
  end
  alias_method :resource_parent, :parent

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
