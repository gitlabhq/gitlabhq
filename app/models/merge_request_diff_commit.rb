class MergeRequestDiffCommit < ActiveRecord::Base
  include ShaAttribute

  belongs_to :merge_request_diff

  sha_attribute :sha
  alias_attribute :id, :sha

  def self.create_bulk(merge_request_diff_id, commits)
    sha_attribute = Gitlab::Database::ShaAttribute.new

    rows = commits.map.with_index do |commit, index|
      # See #parent_ids.
      commit_hash = commit.to_hash.except(:parent_ids)
      sha = commit_hash.delete(:id)

      commit_hash.merge(
        merge_request_diff_id: merge_request_diff_id,
        relative_order: index,
        sha: sha_attribute.type_cast_for_database(sha),
        authored_date: Gitlab::Database.sanitize_timestamp(commit_hash[:authored_date]),
        committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date])
      )
    end

    Gitlab::Database.bulk_insert(self.table_name, rows)
  end

  def to_hash
    Gitlab::Git::Commit::SERIALIZE_KEYS.each_with_object({}) do |key, hash|
      hash[key] = public_send(key) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  # We don't save these, because they would need a table or a serialised
  # field. They aren't used anywhere, so just pretend the commit has no parents.
  def parent_ids
    []
  end
end
