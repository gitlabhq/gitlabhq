class Board < ActiveRecord::Base
  belongs_to :project

  has_many :lists, dependent: :destroy

  validates :project, presence: true
end
