# frozen_string_literal: true

class AddExternalPipelineValidationToApplicationSetting < ActiveRecord::Migration[6.0]
  def up
    add_column :application_settings, :external_pipeline_validation_service_timeout, :integer
    # rubocop:disable Migration/AddLimitToTextColumns
    add_column :application_settings, :encrypted_external_pipeline_validation_service_token, :text
    add_column :application_settings, :encrypted_external_pipeline_validation_service_token_iv, :text
    add_column :application_settings, :external_pipeline_validation_service_url, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    remove_column :application_settings, :external_pipeline_validation_service_timeout
    remove_column :application_settings, :encrypted_external_pipeline_validation_service_token
    remove_column :application_settings, :encrypted_external_pipeline_validation_service_token_iv
    remove_column :application_settings, :external_pipeline_validation_service_url
  end
end
