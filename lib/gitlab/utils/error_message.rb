# frozen_string_literal: true

module Gitlab
  module Utils
    module ErrorMessage
      extend self

      def to_user_facing(message)
        "UF: #{message}"
      end
    end
  end
end
