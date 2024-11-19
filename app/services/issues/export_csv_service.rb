# frozen_string_literal: true

module Issues
  class ExportCsvService < ExportCsv::BaseService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    def initialize(relation, resource_parent, user = nil)
      super(relation, resource_parent)

      @labels = objects.labels_hash.transform_values { |labels| labels.sort.join(',').presence }
    end

    def email(mail_to_user)
      Notify.issues_csv_email(mail_to_user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [
        ::Gitlab::Issues::TypeAssociationGetter.call,
        :author,
        :assignees,
        :timelogs,
        :milestone,
        { project: { namespace: :route } }
      ]
    end

    def header_to_value_hash
      {
        'Title' => 'title',
        'Description' => 'description',
        'Issue ID' => 'iid',
        'URL' => ->(issue) { issue_url(issue) },
        'State' => ->(issue) { issue.closed? ? 'Closed' : 'Open' },
        'Author' => 'author_name',
        'Author Username' => ->(issue) { issue.author&.username },
        'Assignee' => ->(issue) { issue.assignees.map(&:name).join(', ') },
        'Assignee Username' => ->(issue) { issue.assignees.map(&:username).join(', ') },
        'Confidential' => ->(issue) { issue.confidential? ? 'Yes' : 'No' },
        'Locked' => ->(issue) { issue.discussion_locked? ? 'Yes' : 'No' },
        'Due Date' => ->(issue) { issue.due_date&.to_fs(:csv) },
        'Created At (UTC)' => ->(issue) { issue.created_at&.to_fs(:csv) },
        'Updated At (UTC)' => ->(issue) { issue.updated_at&.to_fs(:csv) },
        'Closed At (UTC)' => ->(issue) { issue.closed_at&.to_fs(:csv) },
        'Milestone' => ->(issue) { issue.milestone&.title },
        'Weight' => ->(issue) { issue.weight },
        'Labels' => ->(issue) { issue_labels(issue) },
        'Time Estimate' => ->(issue) { issue.time_estimate.to_fs(:csv) },
        'Time Spent' => ->(issue) { issue_time_spent(issue) }
      }
    end

    def issue_labels(issue)
      @labels[issue.id]
    end

    def issue_time_spent(issue)
      issue.timelogs.sum(&:time_spent)
    end

    def preload_associations_in_batches?
      Feature.enabled?(:export_csv_preload_in_batches, resource_parent)
    end
  end
end

Issues::ExportCsvService.prepend_mod_with('Issues::ExportCsvService')
