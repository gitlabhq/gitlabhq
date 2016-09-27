class Board < ActiveRecord::Base
  belongs_to :project

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all

  validates :project, presence: true

  def backlog_list
    lists.merge(List.backlog).take
  end

  def done_list
    lists.merge(List.done).take
  end
end
