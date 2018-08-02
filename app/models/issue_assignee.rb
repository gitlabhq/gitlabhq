# frozen_string_literal: true

class IssueAssignee < ActiveRecord::Base
  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id

  # EE-specific
  after_commit :update_elasticsearch_index, on: [:create, :destroy]
  # EE-specific

  def update_elasticsearch_index
    if Gitlab::CurrentSettings.current_application_settings.elasticsearch_indexing?
      ElasticIndexerWorker.perform_async(
        :update,
        'Issue',
        issue.id,
        changed_fields: ['assignee_ids']
      )
    end
  end
end
