---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치를 위한 독립 실행형 PostgreSQL
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

데이터베이스 서비스를 GitLab 애플리케이션 서버와 분리하여 호스팅하려면 Linux 패키지에 함께 패키지된 PostgreSQL 바이너리를 사용하여 이를 수행할 수 있습니다. 이는 [최대 40 RPS 또는 2,000명의 사용자를 지원하는 참조 아키텍처](../reference_architectures/2k_users.md)의 일부로 권장됩니다.

## 설정 {#setting-it-up}

1. PostgreSQL 서버에 SSH로 접속합니다.
1. GitLab 다운로드 페이지의 1단계와 2단계를 사용하여 원하는 Linux 패키지를 [다운로드하고 설치](https://about.gitlab.com/install/)합니다. 다운로드 페이지에서 다른 단계는 완료하지 마세요.
1. PostgreSQL을 위한 비밀번호 해시를 생성합니다. 기본 사용자 이름 `gitlab`(권장)을 사용하고 있다고 가정합니다. 명령어는 비밀번호와 확인을 요청합니다. 다음 단계에서 이 명령어에서 출력된 값을 `POSTGRESQL_PASSWORD_HASH`의 값으로 사용합니다.

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 아래의 내용을 추가하며, 자리 표시자 값을 적절하게 업데이트합니다.

   - `POSTGRESQL_PASSWORD_HASH` - 이전 단계에서 출력된 값
   - `APPLICATION_SERVER_IP_BLOCKS` - GitLab 애플리케이션 서버가 데이터베이스에 연결하는 IP 서브넷 또는 IP 주소의 공백으로 구분된 목록입니다. 예: `%w(123.123.123.123/32 123.123.123.234/32)`

   ```ruby
   # Disable all components except PostgreSQL
   roles(['postgres_role'])
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   redis_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432

   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'

   # Replace APPLICATION_SERVER_IP_BLOCKS with Network Address (XXX.XXX.XXX.XXX/YY)
   postgresql['trust_auth_cidr_addresses'] = %w(APPLICATION_SERVER_IP_BLOCKS)

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 합니다.
1. PostgreSQL 노드의 IP 주소 또는 호스트명, 포트 및 일반 텍스트 비밀번호를 확인합니다. 이는 나중에 GitLab 애플리케이션 서버를 구성할 때 필요합니다.
1. [모니터링 활성화](replication_and_failover.md#enable-monitoring)

고급 구성 옵션이 지원되며 필요한 경우 추가할 수 있습니다.
