class DiffNote < Note
  include NoteOnDiff

  serialize :original_position, Gitlab::Diff::Position
  serialize :position, Gitlab::Diff::Position

  validates :original_position, presence: true
  validates :position, presence: true
  validates :diff_line, presence: true
  validates :line_code, presence: true, line_code: true
  validates :noteable_type, inclusion: { in: ['Commit', 'MergeRequest'] }
  validate :positions_complete
  validate :verify_supported

  before_validation :set_original_position, :update_position, on: :create
  before_validation :set_line_code
  after_save :keep_around_commits

  class << self
    def build_discussion_id(noteable_type, noteable_id, position)
      [super(noteable_type, noteable_id), *position.key].join("-")
    end
  end

  def new_diff_note?
    true
  end

  def diff_attributes
    { position: position.to_json }
  end

  def discussion_id
    @discussion_id ||= self.class.build_discussion_id(noteable_type, noteable_id || commit_id, position)
  end

  def original_discussion_id
    @original_discussion_id ||= self.class.build_discussion_id(noteable_type, noteable_id || commit_id, original_position)
  end

  def position=(new_position)
    if new_position.is_a?(String)
      new_position = JSON.parse(new_position) rescue nil
    end

    if new_position.is_a?(Hash)
      new_position = new_position.with_indifferent_access
      new_position = Gitlab::Diff::Position.new(new_position)
    end

    super(new_position)
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

  def active?(diff_refs = nil)
    return false unless supported?
    return true if for_commit?

    diff_refs ||= self.noteable.diff_refs

    self.position.diff_refs == diff_refs
  end

  private

  def supported?
    !self.for_merge_request? || self.noteable.support_new_diff_notes?
  end

  def set_original_position
    self.original_position = self.position.dup
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
      new_diff_refs: self.noteable.diff_refs,
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
