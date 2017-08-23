class Commit
  extend ActiveModel::Naming
  extend Gitlab::Cache::RequestCache

  include ActiveModel::Conversion
  include Noteable
  include Participable
  include Mentionable
  include Referable
  include StaticModel

  attr_mentionable :safe_message, pipeline: :single_line

  participant :author
  participant :committer
  participant :notes_with_associations

  attr_accessor :project, :author

  DIFF_SAFE_LINES = Gitlab::Git::DiffCollection::DEFAULT_LIMITS[:max_lines]

  # Commits above this size will not be rendered in HTML
  DIFF_HARD_LIMIT_FILES = 1000
  DIFF_HARD_LIMIT_LINES = 50000

  # The SHA can be between 7 and 40 hex characters.
  COMMIT_SHA_PATTERN = '\h{7,40}'.freeze

  class << self
    def decorate(commits, project)
      commits.map do |commit|
        if commit.is_a?(Commit)
          commit
        else
          self.new(commit, project)
        end
      end
    end

    # Calculate number of lines to render for diffs
    def diff_line_count(diffs)
      diffs.reduce(0) { |sum, d| sum + Gitlab::Git::Util.count_lines(d.diff) }
    end

    # Truncate sha to 8 characters
    def truncate_sha(sha)
      sha[0..7]
    end

    def max_diff_options
      {
        max_files: DIFF_HARD_LIMIT_FILES,
        max_lines: DIFF_HARD_LIMIT_LINES
      }
    end

    def from_hash(hash, project)
      new(Gitlab::Git::Commit.new(hash), project)
    end

    def valid_hash?(key)
      !!(/\A#{COMMIT_SHA_PATTERN}\z/ =~ key)
    end
  end

  attr_accessor :raw

  def initialize(raw_commit, project)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
    @project = project
  end

  def id
    @raw.id
  end

  def ==(other)
    (self.class === other) && (raw == other.raw)
  end

  def self.reference_prefix
    '@'
  end

  # Pattern used to extract commit references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (?:#{Project.reference_pattern}#{reference_prefix})?
      (?<commit>\h{7,40})
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("commit", /(?<commit>#{COMMIT_SHA_PATTERN})/)
  end

  def to_reference(from_project = nil, full: false)
    commit_reference(from_project, id, full: full)
  end

  def reference_link_text(from_project = nil, full: false)
    commit_reference(from_project, short_id, full: full)
  end

  def diff_line_count
    @diff_line_count ||= Commit.diff_line_count(raw_diffs)
    @diff_line_count
  end

  # Returns the commits title.
  #
  # Usually, the commit title is the first line of the commit message.
  # In case this first line is longer than 100 characters, it is cut off
  # after 80 characters + `...`
  def title
    return full_title if full_title.length < 100

    full_title.truncate(81, separator: ' ', omission: '…')
  end

  # Returns the full commits title
  def full_title
    @full_title ||=
      if safe_message.blank?
        no_commit_message
      else
        safe_message.split("\n", 2).first
      end
  end

  # Returns full commit message if title is truncated (greater than 99 characters)
  # otherwise returns commit message without first line
  def description
    return safe_message if full_title.length >= 100

    safe_message.split("\n", 2)[1].try(:chomp)
  end

  def description?
    description.present?
  end

  def hook_attrs(with_changed_files: false)
    data = {
      id: id,
      message: safe_message,
      timestamp: committed_date.xmlschema,
      url: Gitlab::UrlBuilder.build(self),
      author: {
        name: author_name,
        email: author_email
      }
    }

    if with_changed_files
      data.merge!(repo_changes)
    end

    data
  end

  # Discover issues should be closed when this commit is pushed to a project's
  # default branch.
  def closes_issues(current_user = self.committer)
    Gitlab::ClosingIssueExtractor.new(project, current_user).closed_by_message(safe_message)
  end

  def author
    User.find_by_any_email(author_email.downcase)
  end
  request_cache(:author) { author_email.downcase }

  def committer
    @committer ||= User.find_by_any_email(committer_email.downcase)
  end

  def parents
    @parents ||= parent_ids.map { |id| project.commit(id) }
  end

  def parent
    @parent ||= project.commit(self.parent_id) if self.parent_id
  end

  def notes
    project.notes.for_commit_id(self.id)
  end

  def discussion_notes
    notes.non_diff_notes
  end

  def notes_with_associations
    notes.includes(:author)
  end

  def method_missing(m, *args, &block)
    @raw.send(m, *args, &block)
  end

  def respond_to_missing?(method, include_private = false)
    @raw.respond_to?(method, include_private) || super
  end

  # Truncate sha to 8 characters
  def short_id
    @raw.short_id(7)
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha: self.parent_id || Gitlab::Git::BLANK_SHA,
      head_sha: self.sha
    )
  end

  def pipelines
    project.pipelines.where(sha: sha)
  end

  def last_pipeline
    @last_pipeline ||= pipelines.last
  end

  def status(ref = nil)
    @statuses ||= {}

    return @statuses[ref] if @statuses.key?(ref)

    @statuses[ref] = pipelines.latest_status(ref)
  end

  def signature
    return @signature if defined?(@signature)

    @signature = gpg_commit.signature
  end

  delegate :has_signature?, to: :gpg_commit

  def revert_branch_name
    "revert-#{short_id}"
  end

  def cherry_pick_branch_name
    project.repository.next_branch("cherry-pick-#{short_id}", mild: true)
  end

  def revert_description(user)
    if merged_merge_request?(user)
      "This reverts merge request #{merged_merge_request(user).to_reference}"
    else
      "This reverts commit #{sha}"
    end
  end

  def revert_message(user)
    %Q{Revert "#{title.strip}"\n\n#{revert_description(user)}}
  end

  def reverts_commit?(commit, user)
    description? && description.include?(commit.revert_description(user))
  end

  def merge_commit?
    parents.size > 1
  end

  def merged_merge_request(current_user)
    # Memoize with per-user access check
    @merged_merge_request_hash ||= Hash.new do |hash, user|
      hash[user] = merged_merge_request_no_cache(user)
    end

    @merged_merge_request_hash[current_user]
  end

  def has_been_reverted?(current_user, noteable = self)
    ext = all_references(current_user)

    noteable.notes_with_associations.system.each do |note|
      note.all_references(current_user, extractor: ext)
    end

    ext.commits.any? { |commit_ref| commit_ref.reverts_commit?(self, current_user) }
  end

  def change_type_title(user)
    merged_merge_request?(user) ? 'merge request' : 'commit'
  end

  # Get the URI type of the given path
  #
  # Used to build URLs to files in the repository in GFM.
  #
  # path - String path to check
  #
  # Examples:
  #
  #   uri_type('doc/README.md') # => :blob
  #   uri_type('doc/logo.png')  # => :raw
  #   uri_type('doc/api')       # => :tree
  #   uri_type('not/found')     # => :nil
  #
  # Returns a symbol
  def uri_type(path)
    entry = @raw.tree.path(path)
    if entry[:type] == :blob
      blob = ::Blob.decorate(Gitlab::Git::Blob.new(name: entry[:name]), @project)
      blob.image? || blob.video? ? :raw : :blob
    else
      entry[:type]
    end
  rescue Rugged::TreeError
    nil
  end

  def raw_diffs(*args)
    if Gitlab::GitalyClient.feature_enabled?(:commit_raw_diffs)
      Gitlab::GitalyClient::CommitService.new(project.repository).diff_from_parent(self, *args)
    else
      raw.diffs(*args)
    end
  end

  def raw_deltas
    @deltas ||= Gitlab::GitalyClient.migrate(:commit_deltas) do |is_enabled|
      if is_enabled
        Gitlab::GitalyClient::CommitService.new(project.repository).commit_deltas(self)
      else
        raw.deltas
      end
    end
  end

  def diffs(diff_options = nil)
    Gitlab::Diff::FileCollection::Commit.new(self, diff_options: diff_options)
  end

  def persisted?
    true
  end

  def touch
    # no-op but needs to be defined since #persisted? is defined
  end

  WIP_REGEX = /\A\s*(((?i)(\[WIP\]|WIP:|WIP)\s|WIP$))|(fixup!|squash!)\s/.freeze

  def work_in_progress?
    !!(title =~ WIP_REGEX)
  end

  private

  def commit_reference(from_project, referable_commit_id, full: false)
    reference = project.to_reference(from_project, full: full)

    if reference.present?
      "#{reference}#{self.class.reference_prefix}#{referable_commit_id}"
    else
      referable_commit_id
    end
  end

  def repo_changes
    changes = { added: [], modified: [], removed: [] }

    raw_deltas.each do |diff|
      if diff.deleted_file
        changes[:removed] << diff.old_path
      elsif diff.renamed_file || diff.new_file
        changes[:added] << diff.new_path
      else
        changes[:modified] << diff.new_path
      end
    end

    changes
  end

  def merged_merge_request?(user)
    !!merged_merge_request(user)
  end

  def merged_merge_request_no_cache(user)
    MergeRequestsFinder.new(user, project_id: project.id).find_by(merge_commit_sha: id) if merge_commit?
  end

  def gpg_commit
    @gpg_commit ||= Gitlab::Gpg::Commit.for_commit(self)
  end
end
