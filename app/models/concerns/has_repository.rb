# frozen_string_literal: true

# This concern is created to handle repository actions.
# It should be include inside any object capable
# of directly having a repository, like project or snippet.
#
# It also includes `Referable`, therefore the method
# `to_reference` should be overridden in case the object
# needs any special behavior.
module HasRepository
  extend ActiveSupport::Concern
  include Referable
  include Gitlab::ShellAdapter
  include Gitlab::Utils::StrongMemoize

  delegate :base_dir, :disk_path, to: :storage

  class_methods do
    def pick_repository_storage
      # We need to ensure application settings are fresh when we pick
      # a repository storage to use.
      Gitlab::CurrentSettings.expire_current_application_settings
      Gitlab::CurrentSettings.pick_repository_storage
    end
  end

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:base, _('Invalid repository path'))
    false
  end

  def repo_exists?
    strong_memoize(:repo_exists) do
      repository.exists?
    rescue
      false
    end
  end

  def repository_exists?
    !!repository.exists?
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def commit(ref = 'HEAD')
    repository.commit(ref)
  end

  def commit_by(oid:)
    repository.commit_by(oid: oid)
  end

  def commits_by(oids:)
    repository.commits_by(oids: oids)
  end

  def repository
    raise NotImplementedError
  end

  def storage
    raise NotImplementedError
  end

  def full_path
    raise NotImplementedError
  end

  def lfs_enabled?
    false
  end

  def empty_repo?
    repository.empty?
  end

  def default_branch
    @default_branch ||= repository.root_ref || default_branch_from_preferences
  end

  def default_branch_from_preferences
    return unless empty_repo?

    group_branch_default_name = group&.default_branch_name if respond_to?(:group)

    group_branch_default_name || Gitlab::CurrentSettings.default_branch_name
  end

  def reload_default_branch
    @default_branch = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables

    default_branch
  end

  def url_to_repo
    ssh_url_to_repo
  end

  def ssh_url_to_repo
    Gitlab::RepositoryUrlBuilder.build(repository.full_path, protocol: :ssh)
  end

  def http_url_to_repo
    Gitlab::RepositoryUrlBuilder.build(repository.full_path, protocol: :http)
  end

  # Is overridden in EE::Project for Geo support
  def lfs_http_url_to_repo(_operation = nil)
    http_url_to_repo
  end

  def web_url(only_path: nil)
    Gitlab::UrlBuilder.build(self, only_path: only_path)
  end

  def repository_size_checker
    raise NotImplementedError
  end
end
