# frozen_string_literal: true

module Types
  class AbuseReportType < BaseObject
    graphql_name 'AbuseReport'

    description 'An abuse report'

    authorize :read_abuse_report

    field :id, Types::GlobalIDType[::AbuseReport],
      null: false, description: 'Global ID of the abuse report.'

    field :labels, ::Types::LabelType.connection_type,
      null: true, description: 'Labels of the abuse report.'

    field :discussions, ::Types::Notes::AbuseReport::DiscussionType.connection_type,
      null: false, description: "All discussions on the noteable."
    field :notes, ::Types::Notes::AbuseReport::NoteType.connection_type,
      null: false, description: "All notes on the noteable."
  end
end
