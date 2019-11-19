# frozen_string_literal: true

# Holds reasons for a notification to have been sent as well as a priority list to select which reason to use
# above the rest
class NotificationReason
  OWN_ACTIVITY = 'own_activity'
  ASSIGNED = 'assigned'
  MENTIONED = 'mentioned'
  SUBSCRIBED = 'subscribed'

  # Priority list for selecting which reason to return in the notification
  REASON_PRIORITY = [
    OWN_ACTIVITY,
    ASSIGNED,
    MENTIONED,
    SUBSCRIBED
  ].freeze

  # returns the priority of a reason as an integer
  def self.priority(reason)
    REASON_PRIORITY.index(reason) || REASON_PRIORITY.length + 1
  end
end
