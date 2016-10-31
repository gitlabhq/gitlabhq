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

  def subscribed?(user, to_project = nil)
    if subscription = subscriptions.find_by(user: user, project: (to_project || project))
      subscription.subscribed
    else
      subscribed_without_subscriptions?(user, to_project)
    end
  end

  # Override this method to define custom logic to consider a subscribable as
  # subscribed without an explicit subscription record.
  def subscribed_without_subscriptions?(user, to_project = nil)
    false
  end

  def subscribers(to_project = nil)
    subscriptions.where(project: (to_project || project), subscribed: true).map(&:user)
  end

  def toggle_subscription(user, to_project = nil)
    subscribed = subscribed?(user, (to_project || project))

    find_or_initialize_subscription(user, to_project).
      update(subscribed: !subscribed)
  end

  def subscribe(user, to_project = nil)
    find_or_initialize_subscription(user, to_project).
      update(subscribed: true)
  end

  def unsubscribe(user, to_project = nil)
    find_or_initialize_subscription(user, to_project).
      update(subscribed: false)
  end

  private

  def find_or_initialize_subscription(user, to_project = nil)
    subscriptions.
      find_or_initialize_by(user_id: user.id, project_id: (to_project || project).id)
  end
end
