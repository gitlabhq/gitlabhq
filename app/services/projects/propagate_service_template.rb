# frozen_string_literal: true

module Projects
  class PropagateServiceTemplate
    BATCH_SIZE = 100

    delegate :data_fields_present?, to: :template

    def self.propagate(template)
      new(template).propagate
    end

    def initialize(template)
      @template = template
    end

    def propagate
      return unless template.active?

      propagate_projects_with_template
    end

    private

    attr_reader :template

    def propagate_projects_with_template
      loop do
        batch = Project.uncached { project_ids_batch }

        bulk_create_from_template(batch) unless batch.empty?

        break if batch.size < BATCH_SIZE
      end
    end

    def bulk_create_from_template(batch)
      service_list = batch.map do |project_id|
        service_hash.values << project_id
      end

      Project.transaction do
        results = bulk_insert(Service, service_hash.keys << 'project_id', service_list)

        if data_fields_present?
          data_list = results.map { |row| data_hash.values << row['id'] }

          bulk_insert(template.data_fields.class, data_hash.keys << 'service_id', data_list)
        end

        run_callbacks(batch)
      end
    end

    def project_ids_batch
      Project.connection.select_values(
        <<-SQL
          SELECT id
          FROM projects
          WHERE NOT EXISTS (
            SELECT true
            FROM services
            WHERE services.project_id = projects.id
            AND services.type = #{ActiveRecord::Base.connection.quote(template.type)}
          )
          AND projects.pending_delete = false
          AND projects.archived = false
          LIMIT #{BATCH_SIZE}
        SQL
      )
    end

    def bulk_insert(klass, columns, values_array)
      items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

      klass.insert_all(items_to_insert, returning: [:id])
    end

    def service_hash
      @service_hash ||= template.as_json(methods: :type, except: %w[id template project_id])
    end

    def data_hash
      @data_hash ||= template.data_fields.as_json(only: template.data_fields.class.column_names).except('id', 'service_id')
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def run_callbacks(batch)
      if active_external_issue_tracker?
        Project.where(id: batch).update_all(has_external_issue_tracker: true)
      end

      if active_external_wiki?
        Project.where(id: batch).update_all(has_external_wiki: true)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def active_external_issue_tracker?
      template.issue_tracker? && !template.default
    end

    def active_external_wiki?
      template.type == 'ExternalWikiService'
    end
  end
end
