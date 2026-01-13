# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      expose :name, documentation: { type: 'String', example: 'merge_train' }
      expose :description, documentation: { type: 'String', example: 'merge train feature flag' }
      expose :active, documentation: { type: 'Boolean' }
      expose :version, documentation: { type: 'String', example: 'new_version_flag' }
      expose :created_at, documentation: { type: 'DateTime', example: '2019-11-04T08:13:51.423Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2019-11-04T08:13:51.423Z' }
      expose :scopes do |_ff|
        []
      end
      expose :strategies, using: FeatureFlag::Strategy
    end
  end
end
