class UserAgentDetailService
  attr_accessor :subject, :request

  def initialize(subject, request)
    @subject, @request = subject, request
  end

  def create
    return unless request
    subject.create_user_agent_detail(user_agent: request.env['HTTP_USER_AGENT'], ip_address: request.env['action_dispatch.remote_ip'].to_s)
  end
end
