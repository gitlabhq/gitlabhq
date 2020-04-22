# frozen_string_literal: true

class GroupWiki < Wiki
  alias_method :group, :container

  override :storage
  def storage
    @storage ||= Storage::Hashed.new(container, prefix: Storage::Hashed::GROUP_REPOSITORY_PATH_PREFIX)
  end

  override :repository_storage
  def repository_storage
    # TODO: Add table to track storage
    # https://gitlab.com/gitlab-org/gitlab/-/issues/207865
    'default'
  end

  override :hashed_storage?
  def hashed_storage?
    true
  end

  override :disk_path
  def disk_path(*args, &block)
    storage.disk_path + '.wiki'
  end
end
