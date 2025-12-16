# frozen_string_literal: true

class AddDuoSastFpDetectionEnabledCascadingSetting < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

  def up
    add_cascading_namespace_setting :duo_sast_fp_detection_enabled, :boolean, default: true, null: false
  end

  def down
    remove_cascading_namespace_setting :duo_sast_fp_detection_enabled
  end
end
