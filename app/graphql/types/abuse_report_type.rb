# frozen_string_literal: true

module Types
  class AbuseReportType < BaseObject
    graphql_name 'AbuseReport'

    implements Types::Notes::NoteableInterface

    description 'An abuse report'

    authorize :read_abuse_report

    field :id, Types::GlobalIDType[::AbuseReport],
      null: false, description: 'Global ID of the abuse report.'

    field :labels, ::Types::LabelType.connection_type,
      null: true, description: 'Labels of the abuse report.'
  end
end
