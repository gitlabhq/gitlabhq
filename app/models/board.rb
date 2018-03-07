class Board < ActiveRecord::Base
  belongs_to :group
  belongs_to :project

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  validates :project, presence: true, if: :project_needed?
  validates :group, presence: true, unless: :project

  def project_needed?
    !group
  end

  def parent
    @parent ||= group || project
  end

  def group_board?
    group_id.present?
  end

  def backlog_list
    lists.merge(List.backlog).take
  end

  def closed_list
    lists.merge(List.closed).take
  end
end
