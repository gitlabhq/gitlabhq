# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class RelatedBranch < Grape::Entity
          expose :name, documentation: { type: 'String', example: '1-my-feature-branch' }
          expose :compare_path, documentation: { type: 'String', example: '/group/project/-/compare/master...1-fix' }
          # rubocop:disable API/EntityFieldType -- DetailedStatusEntity is a serializer reused across the API (see Entities::Ci::Pipeline)
          expose :pipeline_status, using: ::DetailedStatusEntity,
            documentation: { type: 'object' }
          # rubocop:enable API/EntityFieldType
        end
      end
    end
  end
end
