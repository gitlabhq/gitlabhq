---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TLS를 사용하여 Redis 및 Sentinel 보안 설정
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Redis TLS 지원 도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/6550)됨 (GitLab 14.7)
- [Sentinel TLS 지원 도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982)됨 (GitLab 18.10)
- [Mutual TLS 지원 도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/477982)됨 (GitLab 18.10)

{{< /history >}}

TLS(전송 계층 보안)를 사용하여Redis와 Sentinel 통신을 보호합니다. 표준 TLS(서버 인증서 검증) 및 상호 TLS(mTLS, 클라이언트와 서버가 서로 인증)가 모두 지원됩니다.

Redis 또는 Sentinel에 대해 TLS를 활성화하는 경우, 배포에서 Redis와 Sentinel 모두에 대해 활성화해야 합니다. 같은 환경에서 TLS와 비 TLS 연결을 혼합하면 구성의 복잡성과 잠재적 보안 이슈가 발생할 수 있습니다.

표준 비 TLS 포트를 비활성화하고 TLS 연결만 수락하려면 구성에서 포트를 0으로 설정하세요. 예를 들어:

- `redis['port'] = 0`을(를) 추가하여 표준 Redis 포트(6379)를 비활성화합니다.
- `sentinel['port'] = 0`을(를) 추가하여 표준 Sentinel 포트(26379)를 비활성화합니다.

## TLS 인증서 및 키 파일 생성 {#generate-tls-certificate-and-key-files}

TLS를 구성하기 전에 다음 인증서와 키를 생성하거나 획득해야 합니다. 다음은 전체 문서에서 사용되는 예제 파일 이름입니다:

- **CA certificate**(`ca.crt`):  서버 인증서를 검증할 인증 기관 인증서입니다.
- **Server certificate**(`redis-server.crt`):  Redis 서버에 대한 인증서(CA로 서명됨)입니다.
- **Server key**(`redis-server.key`):  Redis 서버 인증서에 대한 개인 키입니다.
- **Sentinel server certificate**(`sentinel-server.crt`):  Sentinel 서버에 대한 인증서(CA로 서명됨)입니다.
- **Sentinel server key**(`sentinel-server.key`):  Sentinel 서버 인증서에 대한 개인 키입니다.
- **Client certificate**(`redis-client.crt`, mTLS용):  클라이언트에 대한 인증서(CA로 서명됨)입니다.
- **Client key**(`redis-client.key`, mTLS용):  클라이언트 인증서에 대한 개인 키입니다.

이 예제는 `/etc/gitlab/ssl/`을(를) 인증서 디렉터리로 사용하지만, 프로세스가 인증서를 읽을 수 있도록 적절한 파일 권한이 설정되어 있으면 모든 디렉터리에 인증서를 저장할 수 있습니다.

### 샘플 인증서 생성 스크립트 {#sample-certificate-generation-script}

다음 스크립트는 적절한 SAN을 포함하는 Redis 및 Sentinel에 대한 완전한 인증서 세트를 생성합니다. 실행하기 전에 IP 주소와 호스트 이름을 실제 인프라와 일치하도록 사용자 정의해야 합니다.

> [!warning]
> CA 개인 키(`ca.key`)는 민감한 정보입니다. 인증서를 생성한 후 CA 개인 키를 안전하게 오프라인에 저장하고 프로덕션 서버에서 제거하는 것을 고려하세요.

1. `generate-redis-certs.sh` 파일을 생성하고 다음을 포함하세요:

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

