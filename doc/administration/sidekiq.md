---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Configuring Sidekiq **(FREE SELF)**

This section discusses how to configure an external Sidekiq instance using the
bundled Sidekiq in the GitLab package.

Sidekiq requires connection to the Redis, PostgreSQL and Gitaly instance.
To configure the Sidekiq node:

1. SSH into the Sidekiq server.
1. [Download/install](https://about.gitlab.com/install/) the Omnibus GitLab package
you want using steps 1 and 2 from the GitLab downloads page.
**Do not complete any other steps on the download page.**
1. Open `/etc/gitlab/gitlab.rb` with your editor.
1. Generate the Sidekiq configuration:

   ```ruby
   ## Optional: Enable extra Sidekiq processes
   sidekiq_cluster['enable'] = true
   sidekiq['queue_groups'] = [
     "elastic_commit_indexer",
     "*"
   ]
   ```

1. Setup Sidekiq's connection to Redis:

   ```ruby
   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the master node.
   redis['master_password'] = 'YOUR_PASSOWORD'

   ## A list of sentinels with `host` and `port`
   gitlab_rails['redis_sentinels'] = [
       {'host' => '10.10.1.34', 'port' => 26379},
       {'host' => '10.10.1.35', 'port' => 26379},
       {'host' => '10.10.1.36', 'port' => 26379},
     ]
   ```

1. Set up Sidekiq's connection to Gitaly:

   ```ruby
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly:8075' },
   })
   gitlab_rails['gitaly_token'] = 'YOUR_TOKEN'
   ```

1. Set up Sidekiq's connection to PostgreSQL:

   ```ruby
   gitlab_rails['db_host'] = '10.10.1.30'
   gitlab_rails['db_password'] = 'YOUR_PASSOWORD'
   gitlab_rails['db_port'] = '5432'
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['auto_migrate'] = false
   ```

   Remember to add the Sidekiq nodes to PostgreSQL's trusted addresses:

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 10.10.1.30/32 10.10.1.31/32 10.10.1.32/32 10.10.1.33/32 10.10.1.38/32)
   ```

1. If you run multiple Sidekiq nodes with a shared file storage, such as NFS, you must
   specify the UIDs and GIDs to ensure they match between servers. Specifying the UIDs
   and GIDs prevents permissions issues in the file system. This advice is similar to the
   [advice for Geo setups](geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site):

   ```ruby
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

1. Disable other services:

   ```ruby
   nginx['enable'] = false
   grafana['enable'] = false
   prometheus['enable'] = false
   gitlab_rails['auto_migrate'] = false
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_monitor['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   puma['enable'] = false
   gitlab_exporter['enable'] = false
   ```

1. If you're using the Container Registry and it's running on a different node than Sidekiq, then
   configure the registry URL:

   ```ruby
   registry_external_url 'https://registry.example.com'
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```
  
   You must also copy the `registry.key` file to each Sidekiq node.

1. Define the `external_url`. To maintain uniformity of links across nodes, the
   `external_url` on the Sidekiq server should point to the external URL that users
   will use to access GitLab. This will either be the `external_url` set on your
   application server or the URL of a external load balancer which will route traffic
   to the GitLab application server:

   ```ruby
   external_url 'https://gitlab.example.com'
   ```

1. (Optional) If you want to collect Sidekiq metrics, enable the Sidekiq metrics server.
   To make metrics available from `localhost:8082/metrics`, set the following values:

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = "8082"
   
   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. (Optional) If you use health check probes to observe Sidekiq,
   set a separate port for health checks.
   Configuring health checks is only necessary if there is something that actually probes them.
   For more information about health checks, see the [Sidekiq health check page](sidekiq_health_check.md).
   Enable health checks for Sidekiq:

    ```ruby
    sidekiq['health_checks_enabled'] = true
    sidekiq['health_checks_listen_address'] = "localhost"
    sidekiq['health_checks_listen_port'] = "8092"
   ```

   NOTE:
   If health check settings are not set, they will default to the metrics exporter settings.
   This default is deprecated and is set to be removed in [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/347509).

1. Run `gitlab-ctl reconfigure`.

You will need to restart the Sidekiq nodes after an update has occurred and database
migrations performed.

## Example configuration

Here's what the ending `/etc/gitlab/gitlab.rb` would look like:

```ruby
########################################
#####        Services Disabled       ###
########################################

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

########################################
####              Redis              ###
########################################

## Must be the same in every sentinel node
redis['master_name'] = 'gitlab-redis'

## The same password for Redis authentication you set up for the master node.
redis['master_password'] = 'YOUR_PASSOWORD'

## A list of sentinels with `host` and `port`
gitlab_rails['redis_sentinels'] = [
    {'host' => '10.10.1.34', 'port' => 26379},
    {'host' => '10.10.1.35', 'port' => 26379},
    {'host' => '10.10.1.36', 'port' => 26379},
  ]

#######################################
###              Gitaly             ###
#######################################

git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://gitaly:8075' },
})
gitlab_rails['gitaly_token'] = 'YOUR_TOKEN'

#######################################
###            Postgres             ###
#######################################
gitlab_rails['db_host'] = '10.10.1.30'
gitlab_rails['db_password'] = 'YOUR_PASSOWORD'
gitlab_rails['db_port'] = '5432'
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['auto_migrate'] = false

#######################################
###      Sidekiq configuration      ###
#######################################
sidekiq['metrics_enabled'] = true
sidekiq['exporter_log_enabled'] = false
sidekiq['listen_port'] = "8082"

sidekiq['health_checks_enabled'] = true
sidekiq['health_checks_listen_address'] = "localhost"
sidekiq['health_checks_listen_port'] = "8092"

#######################################
###     Monitoring configuration    ###
#######################################
consul['enable'] = true
consul['monitoring_service_discovery'] =  true

consul['configuration'] = {
  bind_addr: '10.10.1.48',
  retry_join: %w(10.10.1.34 10.10.1.35 10.10.1.36)
}

# Set the network addresses that the exporters will listen on
node_exporter['listen_address'] = '10.10.1.48:9100'

# Rails Status for prometheus
gitlab_rails['monitoring_whitelist'] = ['10.10.1.42', '127.0.0.1']

# Container Registry URL for cleanup jobs
registry_external_url 'https://registry.example.com'
gitlab_rails['registry_api_url'] = "https://registry.example.com"

# External URL (this should match the URL used to access your GitLab instance)
external_url 'https://gitlab.example.com'
```

## Further reading

Related Sidekiq configuration:

1. [Extra Sidekiq processes](operations/extra_sidekiq_processes.md)
1. [Extra Sidekiq routing](operations/extra_sidekiq_routing.md)
1. [Using the GitLab-Sidekiq chart](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)
1. [Sidekiq health checks](sidekiq_health_check.md)
