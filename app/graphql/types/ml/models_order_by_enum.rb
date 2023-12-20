# frozen_string_literal: true

module Types
  module Ml
    class ModelsOrderByEnum < BaseEnum
      graphql_name 'MlModelsOrderBy'
      description 'Values for ordering machine learning models by a specific field'

      value 'NAME', 'Ordered by name.', value: :name
      value 'CREATED_AT', 'Ordered by creation time.', value: :created_at
      value 'UPDATED_AT', 'Ordered by update time.', value: :updated_at
      value 'ID', 'Ordered by id.', value: :id
    end
  end
end
