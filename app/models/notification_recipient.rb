class NotificationRecipient
  attr_reader :user, :type
  def initialize(
    user, type,
    custom_action: nil,
    target: nil,
    acting_user: nil,
    project: nil
  )
    @custom_action = custom_action
    @acting_user = acting_user
    @target = target
    @project = project || @target&.project
    @user = user
    @type = type
  end

  def notification_setting
    @notification_setting ||= find_notification_setting
  end

  def notification_level
    @notification_level ||= notification_setting&.level&.to_sym
  end

  def notifiable?
    return false unless has_access?
    return false if own_activity?

    # even users with :disabled notifications receive manual subscriptions
    return !unsubscribed? if @type == :subscription

    return false unless suitable_notification_level?

    # check this last because it's expensive
    # nobody should receive notifications if they've specifically unsubscribed
    return false if unsubscribed?

    true
  end

  def suitable_notification_level?
    case notification_level
    when :disabled, nil
      false
    when :custom
      custom_enabled? || %i[participating mention].include?(@type)
    when :watch, :participating
      !excluded_watcher_action?
    when :mention
      @type == :mention
    else
      false
    end
  end

  def custom_enabled?
    @custom_action && notification_setting&.event_enabled?(@custom_action)
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

      return true unless read_ability
      return true unless DeclarativePolicy.has_policy?(@target)

      user.can?(read_ability, @target)
    end
  end

  def excluded_watcher_action?
    return false unless @custom_action
    return false if notification_level == :custom

    NotificationSetting::EXCLUDED_WATCHER_EVENTS.include?(@custom_action)
  end

  private

  def read_ability
    return @read_ability if instance_variable_defined?(:@read_ability)

    @read_ability =
      case @target
      when Issuable
        :"read_#{@target.to_ability_name}"
      when Ci::Pipeline
        :read_build # We have build trace in pipeline emails
      when ActiveRecord::Base
        :"read_#{@target.class.model_name.name.underscore}"
      else
        nil
      end
  end

  def find_notification_setting
    project_setting = @project && user.notification_settings_for(@project)

    return project_setting unless project_setting.nil? || project_setting.global?

    group_setting = @project&.group && user.notification_settings_for(@project.group)

    return group_setting unless group_setting.nil? || group_setting.global?

    user.global_notification_setting
  end
end
