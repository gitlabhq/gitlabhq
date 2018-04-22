class SamlProviderPolicy < BasePolicy
  rule { ~anonymous }.enable :sign_in_with_saml_provider
end
