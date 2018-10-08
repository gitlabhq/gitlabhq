# frozen_string_literal: true
class DraftNote < ActiveRecord::Base
  include DiffPositionableNote
  include Gitlab::Utils::StrongMemoize

  PUBLISH_ATTRS = %i(noteable_id noteable_type type note).freeze
  DIFF_ATTRS = %i(position original_position change_position).freeze

  # Attribute used to store quick actions changes and users referenced.
  attr_accessor :commands_changes
  attr_accessor :users_referenced

  # Text with quick actions filtered out
  attr_accessor :rendered_note

  belongs_to :author, class_name: 'User'
  belongs_to :merge_request

  validates :merge_request_id, presence: true
  validates :author_id, presence: true, uniqueness: { scope: [:merge_request_id, :discussion_id] }, if: :discussion_id?
  validates :discussion_id, allow_nil: true, format: { with: /\A\h{40}\z/ }

  scope :authored_by, ->(u) { where(author_id: u.id) }

  def project
    merge_request.target_project
  end

  # noteable_id and noteable_type methods
  # are used to generate discussion_id on Discussion.discussion_id
  def noteable_id
    merge_request_id
  end

  def noteable
    merge_request
  end

  def noteable_type
    "MergeRequest"
  end

  def for_commit?
    false
  end

  def resolvable?
    false
  end

  def emoji_awardable?
    false
  end

  def on_diff?
    position&.complete?
  end

  def type
    return 'DiffNote' if  on_diff?
    return 'DiscussionNote' if discussion_id.present?

    'Note'
  end

  def references
    {
      users: users_referenced,
      commands: commands_changes
    }
  end

  def line_code
    @line_code ||= original_position&.line_code(project.repository)
  end

  def file_hash
    return unless diff_file

    Digest::SHA1.hexdigest(diff_file.file_path)
  end

  def publish_params
    attrs = PUBLISH_ATTRS.dup
    attrs.concat(DIFF_ATTRS) if on_diff?
    params = slice(*attrs)
    params[:in_reply_to_discussion_id] = discussion_id if discussion_id.present?

    params
  end

  def self.preload_author(draft_notes)
    ActiveRecord::Associations::Preloader.new.preload(draft_notes, { author: :status })
  end

  private

  def diff_file
    strong_memoize(:diff_file) do
      original_position&.diff_file(project.repository)
    end
  end
end
