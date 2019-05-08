# frozen_string_literal: true

module Gitlab
  class NamespacedSessionStore
    delegate :[], :[]=, to: :store

    def initialize(key)
      @key = key
    end

    def initiated?
      !Session.current.nil?
    end

    def store
      return unless Session.current

      Session.current[@key] ||= {}
      Session.current[@key]
    end
  end
end