1. 스크립트의 이러한 변수를 인프라와 일치하도록 업데이트하세요:

   - `REDIS_HOSTNAMES`:  모든 Redis 서버 호스트 이름의 쉼표 구분 목록입니다.
   - `REDIS_IPS`:  모든 Redis 서버 IP 주소의 쉼표 구분 목록입니다.
   - `SENTINEL_HOSTNAMES`:  모든 Sentinel 서버 호스트 이름의 쉼표 구분 목록입니다.
   - `SENTINEL_IPS`:  모든 Sentinel 서버 IP 주소의 쉼표 구분 목록입니다.
   - `CERT_DAYS`:  인증서 유효 기간(일)(기본값:  365).

   인증서에는 클라이언트가 Redis 또는 Sentinel에 연결하는 데 사용하는 모든 호스트 이름 및 IP 주소가 포함되어야 합니다. 예를 들어 클라이언트가 `redis.example.com` 및 `10.0.0.1`에 연결하는 경우 둘 다 SAN에 포함되어야 합니다.
1. 스크립트를 실행하세요:

   ```shell
   chmod +x generate-redis-certs.sh
   sudo ./generate-redis-certs.sh
   ```

### 인증서 및 키 파일 권한 설정 {#set-certificate-and-key-file-permissions}

기본적으로 GitLab 프로세스는 다른 사용자로 실행됩니다:

- Redis 및 Sentinel 프로세스는 `gitlab-redis` 사용자로 실행됩니다.
- Puma(GitLab Rails), Workhorse 및 KAS 프로세스는 `git` 사용자로 실행됩니다.

인증서와 키를 `/etc/gitlab/ssl/`에 배치한 후 모든 필요한 프로세스가 인증서를 읽을 수 있도록 충분한 파일 권한이 있는지 확인하세요.

#### 별도 노드 실행 {#when-running-separate-nodes}

Redis/Sentinel이 GitLab 애플리케이션과 다른 노드(다른 머신의 Redis)에서 실행되는 경우:

1. Redis/Sentinel 노드에서 다음 명령을 실행하세요:

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

1. GitLab 애플리케이션 노드(mTLS 클라이언트 연결용)에서 다음 명령을 실행하세요:

   ```shell
   # For GitLab Rails, Workhorse, and KAS processes (running as 'git' user)
   sudo chown root:git /etc/gitlab/ssl/redis-client.{crt,key}
   sudo chown root:git /etc/gitlab/ssl/ca.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.crt
   sudo chmod 640 /etc/gitlab/ssl/redis-client.key
   sudo chmod 644 /etc/gitlab/ssl/ca.crt
   ```

#### 공유 노드 실행 {#when-running-a-shared-node}

Redis/Sentinel 및 GitLab 애플리케이션 프로세스가 같은 노드에서 실행되는 경우 `gitlab-redis` 및 `git` 사용자 모두에게 인증서를 읽을 수 있는 권한을 부여해야 합니다. 공유 그룹 방식을 사용하세요.

1. 공유 노드에서 다음 명령을 실행하세요:

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

1. 권한 변경 후 GitLab을 다시 시작하세요:

   ```shell
   sudo gitlab-ctl restart
   ```

1. 로그를 확인하여 프로세스가 파일을 읽을 수 있는지 확인하세요:

   ```shell
   sudo gitlab-ctl tail
   ```

## 표준 TLS 활성화 {#enable-standard-tls}

표준 TLS는 클라이언트가 서버의 인증서를 검증함을 의미합니다. 서버는 클라이언트 인증서를 요구하거나 검증하지 않습니다.

> [!note]
> 다음 예제에 표시된 인증서 파일 경로(예: `/etc/gitlab/ssl/redis-server.crt`)는 자리 표시자입니다. 인증서 생성 프로세스로 생성된 실제 파일 이름을 사용하세요. 위의 샘플 스크립트를 사용한 경우 파일 이름이 이 예제와 일치합니다.

### 표준 TLS로 Redis 구성 {#configure-redis-with-standard-tls}

TLS로 Redis 주 데이터베이스를 구성합니다:

1. 주 Redis 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

TLS로 Redis 복제본을 구성합니다:

1. 각 복제본 Redis 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab 애플리케이션이 TLS로 Redis에 연결하도록 구성합니다:

1. GitLab 애플리케이션 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### 표준 TLS로 Sentinel 구성 {#configure-sentinel-with-standard-tls}

TLS로 Sentinel 서버를 구성합니다:

