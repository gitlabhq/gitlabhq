# frozen_string_literal: true

class UserAgentDetailService
  attr_accessor :spammable, :request

  def initialize(spammable, request)
    @spammable = spammable
    @request = request
  end

  def create
    return unless request

    spammable.create_user_agent_detail(user_agent: request.env['HTTP_USER_AGENT'], ip_address: request.env['action_dispatch.remote_ip'].to_s)
  end
end
