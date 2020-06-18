# frozen_string_literal: true

module Spam
  module SpamConstants
    CONDITIONAL_ALLOW = "conditional_allow"
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
      CONDITIONAL_ALLOW => {
        priority: 3
      },
      ALLOW => {
        priority: 4
      }
    }.freeze
  end
end
