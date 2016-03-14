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
#  is_award      :boolean          default(FALSE), not null
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Note < ActiveRecord::Base
  include Gitlab::CurrentSettings
  include Participable
  include Mentionable

  default_value_for :system, false

  attr_mentionable :note, cache: true, pipeline: :note
  participant :author

  belongs_to :project
  belongs_to :noteable, polymorphic: true, touch: true
  belongs_to :author, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  has_many :todos, dependent: :destroy

  delegate :gfm_reference, :local_reference, to: :noteable
  delegate :name, to: :project, prefix: true
  delegate :name, :email, to: :author, prefix: true

  before_validation :set_award!
  before_validation :clear_blank_line_code!

  validates :note, :project, presence: true
  validates :note, uniqueness: { scope: [:author, :noteable_type, :noteable_id] }, if: ->(n) { n.is_award }
  validates :note, inclusion: { in: Emoji.emojis_names }, if: ->(n) { n.is_award }
  validates :line_code, line_code: true, allow_blank: true
  # Attachments are deprecated and are handled by Markdown uploader
  validates :attachment, file_size: { maximum: :max_attachment_size }

  validates :noteable_id, presence: true, if: ->(n) { n.noteable_type.present? && n.noteable_type != 'Commit' }
  validates :commit_id, presence: true, if: ->(n) { n.noteable_type == 'Commit' }
  validates :author, presence: true

  mount_uploader :attachment, AttachmentUploader

  # Scopes
  scope :awards, ->{ where(is_award: true) }
  scope :nonawards, ->{ where(is_award: false) }
  scope :for_commit_id, ->(commit_id) { where(noteable_type: "Commit", commit_id: commit_id) }
  scope :inline, ->{ where("line_code IS NOT NULL") }
  scope :not_inline, ->{ where(line_code: nil) }
  scope :system, ->{ where(system: true) }
  scope :user, ->{ where(system: false) }
  scope :common, ->{ where(noteable_type: ["", nil]) }
  scope :fresh, ->{ order(created_at: :asc, id: :asc) }
  scope :inc_author_project, ->{ includes(:project, :author) }
  scope :inc_author, ->{ includes(:author) }

  scope :with_associations, -> do
    includes(:author, :noteable, :updated_by,
             project: [:project_members, { group: [:group_members] }])
  end

  serialize :st_diff
  before_create :set_diff, if: ->(n) { n.line_code.present? }

  class << self
    def discussions_from_notes(notes)
      discussion_ids = []
      discussions = []

      notes.each do |note|
        next if discussion_ids.include?(note.discussion_id)

        # don't group notes for the main target
        if !note.for_diff_line? && note.for_merge_request?
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

    # Searches for notes matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      table   = arel_table
      pattern = "%#{query}%"

      where(table[:note].matches(pattern))
    end

    def grouped_awards
      notes = {}

      awards.select(:note).distinct.map do |note|
        notes[note.note] = where(note: note.note)
      end

      notes["thumbsup"] ||= Note.none
      notes["thumbsdown"] ||= Note.none

      notes
    end
  end

  def cross_reference?
    system && SystemNoteService.cross_reference?(note)
  end

  def max_attachment_size
    current_application_settings.max_attachment_size.megabytes.to_i
  end

  def find_diff
    return nil unless noteable
    return @diff if defined?(@diff)

    # Don't use ||= because nil is a valid value for @diff
    @diff = noteable.diffs(Commit.max_diff_options).find do |d|
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
    return @active if defined?(@active)

    diffs = noteable.diffs(Commit.max_diff_options)
    notable_diff = diffs.find { |d| d.new_path == self.diff.new_path }

    return @active = false if notable_diff.nil?

    parsed_lines = Gitlab::Diff::Parser.new.parse(notable_diff.diff.each_line)
    # We cannot use ||= because @active may be false
    @active = parsed_lines.any? { |line_obj| line_obj.text == diff_line }
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

    highlighted_diff_lines.each do |line|
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
    @diff_lines ||= Gitlab::Diff::Parser.new.parse(diff.diff.each_line)
  end

  def highlighted_diff_lines
    Gitlab::Diff::Highlight.new(diff_lines).highlight
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

  # FIXME: Hack for polymorphic associations with STI
  #        For more information visit http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
  def noteable_type=(noteable_type)
    super(noteable_type.to_s.classify.constantize.base_class.to_s)
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

  def downvote?
    is_award && note == "thumbsdown"
  end

  def upvote?
    is_award && note == "thumbsup"
  end

  def editable?
    !system? && !is_award
  end

  def cross_reference_not_visible_for?(user)
    cross_reference? && referenced_mentionables(user).empty?
  end

  # Checks if note is an award added as a comment
  #
  # If note is an award, this method sets is_award to true
  #   and changes content of the note to award name.
  #
  # Method is executed as a before_validation callback.
  #
  def set_award!
    return unless awards_supported? && contains_emoji_only?

    self.is_award = true
    self.note = award_emoji_name
  end

  private

  def clear_blank_line_code!
    self.line_code = nil if self.line_code.blank?
  end

  def awards_supported?
    (for_issue? || for_merge_request?) && !for_diff_line?
  end

  def contains_emoji_only?
    note =~ /\A#{Banzai::Filter::EmojiFilter.emoji_pattern}\s?\Z/
  end

  def award_emoji_name
    original_name = note.match(Banzai::Filter::EmojiFilter.emoji_pattern)[1]
    AwardEmoji.normilize_emoji_name(original_name)
  end
end
