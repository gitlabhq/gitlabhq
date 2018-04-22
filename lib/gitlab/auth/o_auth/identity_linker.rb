module Gitlab
  module Auth
    module OAuth
      class IdentityLinker < OmniauthIdentityLinkerBase
        def create_or_update
          if identity.new_record?
            @created = identity.save
          end
        end

        def error_message
          identity.validate

          identity.errors.full_messages.join(', ')
        end

        private

        def identity
          @identity ||= current_user.identities
                        .with_extern_uid(oauth['provider'], oauth['uid'])
                        .first_or_initialize(extern_uid: oauth['uid'])
        end
      end
    end
  end
end
