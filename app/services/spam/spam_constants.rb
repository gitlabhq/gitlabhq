# frozen_string_literal: true

module Spam
  module SpamConstants
    ERROR_TYPE = 'spamcheck'
    BLOCK_USER = 'block'
    DISALLOW = 'disallow'
    CONDITIONAL_ALLOW = 'conditional_allow'
    OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM = 'override_via_allow_possible_spam'
    ALLOW = 'allow'
    NOOP = 'noop'

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
      OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM => {
        priority: 4
      },
      ALLOW => {
        priority: 5
      },
      NOOP => {
        priority: 6
      }
    }.freeze
  end
end
