# frozen_string_literal: true

class MergeRequestDiffCommit < ApplicationRecord
  include ShaAttribute
  include CachedCommit

  belongs_to :merge_request_diff

  sha_attribute :sha
  alias_attribute :id, :sha

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
        committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date])
      )
    end

    Gitlab::Database.bulk_insert(self.table_name, rows)
  end
end
