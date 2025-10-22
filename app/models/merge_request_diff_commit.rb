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

  belongs_to :merge_request_commits_metadata,
    ->(diff_commit) { where(project_id: diff_commit.project_id) },
    class_name: 'MergeRequest::CommitsMetadata',
    inverse_of: :merge_request_diff_commits

  sha_attribute :sha

  attribute :trailers, ::Gitlab::Database::Type::IndifferentJsonb.new
  validates :trailers, json_schema: { filename: 'git_trailers' }

  # A list of keys of which their values need to be trimmed before they can be
  # inserted into the merge_request_diff_commit_users table.
  TRIM_USER_KEYS =
    %i[author_name author_email committer_name committer_email].freeze

  # Deprecated; use `bulk_insert!` from `BulkInsertSafe` mixin instead.
  # cf. https://gitlab.com/gitlab-org/gitlab/issues/207989 for progress
  def self.create_bulk(merge_request_diff_id, commits, project, skip_commit_data: false)
    organization_id = project.organization_id
    dedup_enabled = Feature.enabled?(:merge_request_diff_commits_dedup, project)
    partition_enabled = Feature.enabled?(:merge_request_diff_commits_partition, project)
    commit_hashes, user_triples = prepare_commits_for_bulk_insert(commits, organization_id)
    users = MergeRequest::DiffCommitUser.bulk_find_or_create(user_triples)

    rows = commit_hashes.map.with_index do |commit_hash, index|
      raw_sha = commit_hash.delete(:id)
      trailers = commit_hash.fetch(:trailers, {})

      author = users[[commit_hash[:author_name], commit_hash[:author_email], organization_id]]
      committer = users[[commit_hash[:committer_name], commit_hash[:committer_email], organization_id]]

      # These fields are only used to determine the author/committer IDs, we
      # don't store them in the DB.
      #
      # Trailers are stored in the DB here in order to allow changelog parsing.
      # Rather than add an additional column for :extended_trailers, we're instead
      # ignoring it for now until we deprecate the :trailers field and replace it with
      # the new functionality.
      commit_hash = commit_hash
        .except(:author_name, :author_email, :committer_name, :committer_email, :extended_trailers)

      commit_hash = commit_hash.merge(
        commit_author_id: author.id,
        committer_id: committer.id,
        merge_request_diff_id: merge_request_diff_id,
        relative_order: index,
        sha: Gitlab::Database::ShaAttribute.serialize(raw_sha),
        authored_date: Gitlab::Database.sanitize_timestamp(commit_hash[:authored_date]),
        committed_date: Gitlab::Database.sanitize_timestamp(commit_hash[:committed_date]),
        trailers: Gitlab::Json.dump(trailers)
      )

      # Need to add `raw_sha` to commit_hash as we will use that when
      # inserting the `sha` in `merge_request_commits_metadata` table. We
      # only need to do this when dedup is enabled.
      commit_hash[:raw_sha] = raw_sha if dedup_enabled

      commit_hash[:project_id] = project.id if partition_enabled
      commit_hash = commit_hash.merge(message: '') if skip_commit_data

      commit_hash
    end

    if dedup_enabled
      commits_metadata_mapping = MergeRequest::CommitsMetadata.bulk_find_or_create(
        project.id,
        rows
      )

      rows.each do |row|
        row[:merge_request_commits_metadata_id] = commits_metadata_mapping[row[:raw_sha]]

        # At this point, we no longer need the `raw_sha` so we delete it from
        # the row that will be inserted into `merge_request_diff_commits` table.
        row.delete(:raw_sha)
      end
    end

    ApplicationRecord.legacy_bulk_insert(self.table_name, rows) # rubocop:disable Gitlab/BulkInsert
  end

  def self.prepare_commits_for_bulk_insert(commits, organization_id)
    user_triples = Set.new
    hashes = commits.map do |commit|
      hash = commit.to_hash.except(:parent_ids, :referenced_by)

      TRIM_USER_KEYS.each do |key|
        hash[key] = MergeRequest::DiffCommitUser.prepare(hash[key])
      end

      user_triples << [hash[:author_name], hash[:author_email], organization_id]
      user_triples << [hash[:committer_name], hash[:committer_email], organization_id]

      hash
    end

    [hashes, user_triples]
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

  def message
    fetch_message
  end

  def to_hash
    super(exclude_keys: [:message]).merge({
      'id' => sha,
      message: fetch_message
    })
  end

  def project_id
    project.id
  end

  def authored_date
    has_commit_metadata? ? merge_request_commits_metadata.authored_date : super
  end

  def committed_date
    has_commit_metadata? ? merge_request_commits_metadata.committed_date : super
  end

  def sha
    has_commit_metadata? ? merge_request_commits_metadata.sha : super
  end

  def commit_author
    has_commit_metadata? ? merge_request_commits_metadata.commit_author : super
  end

  def committer
    has_commit_metadata? ? merge_request_commits_metadata.committer : super
  end

  private

  def fetch_message
    if ::Feature.enabled?(:disable_message_attribute_on_mr_diff_commits, project)
      ""
    else
      has_commit_metadata? ? merge_request_commits_metadata.message : read_attribute("message")
    end
  end

  # As of %17.10, we still don't have `project_id` on merge_request_diff_commit
  #   records. Until we do, we have to fetch it from merge_request_diff.
  # Also, it's possible that `merge_request_diff` is `nil` when accessing this method from an object
  # that has not been persisted.
  def project
    @_project ||= merge_request_diff&.project
  end

  def has_commit_metadata?
    merge_request_commits_metadata_id.present? && Feature.enabled?(:merge_request_diff_commits_dedup, project)
  rescue ActiveModel::MissingAttributeError => e
    Gitlab::ErrorTracking.track_exception(e, self.attributes)

    false
  end
end
