module Gitlab
  module Auth
    module GroupSaml
      class IdentityLinker < Gitlab::Auth::Saml::IdentityLinker
        attr_reader :saml_provider

        def initialize(current_user, oauth, saml_provider)
          super(current_user, oauth)

          @saml_provider = saml_provider
        end

        protected

        def identity
          @identity ||= current_user.identities.where(provider: :group_saml,
                                                      saml_provider: saml_provider,
                                                      extern_uid: uid.to_s)
                                    .first_or_initialize
        end
      end
    end
  end
end
