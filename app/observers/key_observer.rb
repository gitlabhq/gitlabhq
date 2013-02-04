class KeyObserver < ActiveRecord::Observer
  include Gitolited

  def after_save(key)
    GitoliteWorker.perform_async(
      :add_key,
      key.owner_name,
      key.key
    )
  end

  def after_destroy(key)
    GitoliteWorker.perform_async(
      :remove_key,
      key.key,
    )
  end
end
