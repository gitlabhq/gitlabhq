# frozen_string_literal: true

module Gitlab
  class VersionInfo
    include Comparable

    attr_reader :major, :minor, :patch

    VERSION_REGEX = /(\d+)\.(\d+)\.(\d+)/
    MILESTONE_REGEX = /\A(\d+)\.(\d+)\z/
    # To mitigate ReDoS, limit the length of the version string we're
    # willing to check
    MAX_VERSION_LENGTH = 128

    InvalidMilestoneError = Class.new(StandardError)

    def self.parse_from_milestone(str)
      raise InvalidMilestoneError if str.length > MAX_VERSION_LENGTH

      m = MILESTONE_REGEX.match(str)
      raise InvalidMilestoneError if m.nil?

      VersionInfo.new(m[1].to_i, m[2].to_i)
    end

    def self.parse(str, parse_suffix: false)
      return str if str.is_a?(self)

      if str && str.length <= MAX_VERSION_LENGTH
        match = str.match(VERSION_REGEX)
        if match
          return VersionInfo.new(match[1].to_i, match[2].to_i, match[3].to_i, parse_suffix ? match.post_match : nil)
        end
      end

      VersionInfo.new
    end

    def initialize(major = 0, minor = 0, patch = 0, suffix = nil) # rubocop:disable Metrics/ParameterLists
      @major = major
      @minor = minor
      @patch = patch
      @suffix_s = suffix.to_s
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def <=>(other)
      return unless other.is_a? VersionInfo
      return unless valid? && other.valid?

      if other.major < @major
        1
      elsif @major < other.major
        -1
      elsif other.minor < @minor
        1
      elsif @minor < other.minor
        -1
      elsif other.patch < @patch
        1
      elsif @patch < other.patch
        -1
      elsif @suffix_s.empty? && other.suffix.present?
        1
      elsif other.suffix.empty? && @suffix_s.present?
        -1
      else
        suffix <=> other.suffix
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def to_s
      if valid?
        "%d.%d.%d%s" % [@major, @minor, @patch, @suffix_s] # rubocop:disable Style/FormatString
      else
        'Unknown'
      end
    end

    def to_json(*_args)
      { major: @major, minor: @minor, patch: @patch }.to_json
    end

    def suffix
      @suffix ||= @suffix_s.strip.gsub('-', '.pre.').scan(/\d+|[a-z]+/i).map do |s|
        /^\d+$/.match?(s) ? s.to_i : s
      end.freeze
    end

    def valid?
      @major >= 0 && @minor >= 0 && @patch >= 0 && @major + @minor + @patch > 0
    end

    def hash
      [self.class, to_s].hash
    end

    def eql?(other)
      (self <=> other) == 0
    end

    def same_minor_version?(other)
      @major == other.major && @minor == other.minor
    end

    def without_patch
      self.class.new(@major, @minor, 0)
    end
  end
end
