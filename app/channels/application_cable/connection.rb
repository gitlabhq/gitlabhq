# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include Logging
    include Gitlab::Auth::AuthFinders

    identified_by :current_user

    public :request

    def connect
      self.current_user = find_user_from_bearer_token || find_user_from_session_store
    rescue Gitlab::Auth::AuthenticationError
      reject_unauthorized_connection
    end

    private

    def find_user_from_session_store
      session = ActiveSession.sessions_from_ids(Array.wrap(session_id)).first
      Warden::SessionSerializer.new('rack.session' => session).fetch(:user)
    end

    def session_id
      session_cookie = cookies[Gitlab::Application.config.session_options[:key]]

      Rack::Session::SessionId.new(session_cookie).private_id if session_cookie.present?
    end

    def notification_payload(_)
      super.merge!(params: request.params)
    end
  end
end
