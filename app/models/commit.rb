# frozen_string_literal: true

class Commit
  extend ActiveModel::Naming
  extend Gitlab::Cache::RequestCache
  extend Gitlab::Utils::Override

  include ActiveModel::Conversion
  include Noteable
  include Participable
  include Mentionable
  include Referable
  include StaticModel
  include Presentable
  include ::Gitlab::Utils::StrongMemoize
  include ActsAsPaginatedDiff
  include CacheMarkdownField
  include GlobalID::Identification
  include ::Repositories::StreamableDiff

  participant :author
  participant :committer
  participant :notes_with_associations

  attr_accessor :redacted_description_html
  attr_accessor :redacted_title_html
  attr_accessor :redacted_full_title_html
  attr_reader :container

  delegate :repository, to: :container
  delegate :project, to: :repository, allow_nil: true

  MIN_SHA_LENGTH = Gitlab::Git::Commit::MIN_SHA_LENGTH
  MAX_SHA_LENGTH = Gitlab::Git::Commit::MAX_SHA_LENGTH
  COMMIT_SHA_PATTERN = Gitlab::Git::Commit::SHA_PATTERN
  WHOLE_WORD_COMMIT_SHA_PATTERN = /\b#{COMMIT_SHA_PATTERN}\b/
  EXACT_COMMIT_SHA_PATTERN = /\A#{COMMIT_SHA_PATTERN}\z/
  # Used by GFM to match and present link extensions on node texts and hrefs.
  LINK_EXTENSION_PATTERN = /(patch)/

  DEFAULT_MAX_DIFF_LINES_SETTING = 50_000
  DEFAULT_MAX_DIFF_FILES_SETTING = 1_000
  MAX_DIFF_LINES_SETTING_UPPER_BOUND = 100_000
  MAX_DIFF_FILES_SETTING_UPPER_BOUND = 3_000
  DIFF_SAFE_LIMIT_FACTOR = 10

  CO_AUTHORED_TRAILER = "Co-authored-by"

  cache_markdown_field :title, pipeline: :single_line
  cache_markdown_field :full_title, pipeline: :single_line, limit: 1.kilobyte
  cache_markdown_field :description, pipeline: :commit_description, limit: 1.megabyte

  # Share the cache used by the markdown fields
  attr_mentionable :title, pipeline: :single_line
  attr_mentionable :description, pipeline: :commit_description, limit: 1.megabyte

  class << self
    def decorate(commits, container)
      commits.map do |commit|
        if commit.is_a?(Commit)
          commit
        else
          self.new(commit, container)
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

        attr1 = operands.first.public_send(order_by) # rubocop:disable GitlabSecurity/PublicSend
        attr2 = operands.second.public_send(order_by) # rubocop:disable GitlabSecurity/PublicSend

        # use case insensitive comparison for string values
        order_by.in?(%w[email name]) ? attr1.casecmp(attr2) : attr1 <=> attr2
      end
    end

    # Truncate sha to 8 characters
    def truncate_sha(sha)
      sha[0..MIN_SHA_LENGTH]
    end

    def diff_max_files
      Gitlab::CurrentSettings.diff_max_files
    end

    def diff_max_lines
      Gitlab::CurrentSettings.diff_max_lines
    end

    def max_diff_options
      {
        max_files: diff_max_files,
        max_lines: diff_max_lines
      }
    end

    def diff_safe_max_files
      diff_max_files / DIFF_SAFE_LIMIT_FACTOR
    end

    def diff_safe_max_lines
      diff_max_lines / DIFF_SAFE_LIMIT_FACTOR
    end

    def from_hash(hash, container)
      raw_commit = Gitlab::Git::Commit.new(container.repository.raw, hash)
      new(raw_commit, container)
    end

    def valid_hash?(key)
      !!(EXACT_COMMIT_SHA_PATTERN =~ key)
    end

    def lazy(container, oid)
      BatchLoader.for({ container: container, oid: oid }).batch do |items, loader|
        items_by_container = items.group_by { |i| i[:container] }

        items_by_container.each do |container, commit_ids|
          oids = commit_ids.map { |i| i[:oid] }

          container.repository.commits_by(oids: oids).each do |commit|
            loader.call({ container: commit.container, oid: commit.id }, commit) if commit
          end
        end
      end
    end

    def parent_class
      ::Project
    end

    def build_from_sidekiq_hash(project, hash)
      hash = hash.dup
      date_suffix = '_date'

      # When processing Sidekiq payloads various timestamps are stored as Strings.
      # Commit in turn expects Time-like instances upon input, so we have to
      # manually parse these values.
      hash.each do |key, value|
        hash[key] = Time.zone.parse(value) if key.to_s.end_with?(date_suffix) && value.is_a?(String)
      end

      from_hash(hash, project)
    end

    def underscore
      'commit'
    end
  end

  attr_accessor :raw

  def initialize(raw_commit, container)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
    @container = container
  end

  delegate \
    :pipelines,
    :last_pipeline,
    :lazy_latest_pipeline,
    :latest_pipeline,
    :latest_pipeline_for_project,
    :set_latest_pipeline_for_ref,
    :status,
    to: :with_pipeline

  def with_pipeline
    @with_pipeline ||= Ci::CommitWithPipeline.new(self)
  end

  def id
    raw.id
  end

  def project_id
    project&.id
  end

  def ==(other)
    other.is_a?(self.class) && raw == other.raw
  end

  def self.reference_prefix
    '@'
  end

  def self.reference_valid?(reference)
    !!(reference =~ EXACT_COMMIT_SHA_PATTERN)
  end

  # Pattern used to extract commit references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (?:#{Project.reference_pattern}#{reference_prefix})?
      (?<commit>#{WHOLE_WORD_COMMIT_SHA_PATTERN})
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||=
      compose_link_reference_pattern('commit',
        /(?<commit>#{COMMIT_SHA_PATTERN})?(\.(?<extension>#{LINK_EXTENSION_PATTERN}))?/o)
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

    # Use three dots instead of the ellipsis Unicode character because
    # some clients show the raw Unicode value in the merge commit.
    full_title.truncate(81, separator: ' ', omission: '...')
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

  def author_full_text
    return unless author_name && author_email

    strong_memoize(:author_full_text) do
      "#{author_name} <#{author_email}>"
    end
  end

  # Returns full commit message if title is truncated (greater than 99 characters)
  # otherwise returns commit message without first line
  def description
    return safe_message if full_title.length >= 100
    return no_commit_message if safe_message.blank?

    safe_message.split("\n", 2)[1].try(:chomp)
  end

  def description?
    description.present?
  end

  def timestamp
    committed_date.xmlschema
  end

  def hook_attrs(with_changed_files: false)
    data = {
      id: id,
      message: safe_message,
      title: title,
      timestamp: timestamp,
      url: Gitlab::UrlBuilder.build(self),
      author: {
        name: author_name,
        email: author_email
      }
    }

    data.merge!(repo_changes) if with_changed_files

    data
  end

  def lazy_author
    BatchLoader.for(author_email&.downcase).batch do |emails, loader|
      users = User.by_any_email(emails, confirmed: true).includes(:emails)

      emails.each do |email|
        user = users.find { |u| u.any_email?(email) }

        loader.call(email, user)
      end
    end
  end

  def author
    strong_memoize(:author) do
      lazy_author&.itself
    end
  end
  request_cache(:author) { author_email&.downcase }

  def committer(confirmed: true)
    @committer ||= User.find_by_any_email(committer_email, confirmed: confirmed)
  end

  def parents
    # Usage of `reject` is intentional. `compact` doesn't work here, because of BatchLoader specifics
    @parents ||= parent_ids.map { |oid| Commit.lazy(container, oid) }.reject(&:nil?)
  end

  def parent
    strong_memoize(:parent) do
      container.commit_by(oid: self.parent_id) if self.parent_id
    end
  end

  def notes
    container.notes.for_commit_id(self.id)
  end

  def user_mentions
    user_mention_class.where(commit_id: self.id)
  end

  def discussion_notes
    notes.non_diff_notes
  end

  def notes_with_associations
    notes.includes(:author, :award_emoji)
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
      base_sha: self.parent_id || container.repository.blank_ref,
      head_sha: self.sha
    )
  end

  def has_signature?
    signature_type && signature_type != :NONE
  end

  def raw_signature_type
    strong_memoize(:raw_signature_type) do
      next unless @raw.instance_of?(Gitlab::Git::Commit)

      if defined? @raw.raw_commit.signature_type
        @raw.raw_commit.signature_type
      end
    end
  end

  def signature_type
    @signature_type ||= raw_signature_type || :NONE
  end

  def signature
    strong_memoize(:signature) do
      case signature_type
      when :PGP
        gpg_commit.signature
      when :X509
        Gitlab::X509::Commit.new(self).signature
      when :SSH
        Gitlab::Ssh::Commit.new(self).signature
      end
    end
  end

  def gpg_commit
    @gpg_commit ||= Gitlab::Gpg::Commit.new(self)
  end

  def revert_branch_name
    "revert-#{short_id}"
  end

  def cherry_pick_branch_name
    repository.next_branch("cherry-pick-#{short_id}", mild: true)
  end

  def cherry_pick_description(user)
    message_body = ["(cherry-picked from commit #{sha})"]

    if merged_merge_request?(user)
      commits_in_merge_request = merged_merge_request(user).commits

      if commits_in_merge_request.present?
        message_body << ""

        commits_in_merge_request.reverse_each do |commit_in_merge|
          message_body << "#{commit_in_merge.short_id} #{commit_in_merge.title}"
        end
      end
    end

    message_body.join("\n")
  end

  def cherry_pick_message(user)
    %(#{message}\n\n#{cherry_pick_description(user)})
  end

  def revert_description(user)
    if merged_merge_request?(user)
      "This reverts merge request #{merged_merge_request(user).to_reference}"
    else
      "This reverts commit #{sha}"
    end
  end

  def revert_message(user)
    %(Revert "#{title.strip}"\n\n#{revert_description(user)})
  end

  def reverts_commit?(commit, user)
    description? && description.include?(commit.revert_description(user))
  end

  def merge_commit?
    parent_ids.size > 1
  end

  def merged_merge_request(current_user)
    # Memoize with per-user access check
    @merged_merge_request_hash ||= Hash.new do |hash, user|
      hash[user] = merged_merge_request_no_cache(user)
    end

    @merged_merge_request_hash[current_user]
  end

  def has_been_reverted?(current_user, notes_association = nil)
    ext = Gitlab::ReferenceExtractor.new(project, current_user)
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
      blob = ::Blob.decorate(Gitlab::Git::Blob.new(name: entry[:name]), container)
      blob.image? || blob.video? || blob.audio? ? :raw : :blob
    else
      entry[:type]
    end
  end

  def raw_diffs(...)
    raw.diffs(...)
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

  def to_ability_name
    model_name.singular
  end

  def touch
    # no-op but needs to be defined since #persisted? is defined
  end

  def touch_later
    # No-op.
    # This method is called by ActiveRecord.
    # We don't want to do anything for `Commit` model, so this is empty.
  end

  # We are continuing to support `(fixup!|squash!)` here as it is the prefix
  #   added by `git commit --fixup` which is used by some community members.
  #   https://gitlab.com/gitlab-org/gitlab/-/issues/342937#note_892065311
  #
  DRAFT_REGEX = /\A\s*#{Gitlab::Regex.merge_request_draft}|(fixup!|squash!)\s/

  def draft?
    !!(title =~ DRAFT_REGEX)
  end
  alias_method :work_in_progress?, :draft?

  def merged_merge_request?(user)
    !!merged_merge_request(user)
  end

  def cache_key
    "commit:#{sha}"
  end

  def broadcast_notes_changed
    super

    broadcast_notes_changed_for_related_mrs
  end

  def readable_by?(user)
    Ability.allowed?(user, :read_commit, self)
  end

  override :user_mention_class
  def user_mention_class
    CommitUserMention
  end

  override :user_mention_identifier
  def user_mention_identifier
    {
      commit_id: id,
      note_id: nil
    }
  end

  def tipping_branches(limit: 0)
    tipping_refs(Gitlab::Git::BRANCH_REF_PREFIX, limit: limit)
  end

  def tipping_tags(limit: 0)
    tipping_refs(Gitlab::Git::TAG_REF_PREFIX, limit: limit)
  end

  def branches_containing(limit: 0, exclude_tipped: false)
    excluded = exclude_tipped ? tipping_branches : []

    repository.branch_names_contains(id, limit: limit, exclude_refs: excluded) || []
  end

  def tags_containing(limit: 0, exclude_tipped: false)
    excluded = exclude_tipped ? tipping_tags : []

    repository.tag_names_contains(id, limit: limit, exclude_refs: excluded) || []
  end

  def has_encoded_file_paths?
    raw_diffs.any?(&:encoded_file_path)
  end

  def valid_full_sha
    id.match(Gitlab::Git::Commit::FULL_SHA_PATTERN).to_s
  end

  def first_diffs_slice(limit, diff_options = {})
    diff_options[:max_files] = limit

    diffs(diff_options)
  end

  private

  def tipping_refs(ref_prefix, limit: 0)
    strong_memoize_with(:tipping_tags, ref_prefix, limit) do
      refs = repository.refs_by_oid(oid: id, ref_patterns: [ref_prefix], limit: limit)
      refs.map { |n| n.delete_prefix(ref_prefix) }
    end
  end

  def broadcast_notes_changed_for_related_mrs
    MergeRequest.includes(target_project: :namespace).by_commit_sha(id).find_each(&:broadcast_notes_changed)
  end

  def commit_reference(from, referable_commit_id, full: false)
    base = container.to_reference_base(from, full: full)

    if base.present?
      "#{base}#{self.class.reference_prefix}#{referable_commit_id}"
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
    return MergeRequestsFinder.new(user, project_id: project_id).find_by(merge_commit_sha: id) if merge_commit?

    MergeRequestsFinder.new(user, project_id: project_id).find_by(squash_commit_sha: id)
  end
end

Commit.prepend_mod_with('Projects::Commit')
