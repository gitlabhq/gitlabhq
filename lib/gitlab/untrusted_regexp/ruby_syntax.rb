# frozen_string_literal: true

module Gitlab
  class UntrustedRegexp
    # This class implements support for Ruby syntax of regexps
    # and converts that to RE2 representation:
    # /<regexp>/<flags>
    class RubySyntax
      PATTERN = %r{^/(?<regexp>.*)/(?<flags>[ismU]*)$}.freeze

      # Checks if pattern matches a regexp pattern
      # but does not enforce it's validity
      def self.matches_syntax?(pattern)
        pattern.is_a?(String) && pattern.match(PATTERN).present?
      end

      # The regexp can match the pattern `/.../`, but may not be fabricatable:
      # it can be invalid or incomplete: `/match ( string/`
      def self.valid?(pattern, fallback: false)
        !!self.fabricate(pattern, fallback: fallback)
      end

      def self.fabricate(pattern, fallback: false)
        self.fabricate!(pattern, fallback: fallback)
      rescue RegexpError
        nil
      end

      def self.fabricate!(pattern, fallback: false)
        raise RegexpError, 'Pattern is not string!' unless pattern.is_a?(String)

        matches = pattern.match(PATTERN)
        raise RegexpError, 'Invalid regular expression!' if matches.nil?

        begin
          create_untrusted_regexp(matches[:regexp], matches[:flags])
        rescue RegexpError
          raise unless fallback &&
              Feature.enabled?(:allow_unsafe_ruby_regexp, default_enabled: false)

          create_ruby_regexp(matches[:regexp], matches[:flags])
        end
      end

      def self.create_untrusted_regexp(pattern, flags)
        pattern.prepend("(?#{flags})") if flags.present?

        UntrustedRegexp.new(pattern, multiline: false)
      end
      private_class_method :create_untrusted_regexp

      def self.create_ruby_regexp(pattern, flags)
        options = 0
        options += Regexp::IGNORECASE if flags&.include?('i')
        options += Regexp::MULTILINE if flags&.include?('m')

        Regexp.new(pattern, options)
      end
      private_class_method :create_ruby_regexp
    end
  end
end
