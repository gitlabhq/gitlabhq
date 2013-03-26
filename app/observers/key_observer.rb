class KeyObserver < ActiveRecord::Observer
  include Gitlab::ShellAdapter

  def after_save(key)
    GitlabShellWorker.perform_async(
      :add_key,
      key.shell_id,
      key.key
    )

    # Notify about ssh key being added
    NotificationService.new.new_key(key)
  end

  def after_destroy(key)
    GitlabShellWorker.perform_async(
      :remove_key,
      key.shell_id,
      key.key,
    )
  end
end
