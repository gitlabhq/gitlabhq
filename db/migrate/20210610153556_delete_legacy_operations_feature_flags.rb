# frozen_string_literal: true

class DeleteLegacyOperationsFeatureFlags < ActiveRecord::Migration[6.1]
  LEGACY_FEATURE_FLAG_VERSION = 1

  def up
    execute("DELETE FROM operations_feature_flags WHERE version = #{LEGACY_FEATURE_FLAG_VERSION}")
  end

  def down
    # no-op
  end
end
