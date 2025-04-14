# frozen_string_literal:true

module Authn
  module Tokens
    class GitlabSession
      def self.prefix?(plaintext)
        plaintext.start_with?(session_cookie_key_prefix)
      end

      def self.session_cookie_key_prefix
        "#{Gitlab::Application.config.session_options[:key]}="
      end

      attr_reader :revocable, :source, :session_id

      def initialize(plaintext, source)
        @session_id = find_session_id(plaintext)

        session = find_session
        @revocable = Warden::SessionSerializer.new('rack.session' => session).fetch(:user) if session

        @source = source
      end

      def present_with
        ::API::Entities::User
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        Users::DestroySessionService.new(current_user: current_user, user: revocable,
          private_session_id: session_id.private_id).execute
      end

      private

      def find_session_id(plaintext)
        public_session_id = extract_session(plaintext)
        Rack::Session::SessionId.new(public_session_id)
      end

      def find_session
        ActiveSession.sessions_from_ids([session_id.private_id]).first
      end

      def extract_session(plaintext)
        plaintext.delete_prefix(self.class.session_cookie_key_prefix)
      end
    end
  end
end
