# frozen_string_literal: true

class UserAgentDetailService
  def initialize(spammable:, perform_spam_check:, current_user:)
    @spammable = spammable
    @perform_spam_check = perform_spam_check
    @current_user = current_user
  end

  def create
    spam_params = Gitlab::RequestContext.instance.spam_params
    if !perform_spam_check || spam_params&.user_agent.blank? || spam_params&.ip_address.blank?
      message = 'Skipped UserAgentDetail creation because necessary spam_params were not provided'
      return ServiceResponse.success(message: message)
    end

    spammable.create_user_agent_detail(
      ip_address: spam_params.ip_address,
      organization_id: organization_id,
      user_agent: spam_params.user_agent
    )
  end

  private

  attr_reader :spammable, :perform_spam_check, :current_user

  # UserAgentDetail has no user/user_id of its own to fall back on, so unlike
  # Ai::UsageEvent, a nil current_user here would otherwise silently fail to
  # save instead of erroring - default to the default Organization instead.
  # Deliberate, temporary regression - see
  # https://gitlab.com/gitlab-org/gitlab/-/issues/610965.
  def organization_id
    current_user&.organization_id || Organizations::Organization::DEFAULT_ORGANIZATION_ID # rubocop:todo Gitlab/AvoidConstDefaultOrganizationId -- see comment above
  end
end
