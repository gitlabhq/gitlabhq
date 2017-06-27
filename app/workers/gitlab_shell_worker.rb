class GitlabShellWorker
  include Sidekiq::Worker
  include Gitlab::ShellAdapter
  include DedicatedSidekiqQueue

  def perform(action, *arg)
    if action.to_s == 'batch_add_keys_in_db_starting_from'
      batch_add_keys_in_db_starting_from(arg.first)
    else
      gitlab_shell.send(action, *arg)
    end
  end

  # Not added to Gitlab::Shell because I don't expect this to be used again
  def batch_add_keys_in_db_starting_from(start_id)
    gitlab_shell.batch_add_keys do |adder|
      Key.find_each(start: start_id, batch_size: 1000) do |key|
        adder.add_key(key.shell_id, key.key)
      end
    end
  end
end
