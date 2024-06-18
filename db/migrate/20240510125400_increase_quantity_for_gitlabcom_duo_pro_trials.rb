# frozen_string_literal: true

class IncreaseQuantityForGitlabcomDuoProTrials < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.1'

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

    update_column_in_batches(:subscription_add_on_purchases, :quantity, 100) do |table, query|
      query.where(table[:subscription_add_on_id].eq(duo_pro_addon_id))
           .where(table[:trial].eq(true))
           .where(table[:expires_on].gteq(today))
    end
  end

  def down
    # no-op
  end
end
