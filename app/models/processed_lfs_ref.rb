class ProcessedLfsRef < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true
  validates :ref, presence: true
end
