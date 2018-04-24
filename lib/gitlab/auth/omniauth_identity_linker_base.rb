module Gitlab
  module Auth
    class OmniauthIdentityLinkerBase
      attr_reader :current_user, :oauth

      def initialize(current_user, oauth)
        @current_user = current_user
        @oauth = oauth
        @changed = false
      end

      def link
        save if identity.new_record?
      end

      def changed?
        @changed
      end

      def error_message
        identity.validate

        identity.errors.full_messages.join(', ')
      end

      private

      def save
        @changed = identity.save
      end

      def identity
        @identity ||= current_user.identities
                                  .with_extern_uid(provider, uid)
                                  .first_or_initialize(extern_uid: uid)
      end

      def provider
        oauth['provider']
      end

      def uid
        oauth['uid']
      end
    end
  end
end
