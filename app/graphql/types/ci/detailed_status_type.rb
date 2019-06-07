# frozen_string_literal: true
module Types
  module Ci
    class DetailedStatusType < BaseObject
      graphql_name 'DetailedStatus'

      field :group, GraphQL::STRING_TYPE, null: false
      field :icon, GraphQL::STRING_TYPE, null: false
      field :favicon, GraphQL::STRING_TYPE, null: false
      field :details_path, GraphQL::STRING_TYPE, null: false
      field :has_details, GraphQL::BOOLEAN_TYPE, null: false, method: :has_details?
      field :label, GraphQL::STRING_TYPE, null: false
      field :text, GraphQL::STRING_TYPE, null: false
      field :tooltip, GraphQL::STRING_TYPE, null: false, method: :status_tooltip
    end
  end
end
