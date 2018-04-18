module Gitlab
  module Auth
    module OAuth
      class IdentityLinker < OmniauthIdentityLinkerBase
        def create_or_update
          current_user.identities
                      .with_extern_uid(oauth['provider'], oauth['uid'])
                      .first_or_create(extern_uid: oauth['uid'])

          @created = true
        end
      end
    end
  end
end
