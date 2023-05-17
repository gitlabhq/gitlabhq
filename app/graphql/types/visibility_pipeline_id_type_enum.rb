# frozen_string_literal: true

module Types
  class VisibilityPipelineIdTypeEnum < BaseEnum
    graphql_name 'VisibilityPipelineIdType'
    description 'Determines whether the pipeline list shows ID or IID'

    UserPreference.visibility_pipeline_id_types.each_key do |field|
      value field.upcase, value: field, description: "Display pipeline #{field.upcase}."
    end
  end
end
