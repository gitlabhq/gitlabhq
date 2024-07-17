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

      protected

      def current=(value)
        Thread.current[STORE_KEY] = value
      end
    end
  end
end

Gitlab::Session.prepend_mod
