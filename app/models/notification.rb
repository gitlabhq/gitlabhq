class Notification
  #
  # Notification levels
  #
  N_DISABLED = 0
  N_PARTICIPATING = 1
  N_WATCH = 2

  attr_accessor :user

  def self.notification_levels
    [N_DISABLED, N_PARTICIPATING, N_WATCH]
  end

  def initialize(user)
    @user = user
  end

  def disabled?
    user.notification_level == N_DISABLED
  end

  def participating?
    user.notification_level == N_PARTICIPATING
  end

  def watch?
    user.notification_level == N_WATCH
  end
end
