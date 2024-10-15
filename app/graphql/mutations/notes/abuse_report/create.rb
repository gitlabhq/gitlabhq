# frozen_string_literal: true

module Mutations
  module Notes
    module AbuseReport
      class Create < BaseMutation
        graphql_name 'CreateAbuseReportNote'
        description "Creates an abuse report Note."

        authorize :create_note

        field :note,
          Types::Notes::AbuseReport::NoteType,
          null: true, description: 'Abuse report note after mutation.'

        argument :abuse_report_id, Types::GlobalIDType[::AbuseReport],
          required: true, description: 'ID of the abuse report.'
        argument :body,
          GraphQL::Types::String,
          required: true,
          description: copy_field_description(Types::Notes::NoteType, :body)
        argument :discussion_id,
          ::Types::GlobalIDType[::Discussion],
          required: false,
          description: 'Global ID of the abuse report discussion the note is in reply to.'

        def resolve(args)
          raise_resource_not_available_error! unless Feature.enabled?(:abuse_report_notes, current_user)

          note = ::Notes::AbuseReport::CreateService.new(current_user, create_note_params(args)).execute

          {
            note: (note if note.persisted?),
            errors: errors_on_object(note)
          }
        end

        private

        def create_note_params(args)
          abuse_report = authorized_find!(id: args[:abuse_report_id])
          discussion_id = nil

          if args[:discussion_id]
            discussion = GitlabSchema.find_by_gid(args[:discussion_id])

            discussion_id = discussion.id
          end

          {
            abuse_report: abuse_report,
            note: args[:body],
            in_reply_to_discussion_id: discussion_id
          }
        end
      end
    end
  end
end
