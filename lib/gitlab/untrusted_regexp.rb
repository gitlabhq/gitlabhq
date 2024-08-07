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
  #
  # This class doesn't change any instance variables, which allows it to be frozen
  # and setup in constants.
  class UntrustedRegexp
    require_dependency 're2'

    # recreate Ruby's \R metacharacter
    # https://ruby-doc.org/3.2.2/Regexp.html#class-Regexp-label-Character+Classes
    BACKSLASH_R = '(\n|\v|\f|\r|\x{0085}|\x{2028}|\x{2029}|\r\n)'

    delegate :===, :source, to: :regexp

    def initialize(pattern, multiline: false)
      if multiline
        pattern = "(?m)#{pattern}"
      end

      @regexp = RE2::Regexp.new(pattern, log_errors: false)
      @scan_regexp = initialize_scan_regexp

      raise RegexpError, regexp.error unless regexp.ok?
    end

    def replace_all(text, rewrite)
      RE2.GlobalReplace(text, regexp, rewrite)
    end

    # There is no built-in replace with block support (like `gsub`).  We can accomplish
    # the same thing by parsing and rebuilding the string with the substitutions.
    def replace_gsub(text, limit: 0)
      new_text = +''
      remainder = text
      count = 0

      matched = match(remainder)

      until matched.nil? || matched.to_a.compact.empty?
        partitioned = remainder.partition(matched.to_s)
        new_text << partitioned.first
        remainder = partitioned.last

        new_text << yield(matched)

        if limit > 0
          count += 1
          break if count >= limit
        end

        matched = match(remainder)
      end

      new_text << remainder
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

    # #scan returns an array of the groups captured, rather than MatchData.
    # Use this to give the capture group name and grab the proper value
    def extract_named_group(name, match)
      return unless match

      match_position = regexp.named_capturing_groups[name.to_s]
      raise RegexpError, "Invalid named capture group: #{name}" unless match_position

      match[match_position - 1]
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
      raise if Feature.enabled?(:disable_unsafe_regexp)

      if Feature.enabled?(:ci_unsafe_regexp_logger, type: :ops)
        Gitlab::AppJsonLogger.info(
          class: self.name,
          regexp: pattern.to_s,
          fabricated: 'unsafe ruby regexp'
        )
      end

      Regexp.new(pattern)
    end

    private

    attr_reader :regexp, :scan_regexp

    # RE2 scan operates differently to Ruby scan when there are no capture
    # groups, so work around it
    def initialize_scan_regexp
      if regexp.number_of_capturing_groups == 0
        RE2::Regexp.new('(' + regexp.source + ')')
      else
        regexp
      end
    end
  end
end
