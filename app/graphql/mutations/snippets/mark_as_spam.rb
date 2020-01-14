# frozen_string_literal: true

module Mutations
  module Snippets
    class MarkAsSpam < Base
      graphql_name 'MarkAsSpamSnippet'

      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the snippet to update'

      def resolve(id:)
        snippet = authorized_find!(id: id)

        result = mark_as_spam(snippet)
        errors = result ? [] : ['Error with Akismet. Please check the logs for more info.']

        {
          errors: errors
        }
      end

      private

      def mark_as_spam(snippet)
        SpamService.new(spammable: snippet).mark_as_spam!
      end

      def authorized_resource?(snippet)
        super && snippet.submittable_as_spam_by?(context[:current_user])
      end

      def ability_name
        "admin"
      end
    end
  end
end
