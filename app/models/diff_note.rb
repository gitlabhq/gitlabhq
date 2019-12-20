# frozen_string_literal: true

# A note on merge request or commit diffs
#
# A note of this type can be resolvable.
class DiffNote < Note
  include NoteOnDiff
  include DiffPositionableNote
  include Gitlab::Utils::StrongMemoize

  def self.noteable_types
    %w(MergeRequest Commit)
  end

  validates :original_position, presence: true
  validates :position, presence: true
  validates :line_code, presence: true, line_code: true, if: :on_text?
  # We need to evaluate the `noteable` types when running the validation since
  # EE might have added a type when the module was prepended
  validates :noteable_type, inclusion: { in: -> (_note) { noteable_types } }
  validate :positions_complete
  validate :verify_supported

  before_validation :set_line_code, if: :on_text?, unless: :importing?
  after_save :keep_around_commits, unless: :importing?
  after_commit :create_diff_file, on: :create

  def discussion_class(*)
    DiffDiscussion
  end

  def create_diff_file
    return unless should_create_diff_file?

    diff_file = fetch_diff_file
    diff_line = diff_file.line_for_position(self.original_position)

    creation_params = diff_file.diff.to_hash
      .except(:too_large)
      .merge(diff: diff_file.diff_hunk(diff_line))

    create_note_diff_file(creation_params)
  end

  # Returns the diff file from `position`
  def latest_diff_file
    strong_memoize(:latest_diff_file) do
      position.diff_file(repository)
    end
  end

  # Returns the diff file from `original_position`
  def diff_file
    strong_memoize(:diff_file) do
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
    return note_diff_file.raw_diff_file if note_diff_file

    file =
      if created_at_diff?(noteable.diff_refs)
        # We're able to use the already persisted diffs (Postgres) if we're
        # presenting a "current version" of the MR discussion diff.
        # So no need to make an extra Gitaly diff request for it.
        # As an extra benefit, the returned `diff_file` already
        # has `highlighted_diff_lines` data set from Redis on
        # `Diff::FileCollection::MergeRequestDiff`.
        noteable.diffs(original_position.diff_options).diff_files.first
      else
        original_position.diff_file(repository)
      end

    file&.unfold_diff_lines(position)

    file
  end

  def supported?
    for_commit? || self.noteable.has_complete_diff_refs?
  end

  def set_line_code
    self.line_code = self.position.line_code(repository)
  end

  def verify_supported
    return if supported?

    errors.add(:noteable, "doesn't support new-style diff notes")
  end

  def positions_complete
    return if self.original_position.complete? && self.position.complete?

    errors.add(:position, "is invalid")
  end

  def keep_around_commits
    shas = [
      self.original_position.base_sha,
      self.original_position.start_sha,
      self.original_position.head_sha
    ]

    if self.position != self.original_position
      shas << self.position.base_sha
      shas << self.position.start_sha
      shas << self.position.head_sha
    end

    repository.keep_around(*shas)
  end

  def repository
    noteable.respond_to?(:repository) ? noteable.repository : project.repository
  end
end

DiffNote.prepend_if_ee('::EE::DiffNote')
