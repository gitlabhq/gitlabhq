# frozen_string_literal: true

module Gitlab
  class VersionInfo
    include Comparable

    attr_reader :major, :minor, :patch

    VERSION_REGEX = /(\d+)\.(\d+)\.(\d+)/.freeze
    # To mitigate ReDoS, limit the length of the version string we're
    # willing to check
    MAX_VERSION_LENGTH = 128

    def self.parse(str, parse_suffix: false)
      if str.is_a?(self)
        str
      elsif str && str.length <= MAX_VERSION_LENGTH && m = str.match(VERSION_REGEX)
        VersionInfo.new(m[1].to_i, m[2].to_i, m[3].to_i, parse_suffix ? m.post_match : nil)
      else
        VersionInfo.new
      end
    end

    def initialize(major = 0, minor = 0, patch = 0, suffix = nil)
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
        "%d.%d.%d%s" % [@major, @minor, @patch, @suffix_s]
      else
        'Unknown'
      end
    end

    def to_json(*_args)
      { major: @major, minor: @minor, patch: @patch }.to_json
    end

    def suffix
      @suffix ||= @suffix_s.strip.gsub('-', '.pre.').scan(/\d+|[a-z]+/i).map do |s|
        /^\d+$/ =~ s ? s.to_i : s
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
