class KeyObserver < ActiveRecord::Observer
  include GitHost

  def after_save(key)
    git_host.set_key(key.identifier, key.key, key.projects)
  end

  def after_destroy(key)
    return if key.is_deploy_key && !key.last_deploy?
    git_host.remove_key(key.identifier, key.projects)
  end
end
