class IssueAssignee < ActiveRecord::Base
  extend Gitlab::CurrentSettings

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id
<<<<<<< HEAD

  # EE-specific
  after_create :update_elasticsearch_index
  after_destroy :update_elasticsearch_index
  # EE-specific

  def update_elasticsearch_index
    if current_application_settings.elasticsearch_indexing?
      ElasticIndexerWorker.perform_async(
        :update,
        'Issue',
        issue.id,
        changed_fields: ['assignee_ids']
      )
    end
  end
=======
>>>>>>> upstream/master
end
