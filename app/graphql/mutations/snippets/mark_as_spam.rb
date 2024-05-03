# frozen_string_literal: true

module Mutations
  module Snippets
    class MarkAsSpam < Base
      graphql_name 'MarkAsSpamSnippet'

      argument :id, ::Types::GlobalIDType[::Snippet],
        required: true,
        description: 'Global ID of the snippet to update.'

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
        Spam::AkismetMarkAsSpamService.new(target: snippet).execute
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
