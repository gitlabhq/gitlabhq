# frozen_string_literal: true

module Gitlab
  class NamespacedSessionStore
    delegate :[], :[]=, to: :store

    def initialize(key, session = Session.current)
      @key = key
      @session = session
    end

    def initiated?
      !session.nil?
    end

    def store
      return unless session

      session[@key] ||= {}
      session[@key]
    end

    private

    attr_reader :session
  end
end
