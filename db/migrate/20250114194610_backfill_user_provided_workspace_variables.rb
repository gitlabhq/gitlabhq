# frozen_string_literal: true

class BackfillUserProvidedWorkspaceVariables < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class WorkspaceVariable < MigrationRecord
    self.table_name = :workspace_variables

    include EachBatch
  end

  BATCH_SIZE = 100

  # Since file type is not supported for user variables
  VARIABLE_ENV_TYPE = 0

  # Internal workspace variables that get created on workspace creation
  # Reference: /ee/lib/remote_development/workspace_operations/create/workspace_variables.rb
  WORKSPACE_INTERNAL_VARIABLES = %w[
    GIT_CONFIG_COUNT
    GIT_CONFIG_KEY_0
    GIT_CONFIG_VALUE_0
    GIT_CONFIG_KEY_1
    GIT_CONFIG_VALUE_1
    GIT_CONFIG_KEY_2
    GIT_CONFIG_VALUE_2
    GL_GIT_CREDENTIAL_STORE_FILE_PATH
    GL_TOKEN_FILE_PATH
    GL_WORKSPACE_DOMAIN_TEMPLATE
    GL_EDITOR_EXTENSIONS_GALLERY_SERVICE_URL
    GL_EDITOR_EXTENSIONS_GALLERY_ITEM_URL
    GL_EDITOR_EXTENSIONS_GALLERY_RESOURCE_URL_TEMPLATE
    GITLAB_WORKFLOW_INSTANCE_URL
    GITLAB_WORKFLOW_TOKEN_FILE
  ].freeze

  def up
    WorkspaceVariable.reset_column_information

    WorkspaceVariable.each_batch(of: BATCH_SIZE) do |batch|
      batch.where(variable_type: VARIABLE_ENV_TYPE).where.not(key: WORKSPACE_INTERNAL_VARIABLES)
      .update_all(user_provided: true)
    end
  end

  def down
    WorkspaceVariable.reset_column_information

    # Column is NOT NULL DEFAULT 0, so setting back to default
    WorkspaceVariable.update_all(user_provided: false)
  end
end
