# frozen_string_literal: true

module Admin
  class PropagateIntegrationService
    BATCH_SIZE = 100

    delegate :data_fields_present?, to: :integration

    def self.propagate(integration:, overwrite:)
      new(integration, overwrite).propagate
    end

    def initialize(integration, overwrite)
      @integration = integration
      @overwrite = overwrite
    end

    def propagate
      if overwrite
        update_integration_for_all_projects
      else
        update_integration_for_inherited_projects
      end

      create_integration_for_projects_without_integration
    end

    private

    attr_reader :integration, :overwrite

    # rubocop: disable Cop/InBatches
    # rubocop: disable CodeReuse/ActiveRecord
    def update_integration_for_inherited_projects
      Service.where(type: integration.type, inherit_from_id: integration.id).in_batches(of: BATCH_SIZE) do |batch|
        bulk_update_from_integration(batch)
      end
    end

    def update_integration_for_all_projects
      Service.where(type: integration.type).in_batches(of: BATCH_SIZE) do |batch|
        bulk_update_from_integration(batch)
      end
    end
    # rubocop: enable Cop/InBatches
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def bulk_update_from_integration(batch)
      # Retrieving the IDs instantiates the ActiveRecord relation (batch)
      # into concrete models, otherwise update_all will clear the relation.
      # https://stackoverflow.com/q/34811646/462015
      batch_ids = batch.pluck(:id)

      Service.transaction do
        batch.update_all(service_hash)

        if data_fields_present?
          integration.data_fields.class.where(service_id: batch_ids).update_all(data_fields_hash)
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_integration_for_projects_without_integration
      loop do
        batch = Project.uncached { project_ids_without_integration }

        bulk_create_from_integration(batch) unless batch.empty?

        break if batch.size < BATCH_SIZE
      end
    end

    def bulk_create_from_integration(batch)
      service_list = ServiceList.new(batch, service_hash, { 'inherit_from_id' => integration.id }).to_array

      Project.transaction do
        results = bulk_insert(*service_list)

        if data_fields_present?
          data_list = DataList.new(results, data_fields_hash, integration.data_fields.class).to_array

          bulk_insert(*data_list)
        end

        run_callbacks(batch)
      end
    end

    def bulk_insert(klass, columns, values_array)
      items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

      klass.insert_all(items_to_insert, returning: [:id])
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
      integration.issue_tracker? && !integration.default
    end

    def active_external_wiki?
      integration.type == 'ExternalWikiService'
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_ids_without_integration
      services = Service
        .select('1')
        .where('services.project_id = projects.id')
        .where(type: integration.type)

      Project
        .where('NOT EXISTS (?)', services)
        .where(pending_delete: false)
        .where(archived: false)
        .limit(BATCH_SIZE)
        .pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def service_hash
      @service_hash ||= integration.to_service_hash
        .tap { |json| json['inherit_from_id'] = integration.id }
    end

    def data_fields_hash
      @data_fields_hash ||= integration.to_data_fields_hash
    end
  end
end
