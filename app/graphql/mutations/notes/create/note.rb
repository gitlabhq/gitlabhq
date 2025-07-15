# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class Note < Base
        graphql_name 'CreateNote'
        description "Creates a Note.\n#{QUICK_ACTION_ONLY_WARNING}"

        argument :discussion_id,
          ::Types::GlobalIDType[::Discussion],
          required: false,
          description: 'Global ID of the discussion the note is in reply to.'

        argument :merge_request_diff_head_sha,
          GraphQL::Types::String,
          required: false,
          description: 'SHA of the head commit which is used to ensure that ' \
            'the merge request has not been updated since the request was sent.'

        private

        def create_note_params(noteable, args)
          discussion_id = nil

          if gid = args[:discussion_id]
            discussion_id = ::GitlabSchema.parse_gid(gid, expected_type: ::Discussion).model_id
            discussion = noteable.notes.find_discussion(discussion_id)

            authorize_discussion!(discussion)
          end

          super.merge({
            in_reply_to_discussion_id: discussion_id,
            merge_request_diff_head_sha: args[:merge_request_diff_head_sha]
          })
        end

        def authorize_discussion!(discussion)
          unless Ability.allowed?(current_user, :read_note, discussion, scope: :user)
            error_msg = <<~ERR.squish
              The discussion does not exist or you don't have permission to perform this action
            ERR

            raise_resource_not_available_error! error_msg
          end
        end
      end
    end
  end
end
