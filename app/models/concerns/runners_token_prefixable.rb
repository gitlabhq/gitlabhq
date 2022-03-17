# frozen_string_literal: true

module RunnersTokenPrefixable
  extend ActiveSupport::Concern

  # Prefix for runners_token which can be used to invalidate existing tokens.
  # The value chosen here is GR (for Gitlab Runner) combined with the rotation
  # date (20220225) decimal to hex encoded.
  RUNNERS_TOKEN_PREFIX = 'GR1348941'

  def runners_token_prefix
    RUNNERS_TOKEN_PREFIX
  end
end
