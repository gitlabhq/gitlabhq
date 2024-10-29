# frozen_string_literal: true

module Types
  module PermissionTypes
    module Wikis
      class WikiPage < BasePermissionType
        graphql_name 'WikiPagePermissions'

        abilities :read_wiki_page, :create_note
      end
    end
  end
end
