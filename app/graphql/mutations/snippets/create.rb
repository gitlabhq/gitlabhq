# frozen_string_literal: true

module Mutations
  module Snippets
    class Create < BaseMutation
      graphql_name 'CreateSnippet'

      include ServiceCompatibility
      include Mutations::SpamProtection
      include Gitlab::InternalEventsTracking

      authorize :create_snippet

      field :snippet,
        Types::SnippetType,
        null: true,
        description: 'Snippet after mutation.'

      argument :title, GraphQL::Types::String,
        required: true,
        description: 'Title of the snippet.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description of the snippet.'

      argument :visibility_level, Types::VisibilityLevelsEnum,
        description: 'Visibility level of the snippet.',
        required: true

      argument :project_path, GraphQL::Types::ID,
        required: false,
        description: 'Full path of the project the snippet is associated with.'

      argument :uploaded_files, [GraphQL::Types::String],
        required: false,
        description: 'Paths to files uploaded in the snippet description.'

      argument :blob_actions, [Types::Snippets::BlobActionInputType],
        description: 'Actions to perform over the snippet repository and blobs.',
        required: false

      def resolve(project_path: nil, **args)
        if project_path.present?
          project = authorized_find!(project_path)
        else
          authorize!(:global)
        end

        process_args_for_params!(args)

        service = ::Snippets::CreateService.new(project: project, current_user: current_user, params: args)
        service_response = service.execute

        # Only when the user is not an api user and the operation was successful
        if !api_user? && service_response.success?
          track_internal_event(
            'g_edit_by_snippet_ide',
            user: current_user,
            project: project
          )
        end

        snippet = service_response.payload[:snippet]
        check_spam_action_response!(snippet)

        {
          snippet: service_response.success? ? snippet : nil,
          errors: errors_on_object(snippet)
        }
      end

      private

      def find_object(full_path)
        Project.find_by_full_path(full_path)
      end

      # process_args_for_params!(args)    -> nil
      #
      # Modifies/adds/deletes mutation resolve args as necessary to be passed as params to service layer.
      def process_args_for_params!(args)
        convert_blob_actions_to_snippet_actions!(args)

        # We need to rename `uploaded_files` into `files` because
        # it's the expected key param
        args[:files] = args.delete(:uploaded_files)
        args[:organization_id] = Current.organization_id
        # Return nil to make it explicit that this method is mutating the args parameter, and that
        # the return value is not relevant and is not to be used.
        nil
      end
    end
  end
end
