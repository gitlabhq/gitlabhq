---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TLSを使用してRedisとSentinelをセキュアにする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 14.7で[RedisのTLSサポートが導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6550)されました。
- GitLab 18.10で[SentinelのTLSサポートが導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982)されました。
- GitLab 18.10で[相互TLSサポートが導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982)されました。

{{< /history >}}

TLS（Transport Layer Security）を使用してRedisとSentinelの通信を保護します。標準TLS（サーバー証明書の検証）と相互TLS（クライアントとサーバーが相互に認証するmTLS）の両方がサポートされています。

RedisまたはSentinelでTLSを有効にする場合、デプロイでRedisとSentinelの両方に対して有効にする必要があります。同じ環境でTLSと非TLS接続を混在させると、設定が複雑になり、潜在的なセキュリティ問題につながる可能性があります。

標準の非TLSポートを無効にしてTLS接続のみを受け入れるには、設定でポートを0に設定します。例: 

- 標準のRedisポート (6379) を無効にするには、`redis['port'] = 0`を追加します。
- 標準のSentinelポート (26379) を無効にするには、`sentinel['port'] = 0`を追加します。

## TLS証明書とキーファイルを生成する {#generate-tls-certificate-and-key-files}

TLSを設定する前に、以下の証明書とキーを生成または取得する必要があります。これらのファイル名が全体を通して使用されます:

- **CA certificate** (`ca.crt`): サーバー証明書を検証するための認証局証明書。
- **Server certificate** (`redis-server.crt`): Redisサーバー用の証明書（認証局によって署名されています）。
- **Server key** (`redis-server.key`): Redisサーバー証明書の秘密キー。
- **Sentinel server certificate** (`sentinel-server.crt`): Sentinelサーバー用の証明書（認証局によって署名されています）。
- **Sentinel server key** (`sentinel-server.key`): Sentinelサーバー証明書の秘密キー。
- **Client certificate** (`redis-client.crt`、mTLS用): クライアント用の証明書（認証局によって署名されています）。
- **Client key** (`redis-client.key`、mTLS用): クライアント証明書の秘密キー。

これらの例では`/etc/gitlab/ssl/`を証明書ディレクトリとして使用していますが、証明書を読み取る必要があるプロセスに適切なファイルパーミッションが設定されている限り、任意のディレクトリに証明書を保存できます。

### 証明書生成スクリプトのサンプル {#sample-certificate-generation-script}

次のスクリプトは、適切なSANを持つRedisおよびSentinel用の完全な証明書セットを生成します。実行する前に、実際のインフラストラクチャに合わせてIPアドレスとホスト名をカスタマイズする必要があります。

> [!warning]
> 認証局の秘密キー (`ca.key`) は機密情報です。証明書を生成した後、認証局の秘密キーをオフラインで安全に保管し、本番環境サーバーから削除することを検討してください。

1. `generate-redis-certs.sh`という名前のファイルを以下で作成します:

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

1. スクリプト内のこれらの変数をインフラストラクチャに合わせて更新します:

   - `REDIS_HOSTNAMES`: すべてのRedisサーバーホスト名のコンマ区切りリスト。
   - `REDIS_IPS`: すべてのRedisサーバーIPアドレスのコンマ区切りリスト。
   - `SENTINEL_HOSTNAMES`: すべてのSentinelサーバーホスト名のコンマ区切りリスト。
   - `SENTINEL_IPS`: すべてのSentinelサーバーIPアドレスのコンマ区切りリスト。
   - `CERT_DAYS`: 証明書の有効期間 (日数) (デフォルト: 365)。

   証明書には、クライアントがRedisまたはSentinelへの接続に使用するすべてのホスト名とIPアドレスを含める必要があります。たとえば、クライアントが`redis.example.com`と`10.0.0.1`に接続する場合、両方がSANに含まれている必要があります。
1. スクリプトを実行します:

   ```shell
   chmod +x generate-redis-certs.sh
   sudo ./generate-redis-certs.sh
   ```

### 証明書およびキーファイルのパーミッションを設定する {#set-certificate-and-key-file-permissions}

デフォルトでは、GitLabプロセスは異なるユーザーとして実行されます:

- RedisおよびSentinelプロセスは`gitlab-redis`ユーザーとして実行されます。
- Puma (GitLab Rails)、Workhorse、およびKASプロセスは`git`ユーザーとして実行されます。

証明書とキーを`/etc/gitlab/ssl/`に配置した後、必要なすべてのプロセスがそれらを読み取りできる十分なファイルパーミッションが確保されていることを確認します。

#### 個別のノードで実行する場合 {#when-running-separate-nodes}

