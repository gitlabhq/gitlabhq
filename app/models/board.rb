class Board < ActiveRecord::Base
  prepend EE::Board

  belongs_to :project

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  validates :name, presence: true

  # if block needed only for EE which has group boards feature
  validates :project, presence: true, if: -> { respond_to?(:group_id) && !group }

  def backlog_list
    lists.merge(List.backlog).take
  end

  def closed_list
    lists.merge(List.closed).take
  end
end
