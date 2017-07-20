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
    delegate :===, to: :regexp

    def initialize(pattern)
      @regexp = RE2::Regexp.new(pattern, log_errors: false)

      raise RegexpError.new(regexp.error) unless regexp.ok?
    end

    def replace_all(text, rewrite)
      RE2.GlobalReplace(text, regexp, rewrite)
    end

    def scan(text)
      regexp.scan(text).scan.to_a
    end

    def replace(text, rewrite)
      RE2.Replace(text, regexp, rewrite)
    end

    private

    attr_reader :regexp
  end
end
