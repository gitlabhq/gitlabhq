# frozen_string_literal: true

module Gitlab
  module Utils
    module ErrorMessage
      extend self

      UF_ERROR_PREFIX = 'UF'

      def to_user_facing(message)
        prefixed_error_message(message, UF_ERROR_PREFIX)
      end

      def prefixed_error_message(message, prefix)
        "#{prefix} #{message}"
      end
    end
  end
end
