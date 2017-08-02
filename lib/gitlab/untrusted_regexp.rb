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
      matches = scan_regexp.scan(text).to_a
      matches.map!(&:first) if regexp.number_of_capturing_groups.zero?
      matches
    end

    def replace(text, rewrite)
      RE2.Replace(text, regexp, rewrite)
    end

    private

    attr_reader :regexp

    # RE2 scan operates differently to Ruby scan when there are no capture
    # groups, so work around it
    def scan_regexp
      @scan_regexp ||=
        if regexp.number_of_capturing_groups.zero?
          RE2::Regexp.new('(' + regexp.source + ')')
        else
          regexp
        end
    end
  end
end
