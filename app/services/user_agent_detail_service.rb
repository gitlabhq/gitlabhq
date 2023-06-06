# frozen_string_literal: true

class UserAgentDetailService
  def initialize(spammable:, perform_spam_check:)
    @spammable = spammable
    @perform_spam_check = perform_spam_check
  end

  def create
    spam_params = Gitlab::RequestContext.instance.spam_params
    if !perform_spam_check || spam_params&.user_agent.blank? || spam_params&.ip_address.blank?
      message = 'Skipped UserAgentDetail creation because necessary spam_params were not provided'
      return ServiceResponse.success(message: message)
    end

    spammable.create_user_agent_detail(user_agent: spam_params.user_agent, ip_address: spam_params.ip_address)
  end

  private

  attr_reader :spammable, :perform_spam_check
end
