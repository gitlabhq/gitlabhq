# == Schema Information
#
# Table name: sent_notifications
#
#  id            :integer          not null, primary key
#  project_id    :integer
#  noteable_id   :integer
#  noteable_type :string(255)
#  recipient_id  :integer
#  commit_id     :string(255)
#  line_code     :string(255)
#  reply_key     :string(255)      not null
#

class SentNotification < ActiveRecord::Base
  belongs_to :project
  belongs_to :noteable, polymorphic: true
  belongs_to :recipient, class_name: "User"

  validates :project, :recipient, :reply_key, presence: true
  validates :reply_key, uniqueness: true
  validates :noteable_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?
  validates :line_code, line_code: true, allow_blank: true

  class << self
    def reply_key
      SecureRandom.hex(16)
    end

    def for(reply_key)
      find_by(reply_key: reply_key)
    end

    def record(noteable, recipient_id, reply_key, params = {})
      return unless reply_key

      noteable_id = nil
      commit_id = nil
      if noteable.is_a?(Commit)
        commit_id = noteable.id
      else
        noteable_id = noteable.id
      end

      params.reverse_merge!(
        project:        noteable.project,
        noteable_type:  noteable.class.name,
        noteable_id:    noteable_id,
        commit_id:      commit_id,
        recipient_id:   recipient_id,
        reply_key:      reply_key
      )

      create(params)
    end

    def record_note(note, recipient_id, reply_key, params = {})
      params[:line_code] = note.line_code

      record(note.noteable, recipient_id, reply_key, params)
    end
  end

  def unsubscribable?
    !for_commit?
  end

  def for_commit?
    noteable_type == "Commit"
  end

  def noteable
    if for_commit?
      project.commit(commit_id) rescue nil
    else
      super
    end
  end

  def to_param
    self.reply_key
  end
end
