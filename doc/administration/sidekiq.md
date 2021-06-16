---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
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
   sidekiq['listen_address'] = "10.10.1.48"

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
sidekiq['listen_address'] = "10.10.1.48"

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
```

## Further reading

Related Sidekiq configuration:

1. [Extra Sidekiq processes](operations/extra_sidekiq_processes.md)
1. [Extra Sidekiq routing](operations/extra_sidekiq_routing.md)
1. [Using the GitLab-Sidekiq chart](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)
