# frozen_string_literal: true

module Types
  module Users
    class RecentlyViewedItemType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is a wrapper type, authorization is handled by the underlying items
      graphql_name 'RecentlyViewedItem'

      field :item, Types::Users::RecentlyViewedItemUnion, null: false,
        description: 'Recently viewed item.'

      field :viewed_at, Types::TimeType, null: false,
        description: 'When the item was last viewed.'
    end
  end
end
