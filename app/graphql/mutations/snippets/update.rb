# frozen_string_literal: true

module Mutations
  module Snippets
    class Update < Base
      include ServiceCompatibility
      include CanMutateSpammable
      include Mutations::SpamProtection

      graphql_name 'UpdateSnippet'

      argument :id, ::Types::GlobalIDType[::Snippet],
               required: true,
               description: 'The global ID of the snippet to update.'

      argument :title, GraphQL::STRING_TYPE,
               required: false,
               description: 'Title of the snippet.'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the snippet.'

      argument :visibility_level, Types::VisibilityLevelsEnum,
               description: 'The visibility level of the snippet.',
               required: false

      argument :blob_actions, [Types::Snippets::BlobActionInputType],
               description: 'Actions to perform over the snippet repository and blobs.',
               required: false

      def resolve(id:, **args)
        snippet = authorized_find!(id: id)

        process_args_for_params!(args)

        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])
        service = ::Snippets::UpdateService.new(project: snippet.project, current_user: current_user, params: args, spam_params: spam_params)
        service_response = service.execute(snippet)

        # TODO: DRY this up - From here down, this is all duplicated with Mutations::Snippets::Create#resolve, except for
        #    `snippet.reset`, which is required in order to return the object in its non-dirty, unmodified, database state
        #    See issue here: https://gitlab.com/gitlab-org/gitlab/-/issues/300250

        # Only when the user is not an api user and the operation was successful
        if !api_user? && service_response.success?
          ::Gitlab::UsageDataCounters::EditorUniqueCounter.track_snippet_editor_edit_action(author: current_user)
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
