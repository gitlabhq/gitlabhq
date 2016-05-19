# == Subscribable concern
#
# Users can subscribe to these models.
#
# Used by Issue, MergeRequest, Label
#

module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, dependent: :destroy, as: :subscribable
  end

  def subscribed?(user)
    if subscription = subscriptions.find_by_user_id(user.id)
      subscription.subscribed
    else
      subscribed_without_subscriptions?(user)
    end
  end

  # Override this method to define custom logic to consider a subscribable as
  # subscribed without an explicit subscription record.
  def subscribed_without_subscriptions?(user)
    false
  end

  def subscribers
    subscriptions.where(subscribed: true).map(&:user)
  end

  def toggle_subscription(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: !subscribed?(user))
  end

  def subscribe(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: true)
  end

  def unsubscribe(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: false)
  end
end
