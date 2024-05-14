# frozen_string_literal: true

class ExtendGitlabcomDuoProTrials < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.0'

  class AddOn < MigrationRecord
    self.table_name = :subscription_add_ons

    enum name: {
      code_suggestions: 1
    }
  end

  def up
    return unless Gitlab.com?

    AddOn.reset_column_information

    duo_pro_addon_id = AddOn.find_by(name: "code_suggestions")&.id
    return unless duo_pro_addon_id

    today = Date.current

    # As of the time we create this migration script, `subscription_add_on_purchases` table only has `expires_on`.
    # It does not have a field to tell when the trial DuoPro started.
    #
    # We use the `created_at.to_date` to determine when the trial DuoPro started, this works at
    # this stage because:
    #   - we know the DuoPro trial will NEVER be updated after creation
    #   - DuoPro trial won't be provisioned if the namespace has active paid DuoPro pack purchased
    #   - it is very unlikely for a namespace cancelled paid DuoPro and then applied for DuoPro trial
    # For long term, we may add a new filed `trial_started_on` so that in the future we do not have
    # this trouble, which is discussed at https://gitlab.com/gitlab-org/gitlab/-/issues/455880#note_1888698445
    #
    # But this migration is for a time critical request
    # https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/9483, so we choose to directly
    # use `created_at.to_date` now
    new_expires_on = Arel.sql("(created_at + INTERVAL '60 days')::date")

    update_column_in_batches(:subscription_add_on_purchases, :expires_on, new_expires_on) do |table, query|
      query.where(table[:subscription_add_on_id].eq(duo_pro_addon_id))
           .where(table[:trial].eq(true))
           .where(table[:expires_on].gteq(today))
    end
  end

  def down
    # no-op
  end
end
