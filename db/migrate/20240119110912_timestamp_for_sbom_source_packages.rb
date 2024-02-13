# frozen_string_literal: true

class TimestampForSbomSourcePackages < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def up
    add_timestamps_with_timezone(:sbom_source_packages, null: false, default: -> { 'NOW()' })
  end

  def down
    remove_timestamps(:sbom_source_packages)
  end
end
