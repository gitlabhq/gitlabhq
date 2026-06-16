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

# Skip installing the global RubyVM::InstructionSequence.load_iseq hook (via
# freezolite/require-hooks) when Coverband is measuring E2E coverage. The hook
# recompiles files with RubyVM::InstructionSequence.compile_file, which bypasses
# Ruby's Coverage instrumentation and results in empty runtime coverage data.
# Gitlab::Utils is not loaded this early in boot, so use a plain ENV check.
coverband_enabled = %w[true 1].include?(ENV['COVERBAND_ENABLED'].to_s.strip.downcase)

# To start with, we freeze only one known gem
# https://github.com/nahi/httpclient/commit/06070a4f4431758c64ba6d57cbc520bad3ee4d49
AutoFreeze.setup!(included_gems: %w[httpclient]) unless coverband_enabled
