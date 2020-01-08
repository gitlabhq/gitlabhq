# Debugging Tips

Sometimes things don't work the way they should. Here are some tips on debugging issues out
in production.

## Mail not working

A common problem is that mails are not being sent for some reason. Suppose you configured
an SMTP server, but you're not seeing mail delivered. Here's how to check the settings:

1. Run a Rails console:

   ```sh
   sudo gitlab-rails console production
   ```

   or for source installs:

   ```sh
   bundle exec rails console production
   ```

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
   => {:address=>"localhost", :port=>25, :domain=>"localhost.localdomain", :user_name=>nil, :password=>nil, :authentication=>nil, :enable_starttls_auto=>true}```
   ```

   In the example above, the SMTP server is configured for the local machine. If this is intended, you may need to check your local mail
   logs (e.g. `/var/log/mail.log`) for more details.

1. Send a test message via the console.

   ```ruby
   irb(main):003:0> Notify.test_email('youremail@email.com', 'Hello World', 'This is a test message').deliver_now
   ```

   If you do not receive an e-mail and/or see an error message, then check
   your mail server settings.

## Advanced Issues

For more advanced issues, `gdb` is a must-have tool for debugging issues.

### The GNU Project Debugger (gdb)

To install on Ubuntu/Debian:

```
sudo apt-get install gdb
```

On CentOS:

```
sudo yum install gdb
```

### rbtrace

GitLab 11.2 ships with [rbtrace](https://github.com/tmm1/rbtrace), which
allows you to trace Ruby code, view all running threads, take memory dumps,
and more. However, this is not enabled by default. To enable it, define the
`ENABLE_RBTRACE` variable to the environment. For example, in Omnibus:

```ruby
gitlab_rails['env'] = {"ENABLE_RBTRACE" => "1"}
```

Then reconfigure the system and restart Unicorn and Sidekiq. To run this
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
1. Run `sudo gdb -p <PID>` to attach to the Unicorn process.
1. In the gdb window, type:

   ```
   call (void) rb_backtrace()
   ```

1. This forces the process to generate a Ruby backtrace. Check
   `/var/log/gitlab/unicorn/unicorn_stderr.log` for the backtace. For example, you may see:

   ```ruby
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

   ```
   thread apply all bt
   ```

1. Once you're done debugging with `gdb`, be sure to detach from the process and exit:

   ```
   detach
   exit
   ```

Note that if the Unicorn process terminates before you are able to run these
commands, gdb will report an error. To buy more time, you can always raise the
Unicorn timeout. For omnibus users, you can edit `/etc/gitlab/gitlab.rb` and
increase it from 60 seconds to 300:

```ruby
unicorn['worker_timeout'] = 300
```

For source installations, edit `config/unicorn.rb`.

[Reconfigure] GitLab for the changes to take effect.

[Reconfigure]: ../restart_gitlab.md#omnibus-gitlab-reconfigure

#### Troubleshooting without affecting other users

The previous section attached to a running Unicorn process, and this may have
undesirable effects for users trying to access GitLab during this time. If you
are concerned about affecting others during a production system, you can run a
separate Rails process to debug the issue:

1. Log in to your GitLab account.
1. Copy the URL that is causing problems (e.g. `https://gitlab.com/ABC`).
1. Create a Personal Access Token for your user (Profile Settings -> Access Tokens).
1. Bring up the GitLab Rails console. For omnibus users, run:

   ```
   sudo gitlab-rails console
   ```

1. At the Rails console, run:

   ```ruby
   [1] pry(main)> app.get '<URL FROM STEP 2>/?private_token=<TOKEN FROM STEP 3>'
   ```

   For example:

   ```ruby
   [1] pry(main)> app.get 'https://gitlab.com/gitlab-org/gitlab-foss/issues/1?private_token=123456'
   ```

1. In a new window, run `top`. It should show this ruby process using 100% CPU. Write down the PID.
1. Follow step 2 from the previous section on using gdb.

### GitLab: API is not accessible

This often occurs when GitLab Shell attempts to request authorization via the
internal API (e.g., `http://localhost:8080/api/v4/internal/allowed`), and
something in the check fails. There are many reasons why this may happen:

1. Timeout connecting to a database (e.g., PostgreSQL or Redis)
1. Error in Git hooks or push rules
1. Error accessing the repository (e.g., stale NFS handles)

To diagnose this problem, try to reproduce the problem and then see if there
is a Unicorn worker that is spinning via `top`. Try to use the `gdb`
techniques above. In addition, using `strace` may help isolate issues:

```shell
strace -ttTfyyy -s 1024 -p <PID of unicorn worker> -o /tmp/unicorn.txt
```

If you cannot isolate which Unicorn worker is the issue, try to run `strace`
on all the Unicorn workers to see where the `/internal/allowed` endpoint gets
stuck:

```shell
ps auwx | grep unicorn | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/unicorn.txt
```

The output in `/tmp/unicorn.txt` may help diagnose the root cause.

## More information

- [Debugging Stuck Ruby Processes](https://blog.newrelic.com/engineering/debugging-stuck-ruby-processes-what-to-do-before-you-kill-9/)
- [Cheatsheet of using gdb and ruby processes](gdb-stuck-ruby.txt)
