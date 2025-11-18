# frozen_string_literal: true

class AwardEmoji < ApplicationRecord
  THUMBS_UP     = 'thumbsup'
  THUMBS_DOWN   = 'thumbsdown'
  UPVOTE_NAME   = THUMBS_UP
  DOWNVOTE_NAME = THUMBS_DOWN

  include Participable
  include GhostUser
  include Importable
  include EachBatch

  belongs_to :awardable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :user
  belongs_to :namespace
  belongs_to :organization, class_name: 'Organizations::Organization'

  validates :user, presence: true
  validates :awardable, presence: true

  validates :name, presence: true, 'gitlab/emoji_name': true
  validates :name, uniqueness: { scope: [:user, :awardable_type, :awardable_id] }, unless: -> { ghost_user? || importing? }

  validates_with ExactlyOnePresentValidator, fields: [:namespace, :organization]

  participant :user

  delegate :resource_parent, to: :awardable, allow_nil: true

  scope :downvotes, -> { named(DOWNVOTE_NAME) }
  scope :upvotes, -> { named(UPVOTE_NAME) }
  scope :named, ->(names) { where(name: names) }
  scope :awarded_by, ->(users) { where(user: users) }
  scope :by_awardable, ->(type, ids) { where(awardable_type: type, awardable_id: ids) }

  before_validation :ensure_sharding_key
  after_destroy :expire_cache
  after_save :expire_cache
  after_commit :broadcast_note_update, if: -> { !importing? && awardable.is_a?(Note) }

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
    name == DOWNVOTE_NAME
  end

  def upvote?
    name == UPVOTE_NAME
  end

  def url
    return if TanukiEmoji.find_by_alpha_code(name)

    BatchLoader.for(name).batch(key: resource_parent) do |names, loader|
      emoji = Groups::CustomEmojiFinder.new(resource_parent, { include_ancestor_groups: true }).execute.by_name(names).select(:file)

      emoji.each do |e|
        loader.call(e.name, e.url)
      end
    end
  end

  def expire_cache
    awardable.try(:bump_updated_at)
    awardable.try(:update_upvotes_count) if upvote?
  end

  def broadcast_note_update
    awardable.broadcast_noteable_notes_changed
    awardable.trigger_note_subscription_update
  end

  def to_ability_name
    'emoji'
  end

  def hook_attrs
    Gitlab::HookData::EmojiBuilder.new(self).build
  end

  private

  def ensure_sharding_key
    return if [namespace, organization].any?(&:present?)

    self.namespace_id = case awardable
                        when Issue
                          awardable.namespace_id
                        when MergeRequest
                          awardable.project.project_namespace_id
                        when Note
                          awardable.project&.project_namespace_id || awardable.namespace_id
                        when ProjectSnippet
                          awardable.project&.project_namespace_id
                        end

    self.organization_id = case awardable
                           when PersonalSnippet, Note
                             awardable.organization_id
                           end
  end
end

AwardEmoji.prepend_mod
