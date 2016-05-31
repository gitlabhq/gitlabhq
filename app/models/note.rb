class Note < ActiveRecord::Base
  extend ActiveModel::Naming
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
  delegate :title, to: :noteable, allow_nil: true

  before_validation :set_award!

  validates :note, :project, presence: true
  validates :note, uniqueness: { scope: [:author, :noteable_type, :noteable_id] }, if: ->(n) { n.is_award }
  validates :note, inclusion: { in: Emoji.emojis_names }, if: ->(n) { n.is_award }
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
  scope :system, ->{ where(system: true) }
  scope :user, ->{ where(system: false) }
  scope :common, ->{ where(noteable_type: ["", nil]) }
  scope :fresh, ->{ order(created_at: :asc, id: :asc) }
  scope :inc_author_project, ->{ includes(:project, :author) }
  scope :inc_author, ->{ includes(:author) }

  scope :legacy_diff_notes, ->{ where(type: 'LegacyDiffNote') }
  scope :non_diff_notes, ->{ where(type: ['Note', nil]) }

  scope :with_associations, -> do
    includes(:author, :noteable, :updated_by,
             project: [:project_members, { group: [:group_members] }])
  end

  before_validation :clear_blank_line_code!

  class << self
    def model_name
      ActiveModel::Name.new(self, nil, 'note')
    end

    def build_discussion_id(noteable_type, noteable_id)
      [:discussion, noteable_type.try(:underscore), noteable_id].join("-")
    end

    def discussions
      all.group_by(&:discussion_id).values
    end

    def grouped_diff_notes
      legacy_diff_notes.select(&:active?).sort_by(&:created_at).group_by(&:line_code)
    end

    # Searches for notes matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query   - The search query as a String.
    # as_user - Limit results to those viewable by a specific user
    #
    # Returns an ActiveRecord::Relation.
    def search(query, as_user: nil)
      table   = arel_table
      pattern = "%#{query}%"

      found_notes = joins('LEFT JOIN issues ON issues.id = noteable_id').
        where(table[:note].matches(pattern))

      if as_user
        found_notes.where('
          issues.confidential IS NULL
          OR issues.confidential IS FALSE
          OR (issues.confidential IS TRUE
            AND (issues.author_id = :user_id
            OR issues.assignee_id = :user_id
            OR issues.project_id IN(:project_ids)))',
          user_id: as_user.id,
          project_ids: as_user.authorized_projects.select(:id))
      else
        found_notes.where('issues.confidential IS NULL OR issues.confidential IS FALSE')
      end
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

  def diff_note?
    false
  end

  def legacy_diff_note?
    false
  end

  def active?
    true
  end

  def discussion_id
    @discussion_id ||=
      if for_merge_request?
        [:discussion, :note, id].join("-")
      else
        self.class.build_discussion_id(noteable_type, noteable_id || commit_id)
      end
  end

  def max_attachment_size
    current_application_settings.max_attachment_size.megabytes.to_i
  end

  def hook_attrs
    attributes
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def for_issue?
    noteable_type == "Issue"
  end

  def for_merge_request?
    noteable_type == "MergeRequest"
  end

  def for_snippet?
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
    (for_issue? || for_merge_request?) && !diff_note?
  end

  def contains_emoji_only?
    note =~ /\A#{Banzai::Filter::EmojiFilter.emoji_pattern}\s?\Z/
  end

  def award_emoji_name
    original_name = note.match(Banzai::Filter::EmojiFilter.emoji_pattern)[1]
    AwardEmoji.normilize_emoji_name(original_name)
  end
end
