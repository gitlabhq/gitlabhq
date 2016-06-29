# Debugging Tips

Sometimes things don't work the way they should. Here are some tips on debugging issues out
in production.

## The GNU Project Debugger (gdb)

`gdb` is a must-have tool for debugging issues. To install on Ubuntu/Debian:

```
sudo apt-get install gdb
```

On CentOS:

```
sudo yum install gdb
```

## Common Problems

Many of the tips to diagnose issues below apply to many different situations. We'll use one
concrete example to illustrate what you can do to learn what is going wrong.

### 502 Gateway Timeout after unicorn spins at 100% CPU

This error occurs when the Web server times out (default: 60 s) after not
hearing back from the unicorn worker. If the CPU spins to 100% while this in
progress, there may be something taking longer than it should.

To fix this issue, we first need to figure out what is happening. The
following tips are only recommended if you do NOT mind users being affected by
downtime. Otherwise skip to the next section.

1. Load the problematic URL
1. Run `sudo gdb -p <PID>` to attach to the unicorn process.
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
    apply all thread bt
    ```

1. Once you're done debugging with `gdb`, be sure to detach from the process and exit:

    ```
    detach
    exit
    ```

Note that if the unicorn process terminates before you are able to run these
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

The previous section attached to a running unicorn process, and this may have
undesirable effects for users trying to access GitLab during this time. If you
are concerned about affecting others during a production system, you can run a
separate Rails process to debug the issue:

1. Log in to your GitLab account.
1. Copy the URL that is causing problems (e.g. https://gitlab.com/ABC).
1. Obtain the private token for your user (Profile Settings -> Account).
1. Bring up the GitLab Rails console. For omnibus users, run:

    ````
    sudo gitlab-rails console
    ```

1. At the Rails console, run:

    ```ruby
    [1] pry(main)> app.get '<URL FROM STEP 1>/private_token?<TOKEN FROM STEP 2>'
    ```

    For example:

    ```ruby
    [1] pry(main)> app.get 'https://gitlab.com/gitlab-org/gitlab-ce/issues/1?private_token=123456'
    ```

1. In a new window, run `top`. It should show this ruby process using 100% CPU. Write down the PID.
1. Follow step 2 from the previous section on using gdb.

# More information

* [Debugging Stuck Ruby Processes](https://blog.newrelic.com/2013/04/29/debugging-stuck-ruby-processes-what-to-do-before-you-kill-9/)
* [Cheatsheet of using gdb and ruby processes](gdb-stuck-ruby.txt)
