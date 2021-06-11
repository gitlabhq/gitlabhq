# frozen_string_literal: true

module Serializers
  # Make the resulting hash have deep indifferent access
  class Json
    class << self
      def dump(obj)
        obj
      end

      def load(data)
        return if data.nil?

        Gitlab::Utils.deep_indifferent_access(data)
      end
    end
  end
end
