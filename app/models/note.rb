# == Schema Information
#
# Table name: notes
#
#  id            :integer          not null, primary key
#  note          :text
#  noteable_type :string(255)
#  author_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#  project_id    :integer
#  attachment    :string(255)
#  line_code     :string(255)
#  commit_id     :string(255)
#  noteable_id   :integer
#  system        :boolean          default(FALSE), not null
#  st_diff       :text
#  updated_by_id :integer
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Note < ActiveRecord::Base
  include Mentionable
  include Gitlab::CurrentSettings
  include Participable

  default_value_for :system, false

  attr_mentionable :note
  participant :author, :mentioned_users

  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  delegate :name, to: :project, prefix: true
  delegate :name, :email, to: :author, prefix: true

  validates :note, :project, presence: true
  validates :line_code, format: { with: /\A[a-z0-9]+_\d+_\d+\Z/ }, allow_blank: true
  # Attachments are deprecated and are handled by Markdown uploader
  validates :attachment, file_size: { maximum: :max_attachment_size }

  validates :noteable_id, presence: true, if: ->(n) { n.noteable_type.present? && n.noteable_type != 'Commit' }
  validates :commit_id, presence: true, if: ->(n) { n.noteable_type == 'Commit' }

  mount_uploader :attachment, AttachmentUploader

  # Scopes
  scope :for_commit_id, ->(commit_id) { where(noteable_type: "Commit", commit_id: commit_id) }
  scope :inline, ->{ where("line_code IS NOT NULL") }
  scope :not_inline, ->{ where(line_code: [nil, '']) }
  scope :system, ->{ where(system: true) }
  scope :user, ->{ where(system: false) }
  scope :common, ->{ where(noteable_type: ["", nil]) }
  scope :fresh, ->{ order(created_at: :asc, id: :asc) }
  scope :inc_author_project, ->{ includes(:project, :author) }
  scope :inc_author, ->{ includes(:author) }

  serialize :st_diff
  before_create :set_diff, if: ->(n) { n.line_code.present? }
  after_update :set_references

  class << self
    def discussions_from_notes(notes)
      discussion_ids = []
      discussions = []

      notes.each do |note|
        next if discussion_ids.include?(note.discussion_id)

        # don't group notes for the main target
        if !note.for_diff_line? && note.noteable_type == "MergeRequest"
          discussions << [note]
        else
          discussions << notes.select do |other_note|
            note.discussion_id == other_note.discussion_id
          end
          discussion_ids << note.discussion_id
        end
      end

      discussions
    end

    def build_discussion_id(type, id, line_code)
      [:discussion, type.try(:underscore), id, line_code].join("-").to_sym
    end

    def search(query)
      where("LOWER(note) like :query", query: "%#{query.downcase}%")
    end
  end

  def cross_reference?
    system && SystemNoteService.cross_reference?(note)
  end

  def max_attachment_size
    current_application_settings.max_attachment_size.megabytes.to_i
  end

  def find_diff
    return nil unless noteable && noteable.diffs.present?

    @diff ||= noteable.diffs.find do |d|
      Digest::SHA1.hexdigest(d.new_path) == diff_file_index if d.new_path
    end
  end

  def hook_attrs
    attributes
  end

  def set_diff
    # First lets find notes with same diff
    # before iterating over all mr diffs
    diff = diff_for_line_code unless for_merge_request?
    diff ||= find_diff

    self.st_diff = diff.to_hash if diff
  end

  def diff
    @diff ||= Gitlab::Git::Diff.new(st_diff) if st_diff.respond_to?(:map)
  end

  def diff_for_line_code
    Note.where(noteable_id: noteable_id, noteable_type: noteable_type, line_code: line_code).last.try(:diff)
  end

  # Check if such line of code exists in merge request diff
  # If exists - its active discussion
  # If not - its outdated diff
  def active?
    return true unless self.diff
    return false unless noteable

    noteable.diffs.each do |mr_diff|
      next unless mr_diff.new_path == self.diff.new_path

      lines = Gitlab::Diff::Parser.new.parse(mr_diff.diff.lines.to_a)

      lines.each do |line|
        if line.text == diff_line
          return true
        end
      end
    end

    false
  end

  def outdated?
    !active?
  end

  def diff_file_index
    line_code.split('_')[0] if line_code
  end

  def diff_file_name
    diff.new_path if diff
  end

  def file_path
    if diff.new_path.present?
      diff.new_path
    elsif diff.old_path.present?
      diff.old_path
    end
  end

  def diff_old_line
    line_code.split('_')[1].to_i if line_code
  end

  def diff_new_line
    line_code.split('_')[2].to_i if line_code
  end

  def generate_line_code(line)
    Gitlab::Diff::LineCode.generate(file_path, line.new_pos, line.old_pos)
  end

  def diff_line
    return @diff_line if @diff_line

    if diff
      diff_lines.each do |line|
        if generate_line_code(line) == self.line_code
          @diff_line = line.text
        end
      end
    end

    @diff_line
  end

  def diff_line_type
    return @diff_line_type if @diff_line_type

    if diff
      diff_lines.each do |line|
        if generate_line_code(line) == self.line_code
          @diff_line_type = line.type
        end
      end
    end

    @diff_line_type
  end

  def truncated_diff_lines
    max_number_of_lines = 16
    prev_match_line = nil
    prev_lines = []

    diff_lines.each do |line|
      if line.type == "match"
        prev_lines.clear
        prev_match_line = line
      else
        prev_lines << line

        break if generate_line_code(line) == self.line_code

        prev_lines.shift if prev_lines.length >= max_number_of_lines
      end
    end

    prev_lines
  end

  def diff_lines
    @diff_lines ||= Gitlab::Diff::Parser.new.parse(diff.diff.lines.to_a)
  end

  def discussion_id
    @discussion_id ||= Note.build_discussion_id(noteable_type, noteable_id || commit_id, line_code)
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def for_commit_diff_line?
    for_commit? && for_diff_line?
  end

  def for_diff_line?
    line_code.present?
  end

  def for_issue?
    noteable_type == "Issue"
  end

  def for_merge_request?
    noteable_type == "MergeRequest"
  end

  def for_merge_request_diff_line?
    for_merge_request? && for_diff_line?
  end

  def for_project_snippet?
    noteable_type == "Snippet"
  end

  # override to return commits, which are not active record
  def noteable
    if for_commit?
      project.commit(commit_id)
    else
      super
    end
  # Temp fix to prevent app crash
  # if note commit id doesn't exist
  rescue
    nil
  end

  DOWNVOTES = %w(-1 :-1: :thumbsdown: :thumbs_down_sign:)

  # Check if the note is a downvote
  def downvote?
    votable? && note.start_with?(*DOWNVOTES)
  end

  UPVOTES = %w(+1 :+1: :thumbsup: :thumbs_up_sign:)

  # Check if the note is an upvote
  def upvote?
    votable? && note.start_with?(*UPVOTES)
  end

  def superceded?(notes)
    return false unless vote?

    notes.each do |note|
      next if note == self

      if note.vote? &&
        self[:author_id] == note[:author_id] &&
        self[:created_at] <= note[:created_at]
        return true
      end
    end

    false
  end

  def vote?
    upvote? || downvote?
  end

  def votable?
    for_issue? || (for_merge_request? && !for_diff_line?)
  end

  # Mentionable override.
  def gfm_reference(from_project = nil)
    noteable.gfm_reference(from_project)
  end

  # Mentionable override.
  def local_reference
    noteable
  end

  def noteable_type_name
    if noteable_type.present?
      noteable_type.downcase
    end
  end

  # FIXME: Hack for polymorphic associations with STI
  #        For more information visit http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
  def noteable_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end

  # Reset notes events cache
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when a note is updated
  # * when a note is removed
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.reset_event_cache_for(self)
  end

  def set_references
    create_new_cross_references!(project, author)
  end

  def system?
    read_attribute(:system)
  end

  def editable?
    !read_attribute(:system)
  end
end
