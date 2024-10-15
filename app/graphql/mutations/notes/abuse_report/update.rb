# frozen_string_literal: true

module Mutations
  module Notes
    module AbuseReport
      class Update < BaseMutation
        graphql_name 'UpdateAbuseReportNote'
        description "Updates an abuse report Note."

        authorize :update_note

        field :note,
          Types::Notes::AbuseReport::NoteType,
          null: false, description: 'Abuse report note after mutation.'

        argument :id,
          ::Types::GlobalIDType[::AntiAbuse::Reports::Note],
          required: true,
          description: 'Global ID of the note to update.'

        argument :body,
          GraphQL::Types::String,
          required: true,
          description: copy_field_description(Types::Notes::NoteType, :body)

        def resolve(args)
          raise_resource_not_available_error! unless Feature.enabled?(:abuse_report_notes, current_user)

          note = authorized_find!(id: args[:id])

          response = ::Notes::AbuseReport::UpdateService.new(current_user, { note: args[:body] })
            .execute(note)

          {
            note: note,
            errors: response.error? ? response.message : []
          }
        end
      end
    end
  end
end