Redis/SentinelがGitLabアプリケーションとは別のノード（Redisが異なるマシン上）で実行される場合:

1. Redis/Sentinelノードで、これらのコマンドを実行します:

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

1. GitLabアプリケーションノード（mTLSクライアント接続用）で、これらのコマンドを実行します:

   ```shell
   # For GitLab Rails, Workhorse, and KAS processes (running as 'git' user)
   sudo chown root:git /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:git /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

#### 共有ノードで実行する場合 {#when-running-a-shared-node}

Redis/SentinelとGitLabアプリケーションプロセスが同じノードで実行される場合、`gitlab-redis`と`git`の両方のユーザーが証明書を読み取りできる必要があります。共有グループアプローチを使用します。

1. 共有ノードで、これらのコマンドを実行します:

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

1. パーミッションの変更を行った後、GitLabを再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```

1. ログをチェックして、プロセスがファイルを読み取りできることを検証します:

   ```shell
   sudo gitlab-ctl tail
   ```

## 標準TLSを有効にする {#enable-standard-tls}

標準TLSとは、クライアントがサーバーの証明書を検証することを意味します。サーバーはクライアント証明書を要求または検証しません。

> [!note]
> 以下の例に示されている証明書ファイルパス（`/etc/gitlab/ssl/redis-server.crt`など）はプレースホルダーです。証明書生成プロセスによって生成された実際のファイル名を使用します。上記のサンプルスクリプトを使用した場合は、ファイル名がこれらの例と一致します。

### 標準TLSでRedisを設定する {#configure-redis-with-standard-tls}

TLSでRedisプライマリを設定します:

1. プライマリRedisサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

TLSでRedisレプリカを設定します:

1. 各Redisレプリカサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

TLSでRedisに接続するようにGitLabアプリケーションを設定します:

1. GitLabアプリケーションサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### 標準TLSでSentinelを設定する {#configure-sentinel-with-standard-tls}

TLSでSentinelサーバーを設定します:

1. 各Sentinelサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

TLSでSentinelに接続するようにGitLabアプリケーションを設定します:

1. GitLabアプリケーションサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 相互TLS (mTLS) を有効にする {#enable-mutual-tls-mtls}

相互TLSでは、クライアントとサーバーの両方が証明書を使用して相互に認証する必要があります。

### 相互TLSでRedisを設定する {#configure-redis-with-mutual-tls}

mTLSでRedisプライマリを設定します:

1. プライマリRedisサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

mTLSでRedisレプリカを設定します:

1. 各Redisレプリカサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

mTLSでRedisに接続するようにGitLabアプリケーションを設定します:

1. GitLabアプリケーションサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### 相互TLSでSentinelを設定する {#configure-sentinel-with-mutual-tls}

mTLSでSentinelサーバーを設定します:

1. 各Sentinelサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

mTLSでSentinelに接続するようにGitLabアプリケーションを設定します:

1. GitLabアプリケーションサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## パスワードでSentinelを保護する {#secure-sentinel-with-a-password}

TLSに加えて、Sentinelにパスワード認証を追加できます。パスワード認証はオプションですが、追加のセキュリティのために推奨されます。

### Sentinelのパスワードを設定する {#configure-sentinel-password}

Sentinelサーバーにパスワードを設定します:

1. 各Sentinelサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

Sentinelで認証するようにGitLabアプリケーションを設定します:

1. GitLabアプリケーションサーバーで`/etc/gitlab/gitlab.rb`を編集します:

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

1. 変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## TLS設定を検証する {#verify-tls-configuration}

TLSを設定した後、接続が正しく機能していることを検証します:

1. RedisがTLSポート (6380、デフォルト) でリッスンしていることを検証します:

   ```shell
   sudo netstat -tlnp | grep redis
   ```

   Redisが標準ポート (6379) とTLSポート (6380) の両方でリッスンしていることを確認してください。
1. SentinelがTLSポート (26380、デフォルト) でリッスンしていることを検証します:

   ```shell
   sudo netstat -tlnp | grep sentinel
   ```

   Sentinelが標準ポート (26379) とTLSポート (26380) の両方でリッスンしていることを確認してください。
1. `redis-cli`を使用してRedisへのTLS接続をテストします:

   ```shell
   redis-cli --tls --cacert /etc/gitlab/ssl/ca.crt --cert /etc/gitlab/ssl/redis-client.crt --key /etc/gitlab/ssl/redis-client.key -h 10.0.0.1 -p 6380 ping
   ```

   標準TLS（クライアント証明書なし）の場合、`--cert`と`--key`オプションを省略します。
1. TLS関連のエラーがないかログを監視します:

   ```shell
   sudo gitlab-ctl tail redis
   sudo gitlab-ctl tail sentinel
   sudo gitlab-ctl tail gitlab-rails
   sudo gitlab-ctl tail gitlab-workhorse
   ```

1. GitLab Railsを実行するノードで、生成された設定ファイルを確認し、TLS設定が存在することを確認します:

   ```shell
   cat /var/opt/gitlab/gitlab-rails/etc/resque.yml
   cat /var/opt/gitlab/gitlab-rails/etc/cable.yml
   ```

   証明書パスとともに`ssl: true`と`ssl_params`が表示されるはずです。

## TLS設定リファレンス {#tls-configuration-reference}

Redis、Sentinel、およびGitLabアプリケーション (Rails) の設定リファレンス。

### Redis TLS設定 {#redis-tls-settings}

| 設定                     | 説明 |
|:----------------------------|:------------|
| `redis['port']`             | 標準Redisポート（非TLSポートを無効にするには0に設定） |
| `redis['tls_port']`         | TLS接続用のポート（デフォルト: 6380) |
| `redis['tls_cert_file']`    | サーバー証明書ファイルへのパス |
| `redis['tls_key_file']`     | サーバー秘密キーファイルへのパス |
| `redis['tls_ca_cert_file']` | CA証明書ファイルへのパス |
| `redis['tls_replication']`  | レプリケーションのためにTLSを有効にする（デフォルト: `no`） |
| `redis['tls_auth_clients']` | クライアント証明書の検証を要求する（デフォルト: `no`） |
| `redis['master_name']`      | Redisマスターの名前（Sentinelに必須） |
| `redis['master_password']`  | Redisマスターのパスワード（Redisマスターで認証が有効になっている場合にのみSentinelに必須） |
| `redis['master_port']`      | Redisマスターのポート（レプリケーションのためにTLSが有効になっている場合に必須） |

