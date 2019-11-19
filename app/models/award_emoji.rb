# frozen_string_literal: true

class AwardEmoji < ApplicationRecord
  DOWNVOTE_NAME = "thumbsdown"
  UPVOTE_NAME   = "thumbsup"

  include Participable
  include GhostUser
  include Importable

  belongs_to :awardable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :user

  validates :user, presence: true
  validates :awardable, presence: true, unless: :importing?

  validates :name, presence: true, inclusion: { in: Gitlab::Emoji.emojis_names }
  validates :name, uniqueness: { scope: [:user, :awardable_type, :awardable_id] }, unless: :ghost_user?

  participant :user

  scope :downvotes, -> { named(DOWNVOTE_NAME) }
  scope :upvotes, -> { named(UPVOTE_NAME) }
  scope :named, -> (names) { where(name: names) }
  scope :awarded_by, -> (users) { where(user: users) }

  after_save :expire_etag_cache
  after_destroy :expire_etag_cache

  class << self
    def votes_for_collection(ids, type)
      select('name', 'awardable_id', 'COUNT(*) as count')
        .where('name IN (?) AND awardable_type = ? AND awardable_id IN (?)', [DOWNVOTE_NAME, UPVOTE_NAME], type, ids)
        .group('name', 'awardable_id')
    end

    # Returns the top 100 emoji awarded by the given user.
    #
    # The returned value is a Hash mapping emoji names to the number of times
    # they were awarded:
    #
    #     { 'thumbsup' => 2, 'thumbsdown' => 1 }
    #
    # user - The User to get the awards for.
    # limt - The maximum number of emoji to return.
    def award_counts_for_user(user, limit = 100)
      limit(limit)
        .where(user: user)
        .group(:name)
        .order('count_all DESC, name ASC')
        .count
    end
  end

  def downvote?
    self.name == DOWNVOTE_NAME
  end

  def upvote?
    self.name == UPVOTE_NAME
  end

  def expire_etag_cache
    awardable.try(:expire_etag_cache)
  end
end
