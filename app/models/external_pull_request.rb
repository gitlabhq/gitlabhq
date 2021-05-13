# frozen_string_literal: true

# This model stores pull requests coming from external providers, such as
# GitHub, when GitLab project is set as CI/CD only and remote mirror.
#
# When setting up a remote mirror with GitHub we subscribe to push and
# pull_request webhook events. When a pull request is opened on GitHub,
# a webhook is sent out, we create or update the status of the pull
# request locally.
#
# When the mirror is updated and changes are pushed to branches we check
# if there are open pull requests for the source and target branch.
# If so, we create pipelines for external pull requests.
class ExternalPullRequest < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ShaAttribute

  belongs_to :project

  sha_attribute :source_sha
  sha_attribute :target_sha

  validates :source_branch, presence: true
  validates :target_branch, presence: true
  validates :source_sha, presence: true
  validates :target_sha, presence: true
  validates :source_repository, presence: true
  validates :target_repository, presence: true
  validates :status, presence: true

  enum status: {
    open: 1,
    closed: 2
  }

  # We currently don't support pull requests from fork, so
  # we are going to return an error to the webhook
  validate :not_from_fork

  scope :by_source_branch, ->(branch) { where(source_branch: branch) }
  scope :by_source_repository, -> (repository) { where(source_repository: repository) }

  def self.create_or_update_from_params(params)
    find_params = params.slice(:project_id, :source_branch, :target_branch)

    safe_find_or_initialize_and_update(find: find_params, update: params) do |pull_request|
      yield(pull_request) if block_given?
    end
  end

  def actual_branch_head?
    actual_source_branch_sha == source_sha
  end

  def from_fork?
    source_repository != target_repository
  end

  def source_ref
    Gitlab::Git::BRANCH_REF_PREFIX + source_branch
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new.tap do |variables|
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_IID', value: pull_request_iid.to_s)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY', value: source_repository)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY', value: target_repository)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA', value: source_sha)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA', value: target_sha)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME', value: source_branch)
      variables.append(key: 'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME', value: target_branch)
    end
  end

  def modified_paths
    project.repository.diff_stats(target_sha, source_sha).paths
  end

  private

  def actual_source_branch_sha
    project.commit(source_ref)&.sha
  end

  def not_from_fork
    if from_fork?
      errors.add(:base, _('Pull requests from fork are not supported'))
    end
  end

  def self.safe_find_or_initialize_and_update(find:, update:)
    safe_ensure_unique(retries: 1) do
      model = find_or_initialize_by(find)

      if model.update(update)
        yield(model) if block_given?
      end

      model
    end
  end
end
