# frozen_string_literal: true

module Mutations
  module Snippets
    class Update < Base
      include SpammableMutationFields

      graphql_name 'UpdateSnippet'

      argument :id, ::Types::GlobalIDType[::Snippet],
               required: true,
               description: 'The global id of the snippet to update'

      argument :title, GraphQL::STRING_TYPE,
               required: false,
               description: 'Title of the snippet'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the snippet'

      argument :visibility_level, Types::VisibilityLevelsEnum,
               description: 'The visibility level of the snippet',
               required: false

      argument :blob_actions, [Types::Snippets::BlobActionInputType],
               description: 'Actions to perform over the snippet repository and blobs',
               required: false

      def resolve(args)
        snippet = authorized_find!(id: args.delete(:id))

        result = ::Snippets::UpdateService.new(snippet.project,
                                               context[:current_user],
                                               update_params(args)).execute(snippet)
        snippet = result.payload[:snippet]

        # Only when the user is not an api user and the operation was successful
        if !api_user? && result.success?
          ::Gitlab::UsageDataCounters::EditorUniqueCounter.track_snippet_editor_edit_action(author: current_user)
        end

        with_spam_fields(snippet) do
          {
            snippet: result.success? ? snippet : snippet.reset,
            errors: errors_on_object(snippet)
          }
        end
      end

      private

      def ability_name
        'update'
      end

      def update_params(args)
        with_spam_params do
          args.tap do |update_args|
            # We need to rename `blob_actions` into `snippet_actions` because
            # it's the expected key param
            update_args[:snippet_actions] = update_args.delete(:blob_actions)&.map(&:to_h)
          end
        end
      end
    end
  end
end
