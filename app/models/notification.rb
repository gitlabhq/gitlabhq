class Notification
  #
  # Notification levels
  #
  N_DISABLED = 0
  N_PARTICIPATING = 1
  N_WATCH = 2
  N_GLOBAL = 3
  N_MENTION = 4

  attr_accessor :target

  class << self
    def notification_levels
      [N_DISABLED, N_MENTION, N_PARTICIPATING, N_WATCH]
    end

    def options_with_labels
      {
        disabled: N_DISABLED,
        participating: N_PARTICIPATING,
        watch: N_WATCH,
        mention: N_MENTION,
        global: N_GLOBAL
      }
    end

    def project_notification_levels
      [N_DISABLED, N_MENTION, N_PARTICIPATING, N_WATCH, N_GLOBAL]
    end
  end

  delegate :disabled?, :participating?, :watch?, :global?, :mention?, to: :target

  def initialize(target)
    @target = target
  end

  def level
    target.notification_level
  end

  def to_s
    case level
    when N_DISABLED
      'Disabled'
    when N_PARTICIPATING
      'Participating'
    when N_WATCH
      'Watching'
    when N_MENTION
      'On mention'
    when N_GLOBAL
      'Global'
    else
      # do nothing
    end
  end
end
