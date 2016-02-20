module Awardable
  extend ActiveSupport::Concern

  included do
    has_many :emoji_awards, as: :awardable, dependent: :destroy
  end

  module ClassMethods
    def order_upvotes_desc
      order_votes_desc(EmojiAward::UPVOTE_NAME)
    end

    def order_downvotes_desc
      order_votes_desc(EmojiAward::DOWNVOTE_NAME)
    end

    def order_votes_desc(emoji_name)
      awardable_table = self.arel_table
      awards_table = EmojiAward.arel_table

      join_clause = awardable_table.join(awards_table, Arel::Nodes::OuterJoin).on(
        awards_table[:awardable_id].eq(awardable_table[:id]).and(
          awards_table[:awardable_type].eq(self.name).and(
            awards_table[:name].eq(emoji_name)
          )
        )
      ).join_sources

      joins(join_clause).group(awardable_table[:id]).reorder("COUNT(emoji_awards.id) DESC")
    end
  end

  def grouped_awards
    awards = emoji_awards.group_by(&:name)

    awards[EmojiAward::UPVOTE_NAME] ||= EmojiAward.none
    awards[EmojiAward::DOWNVOTE_NAME] ||= EmojiAward.none

    awards
  end

  def downvotes
    emoji_awards.where(name: EmojiAward::DOWNVOTE_NAME).count
  end

  def upvotes
    emoji_awards.where(name: EmojiAward::UPVOTE_NAME).count
  end

  def emoji_awardable?
    true
  end

  def awarded_emoji?(emoji_name, current_user)
    emoji_awards.where(name: emoji_name, user: current_user).exists?
  end

  def award_emoji(emoji_name, current_user)
    return unless emoji_awardable?
    emoji_awards.create(name: emoji_name, user: current_user)
  end

  def remove_emoji_award(emoji_name, current_user)
    emoji_awards.where(name: emoji_name, user: current_user).destroy_all
  end

  def toggle_emoji_award(emoji_name, current_user)
    if awarded_emoji?(emoji_name, current_user)
      remove_emoji_award(emoji_name, current_user)
    else
      award_emoji(emoji_name, current_user)
    end
  end
end
