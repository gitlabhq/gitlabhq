module Gitlab
  module Auth
    class OmniauthIdentityLinkerBase
      attr_reader :current_user, :oauth

      def initialize(current_user, oauth)
        @current_user = current_user
        @oauth = oauth
        @created = false
      end

      def created?
        @created
      end

      def error_message
        ''
      end

      def create_or_update
        raise NotImplementedError
      end
    end
  end
end
