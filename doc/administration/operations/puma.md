---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure the bundled Puma instance of the GitLab package
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Puma is a fast, multi-threaded, and highly concurrent HTTP 1.1 server for
Ruby applications. It runs the core Rails application that provides the user-facing
features of GitLab.

## Reducing memory use

To reduce memory use, Puma forks worker processes. Each time a worker is created,
it shares memory with the primary process. The worker uses additional memory only
when it changes or adds to its memory pages. This can lead to Puma workers using
more physical memory over time as workers handle additional web requests. The amount of memory
used over time depends on the use of GitLab. The more features used by GitLab users,
the higher the expected memory use over time.

To stop uncontrolled memory growth, the GitLab Rails application runs a supervision thread
that automatically restarts workers if they exceed a given resident set size (RSS) threshold
for a certain amount of time.

GitLab sets a default of `1200Mb` for the memory limit. To override the default value,
set `per_worker_max_memory_mb` to the new RSS limit in megabytes:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['per_worker_max_memory_mb'] = 1024 # 1GB
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

When workers are restarted, capacity to run GitLab is reduced for a short
period of time. Set `per_worker_max_memory_mb` to a higher value if workers are replaced too often.

Worker count is calculated based on CPU cores. A small GitLab deployment
with 4-8 workers may experience performance issues if workers are being restarted
too often (once or more per minute).

A higher value of `1200` or more could be beneficial if the server has free memory.

### Monitor worker restarts

GitLab emits log events if workers are restarted due to high memory use.

The following is an example of one of these log events in `/var/log/gitlab/gitlab-rails/application_json.log`:

```json
{
  "severity": "WARN",
  "time": "2023-01-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "puma_0",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::PumaHandler",
  "memwd_sleep_time_s": 5,
  "memwd_rss_bytes": 1077682176,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded"
}
```

`memwd_rss_bytes` is the actual amount of memory consumed, and `memwd_max_rss_bytes` is the
RSS limit set through `per_worker_max_memory_mb`.

## Change the worker timeout

The default Puma [timeout is 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb).

NOTE:
The `puma['worker_timeout']` setting does not set the maximum request duration.

To change the worker timeout to 600 seconds:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disable Puma clustered mode in memory-constrained environments

