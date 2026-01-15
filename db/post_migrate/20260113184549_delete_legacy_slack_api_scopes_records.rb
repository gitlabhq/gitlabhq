# frozen_string_literal: true

class DeleteLegacySlackApiScopesRecords < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.9'

  ERROR_MESSAGE = <<~MESSAGE
    The `slack_integrations_scopes` table contains records still associates to records in the
    `slack_api_scopes` table that do not have an `organization_id` set.

    Make sure the `BackfillSlackIntegrationsScopesShardingKey` batched background migration
    was finalized correctly in migration 20260113184548.

    If you run into this error please reach out for support at
    https://gitlab.com/gitlab-org/gitlab/-/issues/560356
  MESSAGE

  def up
    slack_api_scopes = define_batchable_model(:slack_api_scopes)
    validate_no_valid_records_exist!(slack_api_scopes)

    slack_api_scopes.where(organization_id: nil).delete_all
  end

  def down
    # no-op
  end

  private

  def validate_no_valid_records_exist!(slack_api_scopes)
    slack_integrations_scopes = define_batchable_model(:slack_integrations_scopes)

    legacy_api_scope_ids = slack_api_scopes.where(organization_id: nil).select(:id)

    return unless slack_integrations_scopes.where(slack_api_scope_id: legacy_api_scope_ids).count > 0

    raise ERROR_MESSAGE
  end
end
