# frozen_string_literal: true

module Mutations
  module Wikis
    class WikiPageSubscribe < BaseMutation
      graphql_name 'WikiPageSubscribe'

      argument :id, ::Types::GlobalIDType[::WikiPage::Meta],
        required: true,
        description: 'Global ID of the wiki page meta record.'

      argument :subscribed,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Desired state of the subscription.'

      field :wiki_page, ::Types::Wikis::WikiPageType,
        null: true,
        description: 'Wiki page after mutation.'

      authorize :update_subscription

      def resolve(args)
        wiki_page_meta = authorized_find!(id: args[:id])

        update_subscription(wiki_page_meta, args[:subscribed])

        {
          wiki_page: wiki_page_meta,
          errors: []
        }
      end

      private

      def update_subscription(wiki_page_meta, subscribed_state)
        wiki_page_meta.set_subscription(current_user, subscribed_state, wiki_page_meta.project)
      end
    end
  end
end
