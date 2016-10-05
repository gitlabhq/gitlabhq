class Approver < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :user

  validates :user, presence: true
end
