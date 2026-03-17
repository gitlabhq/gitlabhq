# frozen_string_literal: true

class RemoveDuoSastFpDetectionCascadingColumns < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    remove_cascading_namespace_setting :duo_sast_fp_detection_enabled
  end

  def down
    add_cascading_namespace_setting :duo_sast_fp_detection_enabled, :boolean, default: true, null: false
  end
end
