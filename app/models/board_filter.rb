class BoardFilter < ActiveRecord::Base
  belongs_to :board
  belongs_to :milestone
  belongs_to :author, class_name: 'User'
  belongs_to :assignee, class_name: 'User'

  has_many :board_filter_labels
  has_many :labels, through: :board_filter_labels

  validates :board, presence: true

  def milestone
    return nil unless board.parent.feature_available?(:scoped_issue_board)

    if milestone_id == ::Milestone::Upcoming.id
      ::Milestone::Upcoming
    else
      super
    end
  end
end
