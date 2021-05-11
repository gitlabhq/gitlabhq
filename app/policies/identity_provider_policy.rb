# frozen_string_literal: true

class IdentityProviderPolicy < BasePolicy
  desc "Provider is SAML or CAS3"
  condition(:protected_provider, scope: :subject, score: 0) { %w(saml cas3).include?(@subject.to_s) }

  rule { anonymous }.prevent_all

  rule { default }.policy do
    enable :unlink
    enable :link
  end

  rule { protected_provider }.prevent(:unlink)
end

IdentityProviderPolicy.prepend_mod_with('IdentityProviderPolicy')
