---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Secure Redis and Sentinel by using TLS
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Redis TLS support introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6550) in GitLab 14.7.
- [Sentinel TLS support introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982) in GitLab 18.10.
- [Mutual TLS support introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982) in GitLab 18.10.

{{< /history >}}

Secure Redis and Sentinel communication using TLS (Transport Layer
Security). Both standard TLS (server certificate validation) and mutual
TLS (mTLS, where both client and server authenticate each other) are
supported.

If you enable TLS for Redis or Sentinel, you should enable it for
both Redis and Sentinel in your deployment. Mixing TLS and non-TLS
connections in the same environment can lead to configuration complexity
and potential security issues.

To disable the standard non-TLS port and only accept TLS connections,
set the port to 0 in your configuration. For example:

- Add `redis['port'] = 0` to disable the standard Redis port (6379).
- Add `sentinel['port'] = 0` to disable the standard Sentinel port (26379).

## Generate TLS certificate and key files

Before configuring TLS, you must generate or obtain the following
certificates and keys. These example filenames are used throughout:

- **CA certificate** (`ca.crt`): A certificate authority certificate to validate server certificates.
- **Server certificate** (`redis-server.crt`): A certificate for the Redis server (signed by the CA).
- **Server key** (`redis-server.key`): The private key for the Redis server certificate.
- **Sentinel server certificate** (`sentinel-server.crt`): A certificate for the Sentinel server (signed by the CA).
- **Sentinel server key** (`sentinel-server.key`): The private key for the Sentinel server certificate.
- **Client certificate** (`redis-client.crt`, for mTLS): A certificate for the client (signed by the CA).
- **Client key** (`redis-client.key`, for mTLS): The private key for the client certificate.

These examples use `/etc/gitlab/ssl/` as the certificate
directory, but you can store certificates in any directory as long as
the appropriate file permissions are set for the processes that need to
read them.

### Sample certificate generation script

The following script generates a complete set of certificates for Redis
and Sentinel with proper SANs. You must customize the IP addresses and
hostnames to match your actual infrastructure before running.

> [!warning]
> The CA private key (`ca.key`) is sensitive. After generating
> certificates, consider storing the CA private key securely offline
> and removing it from production servers.

1. Create a file named `generate-redis-certs.sh` with the following:

   ```shell
   #!/bin/bash

   # Configuration: CUSTOMIZE THESE VALUES FOR YOUR INFRASTRUCTURE
   CERT_DIR="/etc/gitlab/ssl"
   CA_CN="redis-ca"
   REDIS_HOSTNAMES="redis-primary,redis-replica-1,redis-replica-2"
   REDIS_IPS="10.0.0.1,10.0.0.2,10.0.0.3"
   SENTINEL_HOSTNAMES="sentinel-1,sentinel-2,sentinel-3"
   SENTINEL_IPS="10.0.0.1,10.0.0.2,10.0.0.3"
   CERT_DAYS=365

   mkdir -p "$CERT_DIR"

   # Create OpenSSL config for SAN extensions
   cat > /tmp/redis-san.conf << EOF
   [redis_server]
   subjectAltName = DNS:${REDIS_HOSTNAMES},IP:${REDIS_IPS}

   [sentinel_server]
   subjectAltName = DNS:${SENTINEL_HOSTNAMES},IP:${SENTINEL_IPS}

   [redis_client]
   subjectAltName = DNS:redis-client
   EOF

   # Generate CA certificate
   echo "Generating CA certificate..."
   openssl genrsa -out "$CERT_DIR/ca.key" 2048
   openssl req -new -x509 -days "$CERT_DAYS" -key "$CERT_DIR/ca.key" \
     -out "$CERT_DIR/ca.crt" -subj "/CN=$CA_CN"

   # Generate Redis server certificate
   echo "Generating Redis server certificate..."
   openssl genrsa -out "$CERT_DIR/redis-server.key" 2048
   openssl req -new -key "$CERT_DIR/redis-server.key" \
     -out "$CERT_DIR/redis-server.csr" -subj "/CN=redis-server"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/redis-server.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/redis-server.crt" \
     -extensions redis_server -extfile /tmp/redis-san.conf

   # Generate Sentinel server certificate
   echo "Generating Sentinel server certificate..."
   openssl genrsa -out "$CERT_DIR/sentinel-server.key" 2048
   openssl req -new -key "$CERT_DIR/sentinel-server.key" \
     -out "$CERT_DIR/sentinel-server.csr" -subj "/CN=sentinel-server"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/sentinel-server.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/sentinel-server.crt" \
     -extensions sentinel_server -extfile /tmp/redis-san.conf

   # Generate client certificate (for mTLS)
   echo "Generating Redis client certificate..."
   openssl genrsa -out "$CERT_DIR/redis-client.key" 2048
   openssl req -new -key "$CERT_DIR/redis-client.key" \
     -out "$CERT_DIR/redis-client.csr" -subj "/CN=redis-client"
   openssl x509 -req -days "$CERT_DAYS" -in "$CERT_DIR/redis-client.csr" \
     -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
     -out "$CERT_DIR/redis-client.crt" \
     -extensions redis_client -extfile /tmp/redis-san.conf

   # Clean up CSR files and temp config
   rm -f "$CERT_DIR"/*.csr /tmp/redis-san.conf

   # Set basic permissions (will be refined in the next steps)
   chmod 600 "$CERT_DIR"/*.key
   chmod 644 "$CERT_DIR"/*.crt

   echo "Certificates generated in $CERT_DIR"
   echo "Next: Configure file permissions based on your deployment (separate or shared nodes)"
   ```

