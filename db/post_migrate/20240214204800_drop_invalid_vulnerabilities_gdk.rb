# frozen_string_literal: true

class DropInvalidVulnerabilitiesGdk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.10'

  class Vulnerability < MigrationRecord
    self.table_name = 'vulnerabilities'
  end

  def up
    Gitlab::Database::QueryAnalyzers::Base.suppress_schema_issues_for_decomposed_tables do
      Vulnerability.where(finding_id: nil).delete_all if Gitlab.dev_or_test_env?
    end
  end

  def down; end
end