1. 각 Sentinel 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab 애플리케이션이 TLS로 Sentinel에 연결하도록 구성합니다:

1. GitLab 애플리케이션 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

## 상호 TLS(mTLS) 활성화 {#enable-mutual-tls-mtls}

상호 TLS는 클라이언트와 서버가 모두 인증서를 사용하여 서로를 인증해야 함을 의미합니다.

### 상호 TLS로 Redis 구성 {#configure-redis-with-mutual-tls}

mTLS로 Redis 주 데이터베이스를 구성합니다:

1. 주 Redis 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

mTLS로 Redis 복제본을 구성합니다:

1. 각 복제본 Redis 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab 애플리케이션이 mTLS로 Redis에 연결하도록 구성합니다:

1. GitLab 애플리케이션 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### 상호 TLS로 Sentinel 구성 {#configure-sentinel-with-mutual-tls}

mTLS로 Sentinel 서버를 구성합니다:

1. 각 Sentinel 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab 애플리케이션이 mTLS로 Sentinel에 연결하도록 구성합니다:

1. GitLab 애플리케이션 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

## 비밀번호로 Sentinel 보안 설정 {#secure-sentinel-with-a-password}

TLS 외에도 Sentinel에 비밀번호 인증을 추가할 수 있습니다. 비밀번호 인증은 선택 사항이지만 추가 보안을 위해 권장됩니다.

### Sentinel 비밀번호 구성 {#configure-sentinel-password}

Sentinel 서버에서 비밀번호를 설정하세요:

1. 각 Sentinel 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

GitLab 애플리케이션을 Sentinel로 인증하도록 구성합니다:

1. GitLab 애플리케이션 서버에서 `/etc/gitlab/gitlab.rb`을(를) 편집하세요:

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

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

## TLS 구성 확인 {#verify-tls-configuration}

TLS를 구성한 후 연결이 올바르게 작동하는지 확인하세요:

1. Redis가 TLS 포트(기본값 6380)에서 수신 대기 중인지 확인합니다:

   ```shell
   sudo netstat -tlnp | grep redis
   ```

   Redis가 표준 포트(6379)와 TLS 포트(6380) 모두에서 수신 대기 중인 것을 확인해야 합니다.
1. Sentinel이 TLS 포트(기본값 26380)에서 수신 대기 중인지 확인합니다:

   ```shell
   sudo netstat -tlnp | grep sentinel
   ```

   Sentinel이 표준 포트(26379)와 TLS 포트(26380) 모두에서 수신 대기 중인 것을 확인해야 합니다.
1. `redis-cli`을(를) 사용하여 Redis에 대한 TLS 연결을 테스트합니다:

   ```shell
   redis-cli --tls --cacert /etc/gitlab/ssl/ca.crt --cert /etc/gitlab/ssl/redis-client.crt --key /etc/gitlab/ssl/redis-client.key -h 10.0.0.1 -p 6380 ping
   ```

   표준 TLS(클라이언트 인증서 없음)의 경우 `--cert` 및 `--key` 옵션을 생략하세요.
1. TLS 관련 오류에 대해 로그를 모니터링합니다:

   ```shell
   sudo gitlab-ctl tail redis
   sudo gitlab-ctl tail sentinel
   sudo gitlab-ctl tail gitlab-rails
   sudo gitlab-ctl tail gitlab-workhorse
   ```

1. GitLab Rails를 실행하는 노드에서 생성된 구성 파일을 확인하여 TLS 설정이 있는지 확인합니다:

   ```shell
   cat /var/opt/gitlab/gitlab-rails/etc/resque.yml
   cat /var/opt/gitlab/gitlab-rails/etc/cable.yml
   ```

   인증서 경로와 함께 `ssl: true` 및 `ssl_params`이(가) 표시되어야 합니다.

## TLS 구성 참조 {#tls-configuration-reference}

Redis, Sentinel 및 GitLab 애플리케이션(Rails) 설정 참조입니다.