1. Update these variables in the script to match your infrastructure:

   - `REDIS_HOSTNAMES`: Comma-separated list of all Redis server hostnames.
   - `REDIS_IPS`: Comma-separated list of all Redis server IP addresses.
   - `SENTINEL_HOSTNAMES`: Comma-separated list of all Sentinel server hostnames.
   - `SENTINEL_IPS`: Comma-separated list of all Sentinel server IP addresses.
   - `CERT_DAYS`: Certificate validity period in days (default: 365).

   The certificate must include all hostnames and IP addresses that clients
   use to connect to Redis or Sentinel. For example, if clients
   connect to `redis.example.com` and `10.0.0.1`, both must be in the SAN.
1. Run the script:

   ```shell
   chmod +x generate-redis-certs.sh
   sudo ./generate-redis-certs.sh
   ```

### Set certificate and key file permissions

By default, GitLab processes run as different users:

- Redis and Sentinel processes run as the `gitlab-redis` user.
- Puma (GitLab Rails), Workhorse, and KAS processes run as the `git` user.

After placing certificates and keys in `/etc/gitlab/ssl/`, ensure sufficient
file permissions so that all required processes can read them.

#### When running separate nodes

If Redis/Sentinel runs on a separate node (Redis on a different machine)
from the GitLab application:

1. On the Redis/Sentinel node, run these commands:

   ```shell
   # Set ownership to the gitlab-redis user (for Redis/Sentinel processes only)
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/redis-*.{crt,key}
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/sentinel-*.{crt,key}
   sudo chown gitlab-redis:gitlab-redis /etc/gitlab/ssl/ca.crt

   # Set restrictive permissions (readable by owner only)
   sudo chmod 600 /etc/gitlab/ssl/redis-*.key
   sudo chmod 600 /etc/gitlab/ssl/sentinel-*.key
   sudo chmod 644 /etc/gitlab/ssl/redis-*.crt
   sudo chmod 644 /etc/gitlab/ssl/sentinel-*.crt
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

1. On the GitLab application node (for mTLS client connections), run these commands:

   ```shell
   # For GitLab Rails, Workhorse, and KAS processes (running as 'git' user)
   sudo chown root:git /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:git /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

#### When running a shared node

If Redis/Sentinel and GitLab application processes run on the same node,
you must allow both `gitlab-redis` and `git` users to read the
certificates. Use a shared group approach.

