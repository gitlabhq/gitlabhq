# frozen_string_literal: true

class CreateDastScannerProfilesBuilds < ActiveRecord::Migration[6.1]
  def up
    table_comment = { owner: 'group::dynamic analysis', description: 'Join table between DAST Scanner Profiles and CI Builds' }

    create_table :dast_scanner_profiles_builds, primary_key: [:dast_scanner_profile_id, :ci_build_id], comment: table_comment.to_json do |t|
      t.bigint :dast_scanner_profile_id, null: false
      t.bigint :ci_build_id, null: false

      t.index :ci_build_id, unique: true, name: :dast_scanner_profiles_builds_on_ci_build_id
    end
  end

  def down
    drop_table :dast_scanner_profiles_builds
  end
end
