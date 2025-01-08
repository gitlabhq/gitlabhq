# frozen_string_literal: true

# A note on merge request or commit diffs
#
# A note of this type can be resolvable.
class DiffNote < Note
  include NoteOnDiff
  include DiffPositionableNote
  include Gitlab::Utils::StrongMemoize

  self.allow_legacy_sti_class = true

  def self.noteable_types
    %w[MergeRequest Commit DesignManagement::Design]
  end

  validates :original_position, presence: true
  validates :position, presence: true
  validates :line_code, presence: true, line_code: true, if: :on_text?
  # We need to evaluate the `noteable` types when running the validation since
  # EE might have added a type when the module was prepended
  validates :noteable_type, inclusion: { in: ->(_note) { noteable_types } }
  validate :positions_complete
  validate :verify_supported, unless: :importing?

  before_validation :set_line_code, if: :on_text?, unless: :importing?
  after_save :keep_around_commits, unless: -> { importing? || skip_keep_around_commits }

  NoteDiffFileCreationError = Class.new(StandardError)

  DIFF_LINE_NOT_FOUND_MESSAGE = "Failed to find diff line for: %{file_path}, old_line: %{old_line}, new_line: %{new_line}"
  DIFF_FILE_NOT_FOUND_MESSAGE = "Failed to find diff file"

  after_commit :create_diff_file, on: :create

  def discussion_class(*)
    DiffDiscussion
  end

  def create_diff_file
    return unless should_create_diff_file?

    diff_file = fetch_diff_file
    raise NoteDiffFileCreationError, DIFF_FILE_NOT_FOUND_MESSAGE unless diff_file

    diff_line = diff_file.line_for_position(self.original_position)
    unless diff_line
      raise NoteDiffFileCreationError, DIFF_LINE_NOT_FOUND_MESSAGE % {
        file_path: diff_file.file_path,
        old_line: original_position.old_line,
        new_line: original_position.new_line
      }
    end

    creation_params = diff_file.diff.to_hash
      .except(:too_large, :generated, :encoded_file_path)
      .merge(diff: diff_file.diff_hunk(diff_line))

    create_note_diff_file(creation_params)
  end

  # Returns the diff file from `position`
  def latest_diff_file
    strong_memoize(:latest_diff_file) do
      next if for_design?

      position.diff_file(repository)
    end
  end

  # Returns the diff file from `original_position`
  def diff_file
    strong_memoize(:diff_file) do
      next if for_design?

      enqueue_diff_file_creation_job if should_create_diff_file?

      fetch_diff_file
    end
  end

  def diff_line
    @diff_line ||= diff_file&.line_for_position(self.original_position)
  end

  def original_line_code
    return unless on_text?

    self.diff_file.line_code(self.diff_line)
  end

  def created_at_diff?(diff_refs)
    return false unless supported?
    return true if for_commit?

    self.original_position.diff_refs == diff_refs
  end

  # Checks if the current `position` line in the diff
  # exists and is suggestible (not a deletion).
  #
  # Avoid using in iterations as it requests Gitaly.
  def supports_suggestion?
    return false unless noteable&.supports_suggestion? && on_text?
    # We don't want to trigger side-effects of `diff_file` call.
    return false unless file = latest_diff_file
    return false unless line = file.line_for_position(self.position)

    line&.suggestible?
  end

  def banzai_render_context(field)
    super.merge(suggestions_filter_enabled: true)
  end

  def multiline?
    position&.multiline?
  end

  def shas
    [
      self.original_position.base_sha,
      self.original_position.start_sha,
      self.original_position.head_sha
    ].tap do |a|
      if self.position != self.original_position
        a << self.position.base_sha
        a << self.position.start_sha
        a << self.position.head_sha
      end
    end
  end

  def latest_diff_file_path
    latest_diff_file.file_path
  end

  def raw_truncated_diff_lines
    discussion
      .truncated_diff_lines(highlight: false)
      .map(&:text)
      .join("\n")
  end

  private

  def enqueue_diff_file_creation_job
    # Avoid enqueuing multiple file creation jobs at once for a note (i.e.
    # parallel calls to `DiffNote#diff_file`).
    lease = Gitlab::ExclusiveLease.new("note_diff_file_creation:#{id}", timeout: 1.hour.to_i)
    return unless lease.try_obtain

    CreateNoteDiffFileWorker.perform_async(id)
  end

  def should_create_diff_file?
    on_text? && note_diff_file.nil? && start_of_discussion?
  end

  def fetch_diff_file
    return note_diff_file.raw_diff_file if note_diff_file && !note_diff_file.raw_diff_file.has_renderable?

    if created_at_diff?(noteable.diff_refs)
      # We're able to use the already persisted diffs (Postgres) if we're
      # presenting a "current version" of the MR discussion diff.
      # So no need to make an extra Gitaly diff request for it.
      # As an extra benefit, the returned `diff_file` already
      # has `highlighted_diff_lines` data set from Redis on
      # `Diff::FileCollection::MergeRequestDiff`.
      file = original_position.find_diff_file_from(noteable)
      # if line is not found in persisted diffs, fallback and retrieve file from repository using gitaly
      # This is required because of https://gitlab.com/gitlab-org/gitlab/issues/42676
      file = nil if file&.line_for_position(original_position).nil? && importing?
    end

    file ||= original_position.diff_file(repository)
    file&.unfold_diff_lines(position)

    file
  end

  def supported?
    for_commit? || for_design? || self.noteable&.has_complete_diff_refs?
  end

  def set_line_code
    self.line_code = self.line_code.presence || self.position.line_code(repository)
  end

  def verify_supported
    return if supported?

    errors.add(:noteable, "doesn't support new-style diff notes")
  end

  def positions_complete
    return if self.original_position.complete? && self.position.complete?

    errors.add(:position, "is incomplete")
  end

  def keep_around_commits
    repository.keep_around(*shas, source: "#{noteable_type}/#{self.class.name}")
  end

  def repository
    noteable.respond_to?(:repository) ? noteable.repository : project.repository
  end
end
