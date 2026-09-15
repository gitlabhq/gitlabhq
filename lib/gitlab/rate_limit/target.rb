# frozen_string_literal: true

module Gitlab
  module RateLimit
    class Target < Data.define(:type, :identifier)
      TYPES = %i[route project group].freeze

      def initialize(type:, identifier:)
        raise ArgumentError, "unknown target type: #{type}" unless TYPES.include?(type)

        super
      end

      def cache_key
        "#{type}:#{identifier}"
      end

      # The identifier stays a String: casting it would raise on a long enough run
      # of digits, while the models resolve an out-of-range value to no rows.
      def root_id
        case type
        when :route then ::Route.root_namespace_id_by_path(identifier)
        when :project then ::Project.root_namespace_ids_by_project_ids([identifier]).each_value.first
        when :group then ::Namespace.root_ids_for([identifier]).first
        end
      end
    end
  end
end
