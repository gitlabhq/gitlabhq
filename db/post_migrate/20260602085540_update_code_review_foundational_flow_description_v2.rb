# frozen_string_literal: true

class UpdateCodeReviewFoundationalFlowDescriptionV2 < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  FOUNDATIONAL_FLOW_REFERENCE = 'code_review/v1'

  OLD_DESCRIPTION = 'Streamline code reviews by analyzing code changes and relevant codebase context. ' \
    'To run this flow, assign `@GitLabDuo` as a reviewer on a merge request. ' \
    '[Learn more](https://docs.gitlab.com/user/duo_agent_platform/flows/foundational_flows/code_review/#use-the-flow).'

  NEW_DESCRIPTION = 'Streamline code reviews by analyzing code changes and relevant codebase context. ' \
    '[How can I use this flow](https://docs.gitlab.com/user/duo_agent_platform/flows/foundational_flows/code_review/#use-the-flow)?'

  def up
    connection.execute(<<~SQL)
      UPDATE ai_catalog_items
      SET description = #{connection.quote(NEW_DESCRIPTION)},
          updated_at = NOW()
      WHERE foundational_flow_reference = #{connection.quote(FOUNDATIONAL_FLOW_REFERENCE)}
        AND description = #{connection.quote(OLD_DESCRIPTION)}
    SQL
  end

  def down
    connection.execute(<<~SQL)
      UPDATE ai_catalog_items
      SET description = #{connection.quote(OLD_DESCRIPTION)},
          updated_at = NOW()
      WHERE foundational_flow_reference = #{connection.quote(FOUNDATIONAL_FLOW_REFERENCE)}
        AND description = #{connection.quote(NEW_DESCRIPTION)}
    SQL
  end
end
