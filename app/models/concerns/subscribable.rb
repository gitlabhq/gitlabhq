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
    subscription = subscriptions.find_by_user_id(user.id)

    if subscription
      return subscription.subscribed
    end

    # FIXME
    # Issue/MergeRequest has participants, but Label doesn't.
    # Ideally, subscriptions should be separate from participations,
    # but that seems like a larger change with farther-reaching
    # consequences, so this is a compromise for the time being.
    if respond_to?(:participants)
      participants(user).include?(user)
    end
  end

  def toggle_subscription(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: !subscribed?(user))
  end

  def unsubscribe(user)
    subscriptions.
      find_or_initialize_by(user_id: user.id).
      update(subscribed: false)
  end
end
