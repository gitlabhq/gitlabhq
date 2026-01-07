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
  delegate :change_head, to: :repository

  def valid_repo?
    repository.exists?
  rescue StandardError
    errors.add(:base, _('Invalid repository path'))
    false
  end

  def repo_exists?
    repository.exists?
  rescue StandardError
    false
  end
  strong_memoize_attr :repo_exists?

  def repository_exists?
    !!repository.exists?
  end

  def root_ref?(branch)
    repository.root_ref == branch
  end

  def commit(ref = 'HEAD')
    repository.commit(ref)
  end

  def branch_exists?(branch)
    repository.branch_exists?(branch)
  end

  def ref_exists?(ref)
    repository.ref_exists?(ref)
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
    @default_branch ||= repository.empty? ? default_branch_from_preferences : repository.root_ref
  end

  def default_branch=(branch_name)
    return if branch_name.blank?

    return unless instance_of?(Project) && importing?

    # Store the desired default branch for later application
    # This is used during project import to restore the default branch
    @desired_default_branch = branch_name # rubocop:disable Gitlab/ModuleWithInstanceVariables -- no alternative without disabling cop

    # Try to apply it immediately if the repository is ready
    apply_desired_default_branch
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables -- no alternative without disabling cop
  def apply_desired_default_branch
    return unless @desired_default_branch
    return if repository.empty?
    return if repository.root_ref == @desired_default_branch

    # Only change HEAD if the branch exists
    if repository.branch_exists?(@desired_default_branch)
      repository.change_head(@desired_default_branch)
      reload_default_branch
      @desired_default_branch = nil
    end
  rescue StandardError => e
    # Log the error but don't fail the import
    Import::Framework::Logger.warn("Failed to set default branch to #{@desired_default_branch}: #{e.message}")
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def default_branch_from_preferences
    (default_branch_from_group_preferences || Gitlab::CurrentSettings.default_branch_name).presence
  end

  def default_branch_from_group_preferences
    return unless respond_to?(:group)
    return unless group

    group.default_branch_name || group.root_ancestor.default_branch_name
  end

  def reload_default_branch
    @default_branch = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables -- no alternative without disabling cop

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

  def after_repository_change_head
    reload_default_branch

    container_type = self.class.name

    run_after_commit_or_now do
      Gitlab::EventStore.publish(
        ::Repositories::DefaultBranchChangedEvent.new(data: { container_id: id, container_type: container_type }))
    end
  end

  def after_create_repository
    container_type = self.class.name
    container_id = id

    run_after_commit_or_now do
      Gitlab::EventStore.publish(
        ::Repositories::RepositoryCreatedEvent.new(data: { container_id: container_id,
                                                           container_type: container_type }))
    end
  end

  def after_change_head_branch_does_not_exist(branch)
    # No-op (by default)
  end
end
