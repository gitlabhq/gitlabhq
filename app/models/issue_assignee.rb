class IssueAssignee < ActiveRecord::Base
  extend Gitlab::CurrentSettings

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id

  after_create :update_assignee_cache_counts
  after_destroy :update_assignee_cache_counts

<<<<<<< HEAD
  # EE-specific
  after_create :update_elasticsearch_index
  after_destroy :update_elasticsearch_index
  # EE-specific

  def update_assignee_cache_counts
    assignee&.update_cache_counts
  end

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
  def update_assignee_cache_counts
    assignee&.update_cache_counts
  end
>>>>>>> 6ce1df41e175c7d62ca760b1e66cf1bf86150284
end
