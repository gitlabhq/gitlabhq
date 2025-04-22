# frozen_string_literal: true

class MergeRequest::CommitsMetadata < ApplicationRecord # rubocop:disable Style/ClassAndModuleChildren, Gitlab/BoundedContexts -- Same as the rest of the models under `MergeRequest` namespace
  include PartitionedTable
  include ShaAttribute

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

  sha_attribute :sha
end
