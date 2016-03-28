class Notification
  attr_accessor :target

  delegate :disabled?, :participating?, :watch?, :global?, :mention?, to: :target

  def initialize(target)
    @target = target
  end

  def level
    target.notification_level
  end
end
