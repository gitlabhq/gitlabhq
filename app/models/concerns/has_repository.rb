# frozen_string_literal: true

module HasRepository
  extend ActiveSupport::Concern
  include Gitlab::ShellAdapter
  include AfterCommitQueue
  include Gitlab::Utils::StrongMemoize

  delegate :base_dir, :disk_path, to: :storage

  def valid_repo?
    repository.exists?
  rescue
    errors.add(:path, _('Invalid repository path'))
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

  def empty_repo?
    repository.empty?
  end

  def default_branch
    @default_branch ||= repository.root_ref
  end

  def reload_default_branch
    @default_branch = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables

    default_branch
  end

  def url_to_repo
    gitlab_shell.url_to_repo(full_path)
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    custom_root = Gitlab::CurrentSettings.custom_http_clone_url_root

    url = if custom_root.present?
            Gitlab::Utils.append_path(
              custom_root,
              web_url(only_path: true)
            )
          else
            web_url
          end

    "#{url}.git"
  end

  def web_url(only_path: nil)
    raise NotImplementedError
  end
end
