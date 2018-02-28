# == Subscribable concern
#
# Users can subscribe to these models.
#
# Used by Issue, MergeRequest, Label
#

module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, dependent: :destroy, as: :subscribable # rubocop:disable Cop/ActiveRecordDependent
  end

  def subscribed?(user, project = nil)
    return false unless user

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
    subscriptions_available(project)
      .where(subscribed: true)
      .map(&:user)
  end

  def toggle_subscription(user, project = nil)
    unsubscribe_from_other_levels(user, project)

    find_or_initialize_subscription(user, project)
      .update(subscribed: !subscribed?(user, project))
  end

  def subscribe(user, project = nil)
    unsubscribe_from_other_levels(user, project)

    find_or_initialize_subscription(user, project)
      .update(subscribed: true)
  end

  def unsubscribe(user, project = nil)
    unsubscribe_from_other_levels(user, project)

    find_or_initialize_subscription(user, project)
      .update(subscribed: false)
  end

  private

  def unsubscribe_from_other_levels(user, project)
    other_subscriptions = subscriptions.where(user: user)

    other_subscriptions =
      if project.blank?
        other_subscriptions.where.not(project: nil)
      else
        other_subscriptions.where(project: nil)
      end

    other_subscriptions.update_all(subscribed: false)
  end

  def find_or_initialize_subscription(user, project)
    subscriptions
      .find_or_initialize_by(user_id: user.id, project_id: project.try(:id))
  end

  def subscriptions_available(project)
    t = Subscription.arel_table

    subscriptions
      .where(t[:project_id].eq(nil).or(t[:project_id].eq(project.try(:id))))
  end
end
