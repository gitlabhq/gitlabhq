# frozen_string_literal: true

module Types
  class ReleaseType < BaseObject
    graphql_name 'Release'
    description 'Represents a release'

    connection_type_class(Types::CountableConnectionType)

    authorize :read_release

    alias_method :release, :object

    present_using ReleasePresenter

    field :tag_name, GraphQL::Types::String, null: true, method: :tag,
          description: 'Name of the tag associated with the release.',
          authorize: :download_code
    field :tag_path, GraphQL::Types::String, null: true,
          description: 'Relative web path to the tag associated with the release.',
          authorize: :download_code
    field :description, GraphQL::Types::String, null: true,
          description: 'Description (also known as "release notes") of the release.'
    markdown_field :description_html, null: true
    field :name, GraphQL::Types::String, null: true,
          description: 'Name of the release.'
    field :created_at, Types::TimeType, null: true,
          description: 'Timestamp of when the release was created.'
    field :released_at, Types::TimeType, null: true,
          description: 'Timestamp of when the release was released.'
    field :upcoming_release, GraphQL::Types::Boolean, null: true, method: :upcoming_release?,
          description: 'Indicates the release is an upcoming release.'
    field :assets, Types::ReleaseAssetsType, null: true, method: :itself,
          description: 'Assets of the release.'
    field :links, Types::ReleaseLinksType, null: true, method: :itself,
          description: 'Links of the release.'
    field :milestones, Types::MilestoneType.connection_type, null: true,
          description: 'Milestones associated to the release.',
          resolver: ::Resolvers::ReleaseMilestonesResolver
    field :evidences, Types::EvidenceType.connection_type, null: true,
          description: 'Evidence for the release.'

    field :author, Types::UserType, null: true,
          description: 'User that created the release.'

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, release.author_id).find
    end

    field :commit, Types::CommitType, null: true,
          complexity: 10, calls_gitaly: true,
          description: 'The commit associated with the release.'

    def commit
      return if release.sha.nil?

      release.project.commit_by(oid: release.sha)
    end
  end
end
