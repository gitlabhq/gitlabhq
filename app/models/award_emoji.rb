class AwardEmoji < ActiveRecord::Base
  DOWNVOTE_NAME = "thumbsdown".freeze
  UPVOTE_NAME   = "thumbsup".freeze

  include Participable

  belongs_to :awardable, polymorphic: true
  belongs_to :user

  validates :awardable, :user, presence: true
  validates :name, presence: true, inclusion: { in: Gitlab::Emoji.emojis_names }
  validates :name, uniqueness: { scope: [:user, :awardable_type, :awardable_id] }

  participant :user

  scope :downvotes, -> { where(name: DOWNVOTE_NAME) }
  scope :upvotes,   -> { where(name: UPVOTE_NAME) }

  def downvote?
    self.name == DOWNVOTE_NAME
  end

  def upvote?
    self.name == UPVOTE_NAME
  end
end
