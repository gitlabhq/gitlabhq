# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      expose :name
      expose :description
      expose :active
      expose :version
      expose :created_at
      expose :updated_at
      expose :scopes do |_ff|
        []
      end
      expose :strategies, using: FeatureFlag::Strategy
    end
  end
end
