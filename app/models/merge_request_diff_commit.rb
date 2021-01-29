# frozen_string_literal: true

class MergeRequestDiffCommit < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include BulkInsertSafe
  include ShaAttribute
  include CachedCommit

  belongs_to :merge_request_diff

  sha_attribute :sha
  alias_attribute :id, :sha

  serialize :trailers, Serializers::JSON # rubocop:disable Cop/ActiveRecordSerialize
  validates :trailers, json_schema: { filename: 'git_trailers' }

  # Deprecated; use `bulk_insert!` from `BulkInsertSafe` mixin instead.
  # cf. https://gitlab.com/gitlab-org/gitlab/issues/207989 for progress
  def self.create_bulk(merge_request_diff_id, commits)
    rows = commits.map.with_index do |commit, index|
      # See #parent_ids.
      commit_hash = commit.to_hash.except(:parent_ids)
      sha = commit_hash.delete(:id)

      commit_hash.merge(
        merge_request_diff_id: merge_request_diff_id,
        relative_order: index,
        sha: Gitlab::Database::ShaAttribute.serialize(sha), # rubocop:disable Cop/ActiveRecordSerialize
        authored_date: Gitlab::Database.sanitize_timestamp(commit_hash[:authored_date]),
        committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date]),
        trailers: commit_hash.fetch(:trailers, {}).to_json
      )
    end

    Gitlab::Database.bulk_insert(self.table_name, rows) # rubocop:disable Gitlab/BulkInsert
  end

  def self.oldest_merge_request_id_per_commit(project_id, shas)
    # This method is defined here and not on MergeRequest, otherwise the SHA
    # values used in the WHERE below won't be encoded correctly.
    select(['merge_request_diff_commits.sha AS sha', 'min(merge_requests.id) AS merge_request_id'])
      .joins(:merge_request_diff)
      .joins(
        'INNER JOIN merge_requests ' \
          'ON merge_requests.latest_merge_request_diff_id = merge_request_diffs.id'
      )
      .where(sha: shas)
      .where(
        merge_requests: {
          target_project_id: project_id,
          state_id: MergeRequest.available_states[:merged]
        }
      )
      .group(:sha)
  end
end
