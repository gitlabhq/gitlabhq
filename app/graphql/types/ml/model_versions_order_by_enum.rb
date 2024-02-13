# frozen_string_literal: true

module Types
  module Ml
    class ModelVersionsOrderByEnum < BaseEnum
      graphql_name 'MlModelVersionsOrderBy'
      description 'Field names for ordering machine learning model versions'

      value 'VERSION', 'Ordered by name.', value: :name
      value 'CREATED_AT', 'Ordered by creation time.', value: :created_at
      value 'ID', 'Ordered by id.', value: :id
    end
  end
end
