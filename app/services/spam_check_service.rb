class SpamCheckService < BaseService
  attr_accessor :request, :api, :subject

  def execute(request, api, subject)
    @request, @api, @subject = request, api, subject
    return false unless request || subject.check_for_spam?(project)
    return false unless subject.spam?(request.env, current_user)

    create_spam_log

    true
  end

  private
  
  def spam_log_attrs
    {
      user_id: current_user.id,
      project_id: project.id,
      title: params[:title],
      description: params[:description],
      source_ip: subject.client_ip(request.env),
      user_agent: subject.user_agent(request.env),
      noteable_type: subject.class.to_s,
      via_api: api
    }
  end

  def create_spam_log
    CreateSpamLogService.new(project, current_user, spam_log_attrs).execute
  end
end
