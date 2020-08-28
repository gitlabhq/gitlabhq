# frozen_string_literal: true

module Gitlab
  module Ci::MaskSecret
    class << self
      def mask!(value, token)
        return value unless value.present? && token.present?

        # We assume 'value' must be mutable, given
        # that frozen string is enabled.

        ##
        # TODO We need to remove this because it is going to change checksum of
        # a trace.
        #
        value.gsub!(token, 'x' * token.length)
        value
      end
    end
  end
end
