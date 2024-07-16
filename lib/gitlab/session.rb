# frozen_string_literal: true

module Gitlab
  class Session
    STORE_KEY = :session_storage

    class << self
      def with_session(session)
        old = self.current
        self.current = session
        yield
      ensure
        self.current = old
      end

      def current
        Thread.current[STORE_KEY]
      end

      def session_id_for_worker
        session = self.current

        return unless session

        if session.is_a?(ActionDispatch::Request::Session)
          session.id.private_id
        elsif session.respond_to?(:[]) # Hash-like
          session['set_session_id']
        else
          raise("Unsupported session class: #{session.class}")
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        nil
      end

      protected

      def current=(value)
        Thread.current[STORE_KEY] = value
      end
    end
  end
end
