class ReferenceChange < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true
  validates :newrev, presence: true

  scope :processed, -> { where(processed: true) }
  scope :unprocessed, -> { where(processed: false) }
end
