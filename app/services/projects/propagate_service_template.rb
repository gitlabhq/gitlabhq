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
        batch = Project.uncached { project_ids_without_integration }

        bulk_create_from_template(batch) unless batch.empty?

        break if batch.size < BATCH_SIZE
      end
    end

    def bulk_create_from_template(batch)
      service_list = ServiceList.new(batch, service_hash).to_array

      Project.transaction do
        results = bulk_insert(*service_list)

        if data_fields_present?
          data_list = DataList.new(results, data_fields_hash, template.data_fields.class).to_array

          bulk_insert(*data_list)
        end

        run_callbacks(batch)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_ids_without_integration
      services = Service
        .select('1')
        .where('services.project_id = projects.id')
        .where(type: template.type)

      Project
        .where('NOT EXISTS (?)', services)
        .where(pending_delete: false)
        .where(archived: false)
        .limit(BATCH_SIZE)
        .pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def bulk_insert(klass, columns, values_array)
      items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

      klass.insert_all(items_to_insert, returning: [:id])
    end

    def service_hash
      @service_hash ||= template.to_service_hash
    end

    def data_fields_hash
      @data_fields_hash ||= template.to_data_fields_hash
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
