# frozen_string_literal: true

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

    scope :explicitly_subscribed, ->(user) { joins(:subscriptions).where(subscriptions: { user_id: user.id, subscribed: true }) }
    scope :explicitly_unsubscribed, ->(user) { joins(:subscriptions).where(subscriptions: { user_id: user.id, subscribed: false }) }
  end

  def subscribed?(user, project = nil)
    return false unless user

    if (subscription = lazy_subscription(user, project)&.itself)
      subscription.subscribed
    else
      subscribed_without_subscriptions?(user, project)
    end
  end

  def lazy_subscription(user, project = nil)
    return unless user

    BatchLoader.for(id: id, subscribable_type: subscribable_type, project_id: project&.id).batch do |items, loader|
      values = items.each_with_object({ ids: Set.new, subscribable_types: Set.new, project_ids: Set.new }) do |item, result|
        result[:ids] << item[:id]
        result[:subscribable_types] << item[:subscribable_type]
        result[:project_ids] << item[:project_id]
      end

      subscriptions = Subscription.where(subscribable_id: values[:ids], subscribable_type: values[:subscribable_types], project_id: values[:project_ids], user: user)

      subscriptions.each do |subscription|
        loader.call({
          id: subscription.subscribable_id,
          subscribable_type: subscription.subscribable_type,
          project_id: subscription.project_id
        }, subscription)
      end
    end
  end

  # Override this method to define custom logic to consider a subscribable as
  # subscribed without an explicit subscription record.
  def subscribed_without_subscriptions?(user, project)
    false
  end

  def subscribers(project)
    relation = subscriptions_available(project)
                 .where(subscribed: true)
                 .select(:user_id)

    User.where(id: relation)
  end

  def toggle_subscription(user, project = nil)
    unsubscribe_from_other_levels(user, project)

    new_value = !subscribed?(user, project)

    find_or_initialize_subscription(user, project)
      .update(subscribed: new_value)
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

  def set_subscription(user, desired_state, project = nil)
    if desired_state
      subscribe(user, project)
    else
      unsubscribe(user, project)
    end
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
    BatchLoader::Executor.clear_current

    subscriptions
      .find_or_initialize_by(user_id: user.id, project_id: project.try(:id))
  end

  def subscriptions_available(project)
    t = Subscription.arel_table

    subscriptions
      .where(t[:project_id].eq(nil).or(t[:project_id].eq(project.try(:id))))
  end

  def subscribable_type
    # handle project and group labels as well as issuable subscriptions
    if self.class.ancestors.include?(Label)
      'Label'
    elsif self.class.ancestors.include?(Issue)
      'Issue'
    else
      self.class.name
    end
  end
end

Subscribable.prepend_mod
