# frozen_string_literal: true

module WorkItems
  class ExportCsvService < ExportCsv::BaseService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    NotAvailableError = StandardError.new('This feature is currently behind a feature flag and it is not available.')

    def email(mail_to_user)
      Notify.export_work_items_csv_email(mail_to_user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [:namespace, :project, :author, *widget_preloads]
    end

    def widget_preloads
      preloads = [:assignees, :work_item_parent, :milestone, :dates_source, :labels]
      preloads << :timelogs unless preload_associations_in_batches?
      preloads
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
        'Locked' => ->(work_item) { widget_value_for(work_item, :notes, :discussion_locked?) ? 'Yes' : 'No' },
        'Milestone' => ->(work_item) { widget_value_for(work_item, :milestone)&.title },
        'Labels' => ->(work_item) { widget_value_for(work_item, :labels)&.map(&:title)&.join(', ') }
      }
    end

    def author_and_assignees_data
      {
        'Author' => 'author_name',
        'Author Username' => ->(work_item) { work_item.author&.username },
        'Assignee' => ->(work_item) { widget_value_for(work_item, :assignees)&.map(&:name)&.join(', ') },
        'Assignee Username' => ->(work_item) do
          widget_value_for(work_item, :assignees)&.map(&:username)&.join(', ')
        end
      }
    end

    def dates_data
      {
        'Created At (UTC)' => ->(work_item) { work_item.created_at&.to_fs(:csv) },
        'Updated At (UTC)' => ->(work_item) { work_item.updated_at&.to_fs(:csv) },
        'Closed At (UTC)' => ->(work_item) { work_item.closed_at&.to_fs(:csv) },
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
        'Time Spent' => ->(work_item) { total_time_spent_for(work_item) }
      }
    end

    def total_time_spent_for(work_item)
      return unless work_item.get_widget(:time_tracking)

      ::Gitlab::TimeTrackingFormatter.output(batched_time_spent_for(work_item))
    end

    def on_batch_loaded(records)
      @time_spent_by_id = ::Timelog.total_time_spent_by_issue_id(records.map(&:id))
    end

    def batched_time_spent_for(work_item)
      return @time_spent_by_id[work_item.id].to_i if @time_spent_by_id

      work_item.timelogs.sum(&:time_spent)
    end

    def widget_value_for(work_item, widget_name, attr = nil)
      widget = work_item.get_widget(widget_name)
      return if widget.nil?

      field = attr.nil? ? widget_name : attr
      widget.try(field)
    end

    def preload_associations_in_batches?
      Feature.enabled?(:export_csv_preload_in_batches, resource_parent)
    end
  end
end

WorkItems::ExportCsvService.prepend_mod
