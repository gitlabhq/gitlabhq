class ApproverGroup < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :group

  validates :group, presence: true

  delegate :users, to: :group
end