WARNING:
This feature is an [experiment](../../policy/development_stages_support.md#experiment) and subject to change without notice. This feature
is not ready for production use. If you want to use this feature, you should test
outside of production first. See the [known issues](#puma-single-mode-known-issues)
for additional details.

In a memory-constrained environment with less than 4 GB of RAM available, consider disabling Puma
[clustered mode](https://github.com/puma/puma#clustered-mode).

Set the number of `workers` to `0` to reduce memory usage by hundreds of MB:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['worker_processes'] = 0
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Unlike in a clustered mode, which is set up by default, only a single Puma process would serve the application.
For details on Puma worker and thread settings, see the [Puma requirements](../../install/requirements.md#puma).

The downside of running Puma in this configuration is the reduced throughput, which can be
considered a fair tradeoff in a memory-constrained environment.

Remember to have sufficient swap available to avoid out of memory (OOM)
conditions. View the [Memory requirements](../../install/requirements.md#memory)
for details.

### Puma single mode known issues

When running Puma in single mode, some features are not supported:

- [Phased restart](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [Memory killers](#reducing-memory-use)

For more information, see [epic 5303](https://gitlab.com/groups/gitlab-org/-/epics/5303).

## Configuring Puma to listen over SSL

Puma, when deployed with a Linux package installation, listens over a Unix socket by
default. To configure Puma to listen over an HTTPS port instead, follow the
steps below:

1. Generate an SSL certificate key-pair for the address where Puma will
   listen. For the example below, this is `127.0.0.1`.

   NOTE:
   If using a self-signed certificate from a custom Certificate Authority (CA),
   follow [the documentation](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates)
   to make them trusted by other GitLab components.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['ssl_listen'] = '127.0.0.1'
   puma['ssl_port'] = 9111
   puma['ssl_certificate'] = '<path_to_certificate>'
   puma['ssl_certificate_key'] = '<path_to_key>'

   # Disable UNIX socket
   puma['socket'] = ""
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

NOTE:
In addition to the Unix socket, Puma also listens over HTTP on port 8080 for
providing metrics to be scraped by Prometheus. It is not currently possible to
make Prometheus scrape them over HTTPS, and support for it is being discussed
[in this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6811).
Hence, it is not technically possible to turn off this HTTP listener without
losing Prometheus metrics.

### Using an encrypted SSL key

> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7799) in GitLab 16.1.

Puma supports the use of an encrypted private SSL key, which can be
decrypted at runtime. The following instructions illustrate how to
configure this:

1. Encrypt the key with a password if it is not already:

   ```shell
   openssl rsa -aes256 -in /path/to/ssl-key.pem -out /path/to/encrypted-ssl-key.pem
   ```

   Enter in a password twice to write the encrypted file. In this
   example, we use `some-password-here`.

1. Create a script or executable that prints the password. For
   example, create a basic script in
   `/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password` that echoes
   the password:

   ```shell
   #!/bin/sh
   echo some-password-here
   ```

   Avoid storing the password on disk, and use a secure mechanism for retrieving a password, such as
   Vault. For example, the script might look like:

   ```shell
   #!/bin/sh
   export VAULT_ADDR=http://vault-password-distribution-point:8200
   export VAULT_TOKEN=<some token>

   echo "$(vault kv get -mount=secret puma-ssl-password)"
   ```

1. Ensure the Puma process has sufficient permissions to execute the
   script and to read the encrypted key:

   ```shell
   chown git:git /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 770 /var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password
   chmod 660 /path/to/encrypted-ssl-key.pem
   ```

1. Edit `/etc/gitlab/gitlab.rb`, and replace `puma['ssl_certificate_key']` with the encrypted key and specify
   `puma['ssl_key_password_command]`:

   ```ruby
   puma['ssl_certificate_key'] = '/path/to/encrypted-ssl-key.pem'
   puma['ssl_key_password_command'] = '/var/opt/gitlab/gitlab-rails/etc/puma-ssl-key-password'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. If GitLab comes up successfully, you should be able to remove the
   unencrypted SSL key that was stored on the GitLab instance.

## Switch from Unicorn to Puma

NOTE:
For Helm-based deployments, see the
[`webservice` chart documentation](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

Puma is the default web server and Unicorn is no longer supported.

Puma has a multi-thread architecture that uses less memory than a multi-process
application server like Unicorn. On GitLab.com, we saw a 40% reduction in memory
consumption. Most Rails application requests usually include a proportion of I/O wait time.

During I/O wait time, MRI Ruby releases the GVL to other threads.
Multi-threaded Puma can therefore still serve more requests than a single process.

When switching to Puma, any Unicorn server configuration will _not_ carry over
automatically, due to differences between the two application servers.

To switch from Unicorn to Puma:

1. Determine suitable Puma [worker and thread settings](../../install/requirements.md#puma).
1. Convert any custom Unicorn settings to Puma in `/etc/gitlab/gitlab.rb`.

   The table below summarizes which Unicorn configuration keys correspond to those
   in Puma when using the Linux package, and which ones have no corresponding counterpart.

   | Unicorn                              | Puma                               |
   | ------------------------------------ | ---------------------------------- |
   | `unicorn['enable']`                  | `puma['enable']`                   |
   | `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
   | `unicorn['worker_processes']`        | `puma['worker_processes']`         |
   | Not applicable                       | `puma['ha']`                       |
   | Not applicable                       | `puma['min_threads']`              |
   | Not applicable                       | `puma['max_threads']`              |
   | `unicorn['listen']`                  | `puma['listen']`                   |
   | `unicorn['port']`                    | `puma['port']`                     |
   | `unicorn['socket']`                  | `puma['socket']`                   |
   | `unicorn['pidfile']`                 | `puma['pidfile']`                  |
   | `unicorn['tcp_nopush']`              | Not applicable                     |
   | `unicorn['backlog_socket']`          | Not applicable                     |
   | `unicorn['somaxconn']`               | `puma['somaxconn']`                |
   | Not applicable                       | `puma['state_path']`               |
   | `unicorn['log_directory']`           | `puma['log_directory']`            |
   | `unicorn['worker_memory_limit_min']` | Not applicable                     |
   | `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
   | `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
   | `unicorn['exporter_address']`        | `puma['exporter_address']`         |
   | `unicorn['exporter_port']`           | `puma['exporter_port']`            |

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. For multi-node deployments, configure the load balancer to use the
   [readiness check](../load_balancer.md#readiness-check).

## Troubleshooting Puma

### 502 Gateway Timeout after Puma spins at 100% CPU

This error occurs when the Web server times out (default: 60 s) after not
hearing back from the Puma worker. If the CPU spins to 100% while this is in
progress, there may be something taking longer than it should.

To fix this issue, we first need to figure out what is happening. The
following tips are only recommended if you do not mind users being affected by
downtime. Otherwise, skip to the next section.

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

GDB reports an error if the Puma process terminates before you can run these commands.
To buy more time, you can always raise the
Puma worker timeout. For Linux package installation users, you can edit `/etc/gitlab/gitlab.rb` and
increase it from 60 seconds to 600:

```ruby
gitlab_rails['env'] = {
        'GITLAB_RAILS_RACK_TIMEOUT' => 600
}
```

For self-compiled installations, set the environment variable.
Refer to [Puma Worker timeout](../operations/puma.md#change-the-worker-timeout).

[Reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab for the changes to take effect.

#### Troubleshooting without affecting other users

The previous section attached to a running Puma process, which may have
undesirable effects on users trying to access GitLab during this time. If you
are concerned about affecting others during a production system, you can run a
separate Rails process to debug the issue:

1. Sign in to your GitLab account.
1. Copy the URL that is causing problems (for example, `https://gitlab.com/ABC`).
1. Create a personal access token for your user (User Settings -> Access tokens).
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
[internal API](../../development/internal_api/_index.md) (for example, `http://localhost:8080/api/v4/internal/allowed`), and
something in the check fails. There are many reasons why this may happen:

1. Timeout connecting to a database (for example, PostgreSQL or Redis)
1. Error in Git hooks or push rules
1. Error accessing the repository (for example, stale NFS handles)

To diagnose this problem, try to reproduce the problem and then see if there
is a Puma worker that is spinning via `top`. Try to use the `gdb`
techniques above. In addition, using `strace` may help isolate issues:

```shell
strace -ttTfyyy -s 1024 -p <PID of puma worker> -o /tmp/puma.txt
```

If you cannot isolate which Puma worker is the issue, try to run `strace`
on all the Puma workers to see where the
[`/internal/allowed`](../../development/internal_api/_index.md) endpoint gets stuck:

```shell
ps auwx | grep puma | awk '{ print " -p " $2}' | xargs  strace -ttTfyyy -s 1024 -o /tmp/puma.txt
```

The output in `/tmp/puma.txt` may help diagnose the root cause.

## Related topics

- [Use a dedicated metrics server to export web metrics](../monitoring/prometheus/web_exporter.md)