### Sentinel TLS設定 {#sentinel-tls-settings}

| 設定                        | 説明 |
|:-------------------------------|:------------|
| `sentinel['port']`             | 標準Sentinelポート（非TLSポートを無効にするには0に設定） |
| `sentinel['tls_port']`         | TLS接続用のポート（デフォルト: 26380) |
| `sentinel['tls_cert_file']`    | サーバー証明書ファイルへのパス |
| `sentinel['tls_key_file']`     | サーバー秘密キーファイルへのパス |
| `sentinel['tls_ca_cert_file']` | CA証明書ファイルへのパス |
| `sentinel['tls_replication']`  | レプリケーションのためにTLSを有効にする（デフォルト: `no`） |
| `sentinel['tls_auth_clients']` | クライアント証明書の検証を要求する（デフォルト: `no`） |
| `sentinel['password']`         | Sentinel認証用のパスワード（オプション） |

### GitLab Rails TLS設定 {#gitlab-rails-tls-settings}

| 設定                                                | 説明 |
|:-------------------------------------------------------|:------------|
| `gitlab_rails['redis_ssl']`                            | Redis接続のTLSを有効にする（デフォルト: false） |
| `gitlab_rails['redis_sentinels_ssl']`                  | Sentinel接続のTLSを有効にする（デフォルト: false） |
| `gitlab_rails['redis_tls_ca_cert_file']`               | Redis検証用のCA証明書へのパス |
| `gitlab_rails['redis_tls_client_cert_file']`           | Redis mTLS用のクライアント証明書へのパス |
| `gitlab_rails['redis_tls_client_key_file']`            | Redis mTLS用のクライアント秘密キーへのパス |
| `gitlab_rails['redis_sentinels_password']`             | Sentinel認証用のパスワード（オプション） |
| `gitlab_rails['redis_sentinels_tls_ca_cert_file']`     | Sentinel検証用のCA証明書へのパス |
| `gitlab_rails['redis_sentinels_tls_client_cert_file']` | Sentinel mTLS用のクライアント証明書へのパス |
| `gitlab_rails['redis_sentinels_tls_client_key_file']`  | Sentinel mTLS用のクライアント秘密キーへのパス |
| `redis_exporter['enable']`                             | マルチノードRedisインスタンス用のRedis exporterを無効にする (falseに設定) |

## トラブルシューティング {#troubleshooting}

次のエラーが表示される場合があります:

```plaintext
x509: certificate relies on legacy Common Name field, use SANs instead
```

このエラーを回避するには、証明書を生成する際に、従来のCommon Nameフィールドに依存するのではなく、**Subject Alternative Names (SANs)**を含めるようにします。
