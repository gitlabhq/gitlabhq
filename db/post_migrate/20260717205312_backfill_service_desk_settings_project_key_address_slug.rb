# frozen_string_literal: true

class BackfillServiceDeskSettingsProjectKeyAddressSlug < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!
  milestone '19.3'

  BATCH_SIZE = 100

  def up
    scope = ->(model) { model.where.not(project_key: nil) }

    each_batch(:service_desk_settings, scope: scope, of: BATCH_SIZE) do |batch, _model|
      rows = connection.select_rows(<<~SQL)
        SELECT service_desk_settings.project_id, routes.path, service_desk_settings.project_key
        FROM service_desk_settings
        INNER JOIN routes
          ON routes.source_type = 'Project' AND routes.source_id = service_desk_settings.project_id
        WHERE service_desk_settings.project_id IN (#{batch.select(:project_id).to_sql})
      SQL

      values = rows.map do |project_id, path, project_key|
        "(#{project_id}, #{connection.quote("#{slugify(path)}-#{project_key}")})"
      end

      next if values.empty?

      execute(<<~SQL)
        UPDATE service_desk_settings
        SET project_key_address_slug = new_values.slug
        FROM (VALUES #{values.join(', ')}) AS new_values (project_id, slug)
        WHERE service_desk_settings.project_id = new_values.project_id
      SQL
    end
  end

  def down
    # no-op; the column is maintained by the application and a re-run of the
    # backfill converges to the same values.
  end

  private

  # Copy of Gitlab::Utils.slugify; migrations must not depend on app code.
  def slugify(str)
    str.to_s.downcase
      .gsub(/[^a-z0-9]/, '-')[0..62]
      .gsub(/(\A[-.]+|[-.]+\z)/, '')
  end
end
