# frozen_string_literal: true

module Types
  class AbuseReportType < BaseObject
    graphql_name 'AbuseReport'
    description 'An abuse report'
    authorize :read_abuse_report

    field :labels, ::Types::LabelType.connection_type,
      null: true, description: 'Labels of the abuse report.'
  end
end
