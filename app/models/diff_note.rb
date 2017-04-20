# A note on merge request or commit diffs
#
# A note of this type can be resolvable.
class DiffNote < Note
  include NoteOnDiff

  NOTEABLE_TYPES = %w(MergeRequest Commit).freeze

  serialize :original_position, Gitlab::Diff::Position
  serialize :position, Gitlab::Diff::Position

  validates :original_position, presence: true
  validates :position, presence: true
  validates :diff_line, presence: true
  validates :line_code, presence: true, line_code: true
  validates :noteable_type, inclusion: { in: NOTEABLE_TYPES }
  validate :positions_complete
  validate :verify_supported

  before_validation :set_original_position, :update_position, on: :create
  before_validation :set_line_code
  after_save :keep_around_commits

  def discussion_class(*)
    DiffDiscussion
  end

  %i(original_position position).each do |meth|
    define_method "#{meth}=" do |new_position|
      if new_position.is_a?(String)
        new_position = JSON.parse(new_position) rescue nil
      end

      if new_position.is_a?(Hash)
        new_position = new_position.with_indifferent_access
        new_position = Gitlab::Diff::Position.new(new_position)
      end

      super(new_position)
    end
  end

  def diff_file
    @diff_file ||= self.original_position.diff_file(self.project.repository)
  end

  def diff_line
    @diff_line ||= diff_file.line_for_position(self.original_position) if diff_file
  end

  def for_line?(line)
    diff_file.position(line) == self.original_position
  end

  def original_line_code
    self.diff_file.line_code(self.diff_line)
  end

  def active?(diff_refs = nil)
    return false unless supported?
    return true if for_commit?

    diff_refs ||= noteable_diff_refs

    self.position.diff_refs == diff_refs
  end

  def latest_merge_request_diff
    return unless for_merge_request?

    self.noteable.merge_request_diff_for(self.position.diff_refs)
  end

  private

  def supported?
    for_commit? || self.noteable.has_complete_diff_refs?
  end

  def set_original_position
    self.original_position = self.position.dup unless self.original_position&.complete?
  end

  def set_line_code
    self.line_code = self.position.line_code(self.project.repository)
  end

  def update_position
    return unless supported?
    return if for_commit?

    return if active?

    Notes::DiffPositionUpdateService.new(
      self.project,
      nil,
      old_diff_refs: self.position.diff_refs,
      new_diff_refs: noteable_diff_refs,
      paths: self.position.paths
    ).execute(self)
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
    project.repository.keep_around(self.original_position.base_sha)
    project.repository.keep_around(self.original_position.start_sha)
    project.repository.keep_around(self.original_position.head_sha)

    if self.position != self.original_position
      project.repository.keep_around(self.position.base_sha)
      project.repository.keep_around(self.position.start_sha)
      project.repository.keep_around(self.position.head_sha)
    end
  end
end
