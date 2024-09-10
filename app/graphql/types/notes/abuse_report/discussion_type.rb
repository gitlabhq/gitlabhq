# frozen_string_literal: true

module Types
  module Notes
    module AbuseReport
      class DiscussionType < BaseObject
        graphql_name 'AbuseReportDiscussion'

        authorize :read_note

        DiscussionID = ::Types::GlobalIDType[::Discussion]

        implements Types::Notes::BaseDiscussionInterface

        field :abuse_report, Types::AbuseReportType, null: true,
          description: 'Abuse report which the discussion belongs to.'

        field :notes, Types::Notes::AbuseReport::NoteType.connection_type, null: false,
          description: 'All notes in the discussion.'
      end
    end
  end
end
