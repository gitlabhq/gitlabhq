---
reading_time: true
---

# Reference architecture: up to 2,000 users

This page describes GitLab reference architecture for up to 2,000 users.
For a full list of reference architectures, see
[Available reference architectures](index.md#available-reference-architectures).

> - **Supported users (approximate):** 2,000
> - **High Availability:** False
> - **Test requests per second (RPS) rates:** API: 40 RPS, Web: 4 RPS, Git: 4 RPS

| Service                                                      | Nodes     | Configuration                   | GCP           | AWS                   | Azure          |
|--------------------------------------------------------------|-----------|---------------------------------|---------------|-----------------------|----------------|
| Load balancer                                                | 1         | 2 vCPU, 1.8GB memory            | n1-highcpu-2  | c5.large              | F2s v2         |
| Object storage                                               | n/a       | n/a                             | n/a           | n/a                   | n/a            |
| NFS server (optional, not recommended)                       | 1         | 4 vCPU, 3.6GB memory            | n1-highcpu-4  | c5.xlarge             | F4s v2         |
| PostgreSQL                                                   | 1         | 2 vCPU, 7.5GB memory            | n1-standard-2 | m5.large              | D2s v3         |
| Redis                                                        | 1         | 1 vCPU, 3.75GB memory           | n1-standard-1 | m5.large              | D2s v3         |
| Gitaly                                                       | 1         | 4 vCPU, 15GB memory             | n1-standard-4 | m5.xlarge             | D4s v3         |
| GitLab Rails                                                 | 2         | 8 vCPU, 7.2GB memory            | n1-highcpu-8  | c5.2xlarge            | F8s v2         |
| Monitoring node                                              | 1         | 2 vCPU, 1.8GB memory            | n1-highcpu-2  | c5.large              | F2s v2         |

The Google Cloud Platform (GCP) architectures were built and tested using the
[Intel Xeon E5 v3 (Haswell)](https://cloud.google.com/compute/docs/cpu-platforms)
CPU platform. On different hardware you may find that adjustments, either lower
or higher, are required for your CPU or node counts. For more information, see
our [Sysbench](https://github.com/akopytov/sysbench)-based
[CPU benchmark](https://gitlab.com/gitlab-org/quality/performance/-/wikis/Reference-Architectures/GCP-CPU-Benchmarks).

AWS-equivalent and Azure-equivalent configurations are rough suggestions that
may change in the future, and haven't been tested or validated.

Due to better performance and availability, for data objects (such as LFS,
uploads, or artifacts), using an [object storage service](#configure-the-object-storage)
is recommended instead of using NFS. Using an object storage service also
doesn't require you to provision and maintain a node.

## Setup components

To set up GitLab and its components to accommodate up to 2,000 users:

1. [Configure the external load balancing node](#configure-the-load-balancer)
   to handle the load balancing of the two GitLab application services nodes.
1. [Configure the object storage](#configure-the-object-storage) used for
   shared data objects.
1. [Configure NFS](#configure-nfs-optional) (optional, and not recommended)
   to have shared disk storage service as an alternative to Gitaly or object
   storage. You can skip this step if you're not using GitLab Pages (which
   requires NFS).
1. [Configure PostgreSQL](#configure-postgresql), the database for GitLab.
1. [Configure Redis](#configure-redis).
1. [Configure Gitaly](#configure-gitaly), which provides access to the Git
   repositories.
1. [Configure the main GitLab Rails application](#configure-gitlab-rails)
   to run Puma/Unicorn, Workhorse, GitLab Shell, and to serve all frontend
   requests (which include UI, API, and Git over HTTP/SSH).
1. [Configure Prometheus](#configure-prometheus) to monitor your GitLab
   environment.

## Configure the load balancer

NOTE: **Note:**
This architecture has been tested and validated with [HAProxy](https://www.haproxy.org/).
Although you can use a load balancer with a similar set of features, GitLab
hasn't validated other load balancers.

In an active/active GitLab configuration, you'll need a load balancer to route
traffic to the application servers. The specifics for which load balancer to
use or its exact configuration is out of scope for the GitLab documentation.
If you're managing multi-node systems (including GitLab) you'll probably
already have a load balancer of choice. Some examples including HAProxy
(open-source), F5 Big-IP LTM, and Citrix Net Scaler. This documentation
includes the ports and protocols for use with GitLab.

The next question is how you will handle SSL in your environment. There are
several different options:

- [The application node terminates SSL](#application-node-terminates-ssl).
- [The load balancer terminates SSL without backend SSL](#load-balancer-terminates-ssl-without-backend-ssl)
  and communication is not secure between the load balancer and the application node.
- [The load balancer terminates SSL with backend SSL](#load-balancer-terminates-ssl-with-backend-ssl)
  and communication is *secure* between the load balancer and the application node.

### Application node terminates SSL

Configure your load balancer to pass connections on port 443 as `TCP` instead
of `HTTP(S)`. This will pass the connection unaltered to the application node's
NGINX service, which has the SSL certificate and listens to port 443.

For details about managing SSL certificates and configuring NGINX, see the
[NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https).

### Load balancer terminates SSL without backend SSL

Configure your load balancer to use the `HTTP(S)` protocol instead of `TCP`.
The load balancer will be responsible for both managing SSL certificates and
terminating SSL.

Due to communication between the load balancer and GitLab not being secure,
you'll need to complete some additional configuration. For details, see the
[NGINX proxied SSL documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#supporting-proxied-ssl).

### Load balancer terminates SSL with backend SSL

Configure your load balancers (or single balancer, if you have only one) to use
the `HTTP(S)` protocol rather than `TCP`. The load balancers will be
responsible for the managing SSL certificates for end users.

Traffic will be secure between the load balancers and NGINX in this scenario,
and there's no need to add a configuration for proxied SSL. However, you'll
need to add a configuration to GitLab to configure SSL certificates. For
details about managing SSL certificates and configuring NGINX, see the
[NGINX HTTPS documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https).

### Ports

The basic load balancer ports you should use are described in the following
table:

| Port    | Backend Port | Protocol                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP or HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*): [Web terminal](../../ci/environments/index.md#web-terminals) support
  requires your load balancer to correctly handle WebSocket connections.
  When using HTTP or HTTPS proxying, your load balancer must be configured
  to pass through the `Connection` and `Upgrade` hop-by-hop headers. For
  details, see the [web terminal](../integration/terminal.md) integration guide.
- (*2*): When using the HTTPS protocol for port 443, you'll need to add an SSL
  certificate to the load balancers. If you need to terminate SSL at the
  GitLab application server, use the TCP protocol.

If you're using GitLab Pages with custom domain support you will need some
additional port configurations. GitLab Pages requires a separate virtual IP
address. Configure DNS to point the `pages_external_url` from
`/etc/gitlab/gitlab.rb` to the new virtual IP address. For more information,
see the [GitLab Pages documentation](../pages/index.md).

| Port    | Backend Port  | Protocol  |
| ------- | ------------- | --------- |
| 80      | Varies (*1*)  | HTTP      |
| 443     | Varies (*1*)  | TCP (*2*) |

- (*1*): The backend port for GitLab Pages depends on the
  `gitlab_pages['external_http']` and `gitlab_pages['external_https']`
  settings. For details, see the [GitLab Pages documentation](../pages/index.md).
- (*2*): Port 443 for GitLab Pages must use the TCP protocol. Users can
  configure custom domains with custom SSL, which wouldn't be possible if SSL
  was terminated at the load balancer.

#### Alternate SSH Port

Some organizations have policies against opening SSH port 22. In this case,
it may be helpful to configure an alternate SSH hostname that instead allows
users to use SSH over port 443. An alternate SSH hostname requires a new
virtual IP address compared to the previously described GitLab HTTP
configuration.

Configure DNS for an alternate SSH hostname, such as `altssh.gitlab.example.com`:

| LB Port | Backend Port | Protocol |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure the object storage

GitLab supports using an object storage service for holding several types of
data, and is recommended over [NFS](#configure-nfs-optional). In general,
object storage services are better for larger environments, as object storage
is typically much more performant, reliable, and scalable.

Object storage options that GitLab has either tested or is aware of customers
using, includes:

- SaaS/Cloud solutions (such as [Amazon S3](https://aws.amazon.com/s3/) or
  [Google Cloud Storage](https://cloud.google.com/storage)).
- On-premises hardware and appliances, from various storage vendors.
- MinIO ([Deployment guide](https://docs.gitlab.com/charts/advanced/external-object-storage/minio.html)).

To configure GitLab to use object storage, refer to the following guides based
on the features you intend to use:

1. [Object storage for backups](../../raketasks/backup_restore.md#uploading-backups-to-a-remote-cloud-storage).
1. [Object storage for job artifacts](../job_artifacts.md#using-object-storage)
   including [incremental logging](../job_logs.md#new-incremental-logging-architecture).
1. [Object storage for LFS objects](../lfs/index.md#storing-lfs-objects-in-remote-object-storage).
1. [Object storage for uploads](../uploads.md#using-object-storage-core-only).
1. [Object storage for merge request diffs](../merge_request_diffs.md#using-object-storage).
1. [Object storage for Container Registry](../packages/container_registry.md#container-registry-storage-driver) (optional feature).
1. [Object storage for Mattermost](https://docs.mattermost.com/administration/config-settings.html#file-storage) (optional feature).
1. [Object storage for packages](../packages/index.md#using-object-storage) (optional feature). **(PREMIUM ONLY)**
1. [Object storage for Dependency Proxy](../packages/dependency_proxy.md#using-object-storage) (optional feature). **(PREMIUM ONLY)**
1. [Object storage for Pseudonymizer](../pseudonymizer.md#configuration) (optional feature). **(ULTIMATE ONLY)**
1. [Object storage for autoscale Runner caching](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching) (optional, for improved performance).
1. [Object storage for Terraform state files](../terraform_state.md#using-object-storage-core-only).

Using separate buckets for each data type is the recommended approach for GitLab.

A limitation of our configuration is that each use of object storage is
separately configured. We have an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/23345)
for improving this, which would allow for one bucket with separate folders.

Using a single bucket when GitLab is deployed with the Helm chart causes
restoring from a backup to
[not function properly](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-pseudonymizer).
Although you may not be using a Helm deployment right now, if you migrate
GitLab to a Helm deployment later, GitLab would still work, but you may not
realize backups aren't working correctly until a critical requirement for
functioning backups is encountered.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure NFS (optional)

For improved performance, [object storage](#configure-the-object-storage),
along with [Gitaly](#configure-gitaly), are recommended over using NFS whenever
possible. However, if you intend to use GitLab Pages,
[you must use NFS](troubleshooting.md#gitlab-pages-requires-nfs).

For information about configuring NFS, see the [NFS documentation page](../high_availability/nfs.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure PostgreSQL

In this section, you'll be guided through configuring an external PostgreSQL database
to be used with GitLab.

### Provide your own PostgreSQL instance

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed relational
database service (RDS) that runs PostgreSQL.

If you use a cloud-managed service, or provide your own PostgreSQL:

1. Set up PostgreSQL according to the
   [database requirements document](../../install/requirements.md#database).
1. Create a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring the GitLab Rails application](#configure-gitlab-rails).

### Standalone PostgreSQL using Omnibus GitLab

1. SSH into the PostgreSQL server.
1. [Download/install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
   - Do not complete any other steps on the download page.
1. Generate a password hash for PostgreSQL. This assumes you will use the default
   username of `gitlab` (recommended). The command will request a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `POSTGRESQL_PASSWORD_HASH`.

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the contents below, updating placeholder
   values appropriately.

   - `POSTGRESQL_PASSWORD_HASH` - The value output from the previous step
   - `APPLICATION_SERVER_IP_BLOCKS` - A space delimited list of IP subnets or IP
     addresses of the GitLab application servers that will connect to the
     database. Example: `%w(123.123.123.123/32 123.123.123.234/32)`

   ```ruby
   # Disable all components except PostgreSQL
   roles ['postgres_role']
   repmgr['enable'] = false
   consul['enable'] = false
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   redis_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   postgres_exporter['listen_address'] = '0.0.0.0:9187'
   postgres_exporter['dbname'] = 'gitlabhq_production'
   postgres_exporter['password'] = 'POSTGRESQL_PASSWORD_HASH'

   # Set the PostgreSQL address and port
   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432

   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'

   # Replace APPLICATION_SERVER_IP_BLOCK with the CIDR address of the application node
   postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.1/32 APPLICATION_SERVER_IP_BLOCK)

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Note the PostgreSQL node's IP address or hostname, port, and
   plain text password. These will be necessary when configuring the [GitLab
   application server](#configure-gitlab-rails) later.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/database.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Redis

In this section, you'll be guided through configuring an external Redis instance
to be used with GitLab.

### Provide your own Redis instance

Redis version 5.0 or higher is required, as this is what ships with
Omnibus GitLab packages starting with GitLab 13.0. Older Redis versions
do not support an optional count argument to SPOP which is now required for
[Merge Trains](../../ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md).

In addition, GitLab makes use of certain commands like `UNLINK` and `USAGE` which
were introduced only in Redis 4.

Managed Redis from cloud providers such as AWS ElastiCache will work. If these
services support high availability, be sure it is not the Redis Cluster type.

Note the Redis node's IP address or hostname, port, and password (if required).
These will be necessary when configuring the
[GitLab application servers](#configure-gitlab-rails) later.

### Standalone Redis using Omnibus GitLab

The Omnibus GitLab package can be used to configure a standalone Redis server.
The steps below are the minimum necessary to configure a Redis server with
Omnibus:

1. SSH into the Redis server.
1. [Download/install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
     - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   ## Enable Redis
   redis['enable'] = true

   ## Disable all other services
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   puma['enable'] = false
   unicorn['enable'] = false
   postgresql['enable'] = false
   nginx['enable'] = false
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   gitlab_exporter['enable'] = false
   gitaly['enable'] = false
   grafana['enable'] = false

   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = 'SECRET_PASSWORD_HERE'

   gitlab_rails['enable'] = false

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   redis_exporter['flags'] = {
         'redis.addr' => 'redis://0.0.0.0:6379',
         'redis.password' => 'SECRET_PASSWORD_HERE',
   }
   ```

1. [Reconfigure Omnibus GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Note the Redis node's IP address or hostname, port, and
   Redis password. These will be necessary when [configuring the GitLab
   application servers](#configure-gitlab-rails) later.

Advanced [configuration options](https://docs.gitlab.com/omnibus/settings/redis.html)
are supported and can be added if needed.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Gitaly

Deploying Gitaly in its own server can benefit GitLab installations that are
larger than a single machine. Gitaly node requirements are dependent on data,
specifically the number of projects and their sizes. It's recommended that each
Gitaly node store no more than 5TB of data. Your 2K setup may require one or more
nodes depending on your repository storage requirements.

We strongly recommend that all Gitaly nodes should be set up with SSD disks with a throughput of at least
8,000 IOPS for read operations and 2,000 IOPS for write, as Gitaly has heavy I/O.
These IOPS values are recommended only as a starter as with time they may be
adjusted higher or lower depending on the scale of your environment's workload.
If you're running the environment on a Cloud provider
you may need to refer to their documentation on how configure IOPS correctly.

Some things to note:

- The GitLab Rails application shards repositories into [repository storages](../repository_storage_paths.md).
- A Gitaly server can host one or more storages.
- A GitLab server can use one or more Gitaly servers.
- Gitaly addresses must be specified in such a way that they resolve
  correctly for ALL Gitaly clients.
- Gitaly servers must not be exposed to the public internet, as Gitaly's network
  traffic is unencrypted by default. The use of a firewall is highly recommended
  to restrict access to the Gitaly server. Another option is to
  [use TLS](#gitaly-tls-support).

TIP: **Tip:**
For more information about Gitaly's history and network architecture see the
[standalone Gitaly documentation](../gitaly/index.md).

Note: **Note:** The token referred to throughout the Gitaly documentation is
just an arbitrary password selected by the administrator. It is unrelated to
tokens created for the GitLab API or other similar web API tokens.

Below we describe how to configure one Gitaly server `gitaly1.internal` with
secret token `gitalysecret`. We assume your GitLab installation has two
repository storages: `default` and `storage1`.

To configure the Gitaly server:

1. [Download/Install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page but
   **without** providing the `EXTERNAL_URL` value.
1. Edit `/etc/gitlab/gitlab.rb` to configure storage paths, enable
   the network listener and configure the token:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   ```ruby
   # /etc/gitlab/gitlab.rb

   # Gitaly and GitLab use two shared secrets for authentication, one to authenticate gRPC requests
   # to Gitaly, and a second for authentication callbacks from GitLab-Shell to the GitLab internal API.
   # The following two values must be the same as their respective values
   # of the GitLab Rails application setup
   gitaly['auth_token'] = 'gitlaysecret'
   gitlab_shell['secret_token'] = 'shellsecret'

   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   unicorn['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false

   # If you run a seperate monitoring node you can disable these services
   alertmanager['enable'] = false
   prometheus['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['rake_cache_clear'] = false
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from web server to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # Make Gitaly accept connections on all network interfaces. You must use
   # firewalls to restrict access to this address/port.
   # Comment out following line if you only want to support TLS connections
   gitaly['listen_addr'] = "0.0.0.0:8075"
   gitaly['prometheus_listen_addr'] = "0.0.0.0:9236"

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   ```

1. Append the following to `/etc/gitlab/gitlab.rb` on `gitaly1.internal`:

   ```ruby
   git_data_dirs({
     'default' => {
       'path' => '/var/opt/gitlab/git-data'
     },
     'storage1' => {
       'path' => '/mnt/gitlab/git-data'
     },
   })
   ```

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Confirm that Gitaly can perform callbacks to the internal API:

   ```shell
   sudo /opt/gitlab/embedded/service/gitlab-shell/bin/check -config /opt/gitlab/embedded/service/gitlab-shell/config.yml
   ```

### Gitaly TLS support

Gitaly supports TLS encryption. To be able to communicate
with a Gitaly instance that listens for secure connections you will need to use `tls://` URL
scheme in the `gitaly_address` of the corresponding storage entry in the GitLab configuration.

You will need to bring your own certificates as this isn't provided automatically.
The certificate, or its certificate authority, must be installed on all Gitaly
nodes (including the Gitaly node using the certificate) and on all client nodes
that communicate with it following the procedure described in
[GitLab custom certificate configuration](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).

NOTE: **Note**
The self-signed certificate must specify the address you use to access the
Gitaly server. If you are addressing the Gitaly server by a hostname, you can
either use the Common Name field for this, or add it as a Subject Alternative
Name. If you are addressing the Gitaly server by its IP address, you must add it
as a Subject Alternative Name to the certificate.
[gRPC does not support using an IP address as Common Name in a certificate](https://github.com/grpc/grpc/issues/2691).

NOTE: **Note:**
It is possible to configure Gitaly servers with both an
unencrypted listening address `listen_addr` and an encrypted listening
address `tls_listen_addr` at the same time. This allows you to do a
gradual transition from unencrypted to encrypted traffic, if necessary.

To configure Gitaly with TLS:

1. Create the `/etc/gitlab/ssl` directory and copy your key and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Copy the cert to `/etc/gitlab/trusted-certs` so Gitaly will trust the cert when
   calling into itself:

   ```shell
   sudo cp /etc/gitlab/ssl/cert.pem /etc/gitlab/trusted-certs/
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   <!--
   updates to following example must also be made at
   https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
   -->

   ```ruby
   gitaly['tls_listen_addr'] = "0.0.0.0:9999"
   gitaly['certificate_path'] = "/etc/gitlab/ssl/cert.pem"
   gitaly['key_path'] = "/etc/gitlab/ssl/key.pem"
   ```

1. Delete `gitaly['listen_addr']` to allow only encrypted connections.
1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure GitLab Rails

NOTE: **Note:**
In our architectures we run each GitLab Rails node using the Puma webserver
and have its number of workers set to 90% of available CPUs along with four threads. For
nodes that are running Rails with other components the worker value should be reduced
accordingly where we've found 50% achieves a good balance but this is dependent
on workload.

This section describes how to configure the GitLab application (Rails) component.
On each node perform the following:

1. If you're [using NFS](#configure-nfs-optional):

   1. If necessary, install the NFS client utility packages using the following
      commands:

      ```shell
      # Ubuntu/Debian
      apt-get install nfs-common

      # CentOS/Red Hat
      yum install nfs-utils nfs-utils-lib
      ```

   1. Specify the necessary NFS mounts in `/etc/fstab`.
      The exact contents of `/etc/fstab` will depend on how you chose
      to configure your NFS server. See the [NFS documentation](../high_availability/nfs.md)
      for examples and the various options.

   1. Create the shared directories. These may be different depending on your NFS
      mount locations.

      ```shell
      mkdir -p /var/opt/gitlab/.ssh /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/git-data
      ```

1. Download/install Omnibus GitLab using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/install/). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   To maintain uniformity of links across nodes, the `external_url`
   on the application server should point to the external URL that users will use
   to access GitLab. This would be the URL of the [load balancer](#configure-the-load-balancer)
   which will route traffic to the GitLab application server:

   ```ruby
   external_url 'https://gitlab.example.com'

   # Gitaly and GitLab use two shared secrets for authentication, one to authenticate gRPC requests
   # to Gitaly, and a second for authentication callbacks from GitLab-Shell to the GitLab internal API.
   # The following two values must be the same as their respective values
   # of the Gitaly setup
   gitlab_rails['gitaly_token'] = 'gitalyecret'
   gitlab_shell['secret_token'] = 'shellsecret'

   git_data_dirs({
     'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   })

   ## Disable components that will not be on the GitLab application server
   roles ['application_role']
   gitaly['enable'] = false
   nginx['enable'] = true

   ## PostgreSQL connection details
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['db_host'] = '10.1.0.5' # IP/hostname of database server
   gitlab_rails['db_password'] = 'DB password'

   ## Redis connection details
   gitlab_rails['redis_port'] = '6379'
   gitlab_rails['redis_host'] = '10.1.0.6' # IP/hostname of Redis server
   gitlab_rails['redis_password'] = 'Redis Password'

   # Set the network addresses that the exporters used for monitoring will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
   sidekiq['listen_address'] = "0.0.0.0"
   puma['listen'] = '0.0.0.0'

   # Add the monitoring node's IP address to the monitoring whitelist and allow it to
   # scrape the NGINX metrics. Replace placeholder `monitoring.gitlab.example.com` with
   # the address and/or subnets gathered from the monitoring node
   gitlab_rails['monitoring_whitelist'] = ['<MONITOR NODE IP>/32', '127.0.0.0/8']
   nginx['status']['options']['allow'] = ['<MONITOR NODE IP>/32', '127.0.0.0/8']

   ## Uncomment and edit the following options if you have set up NFS
   ##
   ## Prevent GitLab from starting if NFS data mounts are not available
   ##
   #high_availability['mountpoint'] = '/var/opt/gitlab/git-data'
   ##
   ## Ensure UIDs and GIDs match between servers for permissions via NFS
   ##
   #user['uid'] = 9000
   #user['gid'] = 9000
   #web_server['uid'] = 9001
   #web_server['gid'] = 9001
   #registry['uid'] = 9002
   #registry['gid'] = 9002
   ```

1. If you're using [Gitaly with TLS support](#gitaly-tls-support), make sure the
   `git_data_dirs` entry is configured with `tls` instead of `tcp`:

   ```ruby
   git_data_dirs({
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   })
   ```

   1. Copy the cert into `/etc/gitlab/trusted-certs`:

      ```shell
      sudo cp cert.pem /etc/gitlab/trusted-certs/
      ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. Run `sudo gitlab-rake gitlab:gitaly:check` to confirm the node can connect to Gitaly.
1. Tail the logs to see the requests:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

NOTE: **Note:** When you specify `https` in the `external_url`, as in the example
above, GitLab assumes you have SSL certificates in `/etc/gitlab/ssl/`. If
certificates are not present, NGINX will fail to start. See the
[NGINX documentation](https://docs.gitlab.com/omnibus/settings/nginx.html#enable-https)
for more information.

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Configure Prometheus

The Omnibus GitLab package can be used to configure a standalone Monitoring node
running [Prometheus](../monitoring/prometheus/index.md) and
[Grafana](../monitoring/performance/grafana_configuration.md):

1. SSH into the Monitoring node.
1. [Download/install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
   Do not complete any other steps on the download page.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   external_url 'http://gitlab.example.com'

   # Enable Prometheus
   prometheus['enable'] = true
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable Login form
   grafana['disable_login_form'] = false

   # Enable Grafana
   grafana['enable'] = true
   grafana['admin_password'] = 'toomanysecrets'

   # Disable all other services
   gitlab_rails['auto_migrate'] = false
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = true
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   sidekiq['enable'] = false
   puma['enable'] = false
   unicorn['enable'] = false
   node_exporter['enable'] = false
   gitlab_exporter['enable'] = false
   ```

1. Prometheus also needs some scrape configs to pull all the data from the various
   nodes where we configured exporters. Assuming that your nodes' IPs are:

   ```plaintext
   1.1.1.1: postgres
   1.1.1.2: redis
   1.1.1.3: gitaly1
   1.1.1.4: rails1
   1.1.1.5: rails2
   ```

   Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   prometheus['scrape_configs'] = [
     {
        'job_name': 'postgres',
        'static_configs' => [
        'targets' => ['1.1.1.1:9187'],
        ],
     },
     {
        'job_name': 'redis',
        'static_configs' => [
        'targets' => ['1.1.1.2:9121'],
        ],
     },
     {
        'job_name': 'gitaly',
        'static_configs' => [
        'targets' => ['1.1.1.3:9236'],
        ],
     },
     {
        'job_name': 'gitlab-nginx',
        'static_configs' => [
        'targets' => ['1.1.1.4:8060', '1.1.1.5:8060'],
        ],
     },
     {
        'job_name': 'gitlab-workhorse',
        'static_configs' => [
        'targets' => ['1.1.1.4:9229', '1.1.1.5:9229'],
        ],
     },
     {
        'job_name': 'gitlab-rails',
        'metrics_path': '/-/metrics',
        'static_configs' => [
        'targets' => ['1.1.1.4:8080', '1.1.1.5:8080'],
        ],
     },
     {
        'job_name': 'gitlab-sidekiq',
        'static_configs' => [
        'targets' => ['1.1.1.4:8082', '1.1.1.5:8082'],
        ],
     },
     {
        'job_name': 'node',
        'static_configs' => [
        'targets' => ['1.1.1.1:9100', '1.1.1.2:9100', '1.1.1.3:9100', '1.1.1.4:9100', '1.1.1.5:9100'],
        ],
     },
   ]
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).
1. In the GitLab UI, set `admin/application_settings/metrics_and_profiling` > Metrics - Grafana to `/-/grafana` to
`http[s]://<MONITOR NODE>/-/grafana`

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>

## Troubleshooting

See the [troubleshooting documentation](troubleshooting.md).

<div align="right">
  <a type="button" class="btn btn-default" href="#setup-components">
    Back to setup components <i class="fa fa-angle-double-up" aria-hidden="true"></i>
  </a>
</div>
