class Timelog < ActiveRecord::Base
  validates :time_spent, presence: true

  belongs_to :trackable, polymorphic: true
  belongs_to :user
end
