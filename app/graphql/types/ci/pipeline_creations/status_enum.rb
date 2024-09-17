# frozen_string_literal: true

module Types
  module Ci
    module PipelineCreations
      class StatusEnum < BaseEnum
        graphql_name 'CiPipelineCreationStatus'

        ::Ci::PipelineCreationMetadata::STATUSES.each do |status|
          verb_tense = status == :creating ? 'is' : 'has'

          value status.to_s.upcase, value: status, description: "Pipeline #{verb_tense} #{status}."
        end
      end
    end
  end
end
