# Extra Sidekiq processes **[STARTER ONLY]**

GitLab Enterprise Edition allows one to start an extra set of Sidekiq processes
besides the default one. These processes can be used to consume a dedicated set
of queues. This can be used to ensure certain queues always have dedicated
workers, no matter the number of jobs that need to be processed.

## Starting extra processes via Omnibus GitLab

To enable `sidekiq-cluster`, you must apply the `sidekiq_cluster['enable'] = true`
setting `/etc/gitlab/gitlab.rb`:

```ruby
sidekiq_cluster['enable'] = true
```

You will then specify how many additional processes to create via `sidekiq-cluster`
as well as which queues for them to handle. This is done via the 
`sidekiq_cluster['queue_groups']` setting. This is an array whose items contain
which queues to process. Each item in the array will equate to one additional
sidekiq process.

As an example, to make additional sidekiq processes that process the 
`elastic_indexer` and `mailers` queues, you would apply the following:

```ruby
sidekiq_cluster['queue_groups'] = [
  "elastic_indexer",
  "mailers"
]
```

To have an additional sidekiq process handle multiple queues, you simply put a
comma after the first queue name and then put the next queue name:

```ruby
sidekiq_cluster['queue_groups'] = [
  "elastic_indexer,elastic_commit_indexer",
  "mailers"
]
```

Keep in mind, all changes must be followed by reconfiguring your GitLab
application via `sudo gitlab-ctl reconfigure`.

### Monitoring

Once the Sidekiq processes are added, you can visit the "Background Jobs"
section under the admin area in GitLab (`/admin/background_jobs`).

![Extra sidekiq processes](img/sidekiq-cluster.png)

### All queues with exceptions

To have the additional sidekiq processes work on every queue EXCEPT the ones
you list:

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   sidekiq_cluster['negate'] = true
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.


### Limiting concurrency

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   sidekiq_cluster['concurrency'] = 25
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

Keep in mind, this normally would not exceed the number of CPU cores available.

### Modifying the check interval

To modify the check interval for the additional Sidekiq processes:

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   sidekiq_cluster['interval'] = 5
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

This tells the additional processes how often to check for enqueued jobs.

## Starting extra processes via command line

Starting extra Sidekiq processes can be done using the command
`/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster`. This command
takes arguments using the following syntax:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

Each separate argument denotes a group of queues that have to be processed by a
Sidekiq process. Multiple queues can be processed by the same process by
separating them with a comma instead of a space.

Instead of a queue, a queue namespace can also be provided, to have the process
automatically listen on all queues in that namespace without needing to
explicitly list all the queue names. For more information about queue namespaces,
see the relevant section in the
[Sidekiq style guide](../../development/sidekiq_style_guide.md#queue-namespaces).

For example, say you want to start 2 extra processes: one to process the
"process_commit" queue, and one to process the "post_receive" queue. This can be
done as follows:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster process_commit post_receive
```

If you instead want to start one process processing both queues you'd use the
following syntax:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster process_commit,post_receive
```

If you want to have one Sidekiq process process the "process_commit" and
"post_receive" queues, and one process to process the "gitlab_shell" queue,
you'd use the following:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster process_commit,post_receive gitlab_shell
```

### Monitoring

The `sidekiq-cluster` command will not terminate once it has started the desired
amount of Sidekiq processes. Instead, the process will continue running and
forward any signals to the child processes. This makes it easy to stop all
Sidekiq processes as you simply send a signal to the `sidekiq-cluster` process,
instead of having to send it to the individual processes.

If the `sidekiq-cluster` process crashes or receives a `SIGKILL`, the child
processes will terminate themselves after a few seconds. This ensures you don't
end up with zombie Sidekiq processes.

All of this makes monitoring the processes fairly easy. Simply hook up
`sidekiq-cluster` to your supervisor of choice (e.g. runit) and you're good to
go.

If a child process died the `sidekiq-cluster` command will signal all remaining
process to terminate, then terminate itself. This removes the need for
`sidekiq-cluster` to re-implement complex process monitoring/restarting code.
Instead you should make sure your supervisor restarts the `sidekiq-cluster`
process whenever necessary.

### PID files

The `sidekiq-cluster` command can store its PID in a file. By default no PID
file is written, but this can be changed by passing the `--pidfile` option to
`sidekiq-cluster`. For example:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

Keep in mind that the PID file will contain the PID of the `sidekiq-cluster`
command and not the PID(s) of the started Sidekiq processes.

### Environment

The Rails environment can be set by passing the `--environment` flag to the
`sidekiq-cluster` command, or by setting `RAILS_ENV` to a non-empty value. The
default value is "development".

### All queues with exceptions

You're able to run all queues in `sidekiq_queues.yml` file on a single or
multiple processes with exceptions using the `--negate` flag.

For example, say you want to run a single process for all queues,
except "process_commit" and "post_receive". You can do so by executing:

```bash
sidekiq-cluster process_commit,post_receive --negate
```

For multiple processes of all queues (except "process_commit" and "post_receive"):

```bash
sidekiq-cluster process_commit,post_receive process_commit,post_receive --negate
```

### Limiting concurrency

By default, `sidekiq-cluster` will spin up extra Sidekiq processes that use
one thread per queue up to a maximum of 50. If you wish to change the cap, use
the `-m N` option. For example, this would cap the maximum number of threads to 1:

```bash
/opt/gitlab/embedded/service/gitlab-rails/ee/bin/sidekiq-cluster process_commit,post_receive -m 1
```

For each queue group, the concurrency factor will be set to min(number of
queues, N). Setting the value to 0 will disable the limit.

Note that each thread requires a Redis connection, so adding threads may
increase Redis latency and potentially cause client timeouts. See the [Sidekiq
documentation about Redis](https://github.com/mperham/sidekiq/wiki/Using-Redis)
for more details.

## Number of threads

Each process started using `sidekiq-cluster` (whether it be via command line or
via the gitlab.rb file) starts with a number of threads that equals the number
of queues, plus one spare thread. For example, a process that handles the
"process_commit" and "post_receive" queues will use 3 threads in total.
