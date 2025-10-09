# frozen_string_literal: true

module MergeRequests
  class GeneratedRefCommit < ApplicationRecord
    include ShaAttribute
    include PartitionedTable

    self.table_name = 'p_generated_ref_commits'
    self.primary_key = :id
    PARTITION_SIZE = 2_000_000

    partitioned_by :project_id, strategy: :int_range, partition_size: PARTITION_SIZE

    sha_attribute :commit_sha

    if Gitlab.next_rails?
      belongs_to :merge_request,
        primary_key: [:iid, :target_project_id],
        foreign_key: [:merge_request_iid, :project_id],
        inverse_of: :generated_ref_commits
    else
      belongs_to :merge_request,
        primary_key: [:iid, :target_project_id],
        foreign_key: :merge_request_iid,
        inverse_of: :generated_ref_commits,
        query_constraints: [:merge_request_iid, :project_id]
    end

    belongs_to :project
    validates :commit_sha, :project, :merge_request, presence: true
  end
end
