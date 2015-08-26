class VersionInfo
  include Comparable

  attr_reader :major, :minor, :patch

  def self.parse(str)
    if str && m = str.match(/(\d+)\.(\d+)\.(\d+)/)
      VersionInfo.new(m[1].to_i, m[2].to_i, m[3].to_i)
    else
      VersionInfo.new
    end
  end

  def initialize(major = 0, minor = 0, patch = 0)
    @major = major
    @minor = minor
    @patch = patch
  end

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
    else
      0
    end
  end

  def to_s
    if valid?
      "%d.%d.%d" % [@major, @minor, @patch]
    else
      "Unknown"
    end
  end

  def valid?
    @major >= 0 && @minor >= 0 && @patch >= 0 && @major + @minor + @patch > 0
  end
end
