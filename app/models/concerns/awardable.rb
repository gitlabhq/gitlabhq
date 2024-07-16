# frozen_string_literal: true

module Awardable
  extend ActiveSupport::Concern

  included do
    has_many :award_emoji, -> { includes(:user).order(:id) }, as: :awardable, inverse_of: :awardable, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    if self < Participable
      # By default we always load award_emoji user association
      participant :award_emoji
    end
  end

  class_methods do
    def awarded(user, opts = {})
      inner_query = inner_filter_query(user, opts)

      where(inner_query.exists)
    end

    def not_awarded(user, opts = {})
      inner_query = inner_filter_query(user, opts)

      where(inner_query.exists.not)
    end

    def order_upvotes_desc
      order_votes(AwardEmoji::UPVOTE_NAME, 'DESC')
    end

    def order_upvotes_asc
      order_votes(AwardEmoji::UPVOTE_NAME, 'ASC')
    end

    def order_downvotes_desc
      order_votes(AwardEmoji::DOWNVOTE_NAME, 'DESC')
    end

    # Order votes by emoji, optional sort order param `descending` defaults to true
    def order_votes(emoji_name, direction, base_class_name = base_class.name, awardable_id_column = :id)
      awardable_table = self.arel_table
      awards_table = AwardEmoji.arel_table

      join_clause = awardable_table
        .join(awards_table, Arel::Nodes::OuterJoin)
        .on(awards_table[:awardable_id].eq(awardable_table[awardable_id_column])
              .and(awards_table[:awardable_type].eq(base_class_name).and(awards_table[:name].eq(emoji_name))))
        .join_sources

      joins(join_clause).group(awardable_table[:id]).reorder(
        Arel.sql("COUNT(award_emoji.id) #{direction}")
      )
    end

    private

    # Fragment used to build queries when filtering objects by award emoji
    def inner_filter_query(user, opts = {})
      award_emoji_table = Arel::Table.new('award_emoji')

      emoji_name = opts[:name]
      base_class_name = opts[:base_class_name] || base_class.name
      awardable_id_column = opts[:awardable_id_column] || self.arel_table[:id]

      inner_query =
        award_emoji_table
          .project('true')
          .where(award_emoji_table[:user_id].eq(user.id))
          .where(award_emoji_table[:awardable_type].eq(base_class_name))
          .where(award_emoji_table[:awardable_id].eq(awardable_id_column))

      inner_query.where(award_emoji_table[:name].eq(emoji_name)) if emoji_name.present?

      inner_query
    end
  end

  def grouped_awards(with_thumbs: true)
    # By default we always load award_emoji user association
    awards = award_emoji.group_by(&:name)

    if with_thumbs && (!project || project.show_default_award_emojis?)
      awards[AwardEmoji::UPVOTE_NAME]   ||= []
      awards[AwardEmoji::DOWNVOTE_NAME] ||= []
    end

    awards
  end

  def downvotes
    award_emoji.downvotes.count
  end

  def upvotes
    award_emoji.upvotes.count
  end

  def emoji_awardable?
    true
  end

  def user_can_award?(current_user)
    Ability.allowed?(current_user, :award_emoji, self)
  end

  def user_authored?(current_user)
    author = self.respond_to?(:author) ? self.author : self.user

    author == current_user
  end

  def awarded_emoji?(emoji_name, current_user)
    award_emoji.named(emoji_name).awarded_by(current_user).exists?
  end
end
