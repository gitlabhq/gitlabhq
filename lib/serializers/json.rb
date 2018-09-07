# frozen_string_literal: true

module Serializers
  # This serializer exports data as JSON,
  # but when loaded allows to access hashes with symbols
  class JSON
    InvalidValueError = Class.new(StandardError)

    ALLOWED_TYPES = [Hash, Array].freeze

    class << self
      def dump(obj)
        return if obj.nil?

        validate_type!(obj)
        
        if Gitlab::Database.mysql?
          # On MySQL we store data as text
          ActiveSupport::JSON.encode(obj)
        else
          # On PostgreSQL we use native column
          obj
        end
      end

      def load(json)
        return if json.nil?

        # On MySQL we store data as text
        # On PostgreSQL we use native json column
        json = ActiveSupport::JSON.decode(json) if Gitlab::Database.mysql?

        validate_type!(json)
        deep_indifferent_access(json)
      end

      private

      def validate_type!(obj)
        unless ALLOWED_TYPES.any? { |type| obj.is_a?(type) }
          raise InvalidValueError, "the value has to be #{ALLOWED_TYPES.join(", ")}, but is #{obj.class}"
        end
      end

      def deep_indifferent_access(data)
        if data.is_a?(Array)
          data.map { |item| self.deep_indifferent_access(item) }
        elsif data.is_a?(Hash)
          data.with_indifferent_access
        else
          data
        end
      end
    end
  end
end
