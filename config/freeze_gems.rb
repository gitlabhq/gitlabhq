# frozen_string_literal: true

require 'auto_freeze'

## Freeze all gems, except for some which has issues at load time:
#
# Example:
# exclude_gems = %w[
#   arr-pm
#   email_reply_trimmer
#   method_source
#   seed-fu
#   unicode_utils
# ].freeze
# AutoFreeze.setup!(excluded_gems: exclude_gems)

# To start with, we freeze only one known gem
# https://github.com/nahi/httpclient/commit/06070a4f4431758c64ba6d57cbc520bad3ee4d49
AutoFreeze.setup!(included_gems: %w[httpclient])
