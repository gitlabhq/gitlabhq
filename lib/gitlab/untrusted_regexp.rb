# frozen_string_literal: true

module Gitlab
  # An untrusted regular expression is any regexp containing patterns sourced
  # from user input.
  #
  # Ruby's built-in regular expression library allows patterns which complete in
  # exponential time, permitting denial-of-service attacks.
  #
  # Not all regular expression features are available in untrusted regexes, and
  # there is a strict limit on total execution time. See the RE2 documentation
  # at https://github.com/google/re2/wiki/Syntax for more details.
  class UntrustedRegexp
    require_dependency 're2'

    delegate :===, :source, to: :regexp

    def initialize(pattern, multiline: false)
      if multiline
        pattern = "(?m)#{pattern}"
      end

      @regexp = RE2::Regexp.new(pattern, log_errors: false)

      raise RegexpError, regexp.error unless regexp.ok?
    end

    def replace_all(text, rewrite)
      RE2.GlobalReplace(text, regexp, rewrite)
    end

    def scan(text)
      matches = scan_regexp.scan(text).to_a
      matches.map!(&:first) if regexp.number_of_capturing_groups == 0
      matches
    end

    def match(text)
      scan_regexp.match(text)
    end

    def match?(text)
      text.present? && scan(text).present?
    end

    def replace(text, rewrite)
      RE2.Replace(text, regexp, rewrite)
    end

    def ==(other)
      self.source == other.source
    end

    # Handles regular expressions with the preferred RE2 library where possible
    # via UntustedRegex. Falls back to Ruby's built-in regular expression library
    # when the syntax would be invalid in RE2.
    #
    # One difference between these is `(?m)` multi-line mode. Ruby regex enables
    # this by default, but also handles `^` and `$` differently.
    # See: https://www.regular-expressions.info/modifiers.html
    def self.with_fallback(pattern, multiline: false)
      UntrustedRegexp.new(pattern, multiline: multiline)
    rescue RegexpError
      Regexp.new(pattern)
    end

    private

    attr_reader :regexp

    # RE2 scan operates differently to Ruby scan when there are no capture
    # groups, so work around it
    def scan_regexp
      @scan_regexp ||=
        if regexp.number_of_capturing_groups == 0
          RE2::Regexp.new('(' + regexp.source + ')')
        else
          regexp
        end
    end
  end
end
