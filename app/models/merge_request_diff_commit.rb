# frozen_string_literal: true

class MergeRequestDiffCommit < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include BulkInsertSafe
  include ShaAttribute
  include CachedCommit
  include FromUnion

  belongs_to :merge_request_diff

  # This relation is called `commit_author` and not `author`, as the project
  # import/export logic treats relations named `author` as instances of the
  # `User` class.
  #
  # NOTE: these columns are _not_ indexed, nor do they use foreign keys.
  #
  # This is deliberate, as creating these indexes on GitLab.com takes a _very_
  # long time. In addition, there's no real need for them either based on how
  # this data is used.
  #
  # For more information, refer to the following:
  #
  # - https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5038#note_614592881
  # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63669
  belongs_to :commit_author, class_name: 'MergeRequest::DiffCommitUser'
  belongs_to :committer, class_name: 'MergeRequest::DiffCommitUser'

  sha_attribute :sha

  attribute :trailers, ::Gitlab::Database::Type::IndifferentJsonb.new
  validates :trailers, json_schema: { filename: 'git_trailers' }

  # A list of keys of which their values need to be trimmed before they can be
  # inserted into the merge_request_diff_commit_users table.
  TRIM_USER_KEYS =
    %i[author_name author_email committer_name committer_email].freeze

  # Deprecated; use `bulk_insert!` from `BulkInsertSafe` mixin instead.
  # cf. https://gitlab.com/gitlab-org/gitlab/issues/207989 for progress
  def self.create_bulk(merge_request_diff_id, commits)
    commit_hashes, user_tuples = prepare_commits_for_bulk_insert(commits)
    users = MergeRequest::DiffCommitUser.bulk_find_or_create(user_tuples)

    rows = commit_hashes.map.with_index do |commit_hash, index|
      sha = commit_hash.delete(:id)
      author = users[[commit_hash[:author_name], commit_hash[:author_email]]]
      committer =
        users[[commit_hash[:committer_name], commit_hash[:committer_email]]]

      # These fields are only used to determine the author/committer IDs, we
      # don't store them in the DB.
      #
      # Trailers are stored in the DB here in order to allow changelog parsing.
      # Rather than add an additional column for :extended_trailers, we're instead
      # ignoring it for now until we deprecate the :trailers field and replace it with
      # the new functionality.
      commit_hash = commit_hash
        .except(:author_name, :author_email, :committer_name, :committer_email, :extended_trailers)

      commit_hash.merge(
        commit_author_id: author.id,
        committer_id: committer.id,
        merge_request_diff_id: merge_request_diff_id,
        relative_order: index,
        sha: Gitlab::Database::ShaAttribute.serialize(sha),
        authored_date: Gitlab::Database.sanitize_timestamp(commit_hash[:authored_date]),
        committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date]),
        trailers: Gitlab::Json.dump(commit_hash.fetch(:trailers, {}))
      )
    end

    ApplicationRecord.legacy_bulk_insert(self.table_name, rows) # rubocop:disable Gitlab/BulkInsert
  end

  def self.prepare_commits_for_bulk_insert(commits)
    user_tuples = Set.new
    hashes = commits.map do |commit|
      hash = commit.to_hash.except(:parent_ids, :referenced_by)

      TRIM_USER_KEYS.each do |key|
        hash[key] = MergeRequest::DiffCommitUser.prepare(hash[key])
      end

      user_tuples << [hash[:author_name], hash[:author_email]]
      user_tuples << [hash[:committer_name], hash[:committer_email]]

      hash
    end

    [hashes, user_tuples]
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

  def author_name
    commit_author&.name
  end

  def author_email
    commit_author&.email
  end

  def committer_name
    committer&.name
  end

  def committer_email
    committer&.email
  end

  def to_hash
    super.merge({ 'id' => sha })
  end
end
