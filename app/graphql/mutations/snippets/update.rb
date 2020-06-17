# frozen_string_literal: true

module Mutations
  module Snippets
    class Update < Base
      graphql_name 'UpdateSnippet'

      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the snippet to update'

      argument :title, GraphQL::STRING_TYPE,
               required: false,
               description: 'Title of the snippet'

      argument :file_name, GraphQL::STRING_TYPE,
               required: false,
               description: 'File name of the snippet'

      argument :content, GraphQL::STRING_TYPE,
               required: false,
               description: 'Content of the snippet'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description of the snippet'

      argument :visibility_level, Types::VisibilityLevelsEnum,
               description: 'The visibility level of the snippet',
               required: false

      argument :files, [Types::Snippets::FileInputType],
               description: 'The snippet files to update',
               required: false

      def resolve(args)
        snippet = authorized_find!(id: args.delete(:id))

        result = ::Snippets::UpdateService.new(snippet.project,
                                               context[:current_user],
                                               update_params(args)).execute(snippet)
        snippet = result.payload[:snippet]

        {
          snippet: result.success? ? snippet : snippet.reset,
          errors: errors_on_object(snippet)
        }
      end

      private

      def ability_name
        'update'
      end

      def update_params(args)
        args.tap do |update_args|
          # We need to rename `files` into `snippet_files` because
          # it's the expected key param
          update_args[:snippet_files] = update_args.delete(:files)&.map(&:to_h)
        end
      end
    end
  end
end
