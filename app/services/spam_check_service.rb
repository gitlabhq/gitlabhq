class SpamCheckService < BaseService
  include Gitlab::AkismetHelper

  attr_accessor :request, :api

  def execute(request, api)
    @request, @api = request, api
    return false unless request || check_for_spam?(project)
    return false unless is_spam?(request.env, current_user, text)
    
    create_spam_log

    true
  end

  private

  def text
    [params[:title], params[:description]].reject(&:blank?).join("\n")
  end
  
  def spam_log_attrs
    {
      user_id: current_user.id,
      project_id: project.id,
      title: params[:title],
      description: params[:description],
      source_ip: client_ip(request.env),
      user_agent: user_agent(request.env),
      noteable_type: 'Issue',
      via_api: api
    }
  end

  def create_spam_log
    CreateSpamLogService.new(project, current_user, spam_log_attrs).execute
  end
end
