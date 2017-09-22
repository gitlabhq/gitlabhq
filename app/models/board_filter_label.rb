class BoardFilterLabel < ActiveRecord::Base
  belongs_to :board_filter
  belongs_to :label

  validates :board_filter, presence: true
  validates :label, presence: true
  validates :board_filter, uniqueness: { scope: :label_id }
end