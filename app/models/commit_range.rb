# CommitRange makes it easier to work with commit ranges
#
# Examples:
#
#   range = CommitRange.new('f3f85602...e86e1013')
#   range.inclusive?      # => false
#   range.to_s            # => "f3f85602...e86e1013"
#   range.reference_title # => "Commits f3f85602 through e86e1013"
#
#   range = CommitRange.new('f3f856029bc5f966c5a7ee24cf7efefdd20e6019..e86e1013709735be5bb767e2b228930c543f25ae')
#   range.inclusive? # => true
#   range.to_s       # => "f3f85602..e86e1013"
#   range.to_param   # => {from: "f3f856029bc5f966c5a7ee24cf7efefdd20e6019^", to: "e86e1013709735be5bb767e2b228930c543f25ae"}
#
#   # Assuming `project` is a Project with a repository containing both commits:
#   range.project = project
#   range.valid_commits? # => true
#   range.to_a           # => [#<Commit ...>, #<Commit ...>]
#
class CommitRange
  include ActiveModel::Conversion

  attr_reader :sha_from, :notation, :sha_to

  # Optional Project model
  attr_accessor :project

  # See `inclusive?`
  attr_reader :inclusive

  # The beginning and ending SHA sums can be between 6 and 40 hex characters,
  # and the range selection can be double- or triple-dot.
  PATTERN = /\h{6,40}\.{2,3}\h{6,40}/

  # Initialize a CommitRange
  #
  # range_string - The String commit range.
  # project      - An optional Project model.
  #
  # Raises ArgumentError if `range_string` does not match `PATTERN`.
  def initialize(range_string, project = nil)
    range_string.strip!

    unless range_string.match(/\A#{PATTERN}\z/)
      raise ArgumentError, "invalid CommitRange string format: #{range_string}"
    end

    @inclusive = range_string !~ /\.{3}/
    @sha_from, @notation, @sha_to = range_string.split(/(\.{2,3})/, 2)

    @project = project

    @_commit_map = {}
  end

  def inspect
    %(#<#{self.class}:#{object_id} #{to_s}>)
  end

  # Returns an Array of Commit objects, where the first value is the starting
  # commit, and the second value is the ending commit
  #
  # Returns `[nil, nil]` if `valid_commits?` is falsey
  def to_a
    if valid_commits?
      [commit(sha_from), commit(sha_to)]
    else
      [nil, nil]
    end
  end

  def to_s(short: true)
    if short
      "#{sha_from[0..7]}#{notation}#{sha_to[0..7]}"
    else
      "#{sha_from}#{notation}#{sha_to}"
    end
  end

  # Returns a String for use in a link's title attribute
  def reference_title
    "Commits #{sha_from} through #{sha_to}"
  end

  # Return a Hash of parameters for passing to a URL helper
  #
  # See `namespace_project_compare_url`
  def to_param
    { from: sha_from_as_param, to: sha_to }
  end

  # Check if the range is inclusive
  #
  # We consider a CommitRange "inclusive" when it uses the two-dot syntax.
  def inclusive?
    inclusive
  end

  # Check if both the starting and ending commit IDs exist in a project's
  # repository
  #
  # project - An optional Project to check (default: `project`)
  def valid_commits?(project = project)
    return nil   unless project.present?
    return false unless project.valid_repo?

    commit(sha_from).present? && commit(sha_to).present?
  end

  def persisted?
    true
  end

  private

  def sha_from_as_param
    sha_from + (inclusive? ? '^' : '')
  end

  def commit(sha)
    unless @_commit_map[sha]
      # FIXME (rspeicher): Law of Demeter
      @_commit_map[sha] = project.repository.commit(sha)
    end

    @_commit_map[sha]
  end
end
