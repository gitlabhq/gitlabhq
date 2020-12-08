# frozen_string_literal: true

module Resolvers
  class UserDiscussionsCountResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type GraphQL::INT_TYPE, null: true

    def resolve
      authorize!(object)

      BatchLoader::GraphQL.for(object.id).batch(key: :issue_user_discussions_count) do |ids, loader, args|
        counts = Note.count_for_collection(ids, 'Issue', 'COUNT(DISTINCT discussion_id) as count').index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end

    def authorized_resource?(object)
      context[:current_user].present? && Ability.allowed?(context[:current_user], :read_issue, object)
    end
  end
end
