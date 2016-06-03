# == Schema Information
#
# Table name: subscriptions
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  subscribable_id   :integer
#  subscribable_type :string
#  subscribed        :boolean
#  created_at        :datetime
#  updated_at        :datetime
#

class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscribable, polymorphic: true

  validates :user_id,
            uniqueness: { scope: [:subscribable_id, :subscribable_type] },
            presence: true
end
