class NotificationRecipient
  attr_reader :user, :type
  def initialize(
    user, type,
    custom_action: nil,
    target: nil,
    acting_user: nil,
    read_ability: nil,
    project: nil
  )
    @custom_action = custom_action
    @acting_user = acting_user
    @read_ability = read_ability
    @target = target
    @project = project || @target&.project
    @user = user
    @type = type
  end

  def notification_setting
    @notification_setting ||= find_notification_setting
  end

  def raw_notification_level
    notification_setting&.level&.to_sym
  end

  def notification_level
    # custom is treated the same as watch if it's enabled - otherwise it's
    # set to :custom, meaning to send exactly when our type is :participating
    # or :mention.
    @notification_level ||=
      case raw_notification_level
      when :custom
        if @custom_action && notification_setting&.event_enabled?(@custom_action)
          :watch
        else
          :custom
        end
      else
        raw_notification_level
      end
  end

  def notifiable?
    return false unless has_access?
    return false if own_activity?

    return true if @type == :subscription

    return false if notification_level.nil? || notification_level == :disabled

    return %i[participating mention].include?(@type) if notification_level == :custom

    return false if %i[watch participating].include?(notification_level) && excluded_watcher_action?

    return false unless NotificationSetting.levels[notification_level] <= NotificationSetting.levels[@type]

    return false if unsubscribed?

    true
  end

  def unsubscribed?
    return false unless @target
    return false unless @target.respond_to?(:subscriptions)

    subscription = @target.subscriptions.find_by_user_id(@user.id)
    subscription && !subscription.subscribed
  end

  def own_activity?
    return false unless @acting_user
    return false if @acting_user.notified_of_own_activity?

    user == @acting_user
  end

  def has_access?
    DeclarativePolicy.subject_scope do
      return false unless user.can?(:receive_notifications)
      return false if @project && !user.can?(:read_project, @project)

      return true unless @read_ability
      return true unless DeclarativePolicy.has_policy?(@target)

      user.can?(@read_ability, @target)
    end
  end

  def excluded_watcher_action?
    return false unless @custom_action
    return false if raw_notification_level == :custom

    NotificationSetting::EXCLUDED_WATCHER_EVENTS.include?(@custom_action)
  end

  private

  def find_notification_setting
    project_setting = @project && user.notification_settings_for(@project)

    return project_setting unless project_setting.nil? || project_setting.global?

    group_setting = @project&.group && user.notification_settings_for(@project.group)

    return group_setting unless group_setting.nil? || group_setting.global?

    user.global_notification_setting
  end
end
