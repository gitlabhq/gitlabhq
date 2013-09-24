class KeyObserver < BaseObserver
  def after_create(key)
    GitlabShellWorker.perform_async(
      :add_key,
      key.shell_id,
      key.key
    )

    notification.new_key(key)
  end

  def after_destroy(key)
    GitlabShellWorker.perform_async(
      :remove_key,
      key.shell_id,
      key.key,
    )
  end
end
