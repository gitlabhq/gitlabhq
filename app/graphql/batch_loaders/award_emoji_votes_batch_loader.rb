# frozen_string_literal: true

module BatchLoaders
  class AwardEmojiVotesBatchLoader
    def self.load_upvotes(object, awardable_class: nil)
      load_votes_for(object, AwardEmoji::UPVOTE_NAME, awardable_class: awardable_class)
    end

    def self.load_downvotes(object, awardable_class: nil)
      load_votes_for(object, AwardEmoji::DOWNVOTE_NAME, awardable_class: awardable_class)
    end

    def self.load_votes_for(object, vote_type, awardable_class: nil)
      awardable_class ||= object.class.name
      batch_key = "#{object.class.base_class.name}-#{vote_type}"

      BatchLoader::GraphQL.for(object.id).batch(key: batch_key) do |ids, loader, _args|
        counts = AwardEmoji.votes_for_collection(ids, awardable_class).named(vote_type).index_by(&:awardable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end
  end
end

BatchLoaders::AwardEmojiVotesBatchLoader.prepend_mod
