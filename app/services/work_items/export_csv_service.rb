# frozen_string_literal: true

module WorkItems
  class ExportCsvService < ExportCsv::BaseService
    NotAvailableError = StandardError.new('This feature is currently behind a feature flag and it is not available.')

    def csv_data
      raise NotAvailableError unless Feature.enabled?(:import_export_work_items_csv, resource_parent)

      super
    end

    def email(mail_to_user)
      Notify.export_work_items_csv_email(mail_to_user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [:project, [::Gitlab::Issues::TypeAssociationGetter.call => :enabled_widget_definitions], :author]
    end

    def header_to_value_hash
      {
        'Id' => 'iid',
        'Title' => 'title',
        'Description' => ->(work_item) { get_widget_value_for(work_item, :description) },
        'Type' => ->(work_item) { work_item.work_item_type.name },
        'Author' => 'author_name',
        'Author Username' => ->(work_item) { work_item.author.username },
        'Created At (UTC)' => ->(work_item) { work_item.created_at.to_fs(:csv) }
      }
    end

    def get_widget_value_for(work_item, field)
      widget_name = field_to_widget_map[field]
      widget = work_item.get_widget(widget_name)

      widget.try(field)
    end

    def field_to_widget_map
      {
        description: :description
      }
    end
  end
end
