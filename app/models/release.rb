class Release < ActiveRecord::Base
  belongs_to :project

  validates :description, :project, :tag, presence: true
end
