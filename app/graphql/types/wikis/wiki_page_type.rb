# frozen_string_literal: true

module Types
  module Wikis
    class WikiPageType < BaseObject
      graphql_name 'WikiPage'

      implements Types::Notes::NoteableInterface
      implements Types::TodoableInterface

      description 'A wiki page'

      authorize :read_wiki

      expose_permissions Types::PermissionTypes::Wikis::WikiPage

      field :id, Types::GlobalIDType[::WikiPage::Meta],
        null: false, description: 'Global ID of the wiki page metadata record.'

      field :title, GraphQL::Types::String,
        null: false, description: 'Wiki page title.'

      def web_url
        Gitlab::UrlBuilder.build(object)
      end
    end
  end
end
