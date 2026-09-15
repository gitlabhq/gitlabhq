# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class Discussion < Base
        graphql_name 'CreateDiscussion'

        def self.authorization_scopes
          super + [:ai_workflows]
        end

        private

        def create_note_params(noteable, args)
          super.merge({ type: 'DiscussionNote' })
        end
      end
    end
  end
end
