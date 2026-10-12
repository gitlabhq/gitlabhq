# frozen_string_literal: true

module Authz
  module GranularScopes
    # A namespace may appear at most once. Standalone scopes (nil namespace) are
    # keyed by access level instead, so one `user` and one `instance` scope can
    # coexist but two `instance` scopes cannot.
    class UniquenessCheck
      # Scopes with the same key are duplicates of each other. Shared with token rotation,
      # which merges the duplicates older tokens can still hold.
      def self.key_for(scope)
        [scope.access.to_s, scope.namespace_id]
      end

      # @param new_scopes [Array<Authz::GranularScope>] scopes about to be added
      # @param existing_scopes [Enumerable<Authz::GranularScope>] scopes the owner already holds
      def initialize(new_scopes, existing_scopes: [])
        @new_scopes = new_scopes
        @existing_scopes = existing_scopes
      end

      # @return [Authz::GranularScope, nil] the first new scope that collides with an
      #   existing scope or with an earlier scope in new_scopes
      def first_duplicate
        seen = existing_scopes.map { |scope| self.class.key_for(scope) }.to_set

        new_scopes.find { |scope| !seen.add?(self.class.key_for(scope)) }
      end

      private

      attr_reader :new_scopes, :existing_scopes
    end
  end
end
