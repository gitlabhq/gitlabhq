# frozen_string_literal: true

class AddGitLabManagedToDotComFoundationalExternalAgents < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  milestone '18.10'

  ITEM_IDS = [2331, 2332, 2334, 2337].freeze
  GITLAB_MAINTAINED = 100
  UNVERIFIED = 0

  def up
    return unless Gitlab.com_except_jh?

    execute(
      "UPDATE ai_catalog_items SET verification_level = #{GITLAB_MAINTAINED} WHERE id IN (#{ITEM_IDS.join(', ')})"
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    execute("UPDATE ai_catalog_items SET verification_level = #{UNVERIFIED} WHERE id IN (#{ITEM_IDS.join(', ')})")
  end
end
