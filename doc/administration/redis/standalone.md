---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Standalone Redis using the Linux package
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The Linux package can be used to configure a standalone Redis server.
In this configuration, Redis is not scaled, and represents a single
point of failure. However, in a scaled environment the objective is to allow
the environment to handle more users or to increase throughput. Redis itself
is generally stable and can handle many requests, so it is an acceptable
trade off to have only a single instance. See the [reference architectures](../reference_architectures/_index.md)
page for an overview of GitLab scaling options.

## Set up the standalone Redis instance

The steps below are the minimum necessary to configure a Redis server with
the Linux package:

1. SSH into the Redis server.
1. [Download and install](https://about.gitlab.com/install/) the Linux
   package you want by using **steps 1 and 2** from the GitLab downloads page.
   Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   ## Only the primary GitLab application server should handle migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Note the Redis node's IP address or hostname, port, and
   Redis password. These are necessary when [configuring the GitLab application servers](#set-up-the-gitlab-rails-application-instance).

[Advanced configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
are supported and can be added if needed.

## Set up the GitLab Rails application instance

On the instance where GitLab is installed:

1. Edit the `/etc/gitlab/gitlab.rb` file and add the following contents:

   ```ruby
   ## Disable Redis
   redis['enable'] = false

   gitlab_rails['redis_host'] = 'redis.example.com'
   gitlab_rails['redis_port'] = 6379

   ## Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. Save your changes to `/etc/gitlab/gitlab.rb`.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Troubleshooting

See the [Redis troubleshooting guide](troubleshooting.md).
