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

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        session = find_session(plaintext)

        @revocable = Warden::SessionSerializer.new('rack.session' => session).fetch(:user) if session
        @source = source
      end

      def present_with
        ::API::Entities::User
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Revocation not supported for this token type'
      end

      private

      def find_session(plaintext)
        public_session_id = extract_session(plaintext)
        session_id = Rack::Session::SessionId.new(public_session_id)
        ActiveSession.sessions_from_ids([session_id.private_id]).first
      end

      def extract_session(plaintext)
        plaintext.delete_prefix(self.class.session_cookie_key_prefix)
      end
    end
  end
end
