# frozen_string_literal: true

module Gitlab
  module Json
    # GrapeFormatter is a JSON formatter for the Grape API.
    # This is set in lib/api/api.rb

    class GrapeFormatter
      def self.call(object, _env = nil)
        return object.to_s if object.is_a?(Precompiled)

        ::Gitlab::Json.dump(object)
      end
    end
  end
end
