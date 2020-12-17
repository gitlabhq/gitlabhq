# frozen_string_literal: true

module Gitlab
  module Ci::MaskSecret
    class << self
      def mask!(value, token)
        return value unless value.present? && token.present?

        # We assume 'value' must be mutable, given
        # that frozen string is enabled.

        value.gsub!(token, 'x' * token.bytesize)
        value
      end
    end
  end
end
