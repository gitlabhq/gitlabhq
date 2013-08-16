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
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Note < ActiveRecord::Base
  include Mentionable

  attr_accessible :note, :noteable, :noteable_id, :noteable_type, :project_id,
                  :attachment, :line_code, :commit_id

  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :author, class_name: "User"

  delegate :name, to: :project, prefix: true
  delegate :name, :email, to: :author, prefix: true

  validates :note, :project, presence: true
  validates :line_code, format: { with: /\A[a-z0-9]+_\d+_\d+\Z/ }, allow_blank: true
  validates :attachment, file_size: { maximum: 10.megabytes.to_i }

  validates :noteable_id, presence: true, if: ->(n) { n.noteable_type.present? && n.noteable_type != 'Commit' }
  validates :commit_id, presence: true, if: ->(n) { n.noteable_type == 'Commit' }

  mount_uploader :attachment, AttachmentUploader

  # Scopes
  scope :for_commit_id, ->(commit_id) { where(noteable_type: "Commit", commit_id: commit_id) }
  scope :inline, ->{ where("line_code IS NOT NULL") }
  scope :not_inline, ->{ where(line_code: [nil, '']) }

  scope :common, ->{ where(noteable_type: ["", nil]) }
  scope :fresh, ->{ order("created_at ASC, id ASC") }
  scope :inc_author_project, ->{ includes(:project, :author) }
  scope :inc_author, ->{ includes(:author) }

  serialize :st_diff
  before_create :set_diff, if: ->(n) { n.line_code.present? }

  def self.create_status_change_note(noteable, project, author, status)
    create({
      noteable: noteable,
      project: project,
      author: author,
      note: "_Status changed to #{status}_"
    }, without_protection: true)
  end

  def commit_author
    @commit_author ||=
      project.users.find_by_email(noteable.author_email) ||
        project.users.find_by_name(noteable.author_name)
  rescue
    nil
  end

  def find_diff
    return nil unless noteable && noteable.diffs.present?

    @diff ||= noteable.diffs.find do |d|
      Digest::SHA1.hexdigest(d.new_path) == diff_file_index if d.new_path
    end
  end

  def set_diff
    # First lets find notes with same diff
    # before iterating over all mr diffs
    diff = Note.where(noteable_id: self.noteable_id, noteable_type: self.noteable_type, line_code: self.line_code).last.try(:diff)
    diff ||= find_diff

    self.st_diff = diff.to_hash if diff
  end

  def diff
    @diff ||= Gitlab::Git::Diff.new(st_diff) if st_diff.respond_to?(:map)
  end

  def active?
    # TODO: determine if discussion is outdated
    # according to recent MR diff or not
    true
  end

  def diff_file_index
    line_code.split('_')[0]
  end

  def diff_file_name
    diff.new_path if diff
  end

  def diff_old_line
    line_code.split('_')[1].to_i
  end

  def diff_new_line
    line_code.split('_')[2].to_i
  end

  def diff_line
    return @diff_line if @diff_line

    if diff
      Gitlab::DiffParser.new(diff).each do |full_line, type, line_code, line_new, line_old|
        @diff_line = full_line if line_code == self.line_code
      end
    end

    @diff_line
  end

  def discussion_id
    @discussion_id ||= [:discussion, noteable_type.try(:underscore), noteable_id || commit_id, line_code].join("-").to_sym
  end

  # Returns true if this is a downvote note,
  # otherwise false is returned
  def downvote?
    votable? && (note.start_with?('-1') ||
                 note.start_with?(':-1:')
                )
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

  def for_wall?
    noteable_type.blank?
  end

  # override to return commits, which are not active record
  def noteable
    if for_commit?
      project.repository.commit(commit_id)
    else
      super
    end
  # Temp fix to prevent app crash
  # if note commit id doesn't exist
  rescue
    nil
  end

  # Returns true if this is an upvote note,
  # otherwise false is returned
  def upvote?
    votable? && (note.start_with?('+1') ||
                 note.start_with?(':+1:')
                )
  end

  def votable?
    for_issue? || (for_merge_request? && !for_diff_line?)
  end

  def noteable_type_name
    if noteable_type.present?
      noteable_type.downcase
    else
      "wall"
    end
  end

  # FIXME: Hack for polymorphic associations with STI
  #        For more information wisit http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
  def noteable_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end
end
