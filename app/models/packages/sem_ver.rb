# frozen_string_literal: true

class Packages::SemVer
  attr_accessor :major, :minor, :patch, :prerelease, :build

  # TODO: Move logic into the SemanticVersionable concern
  # https://gitlab.com/gitlab-org/gitlab/-/issues/455670

  def initialize(major = 0, minor = 0, patch = 0, prerelease = nil, build = nil, prefixed: false)
    @major = major
    @minor = minor
    @patch = patch
    @prerelease = prerelease
    @build = build
    @prefixed = prefixed
  end

  def prefixed?
    @prefixed
  end

  def ==(other)
    self.class == other.class &&
      self.major == other.major &&
      self.minor == other.minor &&
      self.patch == other.patch &&
      self.prerelease == other.prerelease &&
      self.build == other.build
  end

  def to_s
    s = "#{prefixed? ? 'v' : ''}#{major || 0}.#{minor || 0}.#{patch || 0}"
    s += "-#{prerelease}" if prerelease
    s += "+#{build}" if build

    s
  end

  def self.match(str, prefixed: false)
    return unless str&.start_with?('v') == prefixed

    str = str[1..] if prefixed

    Gitlab::Regex.semver_regex.match(str)
  end

  def self.match?(str, prefixed: false)
    !match(str, prefixed: prefixed).nil?
  end

  def self.parse(str, prefixed: false)
    m = match str, prefixed: prefixed
    return unless m

    new(m[1].to_i, m[2].to_i, m[3].to_i, m[4], m[5], prefixed: prefixed)
  end
end
