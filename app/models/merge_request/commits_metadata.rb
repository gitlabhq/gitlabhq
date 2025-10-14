# frozen_string_literal: true

class MergeRequest::CommitsMetadata < ApplicationRecord # rubocop:disable Style/ClassAndModuleChildren, Gitlab/BoundedContexts -- Same as the rest of the models under `MergeRequest` namespace
  include PartitionedTable
  include ShaAttribute

  ignore_column :trailers, remove_with: '18.7', remove_after: '2025-11-20'

  # Need this to be set as calling `id` will return [id, project_id] since
  # this table is partitioned by `project_id`.
  self.primary_key = :id

  partitioned_by :project_id, strategy: :int_range, partition_size: 2_000_000

  belongs_to :project

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

  has_many :merge_request_diff_commits, inverse_of: :merge_request_commits_metadata

  sha_attribute :sha

  # Creates a new row, or returns an existing one if a row already exists.
  def self.find_or_create(metadata = {})
    find_or_create_by!(project_id: metadata['project_id'], sha: metadata['sha']) do |record|
      record.committer = metadata['committer']
      record.commit_author = metadata['commit_author']
      record.message = metadata['message']
      record.authored_date = metadata['authored_date']
      record.committed_date = metadata['committed_date']
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  # Finds many commits by project_id and array of SHAs in bulk.
  # The return value is an array of ID and SHA pairs.
  def self.bulk_find(project_id, shas)
    rows = []

    shas.each_slice(1_000) do |slice|
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Already limited to 1K SHAs
      rows.concat(where(project_id: project_id, sha: slice).pluck(:id, :sha))
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end

    rows
  end

  # Finds or creates rows for the given project ID and commit rows.
  #
  # The `commit_rows` argument must be an array of hashes. Each hash should have the following keys:
  #
  # - :commit_author_id
  # - :committer_id
  # - :raw_sha
  # - :authored_date
  # - :committed_date
  # - :message
  #
  # The return value is a hash that maps ID of each found or created commits metadata
  # row to a SHA.
  def self.bulk_find_or_create(project_id, commit_rows)
    mapping = {}
    create = []

    # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- This is an array of hashes
    commits_shas = commit_rows.pluck(:raw_sha)
    # rubocop:enable Database/AvoidUsingPluckWithoutLimit

    # Find commits that are already existing in `merge_request_commits_metadata`
    # table. Store them in `mapping` hash so we can map this with rows in
    # `merge_request_diff_commits` table by SHA.
    #
    # `row.last` is the SHA and `row.first` is the ID.
    bulk_find(project_id, commits_shas).each do |row|
      mapping[row.last] = row.first
    end

    # Check if there are commits that don't exist yet in the mapping. It means
    # they're not stored in the DB yet at this point so we need to create them.
    commit_rows.each do |commit_row|
      next if mapping[commit_row[:raw_sha]]

      create << {
        project_id: project_id,
        commit_author_id: commit_row[:commit_author_id],
        committer_id: commit_row[:committer_id],
        sha: commit_row[:raw_sha],
        authored_date: commit_row[:authored_date],
        committed_date: commit_row[:committed_date],
        message: commit_row[:message]
      }
    end

    return mapping if create.empty?

    sha_attribute = Gitlab::Database::ShaAttribute.new

    create.each_slice(1_000) do |slice|
      insert_all(
        slice,
        returning: %w[id sha],
        unique_by: :index_merge_request_commits_metadata_on_project_id_and_sha
      ).each do |row|
        # Need to deserialize sha since it's stored as binary in the database
        # and we need to match by its text value.
        mapping[sha_attribute.deserialize(row['sha'])] = row['id']
      end
    end

    # It's possible for commits to be inserted concurrently,
    # resulting in the above insert not returning anything. Here we get any
    # remaining commits that were created concurrently.
    #
    # `row.last` is the SHA and `row.first` is the ID.
    bulk_find(project_id, commits_shas.reject { |sha| mapping.key?(sha) }).each do |row|
      mapping[row.last] = row.first
    end

    mapping
  end
end