### Redis TLS 설정 {#redis-tls-settings}

| 설정                     | 설명 |
|:----------------------------|:------------|
| `redis['port']`             | 표준 Redis 포트(비 TLS 포트를 비활성화하려면 0으로 설정) |
| `redis['tls_port']`         | TLS 연결용 포트(기본값:  6380) |
| `redis['tls_cert_file']`    | 서버 인증서 파일의 경로 |
| `redis['tls_key_file']`     | 서버 개인 키 파일의 경로 |
| `redis['tls_ca_cert_file']` | CA 인증서 파일의 경로 |
| `redis['tls_replication']`  | 복제에 대해 TLS 활성화(기본값: `no`) |
| `redis['tls_auth_clients']` | 클라이언트 인증서 검증 필요(기본값: `no`) |
| `redis['master_name']`      | Redis 마스터의 이름(Sentinel에 필수) |
| `redis['master_password']`  | Redis 마스터의 비밀번호(Redis 마스터에 인증이 활성화된 경우 Sentinel에만 필수) |
| `redis['master_port']`      | Redis 마스터의 포트(복제에 TLS가 활성화된 경우 필수) |

### Sentinel TLS 설정 {#sentinel-tls-settings}

| 설정                        | 설명 |
|:-------------------------------|:------------|
| `sentinel['port']`             | 표준 Sentinel 포트(비 TLS 포트를 비활성화하려면 0으로 설정) |
| `sentinel['tls_port']`         | TLS 연결용 포트(기본값:  26380) |
| `sentinel['tls_cert_file']`    | 서버 인증서 파일의 경로 |
| `sentinel['tls_key_file']`     | 서버 개인 키 파일의 경로 |
| `sentinel['tls_ca_cert_file']` | CA 인증서 파일의 경로 |
| `sentinel['tls_replication']`  | 복제에 대해 TLS 활성화(기본값: `no`) |
| `sentinel['tls_auth_clients']` | 클라이언트 인증서 검증 필요(기본값: `no`) |
| `sentinel['password']`         | Sentinel 인증을 위한 비밀번호(선택 사항) |

### GitLab Rails TLS 설정 {#gitlab-rails-tls-settings}

| 설정                                                | 설명 |
|:-------------------------------------------------------|:------------|
| `gitlab_rails['redis_ssl']`                            | Redis 연결에 대해 TLS 활성화(기본값: false) |
| `gitlab_rails['redis_sentinels_ssl']`                  | Sentinel 연결에 대해 TLS 활성화(기본값: false) |
| `gitlab_rails['redis_tls_ca_cert_file']`               | Redis 검증을 위한 CA 인증서 경로 |
| `gitlab_rails['redis_tls_client_cert_file']`           | Redis mTLS용 클라이언트 인증서 경로 |
| `gitlab_rails['redis_tls_client_key_file']`            | Redis mTLS용 클라이언트 개인 키 경로 |
| `gitlab_rails['redis_sentinels_password']`             | Sentinel 인증을 위한 비밀번호(선택 사항) |
| `gitlab_rails['redis_sentinels_tls_ca_cert_file']`     | Sentinel 검증을 위한 CA 인증서 경로 |
| `gitlab_rails['redis_sentinels_tls_client_cert_file']` | Sentinel mTLS용 클라이언트 인증서 경로 |
| `gitlab_rails['redis_sentinels_tls_client_key_file']`  | Sentinel mTLS용 클라이언트 개인 키 경로 |
| `redis_exporter['enable']`                             | 다중 노드 Redis 인스턴스에 대해 Redis 내보내기 비활성화(false로 설정) |

## 문제 해결 {#troubleshooting}

다음 오류가 표시될 수 있습니다:

```plaintext
x509: certificate relies on legacy Common Name field, use SANs instead
```

이 오류를 방지하려면 인증서를 생성할 때 **Subject Alternative Names (SANs)**을(를) 포함하도록 하고 레거시 공통 이름 필드에 의존하지 않도록 하세요.
