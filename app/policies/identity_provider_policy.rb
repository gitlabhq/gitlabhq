# frozen_string_literal: true

class IdentityProviderPolicy < BasePolicy
  desc "Provider is SAML"
  condition(:protected_provider, scope: :subject, score: 0) { @subject.to_s == 'saml' }

  rule { anonymous }.prevent_all

  rule { default }.policy do
    enable :unlink
    enable :link
  end

  rule { protected_provider }.prevent(:unlink)
end

# Added for JiHu
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127672#note_1568398967
IdentityProviderPolicy.prepend_mod
