class KeyObserver < ActiveRecord::Observer
  include Gitlab::ShellAdapter

  def after_save(key)
    GitlabShellWorker.perform_async(
      :add_key,
      key.shell_id,
      key.key
    )

    # Notify about ssh key being added
    Notify.delay.new_ssh_key_email(key.id) if key.user
  end

  def after_destroy(key)
    GitlabShellWorker.perform_async(
      :remove_key,
      key.shell_id,
      key.key,
    )
  end
end
