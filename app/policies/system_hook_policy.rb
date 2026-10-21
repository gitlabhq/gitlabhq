# frozen_string_literal: true

class SystemHookPolicy < ::BasePolicy
  delegate { @subject.organization }

  # Instance admins (in admin mode) and organization admins are both authorized through the
  # hook's organization, which grants the granular webhook permissions to their roles.
  #
  # The consumers of system hooks (WebHookLogsFinder, WebHooks::Events::ResendService,
  # WebHooks::DestroyService) still check the legacy abilities, so bridge them here.
  #
  # `admin_web_hook` currently covers update, delete and resend, so require every granular
  # ability it stands for. This fails closed for roles that hold only a subset.
  rule { can?(:read_webhook) }.enable :read_web_hook
  rule { can?(:update_webhook) & can?(:delete_webhook) }.enable :admin_web_hook
end
