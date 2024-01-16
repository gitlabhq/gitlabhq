# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class Discussion < Base
        graphql_name 'CreateDiscussion'

        private

        def create_note_params(noteable, args)
          super(noteable, args).merge({ type: 'DiscussionNote' })
        end
      end
    end
  end
end
