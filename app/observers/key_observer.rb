class KeyObserver < ActiveRecord::Observer
  include Gitolited

  def after_save(key)
    GitoliteWorker.perform_async(
      :set_key,
      key.identifier,
      key.key,
      key.projects.map(&:id)
    )
  end

  def after_destroy(key)
    return if key.is_deploy_key && !key.last_deploy?

    GitoliteWorker.perform_async(
      :remove_key,
      key.identifier,
      key.projects.map(&:id)
    )
  end
end