1. On the shared node, run these commands:

   ```shell
   # Create a shared group for certificate access (if it doesn't exist)
   sudo groupadd -f gitlab-certs

   # Add both users to the shared group
   sudo usermod -a -G gitlab-certs gitlab-redis
   sudo usermod -a -G gitlab-certs git

   # Set ownership and permissions for server certificates (Redis/Sentinel)
   sudo chown gitlab-redis:gitlab-certs /etc/gitlab/ssl/redis-server.{crt,key}
   sudo chown gitlab-redis:gitlab-certs /etc/gitlab/ssl/sentinel-server.{crt,key}
   sudo chmod 640 /etc/gitlab/ssl/redis-server.key
   sudo chmod 644 /etc/gitlab/ssl/redis-server.crt
   sudo chmod 644 /etc/gitlab/ssl/sentinel-server.key
   sudo chmod 644 /etc/gitlab/ssl/sentinel-server.crt

   # Set ownership and permissions for client certificates (GitLab processes)
   sudo chown root:gitlab-certs /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:gitlab-certs /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

1. After making permission changes, restart GitLab:

   ```shell
   sudo gitlab-ctl restart
   ```

1. Verify that the processes can read the files by checking the logs:

   ```shell
   sudo gitlab-ctl tail
   ```

## Enable standard TLS

Standard TLS means the client validates the server's certificate. The
server does not require or validate a client certificate.

> [!note]
> The certificate file paths shown in the following examples (such as
> `/etc/gitlab/ssl/redis-server.crt`) are placeholders. Use the actual
> filenames generated by your certificate generation process. If you
> used the sample script above, the filenames will match these examples.

### Configure Redis with standard TLS

Configure the Redis primary with TLS:

1. Edit `/etc/gitlab/gitlab.rb` on the primary Redis server:

   ```ruby
   roles ['redis_master_role']

   redis['bind'] = '10.0.0.1'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the Redis replicas with TLS:

