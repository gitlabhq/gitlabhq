# frozen_string_literal: true

module Admin
  module PropagateService
    extend ActiveSupport::Concern

    BATCH_SIZE = 100

    delegate :data_fields_present?, to: :integration

    class_methods do
      def propagate(integration)
        new(integration).propagate
      end
    end

    def initialize(integration)
      @integration = integration
    end

    private

    attr_reader :integration

    def create_integration_for_projects_without_integration
      loop do
        batch_ids = Project.uncached { Project.ids_without_integration(integration, BATCH_SIZE) }

        bulk_create_from_integration(batch_ids) unless batch_ids.empty?

        break if batch_ids.size < BATCH_SIZE
      end
    end

    def bulk_create_from_integration(batch_ids)
      service_list = ServiceList.new(batch_ids, service_hash).to_array

      Service.transaction do
        results = bulk_insert(*service_list)

        if data_fields_present?
          data_list = DataList.new(results, data_fields_hash, integration.data_fields.class).to_array

          bulk_insert(*data_list)
        end

        run_callbacks(batch_ids)
      end
    end

    def bulk_insert(klass, columns, values_array)
      items_to_insert = values_array.map { |array| Hash[columns.zip(array)] }

      klass.insert_all(items_to_insert, returning: [:id])
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def run_callbacks(batch_ids)
      if integration.issue_tracker?
        Project.where(id: batch_ids).update_all(has_external_issue_tracker: true)
      end

      if integration.type == 'ExternalWikiService'
        Project.where(id: batch_ids).update_all(has_external_wiki: true)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def data_fields_hash
      @data_fields_hash ||= integration.to_data_fields_hash
    end
  end
end
