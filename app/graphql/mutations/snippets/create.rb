# frozen_string_literal: true

module Mutations
  module Snippets
    class Create < BaseMutation
      include SpammableMutationFields

      authorize :create_snippet

      graphql_name 'CreateSnippet'

      field :snippet,
            Types::SnippetType,
            null: true,
            description: 'The snippet after mutation.'

      argument :title, GraphQL::STRING_TYPE,
               required: true,
               description: 'Title of the snippet.'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the snippet.'

      argument :visibility_level, Types::VisibilityLevelsEnum,
               description: 'The visibility level of the snippet.',
               required: true

      argument :project_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The project full path the snippet is associated with.'

      argument :uploaded_files, [GraphQL::STRING_TYPE],
               required: false,
               description: 'The paths to files uploaded in the snippet description.'

      argument :blob_actions, [Types::Snippets::BlobActionInputType],
               description: 'Actions to perform over the snippet repository and blobs.',
               required: false

      def resolve(project_path: nil, **args)
        if project_path.present?
          project = authorized_find!(project_path)
        else
          authorize!(:global)
        end

        service_response = ::Snippets::CreateService.new(project,
                                                         current_user,
                                                         create_params(args)).execute

        snippet = service_response.payload[:snippet]

        # Only when the user is not an api user and the operation was successful
        if !api_user? && service_response.success?
          ::Gitlab::UsageDataCounters::EditorUniqueCounter.track_snippet_editor_edit_action(author: current_user)
        end

        with_spam_fields(snippet) do
          {
            snippet: service_response.success? ? snippet : nil,
            errors: errors_on_object(snippet)
          }
        end
      end

      private

      def find_object(full_path)
        Project.find_by_full_path(full_path)
      end

      def create_params(args)
        with_spam_params do
          args.tap do |create_args|
            # We need to rename `blob_actions` into `snippet_actions` because
            # it's the expected key param
            create_args[:snippet_actions] = create_args.delete(:blob_actions)&.map(&:to_h)

            # We need to rename `uploaded_files` into `files` because
            # it's the expected key param
            create_args[:files] = create_args.delete(:uploaded_files)
          end
        end
      end
    end
  end
end
