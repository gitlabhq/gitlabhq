---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 복제 일시 중지 및 재개
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!warning]
> 복제의 일시 중지 및 재개는 Linux 패키지로 관리되는 데이터베이스를 사용하는 Geo 설치에서만 지원됩니다. 외부 데이터베이스는 지원되지 않습니다.
>
> 기본 사이트에 치명적인 오류가 발생했고 복구할 수 없는 경우 **Do not pause replication**. 이렇게 하면 도달할 수 없는 복구 대상을 만들어 보조 사이트의 성공적인 승격을 방지할 수 있습니다.

[업그레이드](upgrading_the_geo_sites.md) 중이거나 [계획된 장애 조치](../disaster_recovery/planned_failover.md) 중과 같은 특정 상황에서는 기본 사이트와 보조 사이트 간의 복제를 일시 중지하는 것이 바람직합니다.

업그레이드 중에 보조 사이트에서 사용자 활동을 허용하려는 경우 [무중단 업그레이드](../../../update/zero_downtime.md)를 위해 복제를 일시 중지하지 마세요. 일시 중지되는 동안 보조 사이트는 점점 더 최신 상태가 아닙니다. 알려진 효과 중 하나는 더 많은 Git 가져오기가 기본 사이트로 리디렉션되거나 프록시된다는 것입니다. 추가 알려지지 않은 효과가 있을 수 있습니다.

예를 들어, 별도의 URL을 사용하는 보조 사이트를 일시 중지하면 보조 사이트의 URL에서 로그인이 중단될 수 있습니다. 보조 사이트의 URL에 새 세션이 없는 기본 사이트의 루트 URL에 도달합니다.

## 복제 일시 중지 및 재개 {#pause-and-resume}

복제의 일시 중지 및 재개는 보조 사이트의 특정 노드에서 명령줄 도구를 통해 수행됩니다. 데이터베이스 아키텍처에 따라 이는 `postgresql` 또는 `patroni` 서비스를 대상으로 합니다:

- 보조 사이트의 모든 서비스에 단일 노드를 사용 중인 경우 이 단일 노드에서 명령을 실행해야 합니다.
- 보조 사이트에 독립 실행형 PostgreSQL 노드가 있는 경우 이 독립 실행형 PostgreSQL 노드에서 명령을 실행해야 합니다.
- 보조 사이트가 Patroni 클러스터를 사용 중인 경우 보조 Patroni 대기 리더 노드에서 이 명령들을 실행해야 합니다.

보조 사이트의 모든 서비스에 단일 노드를 사용하지 않는 경우 PostgreSQL 또는 Patroni 노드의 `/etc/gitlab/gitlab.rb`에 구성 줄 `gitlab_rails['geo_node_name'] = 'node_name'`가 포함되어 있는지 확인하세요. 여기서 `node_name`은 애플리케이션 노드의 `geo_node_name`과 동일합니다.

**To Pause: (from secondary site)**

또한 복제를 일시 중지한 후 PostgreSQL이 다시 시작되는 경우(`gitlab-ctl restart postgresql`을 사용하여 VM을 다시 시작하거나 서비스를 다시 시작하여) PostgreSQL이 자동으로 복제를 재개한다는 점에 유의하세요. 이는 업그레이드 중이나 계획된 장애 조치 시나리오에서 원하지 않는 것입니다.

```shell
gitlab-ctl geo-replication-pause
```

**To Resume: (from secondary site)**

```shell
gitlab-ctl geo-replication-resume
```
