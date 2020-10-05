# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      expose :name
      expose :description
      expose :active
      expose :version, if: :feature_flags_new_version_enabled
      expose :created_at
      expose :updated_at
      expose :scopes, using: FeatureFlag::LegacyScope
      expose :strategies, using: FeatureFlag::Strategy, if: :feature_flags_new_version_enabled
    end
  end
end
