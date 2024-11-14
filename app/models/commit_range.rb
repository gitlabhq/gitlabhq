# frozen_string_literal: true

# CommitRange makes it easier to work with commit ranges
#
# Examples:
#
#   range = CommitRange.new('f3f85602...e86e1013', project)
#   range.exclude_start?  # => false
#   range.to_s            # => "f3f85602...e86e1013"
#
#   range = CommitRange.new(
#                           'f3f856029bc5f966c5a7ee24cf7efefdd20e6019..e86e1013709735be5bb767e2b228930c543f25ae',
#                           project
#                          )
#   range.exclude_start?  # => true
#   range.to_param        # => {
#                               from: "f3f856029bc5f966c5a7ee24cf7efefdd20e6019^",
#                               to: "e86e1013709735be5bb767e2b228930c543f25ae"
#                              }
#   range.to_s            # => "f3f85602..e86e1013"
#
#   # Assuming the specified project has a repository containing both commits:
#   range.valid_commits? # => true
#
class CommitRange
  include ActiveModel::Conversion
  include Referable

  attr_reader :commit_from, :notation, :commit_to
  attr_reader :ref_from, :ref_to

  # The Project model
  attr_accessor :project

  # The beginning and ending refs can be named or SHAs, and
  # the range notation can be double- or triple-dot.
  REF_PATTERN = /[0-9a-zA-Z][0-9a-zA-Z_.-]*[0-9a-zA-Z\^]/
  PATTERN = /#{REF_PATTERN}\.{2,3}#{REF_PATTERN}/

  # In text references, the beginning and ending refs can only be valid SHAs.
  STRICT_PATTERN = /#{Gitlab::Git::Commit::RAW_SHA_PATTERN}\.{2,3}#{Gitlab::Git::Commit::RAW_SHA_PATTERN}/

  def self.reference_prefix
    '@'
  end

  # Pattern used to extract commit range references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (?:#{Project.reference_pattern}#{reference_prefix})?
      (?<commit_range>#{STRICT_PATTERN})
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= compose_link_reference_pattern('compare', /(?<commit_range>#{PATTERN})/o)
  end

  # Initialize a CommitRange
  #
  # range_string - The String commit range.
  # project      - The Project model.
  #
  # Raises ArgumentError if `range_string` does not match `PATTERN`.
  def initialize(range_string, project)
    @project = project

    range_string = range_string.strip

    unless /\A#{PATTERN}\z/o.match?(range_string)
      raise ArgumentError, "invalid CommitRange string format: #{range_string}"
    end

    @ref_from, @notation, @ref_to = range_string.split(/(\.{2,3})/, 2)

    if project.valid_repo?
      @commit_from = project.commit(@ref_from)
      @commit_to   = project.commit(@ref_to)
    end

    if valid_commits?
      @ref_from = Commit.truncate_sha(sha_from) if sha_from.start_with?(@ref_from)
      @ref_to   = Commit.truncate_sha(sha_to)   if sha_to.start_with?(@ref_to)
    end
  end

  def inspect
    %(#<#{self.class}:#{object_id} #{self}>)
  end

  def to_s
    sha_from + notation + sha_to
  end

  alias_method :id, :to_s

  def to_reference(from = nil, full: false)
    project_reference = project.to_reference_base(from, full: full)

    if project_reference.present?
      project_reference + self.class.reference_prefix + self.id
    else
      self.id
    end
  end

  def reference_link_text(from = nil)
    project_reference = project.to_reference_base(from)
    reference         = ref_from + notation + ref_to

    if project_reference.present?
      project_reference + self.class.reference_prefix + reference
    else
      reference
    end
  end

  # Return a Hash of parameters for passing to a URL helper
  #
  # See `namespace_project_compare_url`
  def to_param
    { from: sha_start, to: sha_to }
  end

  def exclude_start?
    @notation == '..'
  end

  # Check if both the starting and ending commit IDs exist in a project's
  # repository
  def valid_commits?
    commit_start.present? && commit_end.present?
  end

  def persisted?
    true
  end

  def sha_from
    return unless @commit_from

    @commit_from.id
  end

  def sha_to
    return unless @commit_to

    @commit_to.id
  end

  def sha_start
    return unless sha_from

    exclude_start? ? "#{sha_from}^" : sha_from
  end

  def commit_start
    return unless sha_start

    if exclude_start?
      @commit_start ||= project.commit(sha_start)
    else
      commit_from
    end
  end

  alias_method :sha_end, :sha_to
  alias_method :commit_end, :commit_to
end
