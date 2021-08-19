# frozen_string_literal: true

module Types
  module DesignManagement
    module DesignFields
      include BaseInterface

      field_class Types::BaseField

      field :id, GraphQL::Types::ID, description: 'The ID of this design.', null: false
      field :project, Types::ProjectType, null: false, description: 'The project the design belongs to.'
      field :issue, Types::IssueType, null: false, description: 'The issue the design belongs to.'
      field :filename, GraphQL::Types::String, null: false, description: 'The filename of the design.'
      field :full_path, GraphQL::Types::String, null: false, description: 'The full path to the design file.'
      field :image, GraphQL::Types::String, null: false, extras: [:parent], description: 'The URL of the full-sized image.'
      field :image_v432x230, GraphQL::Types::String, null: true, extras: [:parent],
            description: 'The URL of the design resized to fit within the bounds of 432x230. ' \
                         'This will be `null` if the image has not been generated'
      field :diff_refs, Types::DiffRefsType,
            null: false,
            calls_gitaly: true,
            extras: [:parent],
            description: 'The diff refs for this design.'
      field :event, Types::DesignManagement::DesignVersionEventEnum,
            null: false,
            extras: [:parent],
            description: 'How this design was changed in the current version.'
      field :notes_count,
            GraphQL::Types::Int,
            null: false,
            method: :user_notes_count,
            description: 'The total count of user-created notes for this design.'

      def diff_refs(parent:)
        version = cached_stateful_version(parent)
        version.diff_refs
      end

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        Gitlab::UrlBuilder.build(design, ref: sha)
      end

      def image_v432x230(parent:)
        version = cached_stateful_version(parent)
        action = design.actions.up_to_version(version).most_recent.first

        # A `nil` return value indicates that the image has not been processed
        return unless action.image_v432x230.file

        Gitlab::UrlBuilder.build(design, ref: version.sha, size: :v432x230)
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || ::Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch(['DesignFields', 'actions_for_version', version.id]) do
          version.actions.to_h { |dv| [dv.design_id, dv] }
        end
      end

      def project
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Project, design.project_id).find
      end

      def issue
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Issue, design.issue_id).find
      end
    end
  end
end
