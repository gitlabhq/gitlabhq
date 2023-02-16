# frozen_string_literal: true

module WorkItems
  class ExportCsvService < ExportCsv::BaseService
    NotAvailableError = StandardError.new('This feature is currently behind a feature flag and it is not available.')

    def csv_data
      raise NotAvailableError unless Feature.enabled?(:import_export_work_items_csv, resource_parent)

      super
    end

    def email(mail_to_user)
      # TODO - will be implemented as part of https://gitlab.com/gitlab-org/gitlab/-/issues/379082
    end

    private

    def associations_to_preload
      [:work_item_type, :author]
    end

    def header_to_value_hash
      {
        'Id' => 'iid',
        'Title' => 'title',
        'Type' => ->(work_item) { work_item.work_item_type.name },
        'Author' => 'author_name',
        'Author Username' => ->(work_item) { work_item.author.username },
        'Created At (UTC)' => ->(work_item) { work_item.created_at.to_s(:csv) }
      }
    end
  end
end
