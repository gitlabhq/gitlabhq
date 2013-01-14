class KeyObserver < ActiveRecord::Observer
  include Gitolited

  def after_save(key)
    gitolite.set_key(key.identifier, key.key, key.projects)
  end

  def after_destroy(key)
    return if key.is_deploy_key && !key.last_deploy?
    gitolite.remove_key(key.identifier, key.projects)
  end
end
