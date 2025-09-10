# frozen_string_literal: true

module MergeRequests
  class MergeData < ApplicationRecord
    include PartitionedTable
    include ShaAttribute

    self.table_name = 'merge_requests_merge_data'
    self.primary_key = 'merge_request_id'

    partitioned_by :merge_request_id, strategy: :int_range, partition_size: 10_000_000

    belongs_to :merge_request, inverse_of: :merge_data
    belongs_to :project
    belongs_to :merge_user, class_name: 'User'

    validates :project, presence: true
    validates :merge_request, presence: true
    validates :merge_status, presence: true

    sha_attribute :merge_commit_sha
    sha_attribute :merged_commit_sha
    sha_attribute :merge_ref_sha
    sha_attribute :squash_commit_sha
    sha_attribute :in_progress_merge_commit_sha

    serialize :merge_params, type: Hash # rubocop:disable Cop/ActiveRecordSerialize -- Extraction to a new table
  end
end
