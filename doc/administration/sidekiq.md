---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Configure an external Sidekiq instance **(FREE SELF)**

You can configure an external Sidekiq instance by using the Sidekiq that's
bundled in the GitLab package. Sidekiq requires connection to the Redis,
PostgreSQL, and Gitaly instances.

## Required configuration

To configure Sidekiq:

1. SSH into the Sidekiq server.
1. [Download and install](https://about.gitlab.com/install/) the Omnibus GitLab package
   using steps 1 and 2. **Do not complete any other steps.**
1. Edit `/etc/gitlab/gitlab.rb` with the following information and make sure
   to replace with your values:

   ```ruby
   ##
   ## To maintain uniformity of links across nodes, the
   ##`external_url` on the Sidekiq server should point to the external URL that users
   ## use to access GitLab. This can be either:
   ##
   ## - The `external_url` set on your application server.
   ## - The URL of a external load balancer, which routes traffic to the GitLab application server.
   ##

   external_url 'https://gitlab.example.com'

   ## Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   ########################################
   #####        Services Disabled       ###
   ########################################
   #
   # When running GitLab on just one server, you have a single `gitlab.rb`
   # to enable all services you want to run.
   # When running GitLab on N servers, you have N `gitlab.rb` files.
   # Enable only the services you want to run on each
   # specific server, while disabling all others.
   #
   nginx['enable'] = false
   grafana['enable'] = false
   prometheus['enable'] = false
   gitlab_rails['auto_migrate'] = false
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   puma['enable'] = false
   gitlab_exporter['enable'] = false

   #######################################
   ###      Sidekiq configuration      ###
   #######################################
   sidekiq['enable'] = true
   sidekiq['listen_address'] = "0.0.0.0"

   ## Set number of Sidekiq queue processes to the same number as available CPUs
   sidekiq['queue_groups'] = ['*'] * 4

   ## Set number of Sidekiq threads per queue process to the recommend number of 10
   sidekiq['max_concurrency'] = 10

   ########################################
   ####              Redis              ###
   ########################################

   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the master node.
   redis['master_password'] = '<redis_master_password>'

   #######################################
   ###              Gitaly             ###
   #######################################

   ## Replace <gitaly_token> with the one you set up, see
   ## https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#about-the-gitaly-token
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly:8075' },
   })
   gitlab_rails['gitaly_token'] = '<gitaly_token>'

   #######################################
   ###            Postgres             ###
   #######################################

   # Replace <database_host> and <database_password>
   gitlab_rails['db_host'] = '<database_host>'
   gitlab_rails['db_password'] = '<database_password>'
   gitlab_rails['db_port'] = '5432'
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['auto_migrate'] = false

   # Add the Sidekiq node(s) to PostgreSQL's trusted addresses.
   # In the following example, 10.10.1.30/32 is the private IP
   # of the Sidekiq server.
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 10.10.1.30/32)
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart the Sidekiq nodes after completing the process and finishing the database migrations.

## Configure multiple Sidekiq nodes with shared storage

If you run multiple Sidekiq nodes with a shared file storage, such as NFS, you must
specify the UIDs and GIDs to ensure they match between servers. Specifying the UIDs
and GIDs prevents permissions issues in the file system. This advice is similar to the
[advice for Geo setups](geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site).

To set up multiple Sidekiq nodes:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the Container Registry when using an external Sidekiq

If you're using the Container Registry and it's running on a different
node than Sidekiq, follow the steps below.

1. Edit `/etc/gitlab/gitlab.rb`, and configure the registry URL:

   ```ruby
   registry_external_url 'https://registry.example.com'
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. In the instance where Container Registry is hosted, copy the `registry.key`
   file to the Sidekiq node.

## Configure the Sidekiq metrics server

If you want to collect Sidekiq metrics, enable the Sidekiq metrics server.
To make metrics available from `localhost:8082/metrics`:

To configure the metrics server:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = "8082"

   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure health checks

If you use health check probes to observe Sidekiq,
you can set a separate port for health checks.
Configuring health checks is only necessary if there is something that actually probes them.
For more information about health checks, see the [Sidekiq health check page](sidekiq_health_check.md).

To enable health checks for Sidekiq:

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
   sidekiq['health_checks_enabled'] = true
   sidekiq['health_checks_listen_address'] = "localhost"
   sidekiq['health_checks_listen_port'] = "8092"
   ```

   NOTE:
   If health check settings are not set, they default to the metrics exporter settings.
   This default is deprecated and is set to be removed in [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509).

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Related topics

- [Extra Sidekiq processes](operations/extra_sidekiq_processes.md)
- [Extra Sidekiq routing](operations/extra_sidekiq_routing.md)
- [Using the GitLab-Sidekiq chart](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)
- [Sidekiq health checks](sidekiq_health_check.md)
