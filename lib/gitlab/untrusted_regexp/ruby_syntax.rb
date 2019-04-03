# frozen_string_literal: true

module Gitlab
  class UntrustedRegexp
    # This class implements support for Ruby syntax of regexps
    # and converts that to RE2 representation:
    # /<regexp>/<flags>
    class RubySyntax
      PATTERN = %r{^/(?<regexp>.+)/(?<flags>[ismU]*)$}.freeze

      # Checks if pattern matches a regexp pattern
      # but does not enforce it's validity
      def self.matches_syntax?(pattern)
        pattern.is_a?(String) && pattern.match(PATTERN).present?
      end

      # The regexp can match the pattern `/.../`, but may not be fabricatable:
      # it can be invalid or incomplete: `/match ( string/`
      def self.valid?(pattern)
        !!self.fabricate(pattern)
      end

      def self.fabricate(pattern)
        self.fabricate!(pattern)
      rescue RegexpError
        nil
      end

      def self.fabricate!(pattern)
        raise RegexpError, 'Pattern is not string!' unless pattern.is_a?(String)

        matches = pattern.match(PATTERN)
        raise RegexpError, 'Invalid regular expression!' if matches.nil?

        expression = matches[:regexp]
        flags = matches[:flags]
        expression.prepend("(?#{flags})") if flags.present?

        UntrustedRegexp.new(expression, multiline: false)
      end
    end
  end
end
