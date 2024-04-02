---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure an external Sidekiq instance

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can configure an external Sidekiq instance by using the Sidekiq that's bundled in the GitLab package. Sidekiq requires connection to the Redis,
PostgreSQL, and Gitaly instances.

## Configure TCP access for PostgreSQL, Gitaly, and Redis on the GitLab instance

By default, GitLab uses UNIX sockets and is not set up to communicate via TCP. To change this:

1. Edit the `/etc/gitlab/gitlab.rb` file on your GitLab instance, and add the following:

   ```ruby

   ## PostgreSQL

   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432

   # Add the Sidekiq nodes to PostgreSQL's trusted addresses.
   # In the following example, 10.10.1.30/32 is the private IP
   # of the Sidekiq server.
   postgresql['md5_auth_cidr_addresses'] = %w(127.0.0.1/32 10.10.1.30/32)
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 10.10.1.30/32)

   ## Gitaly

   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces
      listen_addr: '0.0.0.0:8075',
      auth: {
         ## Set up the Gitaly token as a form of authentication since you are accessing Gitaly over the network
         ## https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#about-the-gitaly-token
         token: 'abc123secret',
      },
   }

   gitaly['auth_token'] = ''
   praefect['configuration'][:auth][:token] = 'abc123secret'
   gitlab_rails['gitaly_token'] = 'abc123secret'

   ## Redis configuration

   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   # Password to Authenticate Redis
   redis['password'] = 'redis-password-goes-here'
   gitlab_rails['redis_password'] = 'redis-password-goes-here'

   ```

1. Run `reconfigure`:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart the `PostgreSQL` server:

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Set up Sidekiq instance

1. SSH into the Sidekiq server.

1. Confirm that you can access the PostgreSQL, Gitaly, and Redis ports:

   ```shell
   telnet <GitLab host> 5432 # PostgreSQL
   telnet <GitLab host> 8075 # Gitaly
   telnet <GitLab host> 6379 # Redis
   ```

1. [Download and install](https://about.gitlab.com/install/) the Linux package
   using steps 1 and 2. **Do not complete any other steps.**

1. Copy the `/etc/gitlab/gitlab.rb` file from the GitLab instance and add the following settings. Make sure
   to replace them with your values:

<!--
Updates to example must be made at:
- https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/sidekiq.md
- all reference architecture pages
-->

   ```ruby
   # https://docs.gitlab.com/omnibus/roles/#sidekiq-roles
   roles(["sidekiq_role"])

   ##
   ## To maintain uniformity of links across nodes, the
   ## `external_url` on the Sidekiq server should point to the external URL that users
   ## use to access GitLab. This can be either:
   ##
   ## - The `external_url` set on your application server.
   ## - The URL of a external load balancer, which routes traffic to the GitLab application server.
   ##
   external_url 'https://gitlab.example.com'

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   gitlab_rails['internal_api_url'] = 'GITLAB_URL'
   gitlab_shell['secret_token'] = 'SHELL_TOKEN'

   ########################################
   ####              Redis              ###
   ########################################

   ## Must be the same in every sentinel node.
   redis['master_name'] = 'gitlab-redis' # Required if you have set up redis cluster
   ## The same password for Redis authentication you set up for the master node.
   redis['master_password'] = '<redis_master_password>'

   ### If redis is running on the main Gitlab instance and you have opened the TCP port as above add the following
   gitlab_rails['redis_host'] = '<gitlab_host>'
   gitlab_rails['redis_port'] = 6379

   #######################################
   ###              Gitaly             ###
   #######################################

   ## Replace <gitaly_token> with the one you set up, see
   ## https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#about-the-gitaly-token
   git_data_dirs({
     "default" => {
        "gitaly_address" => "tcp://<gitlab_host>:8075",
        "gitaly_token" => "<gitaly_token>"
     }
   })

   #######################################
   ###            Postgres             ###
   #######################################

   # Replace <database_host> and <database_password>
   gitlab_rails['db_host'] = '<database_host>'
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_password'] = '<database_password>'
   ## Prevent database migrations from running on upgrade automatically
   gitlab_rails['auto_migrate'] = false

   #######################################
   ###      Sidekiq configuration      ###
   #######################################
   sidekiq['enable'] = true
   sidekiq['listen_address'] = "0.0.0.0"

   ## Set number of Sidekiq queue processes to the same number as available CPUs
   sidekiq['queue_groups'] = ['*'] * 4

   ## Set number of Sidekiq threads per queue process to the recommend number of 20
   sidekiq['max_concurrency'] = 20
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the GitLab instance and replace the file in the Sidekiq instance.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart the Sidekiq instance after completing the process and finishing the database migrations.

## Configure multiple Sidekiq nodes with shared storage

If you run multiple Sidekiq nodes with a shared file storage, such as NFS, you must
specify the UIDs and GIDs to ensure they match between servers. Specifying the UIDs
and GIDs prevents permissions issues in the file system. This advice is similar to the
[advice for Geo setups](../geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site).

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

## Configure the container registry when using an external Sidekiq

If you're using the container registry and it's running on a different
node than Sidekiq, follow the steps below.

1. Edit `/etc/gitlab/gitlab.rb`, and configure the registry URL:

   ```ruby
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. In the instance where container registry is hosted, copy the `registry.key`
   file to the Sidekiq node.

## Configure the Sidekiq metrics server

If you want to collect Sidekiq metrics, enable the Sidekiq metrics server.
To make metrics available from `localhost:8082/metrics`:

To configure the metrics server:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = 8082

   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Enable HTTPS

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364771) in GitLab 15.2.

