class CreateSpamLogService < BaseService
  def initialize(project, user, params)
    super(project, user, params)
  end

  def execute
    spam_params = params.merge({ user_id: @current_user.id,
                                 project_id: @project.id } )
    spam_log = SpamLog.new(spam_params)
    spam_log.save
    spam_log
  end
end
