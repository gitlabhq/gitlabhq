# frozen_string_literal: true

module Types
  module Ci
    module PipelineCreation
      class StatusEnum < BaseEnum
        graphql_name 'CiPipelineCreationStatus'

        description 'The status of a pipeline creation'

        ::Ci::PipelineCreation::Requests::STATUSES.each do |status|
          value status.upcase, description: "The pipeline creation is #{status.tr('_', ' ')}", value: status
        end
      end
    end
  end
end
