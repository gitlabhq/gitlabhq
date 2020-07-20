---
type: howto
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Standalone Redis using Omnibus GitLab **(CORE ONLY)**

The Omnibus GitLab package can be used to configure a standalone Redis server.
In this configuration, Redis is not scaled, and represents a single
point of failure. However, in a scaled environment the objective is to allow
the environment to handle more users or to increase throughput. Redis itself
is generally stable and can handle many requests, so it is an acceptable
trade off to have only a single instance. See the [reference architectures](../reference_architectures/index.md)
page for an overview of GitLab scaling options.

## Set up a standalone Redis instance

The steps below are the minimum necessary to configure a Redis server with
Omnibus GitLab:

1. SSH into the Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want by using **steps 1 and 2** from the GitLab downloads page.
   Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   ## Enable Redis
   redis['enable'] = true

   ## Disable all other services
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   puma['enable'] = false
   postgresql['enable'] = false
   nginx['enable'] = false
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   gitlab_exporter['enable'] = false
   gitaly['enable'] = false

   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = 'SECRET_PASSWORD_HERE'

   gitlab_rails['enable'] = false
   ```

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Note the Redis node's IP address or hostname, port, and
   Redis password. These will be necessary when configuring the GitLab
   application servers later.

[Advanced configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
are supported and can be added if needed.

## Troubleshooting

See the [Redis troubleshooting guide](troubleshooting.md).
