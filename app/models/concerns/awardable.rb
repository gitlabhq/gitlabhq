module Awardable
  extend ActiveSupport::Concern

  included do
    has_many :award_emoji, -> { includes(:user).order(:id) }, as: :awardable, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    if self < Participable
      # By default we always load award_emoji user association
      participant :award_emoji
    end
  end

  module ClassMethods
    def awarded(user, name)
      sql = <<~EOL
        EXISTS (
          SELECT TRUE
          FROM award_emoji
          WHERE user_id = :user_id AND
                name = :name AND
                awardable_type = :awardable_type AND
                awardable_id = #{self.arel_table.name}.id
        )
      EOL

      where(sql, user_id: user.id, name: name, awardable_type: self.name)
    end

    def order_upvotes_desc
      order_votes_desc(AwardEmoji::UPVOTE_NAMES)
    end

    def order_downvotes_desc
      order_votes_desc(AwardEmoji::DOWNVOTE_NAMES)
    end

    def order_all_upvotes_desc
      order_votes_desc(AwardEmoji.all_award_emoji(:thumbsup))
    end

    def order_all_downvotes_desc
      order_votes_desc(AwardEmoji.all_award_emoji(:thumbsdown))
    end

    def order_votes_desc(emoji_names)
      awardable_table = self.arel_table
      awards_table = AwardEmoji.arel_table

      join_clause = awardable_table.join(awards_table, Arel::Nodes::OuterJoin).on(
        awards_table[:awardable_id].eq(awardable_table[:id]).and(
          awards_table[:awardable_type].eq(self.name).and(
            awards_table[:name].in(emoji_names)
          )
        )
      ).join_sources

      joins(join_clause).group(awardable_table[:id]).reorder("COUNT(award_emoji.id) DESC")
    end
  end

  def grouped_awards(with_thumbs: true)
    # By default we always load award_emoji user association
    awards = award_emoji.group_by(&:name)

    if with_thumbs
      awards["thumbsup"]   ||= []
      awards["thumbsdown"] ||= []
    end

    awards
  end

  def downvotes
    award_emoji.downvotes.count
  end

  def upvotes
    award_emoji.upvotes.count
  end

  def all_downvotes
    award_emoji.all_downvotes.count
  end

  def all_upvotes
    award_emoji.all_upvotes.count
  end

  def emoji_awardable?
    true
  end

  def awardable_votes?(name)
    AwardEmoji::UPVOTE_NAME == name || AwardEmoji::DOWNVOTE_NAME == name
  end

  def user_can_award?(current_user, name)
    awardable_by_user?(current_user, name) && Ability.allowed?(current_user, :award_emoji, self)
  end

  def user_authored?(current_user)
    author = self.respond_to?(:author) ? self.author : self.user

    author == current_user
  end

  def awarded_emoji?(emoji_name, current_user)
    award_emoji.where(name: emoji_name, user: current_user).exists?
  end

  def create_award_emoji(name, current_user)
    return unless emoji_awardable?

    award_emoji.create(name: normalize_name(name), user: current_user)
  end

  def remove_award_emoji(name, current_user)
    award_emoji.where(name: name, user: current_user).destroy_all
  end

  def toggle_award_emoji(emoji_name, current_user)
    if awarded_emoji?(emoji_name, current_user)
      remove_award_emoji(emoji_name, current_user)
    else
      create_award_emoji(emoji_name, current_user)
    end
  end

  private

  def normalize_name(name)
    Gitlab::Emoji.normalize_emoji_name(name)
  end

  def awardable_by_user?(current_user, name)
    if user_authored?(current_user)
      !awardable_votes?(normalize_name(name))
    else
      true
    end
  end
end
