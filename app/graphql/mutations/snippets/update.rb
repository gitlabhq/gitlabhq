# frozen_string_literal: true

module Mutations
  module Snippets
    class Update < Base
      graphql_name 'UpdateSnippet'

      include ServiceCompatibility
      include Mutations::SpamProtection
      include Gitlab::InternalEventsTracking

      argument :id, ::Types::GlobalIDType[::Snippet],
        required: true,
        description: 'Global ID of the snippet to update.'

      argument :title, GraphQL::Types::String,
        required: false,
        description: 'Title of the snippet.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description of the snippet.'

      argument :visibility_level, Types::VisibilityLevelsEnum,
        description: 'Visibility level of the snippet.',
        required: false

      argument :blob_actions, [Types::Snippets::BlobActionInputType],
        description: 'Actions to perform over the snippet repository and blobs.',
        required: false

      def resolve(id:, **args)
        snippet = authorized_find!(id: id)

        process_args_for_params!(args)

        service = ::Snippets::UpdateService.new(
          project: snippet.project,
          current_user: current_user,
          params: args,
          perform_spam_check: true
        )
        service_response = service.execute(snippet)

        # TODO: DRY this up - From here down, this is all duplicated with Mutations::Snippets::Create#resolve, except
        # for `snippet.reset`, which is required in order to return the object in its non-dirty, unmodified, database
        # state.
        # See issue here: https://gitlab.com/gitlab-org/gitlab/-/issues/300250.

        # Only when the user is not an api user and the operation was successful
        if !api_user? && service_response.success?
          track_internal_event(
            'g_edit_by_snippet_ide',
            user: current_user,
            project: snippet.project
          )
        end

        snippet = service_response.payload[:snippet]
        check_spam_action_response!(snippet)

        {
          snippet: service_response.success? ? snippet : snippet.reset,
          errors: errors_on_object(snippet)
        }
      end

      private

      # process_args_for_params!(args)    -> nil
      #
      # Modifies/adds/deletes mutation resolve args as necessary to be passed as params to service layer.
      def process_args_for_params!(args)
        convert_blob_actions_to_snippet_actions!(args)

        # Return nil to make it explicit that this method is mutating the args parameter, and that
        # the return value is not relevant and is not to be used.
        nil
      end

      def ability_name
        'update'
      end
    end
  end
end