To serve metrics via HTTPS instead of HTTP, enable TLS in the exporter settings:

1. Edit `/etc/gitlab/gitlab.rb` to add (or find and uncomment) the following lines:

   ```ruby
   sidekiq['exporter_tls_enabled'] = true
   sidekiq['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   sidekiq['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

When TLS is enabled, the same `port` and `address` are used as described above.
The metrics server cannot serve both HTTP and HTTPS at the same time.

## Configure health checks

If you use health check probes to observe Sidekiq, enable the Sidekiq health check server.
To make health checks available from `localhost:8092`:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['health_checks_enabled'] = true
   sidekiq['health_checks_listen_address'] = "localhost"
   sidekiq['health_checks_listen_port'] = 8092
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

For more information about health checks, see the [Sidekiq health check page](sidekiq_health_check.md).

## Configure LDAP and user or group synchronization

If you use LDAP for user and group management, you must add the LDAP configuration to your Sidekiq node as well as the LDAP
synchronization worker. If the LDAP configuration and LDAP synchronization worker are not applied to your Sidekiq node,
users and groups are not automatically synchronized.

For more information about configuring LDAP for GitLab, see:

- [GitLab LDAP configuration documentation](../auth/ldap/index.md#configure-ldap)
- [LDAP synchronization documentation](../auth/ldap/ldap_synchronization.md#adjust-ldap-user-sync-schedule)

To enable LDAP with the synchronization worker for Sidekiq:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['prevent_ldap_sign_in'] = false
   gitlab_rails['ldap_servers'] = {
   'main' => {
   'label' => 'LDAP',
   'host' => 'ldap.mydomain.com',
   'port' => 389,
   'uid' => 'sAMAccountName',
   'encryption' => 'simple_tls',
   'verify_certificates' => true,
   'bind_dn' => '_the_full_dn_of_the_user_you_will_bind_with',
   'password' => '_the_password_of_the_bind_user',
   'tls_options' => {
      'ca_file' => '',
      'ssl_version' => '',
      'ciphers' => '',
      'cert' => '',
      'key' => ''
   },
   'timeout' => 10,
   'active_directory' => true,
   'allow_username_or_email_login' => false,
   'block_auto_created_users' => false,
   'base' => 'dc=example,dc=com',
   'user_filter' => '',
   'attributes' => {
      'username' => ['uid', 'userid', 'sAMAccountName'],
      'email' => ['mail', 'email', 'userPrincipalName'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
   },
   'lowercase_usernames' => false,

   # Enterprise Edition only
   # https://docs.gitlab.com/ee/administration/auth/ldap/ldap_synchronization.html
   'group_base' => '',
   'admin_group' => '',
   'external_groups' => [],
   'sync_ssh_keys' => false
   }
   }
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure SAML Groups for SAML Group Sync

If you use [SAML Group Sync](../../user/group/saml_sso/group_sync.md), you must configure [SAML Groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) on all your Sidekiq nodes.

## Related topics

- [Extra Sidekiq processes](extra_sidekiq_processes.md)
- [Processing specific job classes](processing_specific_job_classes.md)
- [Sidekiq health checks](sidekiq_health_check.md)
- [Using the GitLab-Sidekiq chart](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)

## Troubleshooting

See our [administrator guide to troubleshooting Sidekiq](sidekiq_troubleshooting.md).
