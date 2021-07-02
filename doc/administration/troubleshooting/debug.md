---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Debugging tips **(FREE SELF)**

Sometimes things don't work the way they should. Here are some tips on debugging issues out
in production.

## Starting a Rails console session

Troubleshooting and debugging your GitLab instance often requires a Rails console.

Your type of GitLab installation determines how
[to start a rails console](../operations/rails_console.md).
See also:

- [GitLab Rails Console Cheat Sheet](gitlab_rails_cheat_sheet.md).
- [Navigating GitLab via Rails console](navigating_gitlab_via_rails_console.md).

### Enabling Active Record logging

You can enable output of Active Record debug logging in the Rails console
session by running:

```ruby
ActiveRecord::Base.logger = Logger.new($stdout)
```

This will show information about database queries triggered by any Ruby code
you may run in the console. To turn off logging again, run:

```ruby
ActiveRecord::Base.logger = nil
```

### Disabling database statement timeout

You can disable the PostgreSQL statement timeout for the current Rails console
session by running:

```ruby
ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
```

Note that this change only affects the current Rails console session and will
not be persisted in the GitLab production environment or in the next Rails
console session.

### Output Rails console session history

If you'd like to output your Rails console command history in a format that's
easy to copy and save for future reference, you can run:

```ruby
puts Readline::HISTORY.to_a
```

## Using the Rails runner

