# frozen_string_literal: true

module Mutations
  module Snippets
    class Create < BaseMutation
      include ServiceCompatibility
      include CanMutateSpammable
      include Mutations::SpamProtection

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

        process_args_for_params!(args)

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        service = ::Snippets::CreateService.new(project: project, current_user: current_user, params: args, spam_params: spam_params)
        service_response = service.execute

        # Only when the user is not an api user and the operation was successful
        if !api_user? && service_response.success?
          ::Gitlab::UsageDataCounters::EditorUniqueCounter.track_snippet_editor_edit_action(author: current_user)
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

        # Return nil to make it explicit that this method is mutating the args parameter, and that
        # the return value is not relevant and is not to be used.
        nil
      end
    end
  end
end
