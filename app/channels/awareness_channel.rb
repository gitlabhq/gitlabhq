# frozen_string_literal: true

class AwarenessChannel < ApplicationCable::Channel # rubocop:disable Gitlab/NamespacedClass
  REFRESH_INTERVAL = ENV.fetch("GITLAB_AWARENESS_REFRESH_INTERVAL_SEC", 60)
  private_constant :REFRESH_INTERVAL

  # Produces a refresh interval value, based of the
  # GITLAB_AWARENESS_REFRESH_INTERVAL_SEC environment variable or the given
  # default. Makes sure, that the interval after a jitter is applied, is never
  # less than half the predefined interval.
  def self.refresh_interval(range: -10..10)
    min = REFRESH_INTERVAL / 2.to_f
    [min.to_i, REFRESH_INTERVAL.to_i + rand(range)].max.seconds
  end
  private_class_method :refresh_interval

  # keep clients updated about session membership
  periodically every: self.refresh_interval do
    transmit payload
  end

  def subscribed
    reject unless valid_subscription?
    return if subscription_rejected?

    stream_for session, coder: ActiveSupport::JSON

    session.join(current_user)
    AwarenessChannel.broadcast_to(session, payload)
  end

  def unsubscribed
    return if subscription_rejected?

    session.leave(current_user)
    AwarenessChannel.broadcast_to(session, payload)
  end

  # Allows a client to let the server know they are still around. This is not
  # like a heartbeat mechanism. This can be triggered by any action that results
  # in a meaningful "presence" update. Like scrolling the screen (debounce),
  # window becoming active, user starting to type in a text field, etc.
  def touch
    session.touch!(current_user)

    transmit payload
  end

  private

  def valid_subscription?
    current_user.present? && path.present?
  end

  def payload
    { collaborators: collaborators }
  end

  def collaborators
    session.online_users_with_last_activity.map do |user, last_activity|
      collaborator(user, last_activity)
    end
  end

  def collaborator(user, last_activity)
    {
      id: user.id,
      name: user.name,
      avatar_url: user.avatar_url(size: 36),
      last_activity: last_activity,
      last_activity_humanized: ActionController::Base.helpers.distance_of_time_in_words(
        Time.zone.now, last_activity
      )
    }
  end

  def session
    @session ||= AwarenessSession.for(path)
  end

  def path
    params[:path]
  end
end
