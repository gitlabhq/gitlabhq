# frozen_string_literal: true

class BackfillOrganizationIdOnLegacyAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  DEFAULT_ORG_ID = 1

  def up
    ai_settings = define_batchable_model('ai_settings')
    legacy_setting = ai_settings.find_by(organization_id: nil)

    return unless legacy_setting

    if ai_settings.exists?(organization_id: DEFAULT_ORG_ID)
      legacy_setting.delete
    else
      legacy_setting.update_column(:organization_id, DEFAULT_ORG_ID)
    end
  end

  def down
    # no-op
  end
end
