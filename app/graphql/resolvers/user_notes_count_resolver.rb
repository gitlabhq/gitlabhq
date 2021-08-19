# frozen_string_literal: true

module Resolvers
  class UserNotesCountResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type GraphQL::Types::Int, null: true

    def resolve
      authorize!(object)

      BatchLoader::GraphQL.for(object.id).batch(key: :user_notes_count) do |ids, loader, args|
        counts = Note.count_for_collection(ids, object.class.name).index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end

    def authorized_resource?(object)
      ability = "read_#{object.class.name.underscore}".to_sym
      context[:current_user].present? && Ability.allowed?(context[:current_user], ability, object)
    end
  end
end
