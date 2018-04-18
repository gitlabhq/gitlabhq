module Gitlab
  module Auth
    module Saml
      class IdentityLinker < OmniauthIdentityLinkerBase
        def create_or_update
          if find_saml_identity.nil?
            create_saml_identity

            @created = true
          else
            @created = false
          end
        end

        protected

        def find_saml_identity
          current_user.identities.with_extern_uid(:saml, oauth['uid']).take
        end

        def create_saml_identity
          current_user.identities.create(extern_uid: oauth['uid'], provider: :saml)
        end
      end
    end
  end
end
