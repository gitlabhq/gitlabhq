class AwardEmoji < ActiveRecord::Base
  DOWNVOTE_NAMES = %w(thumbsdown thumbsdown_tone1 thumbsdown_tone2 thumbsdown_tone3 thumbsdown_tone4 thumbsdown_tone5)
  UPVOTE_NAMES   = %w(thumbsup thumbsup_tone1 thumbsup_tone2 thumbsup_tone3 thumbsup_tone4 thumbsup_tone5)

  include Participable
  include GhostUser

  belongs_to :awardable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :user

  validates :awardable, :user, presence: true
  validates :name, presence: true, inclusion: { in: Gitlab::Emoji.emojis_names }
  validates :name, uniqueness: { scope: [:user, :awardable_type, :awardable_id] }, unless: :ghost_user?

  participant :user

  scope :downvotes, -> { where(name: DOWNVOTE_NAMES) }
  scope :upvotes,   -> { where(name: UPVOTE_NAMES) }

  after_save :expire_etag_cache
  after_destroy :expire_etag_cache

  class << self
    def votes_for_collection(ids, type)
      select('name', 'awardable_id', 'COUNT(*) as count')
        .where('name IN (?) AND awardable_type = ? AND awardable_id IN (?)', [*DOWNVOTE_NAMES, *UPVOTE_NAMES], type, ids)
        .group('name', 'awardable_id')
    end
  end

  def downvote?
    DOWNVOTE_NAMES.include?(name)
  end

  def upvote?
    UPVOTE_NAMES.include?(name)
  end


  def expire_etag_cache
    awardable.try(:expire_etag_cache)
  end
end
