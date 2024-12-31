# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateCveInPmAdvisories < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_pm

  BATCH_SIZE = 1000

  def up
    advisory_model = define_batchable_model('pm_advisories')
    advisory_model.each_batch(of: BATCH_SIZE) do |batch|
      cve_updates = batch.filter_map do |advisory|
        cve = extract_cve_from_identifiers(advisory.identifiers)
        [advisory.id, cve] if cve
      end

      next if cve_updates.empty?

      update_sql = <<-SQL
        UPDATE pm_advisories
        SET cve = CASE id
          #{cve_updates.map { |id, cve| "WHEN #{id} THEN #{connection.quote(cve)}" }.join("\n")}
        END
        WHERE id IN (#{cve_updates.map(&:first).join(', ')})
      SQL

      execute(update_sql)
    end
  end

  def down
    advisory_model = define_batchable_model('pm_advisories')
    advisory_model.each_batch(of: BATCH_SIZE) do |batch|
      ids = batch.pluck(:id)
      execute <<-SQL
        UPDATE pm_advisories
        SET cve = NULL
        WHERE id IN (#{ids.join(', ')})
      SQL
    end
  end

  private

  def extract_cve_from_identifiers(identifiers)
    return unless identifiers.is_a?(Array)

    cve_identifier = identifiers.find { |identifier| identifier['type']&.downcase == 'cve' }
    cve_identifier['name'] if cve_identifier
  end
end
