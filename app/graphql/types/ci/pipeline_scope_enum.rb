# frozen_string_literal: true

module Types
  module Ci
    class PipelineScopeEnum < BaseEnum
      SCOPES_DESCRIPTION = {
        running: 'Pipeline is running.',
        pending: 'Pipeline has not started running yet.',
        finished: 'Pipeline has completed.',
        branches: 'Branches.',
        tags: 'Tags.'
      }.freeze

      SCOPES_DESCRIPTION.each do |scope, description|
        value scope.to_s.upcase,
          description: description,
          value: scope.to_s
      end
    end
  end
end
