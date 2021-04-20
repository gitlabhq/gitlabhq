# frozen_string_literal: true

class AddUrlLimitToPipelineValidation < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'app_settings_ext_pipeline_validation_service_url_text_limit'

  def up
    add_text_limit :application_settings, :external_pipeline_validation_service_url, 255, constraint_name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:application_settings, CONSTRAINT_NAME)
  end
end
