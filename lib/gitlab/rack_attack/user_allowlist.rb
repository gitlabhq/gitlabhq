# frozen_string_literal: true

module Gitlab
  module RackAttack
    class UserAllowlist
      extend Forwardable

      def_delegators :@set, :empty?, :include?, :to_a

      def initialize(list)
        @set = Set.new

        list.to_s.split(',').each do |id|
          @set << Integer(id) unless id.blank?
        rescue ArgumentError
          Gitlab::AuthLogger.error(message: 'ignoring invalid user allowlist entry', entry: id)
        end
      end
    end
  end
end
