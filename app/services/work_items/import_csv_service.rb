# frozen_string_literal: true

module WorkItems
  class ImportCsvService < ImportCsv::BaseService
    extend ::Gitlab::Utils::Override

    NotAvailableError = StandardError.new('This feature is currently behind a feature flag and it is not available.')

    def self.required_headers
      %w[title].freeze
    end

    def execute
      raise NotAvailableError if ::Feature.disabled?(:import_export_work_items_csv, project)

      super
    end

    def email_results_to_user
      Notify.import_work_items_csv_email(user.id, project.id, results).deliver_later
    end

    private

    def create_object(attributes)
      super[:work_item]
    end

    def create_object_class
      ::WorkItems::CreateService
    end

    override :attributes_for
    def attributes_for(row)
      {
        title: row[:title],
        work_item_type: WorkItems::Type.default_issue_type
      }
    end

    override :validate_headers_presence!
    def validate_headers_presence!(headers)
      required_headers = self.class.required_headers

      headers.downcase!
      return if headers && required_headers.all? { |rh| headers.include?(rh) }

      required_headers_message = "Required headers are missing. Required headers are #{required_headers.join(', ')}"
      raise CSV::MalformedCSVError.new(required_headers_message, 1)
    end
  end
end