1. Edit `/etc/gitlab/gitlab.rb` on each replica Redis server:

   ```ruby
   roles ['redis_replica_role']

   redis['bind'] = '10.0.0.2'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['master_port'] = 6380  # Use TLS port

   # Enable TLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the GitLab application to connect to Redis with TLS:

1. Edit `/etc/gitlab/gitlab.rb` on the GitLab application server:

   ```ruby
   # Configure Redis with TLS
   gitlab_rails['redis_host'] = '10.0.0.1'
   gitlab_rails['redis_port'] = 6380
   gitlab_rails['redis_password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   gitlab_rails['redis_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Configure Sentinel with standard TLS

Configure the Sentinel servers with TLS:

1. Edit `/etc/gitlab/gitlab.rb` on each Sentinel server:

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Enable TLS for Sentinel
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the GitLab application to connect to Sentinel with TLS:

1. Edit `/etc/gitlab/gitlab.rb` on the GitLab application server:

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with TLS
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Enable TLS for Sentinel
   gitlab_rails['redis_sentinels_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Enable mutual TLS (mTLS)

Mutual TLS requires both the client and server to authenticate each
other using certificates.

### Configure Redis with mutual TLS

Configure the Redis primary with mTLS:

1. Edit `/etc/gitlab/gitlab.rb` on the primary Redis server:

   ```ruby
   roles ['redis_master_role']

   redis['bind'] = '10.0.0.1'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'

   # Enable mTLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'

   # Require client certificate validation
   redis['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the Redis replicas with mTLS:

1. Edit `/etc/gitlab/gitlab.rb` on each replica Redis server:

   ```ruby
   roles ['redis_replica_role']

   redis['bind'] = '10.0.0.2'
   redis['port'] = 6379
   redis['password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['master_port'] = 6380  # Use TLS port

   # Enable mTLS for Redis
   redis['tls_port'] = 6380
   redis['tls_cert_file'] = '/etc/gitlab/ssl/redis-server.crt'
   redis['tls_key_file'] = '/etc/gitlab/ssl/redis-server.key'
   redis['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   redis['tls_replication'] = 'yes'

   # Require client certificate validation
   redis['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the GitLab application to connect to Redis with mTLS:

1. Edit `/etc/gitlab/gitlab.rb` on the GitLab application server:

   ```ruby
   # Configure Redis with mTLS
   gitlab_rails['redis_host'] = '10.0.0.1'
   gitlab_rails['redis_port'] = 6380
   gitlab_rails['redis_password'] = 'redis-password-goes-here'

   # Enable TLS for Redis
   gitlab_rails['redis_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'

   # Provide client certificate and key for mTLS
   gitlab_rails['redis_tls_client_cert_file'] = '/etc/gitlab/ssl/redis-client.crt'
   gitlab_rails['redis_tls_client_key_file'] = '/etc/gitlab/ssl/redis-client.key'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

### Configure Sentinel with mutual TLS

Configure the Sentinel servers with mTLS:

1. Edit `/etc/gitlab/gitlab.rb` on each Sentinel server:

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Enable mTLS for Sentinel
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'

   # Require client certificate validation
   sentinel['tls_auth_clients'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the GitLab application to connect to Sentinel with mTLS:

1. Edit `/etc/gitlab/gitlab.rb` on the GitLab application server:

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with mTLS
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Enable TLS for Sentinel
   gitlab_rails['redis_sentinels_ssl'] = true

   # Provide CA certificate for validation
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'

   # Provide client certificate and key for mTLS
   gitlab_rails['redis_sentinels_tls_client_cert_file'] = '/etc/gitlab/ssl/redis-client.crt'
   gitlab_rails['redis_sentinels_tls_client_key_file'] = '/etc/gitlab/ssl/redis-client.key'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Secure Sentinel with a password

In addition to TLS, you can add password authentication to Sentinel. Password authentication is optional but recommended
for additional security.

### Configure Sentinel password

Set a password on Sentinel servers:

1. Edit `/etc/gitlab/gitlab.rb` on each Sentinel server:

   ```ruby
   roles ['redis_sentinel_role']

   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'
   redis['master_ip'] = '10.0.0.1'
   redis['port'] = 6379

   # Set Sentinel password
   sentinel['password'] = 'sentinel-password-goes-here'

   # TLS configuration (if enabled)
   sentinel['bind'] = '10.0.0.1'
   sentinel['port'] = 26379
   sentinel['tls_port'] = 26380
   sentinel['tls_cert_file'] = '/etc/gitlab/ssl/sentinel-server.crt'
   sentinel['tls_key_file'] = '/etc/gitlab/ssl/sentinel-server.key'
   sentinel['tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   sentinel['tls_replication'] = 'yes'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

Configure the GitLab application to authenticate with Sentinel:

1. Edit `/etc/gitlab/gitlab.rb` on the GitLab application server:

   ```ruby
   redis['master_name'] = 'gitlab-redis'
   redis['master_password'] = 'redis-password-goes-here'

   # Configure Sentinels with password authentication
   gitlab_rails['redis_sentinels'] = [
     { 'host' => '10.0.0.1', 'port' => 26380 },
     { 'host' => '10.0.0.2', 'port' => 26380 },
     { 'host' => '10.0.0.3', 'port' => 26380 }
   ]

   # Set Sentinel password
   gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here'

   # Enable TLS for Sentinel (if configured)
   gitlab_rails['redis_sentinels_ssl'] = true
   gitlab_rails['redis_sentinels_tls_ca_cert_file'] = '/etc/gitlab/ssl/ca.crt'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Verify TLS configuration

After configuring TLS, verify that the connections are working correctly:

1. Verify that Redis is listening on the TLS port (6380 by default):

   ```shell
   sudo netstat -tlnp | grep redis
   ```

   You should see Redis listening on both the standard port (6379) and the TLS port (6380).
1. Verify that Sentinel is listening on the TLS port (26380 by default):

   ```shell
   sudo netstat -tlnp | grep sentinel
   ```

   You should see Sentinel listening on both the standard port (26379) and the TLS port (26380).
1. Test the TLS connection to Redis using `redis-cli`:

   ```shell
   redis-cli --tls --cacert /etc/gitlab/ssl/ca.crt --cert /etc/gitlab/ssl/redis-client.crt --key /etc/gitlab/ssl/redis-client.key -h 10.0.0.1 -p 6380 ping
   ```

   For standard TLS (without client certificates), omit the `--cert` and `--key` options.
1. Monitor logs for any TLS-related errors:

   ```shell
   sudo gitlab-ctl tail redis
   sudo gitlab-ctl tail sentinel
   sudo gitlab-ctl tail gitlab-rails
   sudo gitlab-ctl tail gitlab-workhorse
   ```

1. On nodes that run GitLab Rails, check the generated configuration files to ensure TLS settings are present:

   ```shell
   cat /var/opt/gitlab/gitlab-rails/etc/resque.yml
   cat /var/opt/gitlab/gitlab-rails/etc/cable.yml
   ```

   You should see `ssl: true` and `ssl_params` with certificate paths.

## TLS configuration reference

Redis, Sentinel, and GitLab application (Rails) settings reference.

### Redis TLS settings

| Setting                     | Description |
|:----------------------------|:------------|
| `redis['port']`             | Standard Redis port (set to 0 to disable non-TLS port) |
| `redis['tls_port']`         | Port for TLS connections (default: 6380) |
| `redis['tls_cert_file']`    | Path to server certificate file |
| `redis['tls_key_file']`     | Path to server private key file |
| `redis['tls_ca_cert_file']` | Path to CA certificate file |
| `redis['tls_replication']`  | Enable TLS for replication (default: `no`) |
| `redis['tls_auth_clients']` | Require client certificate validation (default: `no`) |
| `redis['master_name']`      | Name of the Redis master (required for Sentinel) |
| `redis['master_password']`  | Password for the Redis master (required for Sentinel only if the Redis master has authentication enabled) |
| `redis['master_port']`      | Port of the Redis master (required if TLS is enabled for replication) |

### Sentinel TLS settings

| Setting                        | Description |
|:-------------------------------|:------------|
| `sentinel['port']`             | Standard Sentinel port (set to 0 to disable non-TLS port) |
| `sentinel['tls_port']`         | Port for TLS connections (default: 26380) |
| `sentinel['tls_cert_file']`    | Path to server certificate file |
| `sentinel['tls_key_file']`     | Path to server private key file |
| `sentinel['tls_ca_cert_file']` | Path to CA certificate file |
| `sentinel['tls_replication']`  | Enable TLS for replication (default: `no`) |
| `sentinel['tls_auth_clients']` | Require client certificate validation (default: `no`) |
| `sentinel['password']`         | Password for Sentinel authentication (optional) |

### GitLab Rails TLS settings

| Setting                                                | Description |
|:-------------------------------------------------------|:------------|
| `gitlab_rails['redis_ssl']`                            | Enable TLS for Redis connections (default: false) |
| `gitlab_rails['redis_sentinels_ssl']`                  | Enable TLS for Sentinel connections (default: false) |
| `gitlab_rails['redis_tls_ca_cert_file']`               | Path to CA certificate for Redis validation |
| `gitlab_rails['redis_tls_client_cert_file']`           | Path to client certificate for Redis mTLS |
| `gitlab_rails['redis_tls_client_key_file']`            | Path to client private key for Redis mTLS |
| `gitlab_rails['redis_sentinels_password']`             | Password for Sentinel authentication (optional) |
| `gitlab_rails['redis_sentinels_tls_ca_cert_file']`     | Path to CA certificate for Sentinel validation |
| `gitlab_rails['redis_sentinels_tls_client_cert_file']` | Path to client certificate for Sentinel mTLS |
| `gitlab_rails['redis_sentinels_tls_client_key_file']`  | Path to client private key for Sentinel mTLS |
| `redis_exporter['enable']`                             | Disable Redis exporter for multi-node Redis instances (set to false) |

## Troubleshooting

You might see the following error:

```plaintext
x509: certificate relies on legacy Common Name field, use SANs instead
```

To avoid this error, when generating certificates, ensure they include
**Subject Alternative Names (SANs)** instead of relying on the legacy Common Name field.
