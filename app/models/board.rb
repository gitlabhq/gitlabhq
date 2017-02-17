class Board < ActiveRecord::Base
  belongs_to :project
  belongs_to :milestone

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all

  validates :name, :project, presence: true

  def done_list
    lists.merge(List.done).take
  end

  def milestone
    if milestone_id === Milestone::Upcoming.id
      Milestone::Upcoming
    else
      super
    end
  end
end
