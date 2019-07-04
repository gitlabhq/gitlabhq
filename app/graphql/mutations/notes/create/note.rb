# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class Note < Base
        graphql_name 'CreateNote'

        argument :discussion_id,
                  GraphQL::ID_TYPE,
                  required: false,
                  description: 'The global id of the discussion this note is in reply to'

        private

        def create_note_params(noteable, args)
          discussion_id = nil

          if args[:discussion_id]
            discussion = GitlabSchema.object_from_id(args[:discussion_id])
            authorize_discussion!(discussion)

            discussion_id = discussion.id
          end

          super(noteable, args).merge({
            in_reply_to_discussion_id: discussion_id
          })
        end

        def authorize_discussion!(discussion)
          unless Ability.allowed?(current_user, :read_note, discussion, scope: :user)
            raise Gitlab::Graphql::Errors::ResourceNotAvailable,
              "The discussion does not exist or you don't have permission to perform this action"
          end
        end
      end
    end
  end
end
