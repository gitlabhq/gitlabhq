# frozen_string_literal: true

module BatchLoaders
  module AwardEmojiVotesBatchLoader
    private

    def load_votes(object, vote_type)
      BatchLoader::GraphQL.for(object.id).batch(key: "#{object.issuing_parent_id}-#{vote_type}") do |ids, loader, args|
        counts = AwardEmoji.votes_for_collection(ids, object.class.name).named(vote_type).index_by(&:awardable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end

    def authorized_resource?(object)
      Ability.allowed?(current_user, "read_#{object.to_ability_name}".to_sym, object)
    end
  end
end
