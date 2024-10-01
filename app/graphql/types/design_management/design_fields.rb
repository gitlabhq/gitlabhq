# frozen_string_literal: true

module Types
  module DesignManagement
    module DesignFields
      include BaseInterface

      field_class Types::BaseField

      field :id, GraphQL::Types::ID, description: 'ID of this design.', null: false
      field :project, Types::ProjectType, null: false, description: 'Project the design belongs to.'
      field :issue, Types::IssueType, null: false, description: 'Issue the design belongs to.'
      field :filename, GraphQL::Types::String, null: false, description: 'Filename of the design.'
      field :full_path, GraphQL::Types::ID, null: false, description: 'Full path to the design file.'
      field :image, GraphQL::Types::String, null: false, extras: [:parent], description: 'URL of the full-sized image.'
      field :image_v432x230,
        GraphQL::Types::String,
        null: true,
        extras: [:parent],
        description: 'The URL of the design resized to fit within the bounds of 432x230. ' \
          'This will be `null` if the image has not been generated'
      field :diff_refs, Types::DiffRefsType,
        null: false,
        calls_gitaly: true,
        extras: [:parent],
        description: 'Diff refs for this design.'
      field :event, Types::DesignManagement::DesignVersionEventEnum,
        null: false,
        extras: [:parent],
        description: 'How this design was changed in the current version.'
      field :notes_count,
        GraphQL::Types::Int,
        null: false,
        method: :user_notes_count,
        description: 'Total count of user-created notes for this design.'

      def diff_refs(parent:)
        version = cached_stateful_version(parent)
        version.diff_refs
      end

      def image(parent:)
        sha = cached_stateful_version(parent).sha

        Gitlab::UrlBuilder.build(design, ref: sha)
      end

      def image_v432x230(parent:)
        Gitlab::Graphql::Lazy.with_value(lazy_action(parent)) do |action|
          # A `nil` return value indicates that the image has not been processed
          next unless action&.image_v432x230&.file

          Gitlab::UrlBuilder.build(action.design, ref: action.version.sha, size: :v432x230)
        end
      end

      def event(parent:)
        version = cached_stateful_version(parent)

        action = cached_actions_for_version(version)[design.id]

        action&.event || ::Types::DesignManagement::DesignVersionEventEnum::NONE
      end

      def cached_actions_for_version(version)
        Gitlab::SafeRequestStore.fetch(['DesignFields', 'actions_for_version', version.id]) do
          version.actions.index_by(&:design_id)
        end
      end

      def project
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Project, design.project_id).find
      end

      def issue
        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Issue, design.issue_id).find
      end

      private

      def lazy_action(parent)
        version = cached_stateful_version(parent)

        BatchLoader::GraphQL.for([version, design]).batch do |ids, loader|
          by_version = ids.group_by(&:first).transform_values { _1.map(&:second) }
          designs_by_id = ids.map(&:second).index_by(&:id)

          by_version.each do |v, designs|
            actions = ::DesignManagement::Action.most_recent.up_to_version(v).by_design(designs).with_version
            actions.each do |action|
              action.design = designs_by_id[action.design_id] # eliminate duplicate load
              loader.call([v, action.design], action)
            end
          end
        end
      end
    end
  end
end
