# A note on merge request or commit diffs, using the legacy implementation.
#
# All new diff notes are of the type `DiffNote`, but any diff notes created
# before the introduction of the new implementation still use `LegacyDiffNote`.
#
# A note of this type is never resolvable.
class LegacyDiffNote < Note
  include NoteOnDiff

  serialize :st_diff # rubocop:disable Cop/ActiveRecordSerialize

  validates :line_code, presence: true, line_code: true

  before_create :set_diff

  def discussion_class(*)
    LegacyDiffDiscussion
  end

  def project_repository
    if RequestStore.active?
      RequestStore.fetch("project:#{project_id}:repository") { self.project.repository }
    else
      self.project.repository
    end
  end

  def diff_file_hash
    line_code.split('_')[0] if line_code
  end

  def diff
    @diff ||= Gitlab::Git::Diff.new(st_diff) if st_diff.respond_to?(:map)
  end

  def diff_file
    @diff_file ||= Gitlab::Diff::File.new(diff, repository: project_repository) if diff
  end

  def diff_line
    @diff_line ||= diff_file&.line_for_line_code(self.line_code)
  end

  def original_line_code
    self.line_code
  end

  # Check if this note is part of an "active" discussion
  #
  # This will always return true for anything except MergeRequest noteables,
  # which have special logic.
  #
  # If the note's current diff cannot be matched in the MergeRequest's current
  # diff, it's considered inactive.
  def active?(diff_refs = nil)
    return @active if defined?(@active)
    return true if for_commit?
    return true unless diff_line
    return false unless noteable
    return false if diff_refs && diff_refs != noteable.diff_refs

    noteable_diff = find_noteable_diff

    if noteable_diff
      parsed_lines = Gitlab::Diff::Parser.new.parse(noteable_diff.diff.each_line)

      @active = parsed_lines.any? { |line_obj| line_obj.text == diff_line.text }
    else
      @active = false
    end

    @active
  end

  private

  def find_diff
    return nil unless noteable
    return @diff if defined?(@diff)

    @diff = noteable.raw_diffs(Commit.max_diff_options).find do |d|
      d.new_path && Digest::SHA1.hexdigest(d.new_path) == diff_file_hash
    end
  end

  def set_diff
    # First lets find notes with same diff
    # before iterating over all mr diffs
    diff = diff_for_line_code unless for_merge_request?
    diff ||= find_diff

    self.st_diff = diff.to_hash if diff
  end

  def diff_for_line_code
    attributes = {
      noteable_type: noteable_type,
      line_code: line_code
    }

    if for_commit?
      attributes[:commit_id] = commit_id
    else
      attributes[:noteable_id] = noteable_id
    end

    self.class.where(attributes).last.try(:diff)
  end

  # Find the diff on noteable that matches our own
  def find_noteable_diff
    diffs = noteable.raw_diffs(Commit.max_diff_options)
    diffs.find { |d| d.new_path == self.diff.new_path }
  end
end
