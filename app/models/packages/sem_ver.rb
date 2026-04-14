# frozen_string_literal: true

class Packages::SemVer
  include Comparable

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

  def <=>(other)
    return unless other.is_a?(self.class)

    result = [major.to_i, minor.to_i, patch.to_i] <=> [other.major.to_i, other.minor.to_i, other.patch.to_i]
    return result unless result == 0

    compare_prerelease(prerelease, other.prerelease)
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

  private

  def compare_prerelease(pre_a, pre_b)
    return 0 if pre_a.nil? && pre_b.nil?
    return 1 if pre_a.nil?
    return -1 if pre_b.nil?

    a_parts = pre_a.split('.')
    b_parts = pre_b.split('.')

    a_parts.zip(b_parts).each do |a_part, b_part|
      return 1 if b_part.nil?

      result = compare_identifiers(a_part, b_part)
      return result unless result == 0
    end

    a_parts.length <=> b_parts.length
  end

  def compare_identifiers(id_a, id_b)
    a_num = id_a.match?(/\A\d+\z/) ? id_a.to_i : nil
    b_num = id_b.match?(/\A\d+\z/) ? id_b.to_i : nil

    if a_num && b_num
      a_num <=> b_num
    elsif a_num
      -1
    elsif b_num
      1
    else
      id_a <=> id_b
    end
  end
end
