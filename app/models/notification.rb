class Notification
  #
  # Notification levels
  #
  N_DISABLED = 0
  N_PARTICIPATING = 1
  N_WATCH = 2
  N_GLOBAL = 3

  attr_accessor :target

  def self.notification_levels
    [N_DISABLED, N_PARTICIPATING, N_WATCH]
  end

  def self.project_notification_levels
    [N_DISABLED, N_PARTICIPATING, N_WATCH, N_GLOBAL]
  end

  def initialize(target)
    @target = target
  end

  def disabled?
    target.notification_level == N_DISABLED
  end

  def participating?
    target.notification_level == N_PARTICIPATING
  end

  def watch?
    target.notification_level == N_WATCH
  end

  def global?
    target.notification_level == N_GLOBAL
  end
end
