# frozen_string_literal: true

module WorkItems
  class ExportCsvService < ExportCsv::BaseService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

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
      [:project, { work_item_type: :enabled_widget_definitions }, :author, *widget_preloads]
    end

    def widget_preloads
      [:assignees, :work_item_parent, :milestone, :dates_source, :labels, :timelogs]
    end

    def header_to_value_hash
      {
        'ID' => 'id',
        'IID' => 'iid',
        'Title' => 'title',
        'Description' => ->(work_item) { widget_value_for(work_item, :description) },
        'Type' => ->(work_item) { work_item.work_item_type.name },
        'URL' => ->(work_item) { work_item_url(work_item) }
      }.merge(
        base_metadata
      ).merge(
        author_and_assignees_data
      ).merge(
        dates_data
      ).merge(
        parent_item_data
      ).merge(
        time_tracking_data
      )
    end

    def base_metadata
      {
        'State' => ->(work_item) { work_item.closed? ? 'Closed' : 'Open' },
        'Confidential' => ->(work_item) { work_item.confidential? ? 'Yes' : 'No' },
        'Locked' => ->(work_item) { widget_value_for(work_item, :notes, :discussion_locked?) },
        'Milestone' => ->(work_item) { widget_value_for(work_item, :milestone)&.title },
        'Labels' => ->(work_item) { widget_value_for(work_item, :labels)&.map(&:title)&.join(', ') }
      }
    end

    def author_and_assignees_data
      {
        'Author' => 'author_name',
        'Author Username' => ->(work_item) { work_item.author&.username },
        'Assignee(s)' => ->(work_item) { widget_value_for(work_item, :assignees)&.map(&:name)&.join(', ') },
        'Assignee(s) Username(s)' => ->(work_item) do
          widget_value_for(work_item, :assignees)&.map(&:username)&.join(', ')
        end
      }
    end

    def dates_data
      {
        'Created At' => ->(work_item) { work_item.created_at&.to_fs(:csv) },
        'Updated At' => ->(work_item) { work_item.updated_at&.to_fs(:csv) },
        'Closed At' => ->(work_item) { work_item.closed_at&.to_fs(:csv) },
        'Due Date' => ->(work_item) { widget_value_for(work_item, :start_and_due_date, :due_date)&.to_fs(:csv) },
        'Start Date' => ->(work_item) { widget_value_for(work_item, :start_and_due_date, :start_date)&.to_fs(:csv) }
      }
    end

    def parent_item_data
      {
        'Parent ID' => ->(work_item) { widget_value_for(work_item, :hierarchy, :parent)&.id },
        'Parent IID' => ->(work_item) { widget_value_for(work_item, :hierarchy, :parent)&.iid },
        'Parent Title' => ->(work_item) { widget_value_for(work_item, :hierarchy, :parent)&.title }
      }
    end

    def time_tracking_data
      {
        'Time Estimate' => ->(work_item) { widget_value_for(work_item, :time_tracking, :human_time_estimate) },
        'Time Spent' => ->(work_item) { widget_value_for(work_item, :time_tracking, :human_total_time_spent) }
      }
    end

    def widget_value_for(work_item, widget_name, attr = nil)
      widget = work_item.get_widget(widget_name)
      return if widget.nil?

      field = attr.nil? ? widget_name : attr
      widget.try(field)
    end
  end
end

WorkItems::ExportCsvService.prepend_mod
