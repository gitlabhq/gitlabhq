---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure an external Sidekiq instance
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can configure an external Sidekiq instance by using the Sidekiq that's bundled in the GitLab package. Sidekiq requires connection to the Redis,
PostgreSQL, and Gitaly instances.

## Configure TCP access for PostgreSQL, Gitaly, and Redis on the GitLab instance

By default, GitLab uses UNIX sockets and is not set up to communicate via TCP. To change this:

1. [Configure packaged PostgreSQL server to listen on TCP/IP](https://docs.gitlab.com/omnibus/settings/database.html#configure-packaged-postgresql-server-to-listen-on-tcpip) adding the Sidekiq server IP addresses to `postgresql['md5_auth_cidr_addresses']`
1. [Make the bundled Redis reachable via TCP](https://docs.gitlab.com/omnibus/settings/redis.html#making-the-bundled-redis-reachable-via-tcp)
1. Edit the `/etc/gitlab/gitlab.rb` file on your GitLab instance, and add the following:

   ```ruby
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

   gitlab_rails['gitaly_token'] = 'abc123secret'

   # Password to Authenticate Redis
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

Find [your reference architecture](../reference_architectures/_index.md#available-reference-architectures) and follow the Sidekiq instance setup details.

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

- [GitLab LDAP configuration documentation](../auth/ldap/_index.md#configure-ldap)
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
