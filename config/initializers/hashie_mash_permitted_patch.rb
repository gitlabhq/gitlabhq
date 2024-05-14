# frozen_string_literal: true

# Pulls logic from https://github.com/Maxim-Filimonov/hashie-forbidden_attributes so we could drop the dependency.
# This gem is simply `Hashie::Mash` monkey patch to allow mass assignment bypassing `:permitted?` check.
#
# Reasons:
# 1. The gem was last updated 5 years ago and does not have CI setup to test under the latest Ruby/Rails.
# 2. There is a significant chance this logic is not used at all.
# We didn't find any explicit places in the code where we mass-assign to `Hashie::Mash`.
# Experimental MR where we dropped the gem showed that no tests from the full suite failed:
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101535
# 3. The logic is very simple. Even if we need it, keeping it in our codebase is better than pulling a dependency.
# This logic will be visible and it will be one less gem to install.
#
# Next steps:
# 1. Keep the patch for at least one milestone in our codebase. Log its usage.
# 2. After that, check if there were any related log events.
# 3. If no usages were tracked, we could drop the patch (delete this file).
# 4. Otherwise, audit where and why we need it, and add a comment to that place.
#
# See discussion https://gitlab.com/gitlab-org/gitlab/-/issues/378398#note_1143133426

require 'hashie/mash'

module Hashie
  class Mash
    module MonkeyPatch
      def respond_to_missing?(method_name, *args)
        if method_name == :permitted?
          Gitlab::AppLogger.info(message: 'Hashie::Mash#respond_to?(:permitted?)',
            caller: Gitlab::BacktraceCleaner.clean_backtrace(caller))

          return false
        end

        super
      end

      def method_missing(method_name, *args)
        if method_name == :permitted?
          Gitlab::AppLogger.info(message: 'Hashie::Mash#permitted?',
            caller: Gitlab::BacktraceCleaner.clean_backtrace(caller))

          raise ArgumentError
        end

        super
      end
    end

    prepend MonkeyPatch
  end
end
