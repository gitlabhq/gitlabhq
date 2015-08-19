class BaseService
  include Gitlab::CurrentSettings

  attr_accessor :project, :current_user, :params

  def initialize(project, user, params = {})
    @project, @current_user, @params = project, user, params.dup
  end

  def abilities
    Ability.abilities
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def notification_service
    NotificationService.new
  end

  def event_service
    EventCreateService.new
  end

  def log_info(message)
    Gitlab::AppLogger.info message
  end

  def system_hook_service
    SystemHooksService.new
  end

  def repository
    project.repository
  end

  # Add an error to the specified model for restricted visibility levels
  def deny_visibility_level(model, denied_visibility_level = nil)
    denied_visibility_level ||= model.visibility_level

    level_name = 'Unknown'
    Gitlab::VisibilityLevel.options.each do |name, level|
      level_name = name if level == denied_visibility_level
    end

    model.errors.add(
      :visibility_level,
      "#{level_name} visibility has been restricted by your GitLab administrator"
    )
  end

  private

  def error(message, http_status = nil)
    result = {
      message: message,
      status: :error
    }

    result[:http_status] = http_status if http_status
    result
  end

  def success
    {
      status: :success
    }
  end
end
