---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 여러 노드에 대한 Geo 설정
description: "다중 노드 환경에서 Geo를 구성합니다. 프라이머리 및 세컨더리 사이트 설정, 데이터베이스 복제, 추적 데이터베이스 구성, 로드 밸런서 통합을 다룹니다."
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 문서는 다중 노드 구성에서 Geo를 실행하기 위한 최소 참조 아키텍처를 설명합니다. 다중 노드 설정이 설명된 것과 다르면 이러한 지침을 사용자의 필요에 맞게 조정할 수 있습니다.

이 가이드는 여러 애플리케이션 노드(Sidekiq 또는 GitLab Rails)가 있는 설치에 적용됩니다. 외부 PostgreSQL을 사용하는 단일 노드 설치의 경우 [두 개의 단일 노드 사이트에 대한 Geo 설정(외부 PostgreSQL 서비스 포함)](../setup/two_single_node_external_services.md)을 따르고 다른 외부 서비스를 사용하는 경우 구성을 조정하세요.

## 아키텍처 개요 {#architecture-overview}

![프라이머리 및 세컨더리 백엔드 서비스를 사용한 다중 노드 구성에서 Geo를 실행하기 위한 아키텍처](img/geo-ha-diagram_v11_11.png)

**[다이어그램 소스 - GitLab 팀 구성원만 해당](https://docs.google.com/drawings/d/1z0VlizKiLNXVVVaERFwgsIOuEgjcUqDTWPdQYsE7Z4c/edit)**

토폴로지 다이어그램은 **프라이머리** 및 **세컨더리** Geo 사이트가 두 개의 별도 위치에 있고 자체 가상 네트워크의 프라이빗 IP 주소를 사용한다고 가정합니다. 네트워크는 한 지역의 모든 머신이 프라이빗 IP 주소를 사용하여 서로 통신할 수 있도록 구성됩니다. 제공된 IP 주소는 예시이며 배포의 네트워크 토폴로지에 따라 다를 수 있습니다.

두 개의 Geo 사이트에 액세스하는 유일한 외부 방법은 HTTPS를 통해 `gitlab.us.example.com` 및 `gitlab.eu.example.com`입니다(이전 예시).

> [!note]
> **프라이머리** 및 **세컨더리** Geo 사이트는 HTTPS를 통해 서로 통신할 수 있어야 합니다.

## 여러 노드에 대한 Redis 및 PostgreSQL {#redis-and-postgresql-for-multiple-nodes}

PostgreSQL 및 Redis에 대한 이 구성 설정과 관련된 추가 복잡성으로 인해 이 Geo 다중 노드 설명서에는 포함되지 않습니다.

Linux 패키지를 사용하여 다중 노드 PostgreSQL 클러스터 및 Redis 클러스터 설정에 대한 자세한 정보는 다음을 참조하세요:

- [Geo 다중 노드 데이터베이스 복제](../setup/database.md#multi-node-database-replication)
- [Redis 다중 노드 설명서](../../redis/replication_and_failover.md)

> [!note]
> PostgreSQL 및 Redis에 클라우드 호스팅 서비스를 사용할 수 있지만 이는 이 문서의 범위를 벗어납니다.

## 전제 조건: 독립적으로 작동하는 두 개의 GitLab 다중 노드 사이트 {#prerequisites-two-independently-working-gitlab-multi-node-sites}

한 개의 GitLab 사이트는 Geo **프라이머리** 사이트로 사용됩니다. [GitLab 참조 아키텍처 설명서](../../reference_architectures/_index.md)를 사용하여 설정하세요. 각 Geo 사이트에 다양한 참조 아키텍처 크기를 사용할 수 있습니다. 이미 사용 중인 작동하는 GitLab 인스턴스가 있는 경우 **프라이머리** 사이트로 사용할 수 있습니다.

두 번째 GitLab 사이트는 Geo **세컨더리** 사이트로 사용됩니다. 다시 [GitLab 참조 아키텍처 설명서](../../reference_architectures/_index.md)를 사용하여 설정하세요. 로그인하고 테스트하는 것이 좋습니다. 그러나 **프라이머리** 사이트에서 복제하는 과정의 일부로 데이터가 삭제됩니다.

## GitLab 사이트를 Geo **프라이머리** 사이트가 되도록 구성 {#configure-a-gitlab-site-to-be-the-geo-primary-site}

다음 단계를 수행하면 GitLab 사이트가 Geo **프라이머리** 사이트로 사용될 수 있습니다.

### 1단계:  **프라이머리** 프론트엔드 노드 구성 {#step-1-configure-the-primary-frontend-nodes}

> [!note]
> [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)을 사용하지 마세요. 단일 노드 사이트를 위해 설계되었습니다.

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가하세요:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false
   ```

이러한 변경을 수행한 후 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용하세요.

### 2단계:  사이트를 **프라이머리** 사이트로 정의 {#step-2-define-the-site-as-the-primary-site}

1. 프론트엔드 노드 중 하나에서 다음 명령을 실행하세요:

   ```shell
   sudo gitlab-ctl set-geo-primary-node
   ```

> [!note]
> PostgreSQL 및 Redis는 일반적인 GitLab 다중 노드 설정 중에 애플리케이션 노드에서 이미 비활성화되었어야 합니다. 애플리케이션 노드에서 백엔드 노드의 서비스로의 연결도 구성되었어야 합니다. [PostgreSQL](../../postgresql/replication_and_failover.md#configuring-the-application-nodes) 및 [Redis](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)에 대한 다중 노드 구성 설명서를 참조하세요.

## 다른 GitLab 사이트를 Geo **세컨더리** 사이트가 되도록 구성 {#configure-the-other-gitlab-site-to-be-a-geo-secondary-site}

**세컨더리** 사이트는 다른 GitLab 다중 노드 사이트와 유사하지만 세 가지 주요 차이점이 있습니다:

- 주 PostgreSQL 데이터베이스는 Geo **프라이머리** 사이트의 PostgreSQL 데이터베이스의 읽기 전용 복제본입니다.
- 각 Geo **세컨더리** 사이트에는 "Geo 추적 데이터베이스"라는 추가 PostgreSQL 데이터베이스가 있으며, 이는 다양한 리소스의 복제 및 검증 상태를 추적합니다.
- 추가 GitLab 서비스 [`geo-logcursor`](../_index.md#geo-log-cursor)이 있습니다.

따라서 다중 노드 구성 요소를 하나씩 설정하고 일반적인 다중 노드 설정에서의 편차를 포함합니다. 그러나 먼저 새로운 GitLab 사이트를 구성하는 것을 강력히 권장합니다. Geo 설정의 일부가 아닌 것처럼 말입니다. 이를 통해 작동하는 GitLab 사이트임을 확인할 수 있습니다. 그런 다음에만 Geo **세컨더리** 사이트로 사용하도록 수정해야 합니다. 이는 Geo 설정 문제를 관련 없는 다중 노드 구성 문제와 분리하는 데 도움이 됩니다.

### 1단계:  Geo **세컨더리** 사이트에서 Redis 및 Gitaly 서비스 구성 {#step-1-configure-the-redis-and-gitaly-services-on-the-geo-secondary-site}

다음 서비스를 다시 비-Geo 다중 노드 설명서를 사용하여 구성하세요:

- [GitLab용 Redis 구성](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)(여러 노드의 경우).
- [Gitaly](../../gitaly/_index.md)(Geo **프라이머리** 사이트에서 동기화된 데이터를 저장).

> [!note]
> [NFS](../../nfs.md)를 Gitaly 대신 사용할 수 있지만 권장되지 않습니다.

### 2단계:  Geo **세컨더리** 사이트에서 Geo 추적 데이터베이스 구성 {#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site}

Geo 추적 데이터베이스는 다중 노드 PostgreSQL 클러스터에서 실행될 수 없습니다. [추적 PostgreSQL 데이터베이스용 Patroni 클러스터 구성](../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)을 참조하세요.

Geo 추적 데이터베이스를 단일 노드에서 다음과 같이 실행할 수 있습니다:

1. GitLab 애플리케이션이 추적 데이터베이스에 액세스하는 데 사용하는 데이터베이스 사용자의 원하는 비밀번호의 MD5 해시를 생성합니다:

   사용자 이름(`gitlab_geo`, 기본값)이 해시에 통합됩니다.

   ```shell
   gitlab-ctl pg-password-md5 gitlab_geo
   # Enter password: <your_tracking_db_password_here>
   # Confirm password: <your_tracking_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   이 해시를 사용하여 `<tracking_database_password_md5_hash>`을 다음 단계에서 입력하세요.

1. Geo 추적 데이터베이스가 실행되도록 의도된 머신에서 다음을 `/etc/gitlab/gitlab.rb`에 추가하세요:

   ```ruby
   ##
   ## Enable the Geo secondary tracking database
   ##
   geo_postgresql['enable'] = true
   geo_postgresql['listen_address'] = '<ip_address_of_this_host>'
   geo_postgresql['sql_user_password'] = '<tracking_database_password_md5_hash>'

   ##
   ## Configure PostgreSQL connection to the replica database
   ##
   geo_postgresql['md5_auth_cidr_addresses'] = ['<replica_database_ip>/32']
   gitlab_rails['db_host'] = '<replica_database_ip>'

   # Prevent reconfigure from attempting to run migrations on the replica database
   gitlab_rails['auto_migrate'] = false
   ```

1. [자동 PostgreSQL 업그레이드를 거부](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)하여 GitLab 업그레이드 시 의도하지 않은 다운타임을 방지하세요. [Geo를 사용한 PostgreSQL 업그레이드 시 주의 사항](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo)을 알아두세요. 특히 더 큰 환경의 경우 PostgreSQL 업그레이드는 의도적으로 계획되고 실행되어야 합니다. 그 결과로 앞으로 PostgreSQL 업그레이드가 정기적인 유지 관리 활동의 일부인지 확인하세요.

이러한 변경을 수행한 후 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용하세요.

외부 PostgreSQL 인스턴스를 사용하는 경우 [외부 PostgreSQL 인스턴스가 있는 Geo](../setup/external_database.md)도 참조하세요.

### 3단계:  PostgreSQL 스트리밍 복제 구성 {#step-3-configure-postgresql-streaming-replication}

[Geo 데이터베이스 복제 지침](../setup/database.md)을 따르세요.

외부 PostgreSQL 인스턴스를 사용하는 경우 [외부 PostgreSQL 인스턴스가 있는 Geo](../setup/external_database.md)도 참조하세요.

스트리밍 복제를 활성화한 후 `gitlab-rake db:migrate:status:geo`은 [세컨더리 사이트 구성이 완료](#step-7-copy-secrets-and-add-the-secondary-site-in-the-application)될 때까지 실패합니다. 특히 [Geo 구성 - 3단계. 세컨더리 사이트 추가](configuration.md#step-3-add-the-secondary-site).

### 4단계:  Geo **세컨더리** 사이트에서 프론트엔드 애플리케이션 노드 구성 {#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site}

> [!note]
> [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)을 사용하지 마세요. 단일 노드 사이트를 위해 설계되었습니다.

최소 [아키텍처 다이어그램](#architecture-overview)에는 GitLab 애플리케이션 서비스를 실행하는 두 개의 머신이 있습니다. 이러한 서비스는 구성에서 선택적으로 활성화됩니다.

[참조 아키텍처](../../reference_architectures/_index.md)에 설명된 관련 단계에 따라 GitLab Rails 애플리케이션 노드를 구성한 후에 다음 수정을 수행하세요:

1. `/etc/gitlab/gitlab.rb`을 Geo **세컨더리** 사이트의 각 애플리케이션 노드에서 편집하고 다음을 추가하세요:

   ```ruby
   ##
   ## Enable GitLab application services. The application_role enables many services.
   ## Alternatively, you can choose to enable or disable specific services on
   ## different nodes to aid in horizontal scaling and separation of concerns.
   ##
   roles ['application_role']

   ## `application_role` already enables this. You only need this line if
   ## you selectively enable individual services that depend on Rails, like
   ## `puma`, `sidekiq`, `geo-logcursor`, and so on.
   gitlab_rails['enable'] = true

   ##
   ## Enable Geo Log Cursor service
   ##
   geo_logcursor['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

> [!warning]
> Linux 패키지를 사용하여 PostgreSQL 클러스터를 설정했으며 `postgresql['sql_user_password'] = 'md5 digest of secret'`를 설정했다면 `gitlab_rails['db_password']` 및 `geo_secondary['db_password']`에 일반 텍스트 비밀번호가 포함되어 있다는 점을 주의하세요. 이러한 구성은 Rails 노드가 데이터베이스에 연결할 수 있도록 하는 데 사용됩니다.

현재 노드의 IP가 읽기-복제본 데이터베이스의 `postgresql['md5_auth_cidr_addresses']` 설정에 나열되어 있는지 확인하여 이 노드의 Rails가 PostgreSQL에 연결할 수 있도록 하세요.

이러한 변경을 수행한 후 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용하세요.

[아키텍처 개요](#architecture-overview) 토폴로지에서 다음 GitLab 서비스는 "프론트엔드" 노드에서 활성화됩니다:

- `geo-logcursor`
- `gitlab-pages`
- `gitlab-workhorse`
- `logrotate`
- `nginx`
- `registry`
- `remote-syslog`
- `sidekiq`
- `puma`

프론트엔드 애플리케이션 노드에서 `sudo gitlab-ctl status`을 실행하여 이러한 서비스가 존재하는지 확인하세요.

### 5단계:  Geo **세컨더리** 사이트에 대한 로드 밸런서 설정 {#step-5-set-up-the-loadbalancer-for-the-geo-secondary-site}

최소 [아키텍처 다이어그램](#architecture-overview)은 각 지역 위치에서 로드 밸런서를 표시하여 애플리케이션 노드로의 트래픽을 라우팅합니다.

[여러 노드가 있는 GitLab용 로드 밸런서](../../load_balancer.md)를 참조하세요.

### 6단계:  Geo **세컨더리** 사이트에서 백엔드 애플리케이션 노드 구성 {#step-6-configure-the-backend-application-nodes-on-the-geo-secondary-site}

최소 [아키텍처 다이어그램](#architecture-overview)은 모든 애플리케이션 서비스가 동일한 머신에서 함께 실행되는 것을 보여줍니다. 그러나 여러 노드의 경우 [모든 서비스를 별도로 실행할 것을 강력히 권장합니다](../../reference_architectures/_index.md).

예를 들어 Sidekiq 노드는 이전에 설명한 프론트엔드 애플리케이션 노드와 유사하게 구성할 수 있지만 `sidekiq` 서비스만 실행하는 일부 변경 사항이 있습니다:

1. `/etc/gitlab/gitlab.rb`을 Geo **세컨더리** 사이트의 각 Sidekiq 노드에서 편집하고 다음을 추가하세요:

   ```ruby
   ##
   ## Enable the Sidekiq service
   ##
   sidekiq['enable'] = true
   gitlab_rails['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

   `geo-logcursor` 서비스만 실행하도록 노드를 유사하게 구성할 수 있습니다. `geo_logcursor['enable'] = true`를 사용하고 `sidekiq['enable'] = false`로 Sidekiq을 비활성화합니다.

   이러한 노드는 로드 밸런서에 연결될 필요가 없습니다.

### 7단계:  비밀번호를 복사하고 애플리케이션에 세컨더리 사이트 추가 {#step-7-copy-secrets-and-add-the-secondary-site-in-the-application}

1. [GitLab 구성](configuration.md)하여 **프라이머리** 및 **세컨더리** 사이트를 설정합니다.
