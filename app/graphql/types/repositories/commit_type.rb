# frozen_string_literal: true

module Types
  module Repositories
    class CommitType < BaseObject
      graphql_name 'Commit'

      authorize :read_code

      present_using CommitPresenter

      implements Types::TodoableInterface

      field :id, type: GraphQL::Types::ID, null: false,
        description: 'ID (global ID) of the commit.'

      field :sha, type: GraphQL::Types::String, null: false,
        description: 'SHA1 ID of the commit.'

      field :short_id, type: GraphQL::Types::String, null: false,
        description: 'Short SHA1 ID of the commit.'

      field :title, type: GraphQL::Types::String, null: true, calls_gitaly: true,
        description: 'Title of the commit message.'

      field :full_title, type: GraphQL::Types::String, null: true, calls_gitaly: true,
        description: 'Full title of the commit message.'

      field :description, type: GraphQL::Types::String, null: true,
        description: 'Description of the commit message.'

      field :message, type: GraphQL::Types::String, null: true,
        description: 'Raw commit message.'

      field :authored_date, type: Types::TimeType, null: true,
        description: 'Timestamp of when the commit was authored.'

      field :committed_date, type: Types::TimeType, null: true,
        description: 'Timestamp of when the commit was committed.'

      field :web_url, type: GraphQL::Types::String, null: false,
        description: 'Web URL of the commit.'

      field :web_path, type: GraphQL::Types::String, null: false,
        description: 'Web path of the commit.'

      field :signature, type: Types::CommitSignatureInterface,
        null: true,
        calls_gitaly: true,
        description: 'Signature of the commit.'

      field :signature_html, type: GraphQL::Types::String, null: true, calls_gitaly: true,
        description: 'Rendered HTML of the commit signature.'

      field :author_email, type: GraphQL::Types::String, null: true,
        description: "Commit author's email."
      field :author_gravatar, type: GraphQL::Types::String, null: true,
        description: 'Commit authors gravatar.'
      field :author_name, type: GraphQL::Types::String, null: true,
        description: 'Commit authors name.'

      field :committer_email, type: GraphQL::Types::String, null: true,
        description: "Email of the committer."

      field :committer_name, type: GraphQL::Types::String, null: true,
        description: "Name of the committer."

      # models/commit lazy loads the author by email
      field :author, type: Types::UserType, null: true,
        description: 'Author of the commit.'

      field :diffs, [Types::DiffType], null: true, calls_gitaly: true,
        description: 'Diffs contained within the commit. ' \
          'This field can only be resolved for 10 diffs in any single request.' do
        # Limited to 10 calls per GraphQL request as calling `diffs` multiple times will
        # lead to N+1 queries to Gitaly.
        extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 10
      end

      field :pipelines,
        null: true,
        description: 'Pipelines of the commit ordered latest first.',
        resolver: Resolvers::CommitPipelinesResolver

      markdown_field :title_html, null: true
      markdown_field :full_title_html, null: true
      markdown_field :description_html, null: true

      def diffs
        object.diffs.diffs
      end

      def author_gravatar
        GravatarService.new.execute(object.author_email, 40)
      end
    end
  end
end
