class Board < ActiveRecord::Base
  belongs_to :project

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all
  belongs_to :milestone

  validates :name, :project, presence: true

  def done_list
    lists.merge(List.done).take
  end
end
