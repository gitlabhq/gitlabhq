# frozen_string_literal: true

module Types
  class ReleaseLinksType < BaseObject
    graphql_name 'ReleaseLinks'

    authorize :download_code

    alias_method :release, :object

    present_using ReleasePresenter

    field :self_url, GraphQL::STRING_TYPE, null: true,
          description: 'HTTP URL of the release'
    field :merge_requests_url, GraphQL::STRING_TYPE, null: true,
          description: 'HTTP URL of the merge request page filtered by this release'
    field :issues_url, GraphQL::STRING_TYPE, null: true,
          description: 'HTTP URL of the issues page filtered by this release'
    field :edit_url, GraphQL::STRING_TYPE, null: true,
          description: "HTTP URL of the release's edit page",
          authorize: :update_release
  end
end
