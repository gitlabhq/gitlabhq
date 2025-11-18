# frozen_string_literal: true

module Types
  class AbuseReportType < BaseObject
    graphql_name 'AbuseReport'

    description 'An abuse report'

    authorize :read_abuse_report

    field :id, Types::GlobalIDType[::AbuseReport],
      null: false, description: 'Global ID of the abuse report.'
  end
end
