# frozen_string_literal: true

module Types
  module AntiAbuse
    class AbuseReportLabelType < BaseObject
      graphql_name 'AbuseReportLabel'

      implements LabelInterface

      connection_type_class Types::CountableConnectionType

      authorize :read_label

      markdown_field :description_html, null: true
    end
  end
end
