# frozen_string_literal: true

module Types
  class ReleaseLinksType < BaseObject
    graphql_name 'ReleaseLinks'

    authorize :read_release

    alias_method :release, :object

    present_using ReleasePresenter

    field :closed_issues_url,
          GraphQL::Types::String,
          null: true,
          description: 'HTTP URL of the issues page, filtered by this release and `state=closed`.',
          authorize: :download_code
    field :closed_merge_requests_url,
          GraphQL::Types::String,
          null: true,
          description: 'HTTP URL of the merge request page , filtered by this release and `state=closed`.',
          authorize: :download_code
    field :edit_url, GraphQL::Types::String, null: true,
                                             description: "HTTP URL of the release's edit page.",
                                             authorize: :update_release
    field :merged_merge_requests_url,
          GraphQL::Types::String,
          null: true,
          description: 'HTTP URL of the merge request page , filtered by this release and `state=merged`.',
          authorize: :download_code
    field :opened_issues_url,
          GraphQL::Types::String,
          null: true,
          description: 'HTTP URL of the issues page, filtered by this release and `state=open`.',
          authorize: :download_code
    field :opened_merge_requests_url,
          GraphQL::Types::String,
          null: true,
          description: 'HTTP URL of the merge request page, filtered by this release and `state=open`.',
          authorize: :download_code
    field :self_url, GraphQL::Types::String, null: true,
                                             description: 'HTTP URL of the release.'
  end
end
