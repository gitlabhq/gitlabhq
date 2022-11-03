# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      expose :name, documentation: { type: 'string', example: 'merge_train' }
      expose :description, documentation: { type: 'string', example: 'merge train feature flag' }
      expose :active, documentation: { type: 'boolean' }
      expose :version, documentation: { type: 'string', example: 'new_version_flag' }
      expose :created_at, documentation: { type: 'dateTime', example: '2019-11-04T08:13:51.423Z' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2019-11-04T08:13:51.423Z' }
      expose :scopes do |_ff|
        []
      end
      expose :strategies, using: FeatureFlag::Strategy
    end
  end
end
