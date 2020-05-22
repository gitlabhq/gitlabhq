# frozen_string_literal: true

module Spam
  module SpamConstants
    REQUIRE_RECAPTCHA = "recaptcha"
    DISALLOW = "disallow"
    ALLOW = "allow"
    BLOCK_USER = "block"

    SUPPORTED_VERDICTS = {
      BLOCK_USER => {
        priority: 1
      },
      DISALLOW => {
        priority: 2
      },
      REQUIRE_RECAPTCHA => {
        priority: 3
      },
      ALLOW => {
        priority: 4
      }
    }.freeze
  end
end
