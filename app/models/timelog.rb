class Timelog < ActiveRecord::Base
  validates :time_spent, :trackable, presence: true

  belongs_to :trackable, polymorphic: true
end
