# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include Logging

    identified_by :current_user

    public :request

    def connect
      self.current_user = find_user_from_session_store
    end

    private

    def find_user_from_session_store
      session = ActiveSession.sessions_from_ids([session_id]).first
      Warden::SessionSerializer.new('rack.session' => session).fetch(:user)
    end

    def session_id
      Rack::Session::SessionId.new(cookies[Gitlab::Application.config.session_options[:key]])
    end

    def notification_payload(_)
      super.merge!(params: request.params)
    end
  end
end