If you need to run some Ruby code in the context of your GitLab production
environment, you can do so using the [Rails runner](https://guides.rubyonrails.org/command_line.html#rails-runner). When executing a script file, the script must be accessible by the `git` user.

**For Omnibus installations**

```shell
sudo gitlab-rails runner "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo gitlab-rails runner "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo gitlab-rails runner /path/to/script.rb
```

**For installations from source**

```shell
sudo -u git -H bundle exec rails runner -e production "RAILS_COMMAND"

# Example with a two-line Ruby script
sudo -u git -H bundle exec rails runner -e production "user = User.first; puts user.username"

# Example with a ruby script file (make sure to use the full path)
sudo -u git -H bundle exec rails runner -e production /path/to/script.rb
```

## Mail not working

A common problem is that mails are not being sent for some reason. Suppose you configured
an SMTP server, but you're not seeing mail delivered. Here's how to check the settings:

1. Run a [Rails console](../operations/rails_console.md#starting-a-rails-console-session).

1. Look at the ActionMailer `delivery_method` to make sure it matches what you
   intended. If you configured SMTP, it should say `:smtp`. If you're using
   Sendmail, it should say `:sendmail`:

   ```ruby
   irb(main):001:0> ActionMailer::Base.delivery_method
   => :smtp
   ```

1. If you're using SMTP, check the mail settings:

   ```ruby
   irb(main):002:0> ActionMailer::Base.smtp_settings
   => {:address=>"localhost", :port=>25, :domain=>"localhost.localdomain", :user_name=>nil, :password=>nil, :authentication=>nil, :enable_starttls_auto=>true}
   ```

   In the example above, the SMTP server is configured for the local machine. If this is intended, you may need to check your local mail
   logs (e.g. `/var/log/mail.log`) for more details.

1. Send a test message via the console.

   ```ruby
   irb(main):003:0> Notify.test_email('youremail@email.com', 'Hello World', 'This is a test message').deliver_now
   ```

   If you do not receive an email and/or see an error message, then check
   your mail server settings.

## Advanced Issues

For more advanced issues, `gdb` is a must-have tool for debugging issues.

### The GNU Project Debugger (GDB)

To install on Ubuntu/Debian:

```shell
sudo apt-get install gdb
```

On CentOS:

```shell
sudo yum install gdb
```

<!-- vale gitlab.Spelling = NO -->

### rbtrace

<!-- vale gitlab.Spelling = YES -->

GitLab 11.2 ships with [`rbtrace`](https://github.com/tmm1/rbtrace), which
allows you to trace Ruby code, view all running threads, take memory dumps,
and more. However, this is not enabled by default. To enable it, define the
`ENABLE_RBTRACE` variable to the environment. For example, in Omnibus:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

Then reconfigure the system and restart Puma and Sidekiq. To run this
in Omnibus, run as root:

```ruby
/opt/gitlab/embedded/bin/ruby /opt/gitlab/embedded/bin/rbtrace
```

## Common Problems

Many of the tips to diagnose issues below apply to many different situations. We'll use one
concrete example to illustrate what you can do to learn what is going wrong.

### 502 Gateway Timeout after Unicorn spins at 100% CPU

This error occurs when the Web server times out (default: 60 s) after not
hearing back from the Unicorn worker. If the CPU spins to 100% while this in
progress, there may be something taking longer than it should.

To fix this issue, we first need to figure out what is happening. The
following tips are only recommended if you do NOT mind users being affected by
downtime. Otherwise skip to the next section.

1. Load the problematic URL
1. Run `sudo gdb -p <PID>` to attach to the Puma process.
1. In the GDB window, type:

   ```plaintext
   call (void) rb_backtrace()
   ```

1. This forces the process to generate a Ruby backtrace. Check
   `/var/log/gitlab/puma/puma_stderr.log` for the backtrace. For example, you may see:

   ```plaintext
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `block in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:33:in `loop'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:36:in `block (2 levels) in start'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:44:in `sample'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each_with_object'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:68:in `each'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `block in sample_objects'
   from /opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/metrics/sampler.rb:69:in `name'
   ```

1. To see the current threads, run:

   ```plaintext
   thread apply all bt
   ```

1. Once you're done debugging with `gdb`, be sure to detach from the process and exit:

   ```plaintext
   detach
   exit
   ```

Note that if the Puma process terminates before you are able to run these
commands, GDB will report an error. To buy more time, you can always raise the
Puma worker timeout. For omnibus users, you can edit `/etc/gitlab/gitlab.rb` and
increase it from 60 seconds to 600:

```ruby
gitlab_rails['env'] = {
        'GITLAB_RAILS_RACK_TIMEOUT' => 600
}
```

For source installations, set the environment variable.
Refer to [Puma Worker timeout](https://docs.gitlab.com/omnibus/settings/puma.html#worker-timeout).

[Reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

#### Troubleshooting without affecting other users

The previous section attached to a running Unicorn process, and this may have
undesirable effects for users trying to access GitLab during this time. If you
are concerned about affecting others during a production system, you can run a
separate Rails process to debug the issue:

1. Log in to your GitLab account.
1. Copy the URL that is causing problems (e.g. `https://gitlab.com/ABC`).
1. Create a Personal Access Token for your user (User Settings -> Access Tokens).
1. Bring up the [GitLab Rails console.](../operations/rails_console.md#starting-a-rails-console-session)
1. At the Rails console, run:

   ```ruby
   app.get '<URL FROM STEP 2>/?private_token=<TOKEN FROM STEP 3>'
   ```

   For example:

   ```ruby
   app.get 'https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1?private_token=123456'
   ```

1. In a new window, run `top`. It should show this Ruby process using 100% CPU. Write down the PID.
1. Follow step 2 from the previous section on using GDB.

### GitLab: API is not accessible

This often occurs when GitLab Shell attempts to request authorization via the
[internal API](../../development/internal_api.md) (e.g., `http://localhost:8080/api/v4/internal/allowed`), and
something in the check fails. There are many reasons why this may happen:

1. Timeout connecting to a database (e.g., PostgreSQL or Redis)
1. Error in Git hooks or push rules
1. Error accessing the repository (e.g., stale NFS handles)

To diagnose this problem, try to reproduce the problem and then see if there
is a Unicorn worker that is spinning via `top`. Try to use the `gdb`
techniques above. In addition, using `strace` may help isolate issues:

```shell
strace -ttTfyyy -s 1024 -p <PID of puma worker> -o /tmp/puma.txt
```

If you cannot isolate which Unicorn worker is the issue, try to run `strace`
on all the Unicorn workers to see where the
[`/internal/allowed`](../../development/internal_api.md) endpoint gets stuck:

```shell
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/puma.txt
```

The output in `/tmp/puma.txt` may help diagnose the root cause.

## More information

- [Debugging Stuck Ruby Processes](https://newrelic.com/blog/engineering/debugging-stuck-ruby-processes-what-to-do-before-you-kill-9/)
- [Cheat sheet of using GDB and Ruby processes](gdb-stuck-ruby.txt)
