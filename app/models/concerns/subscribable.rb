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

  def subscribed?(user, project)
    if subscription = subscriptions.find_by(user: user, project: project)
      subscription.subscribed
    else
      subscribed_without_subscriptions?(user, project)
    end
  end

  # Override this method to define custom logic to consider a subscribable as
  # subscribed without an explicit subscription record.
  def subscribed_without_subscriptions?(user, project)
    false
  end

  def subscribers(project)
    subscriptions.where(project: project, subscribed: true).map(&:user)
  end

  def toggle_subscription(user, project)
    find_or_initialize_subscription(user, project).
      update(subscribed: !subscribed?(user, project))
  end

  def subscribe(user, project)
    find_or_initialize_subscription(user, project).
      update(subscribed: true)
  end

  def unsubscribe(user, project)
    find_or_initialize_subscription(user, project).
      update(subscribed: false)
  end

  private

  def find_or_initialize_subscription(user, project)
    subscriptions.
      find_or_initialize_by(user_id: user.id, project_id: project.id)
  end
end
