# frozen_string_literal: true

require 'json'

module Gitlab
  module PolicyStore
    module JsonBytesize
      private

      def json_bytesize(object)
        JSON.generate(object).bytesize
      rescue JSON::JSONError, Encoding::UndefinedConversionError
        nil
      end
    end
  end
end
