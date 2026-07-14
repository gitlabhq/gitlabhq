---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL 서버 내보내기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[PostgreSQL 서버 내보내기](https://github.com/prometheus-community/postgres_exporter)를 사용하면 다양한 PostgreSQL 메트릭을 내보낼 수 있습니다.

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

PostgreSQL 서버 내보내기를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집하고 `postgres_exporter`을 활성화합니다:

   ```ruby
   postgres_exporter['enable'] = true
   ```

   PostgreSQL 서버 내보내기가 별도의 노드에 구성된 경우, 로컬 주소가 [`trust_auth_cidr_addresses`에 나열되어 있는지](../../postgresql/replication_and_failover.md#network-information) 확인하거나 내보내기가 데이터베이스에 연결할 수 없습니다.

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

Prometheus는 `localhost:9187` 아래에 공개된 PostgreSQL 서버 내보내기에서 성능 데이터를 수집하기 시작합니다.

## 고급 구성 {#advanced-configuration}

대부분의 경우 PostgreSQL 서버 내보내기는 기본값으로 작동하며 아무것도 변경할 필요가 없습니다. PostgreSQL 서버 내보내기를 추가로 사용자 지정하려면 다음 구성 옵션을 사용합니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   # The name of the database to connect to.
   postgres_exporter['dbname'] = 'pgbouncer'
   # The user to sign in as.
   postgres_exporter['user'] = 'gitlab-psql'
   # The user's password.
   postgres_exporter['password'] = ''
   # The host to connect to. Values that start with '/' are for unix domain sockets
   # (default is 'localhost').
   postgres_exporter['host'] = 'localhost'
   # The port to bind to (default is '5432').
   postgres_exporter['port'] = 5432
   # Whether or not to use SSL. Valid options are:
   #   'disable' (no SSL),
   #   'require' (always use SSL and skip verification, this is the default value),
   #   'verify-ca' (always use SSL and verify that the certificate presented by
   #   the server was signed by a trusted CA),
   #   'verify-full' (always use SSL and verify that the certification presented
   #   by the server was signed by a trusted CA and the server host name matches
   #   the one in the certificate).
   postgres_exporter['sslmode'] = 'require'
   # An application_name to fall back to if one isn't provided.
   postgres_exporter['fallback_application_name'] = ''
   # Maximum wait for connection, in seconds. Zero or not specified means wait indefinitely.
   postgres_exporter['connect_timeout'] = ''
   # Cert file location. The file must contain PEM encoded data.
   postgres_exporter['sslcert'] = 'ssl.crt'
   # Key file location. The file must contain PEM encoded data.
   postgres_exporter['sslkey'] = 'ssl.key'
   # The location of the root certificate file. The file must contain PEM encoded data.
   postgres_exporter['sslrootcert'] = 'ssl-root.crt'
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.
