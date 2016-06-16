# Unicorn settings

If you need to adjust the Unicorn timeout or the number of workers you can use
the following settings in `/etc/gitlab/gitlab.rb`.
Run `sudo gitlab-ctl reconfigure` for the change to take effect.

```ruby
unicorn['worker_processes'] = 3
unicorn['worker_timeout'] = 60
```

## Advanced settings

Change the following settings only if you really need to.

```
unicorn['listen'] = '127.0.0.1'
unicorn['port'] = 8080
unicorn['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
unicorn['pidfile'] = '/opt/gitlab/var/unicorn/unicorn.pid'
unicorn['tcp_nopush'] = true
unicorn['backlog_socket'] = 1024
```

Make sure `somaxconn` is equal or higher than `backlog_socket`.

```
unicorn['somaxconn'] = 1024
```

We do not recommend changing this setting, but if you really must to:

```
unicorn['log_directory'] = "/var/log/gitlab/unicorn"
```

Only change these settings if you understand well what they mean
see https://about.gitlab.com/2015/06/05/how-gitlab-uses-unicorn-and-unicorn-worker-killer/
and https://github.com/kzk/unicorn-worker-killer

```
unicorn['worker_memory_limit_min'] = "300 * 1 << 20"
unicorn['worker_memory_limit_max'] = "350 * 1 << 20"
```
