# frozen_string_literal: true

module Gitlab
  module Ci::MaskSecret
    MASKED_STRING = '[MASKED]'

    class << self
      def mask!(value, token)
        return value unless value.present? && token.present?

        token_size = token.bytesize
        masked_string_size = MASKED_STRING.bytesize

        mask = if token_size >= masked_string_size
                 MASKED_STRING + ('x' * (token_size - masked_string_size))
               else
                 # While masked variables can't be less than 8 characters, this fallback case
                 # ensures that we still apply masking even in unexpected circumstances.
                 'x' * token_size
               end

        # We assume 'value' must be mutable, given that frozen string is enabled.
        value.gsub!(token, mask)

        value
      end
    end
  end
end
