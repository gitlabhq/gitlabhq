# CommitRange makes it easier to work with commit ranges
#
# Examples:
#
#   range = CommitRange.new('f3f85602...e86e1013')
#   range.exclude_start?  # => false
#   range.reference_title # => "Commits f3f85602 through e86e1013"
#   range.to_s            # => "f3f85602...e86e1013"
#
#   range = CommitRange.new('f3f856029bc5f966c5a7ee24cf7efefdd20e6019..e86e1013709735be5bb767e2b228930c543f25ae')
#   range.exclude_start?  # => true
#   range.reference_title # => "Commits f3f85602^ through e86e1013"
#   range.to_param        # => {from: "f3f856029bc5f966c5a7ee24cf7efefdd20e6019^", to: "e86e1013709735be5bb767e2b228930c543f25ae"}
#   range.to_s            # => "f3f85602..e86e1013"
#
#   # Assuming `project` is a Project with a repository containing both commits:
#   range.project = project
#   range.valid_commits? # => true
#
class CommitRange
  include ActiveModel::Conversion
  include Referable

  attr_reader :sha_from, :notation, :sha_to

  # Optional Project model
  attr_accessor :project

  # See `exclude_start?`
  attr_reader :exclude_start

  # The beginning and ending SHAs can be between 6 and 40 hex characters, and
  # the range notation can be double- or triple-dot.
  PATTERN = /\h{6,40}\.{2,3}\h{6,40}/

  def self.reference_prefix
    '@'
  end

  # Pattern used to extract commit range references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    %r{
      (?:#{Project.reference_pattern}#{reference_prefix})?
      (?<commit_range>#{PATTERN})
    }x
  end

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

    @exclude_start = !range_string.include?('...')
    @sha_from, @notation, @sha_to = range_string.split(/(\.{2,3})/, 2)

    @project = project
  end

  def inspect
    %(#<#{self.class}:#{object_id} #{to_s}>)
  end

  def to_s
    "#{sha_from[0..7]}#{notation}#{sha_to[0..7]}"
  end

  def to_reference(from_project = nil)
    # Not using to_s because we want the full SHAs
    reference = sha_from + notation + sha_to

    if cross_project_reference?(from_project)
      reference = project.to_reference + '@' + reference
    end

    reference
  end

  # Returns a String for use in a link's title attribute
  def reference_title
    "Commits #{suffixed_sha_from} through #{sha_to}"
  end

  # Return a Hash of parameters for passing to a URL helper
  #
  # See `namespace_project_compare_url`
  def to_param
    { from: suffixed_sha_from, to: sha_to }
  end

  def exclude_start?
    exclude_start
  end

  # Check if both the starting and ending commit IDs exist in a project's
  # repository
  #
  # project - An optional Project to check (default: `project`)
  def valid_commits?(project = project)
    return nil   unless project.present?
    return false unless project.valid_repo?

    commit_from.present? && commit_to.present?
  end

  def persisted?
    true
  end

  def commit_from
    @commit_from ||= project.repository.commit(suffixed_sha_from)
  end

  def commit_to
    @commit_to ||= project.repository.commit(sha_to)
  end

  private

  def suffixed_sha_from
    sha_from + (exclude_start? ? '^' : '')
  end
end
