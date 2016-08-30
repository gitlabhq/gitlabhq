class Board < ActiveRecord::Base
  belongs_to :project

  has_many :lists, -> { order(:list_type, :position) }, dependent: :delete_all

  validates :project, presence: true
end
