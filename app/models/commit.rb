# coding: utf-8
class Commit
  extend ActiveModel::Naming
  extend Gitlab::Cache::RequestCache

  include ActiveModel::Conversion
  include Noteable
  include Participable
  include Mentionable
  include Referable
  include StaticModel
  include ::Gitlab::Utils::StrongMemoize

  attr_mentionable :safe_message, pipeline: :single_line

  participant :author
  participant :committer
  participant :notes_with_associations

  attr_accessor :project, :author
  attr_accessor :redacted_description_html
  attr_accessor :redacted_title_html
  attr_reader :gpg_commit

  DIFF_SAFE_LINES = Gitlab::Git::DiffCollection::DEFAULT_LIMITS[:max_lines]

  # Commits above this size will not be rendered in HTML
  DIFF_HARD_LIMIT_FILES = 1000
  DIFF_HARD_LIMIT_LINES = 50000

  MIN_SHA_LENGTH = Gitlab::Git::Commit::MIN_SHA_LENGTH
  COMMIT_SHA_PATTERN = /\h{#{MIN_SHA_LENGTH},40}/.freeze
  # Used by GFM to match and present link extensions on node texts and hrefs.
  LINK_EXTENSION_PATTERN = /(patch)/.freeze

  def banzai_render_context(field)
    pipeline = field == :description ? :commit_description : :single_line
    context = { pipeline: pipeline, project: self.project }
    context[:author] = self.author if self.author

    context
  end

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

    def order_by(collection:, order_by:, sort:)
      return collection unless %w[email name commits].include?(order_by)
      return collection unless %w[asc desc].include?(sort)

      collection.sort do |a, b|
        operands = [a, b].tap { |o| o.reverse! if sort == 'desc' }

        attr1, attr2 = operands.first.public_send(order_by), operands.second.public_send(order_by) # rubocop:disable PublicSend

        # use case insensitive comparison for string values
        order_by.in?(%w[email name]) ? attr1.casecmp(attr2) : attr1 <=> attr2
      end
    end

    # Truncate sha to 8 characters
    def truncate_sha(sha)
      sha[0..MIN_SHA_LENGTH]
    end

    def max_diff_options
      {
        max_files: DIFF_HARD_LIMIT_FILES,
        max_lines: DIFF_HARD_LIMIT_LINES
      }
    end

    def from_hash(hash, project)
      raw_commit = Gitlab::Git::Commit.new(project.repository.raw, hash)
      new(raw_commit, project)
    end

    def valid_hash?(key)
      !!(/\A#{COMMIT_SHA_PATTERN}\z/ =~ key)
    end

    def lazy(project, oid)
      BatchLoader.for({ project: project, oid: oid }).batch do |items, loader|
        items_by_project = items.group_by { |i| i[:project] }

        items_by_project.each do |project, commit_ids|
          oids = commit_ids.map { |i| i[:oid] }

          project.repository.commits_by(oids: oids).each do |commit|
            loader.call({ project: commit.project, oid: commit.id }, commit) if commit
          end
        end
      end
    end
  end

  attr_accessor :raw

  def initialize(raw_commit, project)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
    @project = project
    @statuses = {}
    @gpg_commit = Gitlab::Gpg::Commit.new(self) if project
  end

  def id
    raw.id
  end

  def project_id
    project.id
  end

  def ==(other)
    other.is_a?(self.class) && raw == other.raw
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
      (?<commit>#{COMMIT_SHA_PATTERN})
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||=
      super("commit", /(?<commit>#{COMMIT_SHA_PATTERN})?(\.(?<extension>#{LINK_EXTENSION_PATTERN}))?/)
  end

  def to_reference(from = nil, full: false)
    commit_reference(from, id, full: full)
  end

  def reference_link_text(from = nil, full: false)
    commit_reference(from, short_id, full: full)
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
        safe_message.split(/[\r\n]/, 2).first
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
    @parents ||= parent_ids.map { |oid| Commit.lazy(project, oid) }
  end

  def parent
    strong_memoize(:parent) do
      project.commit_by(oid: self.parent_id) if self.parent_id
    end
  end

  def notes
    project.notes.for_commit_id(self.id)
  end

  def discussion_notes
    notes.non_diff_notes
  end

  def notes_with_associations
    notes.includes(:author, :award_emoji)
  end

  def merge_requests
    @merge_requests ||= project.merge_requests.by_commit_sha(sha)
  end

  def method_missing(method, *args, &block)
    @raw.__send__(method, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to_missing?(method, include_private = false)
    @raw.respond_to?(method, include_private) || super
  end

  def short_id
    @raw.short_id(MIN_SHA_LENGTH)
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
    return @statuses[ref] if @statuses.key?(ref)

    @statuses[ref] = project.pipelines.latest_status_per_commit(id, ref)[id]
  end

  def set_status_for_ref(ref, status)
    @statuses[ref] = status
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

  def cherry_pick_description(user)
    message_body = "(cherry picked from commit #{sha})"

    if merged_merge_request?(user)
      commits_in_merge_request = merged_merge_request(user).commits

      if commits_in_merge_request.present?
        message_body << "\n"

        commits_in_merge_request.reverse.each do |commit_in_merge|
          message_body << "\n#{commit_in_merge.short_id} #{commit_in_merge.title}"
        end
      end
    end

    message_body
  end

  def cherry_pick_message(user)
    %Q{#{message}\n\n#{cherry_pick_description(user)}}
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

  def has_been_reverted?(current_user, notes_association = nil)
    ext = all_references(current_user)
    notes_association ||= notes_with_associations

    notes_association.system.each do |note|
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
  #   uri_type('not/found')     # => nil
  #
  # Returns a symbol
  def uri_type(path)
    entry = @raw.tree_entry(path)
    return unless entry

    if entry[:type] == :blob
      blob = ::Blob.decorate(Gitlab::Git::Blob.new(name: entry[:name]), @project)
      blob.image? || blob.video? ? :raw : :blob
    else
      entry[:type]
    end
  end

  def raw_diffs(*args)
    raw.diffs(*args)
  end

  def raw_deltas
    @deltas ||= raw.deltas
  end

  def diffs(diff_options = {})
    Gitlab::Diff::FileCollection::Commit.new(self, diff_options: diff_options)
  end

  def persisted?
    true
  end

  def touch
    # no-op but needs to be defined since #persisted? is defined
  end

  def touch_later
    # No-op.
    # This method is called by ActiveRecord.
    # We don't want to do anything for `Commit` model, so this is empty.
  end

  WIP_REGEX = /\A\s*(((?i)(\[WIP\]|WIP:|WIP)\s|WIP$))|(fixup!|squash!)\s/.freeze

  def work_in_progress?
    !!(title =~ WIP_REGEX)
  end

  def merged_merge_request?(user)
    !!merged_merge_request(user)
  end

  private

  def commit_reference(from, referable_commit_id, full: false)
    reference = project.to_reference(from, full: full)

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

  def merged_merge_request_no_cache(user)
    MergeRequestsFinder.new(user, project_id: project.id).find_by(merge_commit_sha: id) if merge_commit?
  end
end
