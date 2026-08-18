---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: ClickHouse
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  GitLab Dedicated의 베타

{{< /details >}}

{{< history >}}

- [일반 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/20337)은 GitLab 18.11의 GitLab Self-Managed에 제공됩니다.

{{< /history >}}

[ClickHouse](https://clickhouse.com)는 오픈소스 열지향 데이터베이스 관리 시스템입니다. 대규모 데이터 세트에서 효율적으로 필터링, 집계 및 쿼리할 수 있습니다.

GitLab은 ClickHouse를 보조 데이터 저장소로 사용하여 GitLab Duo, SDLC 트렌드, CI Analytics 같은 고급 분석 기능을 활성화합니다. GitLab은 ClickHouse에 이러한 기능을 지원하는 데이터만 저장합니다.

[ClickHouse Cloud](https://clickhouse.com/cloud)를 사용하여 ClickHouse를 GitLab에 연결해야 합니다.

또는 [자신의 ClickHouse를 가져올](https://clickhouse.com/docs/en/install) 수 있습니다. 자세한 정보는 [GitLab Self-Managed용 ClickHouse 권장 사항](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations)을 참조하세요.

## ClickHouse로 사용 가능한 분석 {#analytics-available-with-clickhouse}

ClickHouse를 구성한 후 다음 분석 기능을 사용할 수 있습니다:

| 기능 | 설명 |
|----------------------|---------------------|
| [러너 플릿 대시보드](../ci/runners/runner_fleet_dashboard.md#dashboard-metrics)  | 러너 사용 메트릭과 작업 대기 시간을 표시합니다. 각 프로젝트의 러너 유형 및 작업 상태별로 작업 수와 실행된 러너 시간이 포함된 CSV 파일의 내보내기를 제공합니다.   |
| [기여도 분석](../user/group/contribution_analytics/_index.md)  | 시간 경과에 따른 그룹 구성원 기여도(푸시 이벤트, 이슈, 머지 리퀘스트)의 분석을 제공합니다. ClickHouse는 대규모 인스턴스의 타임아웃 이슈 가능성을 줄입니다. |
| [GitLab Duo 및 SDLC 트렌드](../user/analytics/duo_and_sdlc_trends.md)  | 소프트웨어 개발 성능에 대한 GitLab Duo의 영향을 측정합니다. 배포 빈도, 리드 타임, 변경 실패율, 복구 시간 등의 개발 메트릭을 GitLab Duo 사용자 채택, 코드 제안 수락률, GitLab Duo Chat 사용 현황 등의 AI 관련 지표와 함께 추적합니다. |
| [AI 메트릭용 GraphQL API](../api/graphql/duo_and_sdlc_trends.md) | `AiMetrics`, `AiUserMetrics`, `AiUsageData` 엔드포인트를 통해 GitLab Duo 및 SDLC 트렌드 데이터에 프로그래밍 방식으로 액세스할 수 있습니다. BI 도구 및 사용자 정의 분석과 통합할 수 있는 사전 집계된 메트릭 및 원시 이벤트 데이터의 내보내기를 제공합니다. |

## 지원되는 ClickHouse 버전 {#supported-clickhouse-versions}

지원되는 ClickHouse 버전은 GitLab 버전에 따라 다릅니다:

- GitLab 17.7 이상은 ClickHouse 23.x를 지원합니다. ClickHouse 24.x 또는 25.x를 사용하려면 [해결 방법](#database-schema-migrations-on-gitlab-1800-and-earlier)을 사용하세요.
- GitLab 18.1 이상은 ClickHouse 23.x, 24.x, 25.x를 지원합니다.
- GitLab 18.8 이상은 ClickHouse 23.x, 24.x, 25.x 및 Replicated 데이터베이스 엔진을 지원합니다.
  - 이전 클러스터에는 추가 권한(`dictGet`)이 필요하며, [스니펫](#database-dictionary-read-support)을 참조하세요.
- GitLab 19.0 이상은 ClickHouse 25.x 및 26.x를 지원합니다. ClickHouse 23.x 및 24.x에 대한 지원이 제거되었습니다.

ClickHouse Cloud는 항상 최신 안정 GitLab 릴리스와 호환됩니다.

> [!warning]
> ClickHouse 25.12를 사용 중인 경우 `ALTER MODIFY COLUMN`에 대해 [하위 호환성이 없는 변경](https://clickhouse.com/docs/whats-new/changelog#backward-incompatible-change)이 도입되었음을 참고하세요. 이는 18.8 이전 버전의 GitLab ClickHouse 통합 마이그레이션 프로세스를 중단합니다. GitLab을 18.8+ 버전으로 업그레이드해야 합니다.

## ClickHouse 설정 {#set-up-clickhouse}

운영 요구 사항에 따라 배포 유형을 선택하세요:

- **[ClickHouse Cloud](#set-up-clickhouse-cloud)**(권장): 자동 업그레이드, 백업 및 스케일링이 포함된 완전 관리 서비스입니다.
- **[GitLab Self-Managed용 ClickHouse(BYOC)](#set-up-clickhouse-for-gitlab-self-managed-byoc)**: 인프라 및 구성에 대한 완전한 제어입니다.

ClickHouse 인스턴스를 설정한 후:

1. [GitLab 데이터베이스 및 사용자 생성](#create-database-and-user)
1. [GitLab 연결 구성](#configure-the-gitlab-connection)
1. [연결 확인](#verify-the-connection)
1. [ClickHouse 마이그레이션 실행](#run-clickhouse-migrations)
1. [분석을 위해 ClickHouse 활성화](#enable-clickhouse-for-analytics)

### ClickHouse Cloud 설정 {#set-up-clickhouse-cloud}

전제 조건:

- ClickHouse Cloud 계정이 있습니다.
- GitLab 인스턴스에서 ClickHouse Cloud로의 네트워크 연결을 활성화합니다.
- GitLab 인스턴스의 관리자여야 합니다.

ClickHouse Cloud를 설정하려면:

1. [ClickHouse Cloud](https://clickhouse.cloud)에 로그인하세요.
1. **New Service**를 선택하세요.
1. 서비스 티어를 선택하세요:
   - **개발**: 테스트 및 개발 환경용입니다.
   - **프로덕션**: 고가용성의 프로덕션 워크로드용입니다.
1. 클라우드 공급자 및 지역을 선택하세요. 최적 성능을 위해 GitLab 인스턴스에 가까운 지역을 선택하세요.
1. 서비스 이름 및 설정을 구성하세요.
1. **Create Service**를 선택하세요.
1. 프로비저닝되면 서비스 대시보드에서 연결 세부 정보를 기록하세요:
   - 호스트
   - 포트(`8443` for HTTPS connections used by GitLab, or `9440` for native TCP with TLS used by `clickhouse-client`)
   - 사용자 이름
   - 비밀번호

> [!note]
> ClickHouse Cloud는 버전 업그레이드 및 보안 패치를 자동으로 처리합니다. Enterprise Edition(EE) 고객은 업그레이드가 발생하는 시기를 제어하고 업무 시간 중 예상치 못한 서비스 중단을 피할 수 있습니다. 자세한 정보는 [ClickHouse 업그레이드](#upgrade-clickhouse)를 참조하세요.

ClickHouse Cloud 서비스를 생성한 후 [GitLab 데이터베이스 및 사용자를 생성](#create-database-and-user)하세요.

### GitLab Self-Managed용 ClickHouse 설정(BYOC) {#set-up-clickhouse-for-gitlab-self-managed-byoc}

전제 조건:

- ClickHouse 인스턴스가 설치되고 실행 중입니다. ClickHouse가 설치되지 않은 경우 다음을 참조하세요:
  - [ClickHouse 공식 설치 가이드](https://clickhouse.com/docs/en/install)
  - [GitLab Self-Managed용 ClickHouse 권장 사항](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations)
- [지원되는 ClickHouse 버전](#supported-clickhouse-versions)이 있습니다.
- GitLab 인스턴스에서 ClickHouse로의 네트워크 연결을 활성화합니다.
- ClickHouse 및 GitLab 인스턴스 모두의 관리자여야 합니다.

> [!warning]
> GitLab Self-Managed용 ClickHouse의 경우 버전 업그레이드, 보안 패치 및 백업 계획 및 실행을 담당합니다. 자세한 정보는 [ClickHouse 업그레이드](#upgrade-clickhouse)를 참조하세요.

#### 고가용성 구성 {#configure-high-availability}

다중 노드 고가용성(HA) 설정의 경우 GitLab은 ClickHouse의 Replicated 테이블 엔진을 지원합니다.

전제 조건:

- 여러 노드가 있는 ClickHouse 클러스터가 있습니다. 최소 3개 노드를 권장합니다.
- `remote_servers` 구성 섹션에서 클러스터를 정의합니다.
- ClickHouse 구성에서 다음 매크로를 구성합니다:
  - `cluster`
  - `shard`
  - `replica`

HA에 대해 데이터베이스를 구성할 때 `ON CLUSTER` 절로 명령문을 실행해야 합니다.

자세한 정보는 [ClickHouse Replicated 데이터베이스 엔진 설명서](https://clickhouse.com/docs/en/engines/database-engines/replicated)를 참조하세요.

#### 로드 밸런서 구성 {#configure-load-balancer}

GitLab 애플리케이션은 HTTP/HTTPS 인터페이스를 통해 ClickHouse 클러스터와 통신합니다. HA 배포의 경우 HTTP 프록시 또는 로드 밸런서를 사용하여 ClickHouse 클러스터 노드 전체에 요청을 분산합니다.

권장 로드 밸런서 옵션:

- [chproxy](https://www.chproxy.org/) \- 기본 제공 캐싱 및 라우팅이 있는 ClickHouse 특화 HTTP 프록시입니다.
- HAProxy - 범용 TCP/HTTP 로드 밸런서입니다.
- NGINX - 로드 밸런싱 기능이 있는 웹 서버입니다.
- 클라우드 공급자 로드 밸런서(AWS Application Load Balancer, GCP Load Balancer, Azure Load Balancer)

기본 chproxy 구성 예제:

```yaml
server:
  http:
    listen_addr: ":8080"

clusters:
  - name: "clickhouse_cluster"
    nodes: [
      "http://ch-node1:8123",
      "http://ch-node2:8123",
      "http://ch-node3:8123"
    ]

users:
  - name: "gitlab"
    password: "your_secure_password"
    to_cluster: "clickhouse_cluster"
    to_user: "gitlab"
```

로드 밸런서를 사용할 때 개별 ClickHouse 노드 대신 로드 밸런서 URL에 연결하도록 GitLab을 구성합니다.

자세한 정보는 [chproxy 설명서](https://www.chproxy.org/)를 참조하세요.

GitLab Self-Managed 인스턴스용 ClickHouse를 구성한 후 [GitLab 데이터베이스 및 사용자를 생성](#create-database-and-user)하세요.

### ClickHouse 설치 확인 {#verify-clickhouse-installation}

데이터베이스를 구성하기 전에 ClickHouse가 설치되고 액세스 가능한지 확인하세요:

1. ClickHouse가 실행 중인지 확인합니다:

   ```shell
   clickhouse-client --query "SELECT version()"
   ```

   ClickHouse가 실행 중인 경우 버전 번호가 표시됩니다(예: `24.3.1.12`).
1. 자격 증명으로 연결할 수 있는지 확인하세요:

   ```shell
   clickhouse-client --host your-clickhouse-host --port 9440 --secure --user default --password 'your-password'
   ```

   > [!note]
   > 아직 TLS를 구성하지 않은 경우 `--secure` 플래그 없이 포트 `9000`를 초기 테스트에 사용하세요.

### 데이터베이스 및 사용자 생성 {#create-database-and-user}

필요한 사용자 및 데이터베이스 객체를 생성하려면:

1. 보안 비밀번호를 생성하고 저장합니다.
1. 로그인합니다:
   - ClickHouse Cloud의 경우 ClickHouse SQL 콘솔입니다.
   - GitLab Self-Managed용 ClickHouse의 경우 `clickhouse-client`입니다.
1. 다음 명령을 실행하여 `PASSWORD_HERE`을 생성된 비밀번호로 바꿉니다.

{{< tabs >}}

{{< tab title="Single-node or ClickHouse Cloud" >}}

```sql
CREATE DATABASE gitlab_clickhouse_main_production;
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
CREATE ROLE gitlab_app;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
GRANT SELECT ON information_schema.* TO gitlab_app;
GRANT gitlab_app TO gitlab;
```

{{< /tab >}}

{{< tab title="HA ClickHouse for GitLab Self-Managed" >}}

`CLUSTER_NAME_HERE`을 클러스터의 이름으로 바꿉니다:

```sql
CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}');
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

### GitLab 연결 구성 {#configure-the-gitlab-connection}

{{< tabs >}}

{{< tab title="Linux package" >}}

GitLab에 ClickHouse 자격 증명을 제공하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://your-clickhouse-host:port'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

   URL을 다음으로 바꿉니다:
   - ClickHouse Cloud의 경우: `https://your-service.clickhouse.cloud:8443`
   - GitLab Self-Managed용 ClickHouse: `https://your-clickhouse-host:8443`
   - 로드 밸런서를 사용한 GitLab Self-Managed HA용 ClickHouse: `https://your-load-balancer:8080`(또는 로드 밸런서 URL)

1. 파일을 저장하고 GitLab을 다시 구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. ClickHouse 비밀번호를 Kubernetes Secret으로 저장합니다:

   ```shell
   kubectl create secret generic gitlab-clickhouse-password --from-literal="main_password=PASSWORD_HERE"
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다.

   ```yaml
   global:
     clickhouse:
       enabled: true
       main:
         username: gitlab
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'https://your-clickhouse-host:port'
   ```

   URL을 다음으로 바꿉니다:
   - ClickHouse Cloud의 경우: `https://your-service.clickhouse.cloud:8443`
   - GitLab Self-Managed 단일 노드용 ClickHouse: `https://your-clickhouse-host:8443`
   - 로드 밸런서를 사용한 GitLab Self-Managed HA용 ClickHouse: `https://your-load-balancer:8080`(또는 로드 밸런서 URL)

1. 파일을 저장하고 새 값을 적용하세요:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> 프로덕션 배포의 경우 ClickHouse 인스턴스에서 TLS/SSL을 구성하고 `https://` URL을 사용합니다. GitLab Self-Managed 설치의 경우 [네트워크 보안](#network-security) 설명서를 참조하세요.

### 연결 확인 {#verify-the-connection}

연결이 성공적으로 설정되었는지 확인하려면:

1. [Rails 콘솔](../administration/operations/rails_console.md#starting-a-rails-console-session)에 로그인하세요.
1. 다음 명령을 실행하세요:

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   성공하면 명령은 `[{"1"=>1}]`을 반환합니다.

연결에 실패하면 다음을 확인하세요:

- ClickHouse 서비스가 실행 중이고 액세스 가능합니다.
- GitLab에서 ClickHouse로의 네트워크 연결입니다. 방화벽 및 보안 그룹이 연결을 허용하는지 확인합니다.
- 연결 URL이 올바릅니다(호스트, 포트, 프로토콜).
- 자격 증명이 올바릅니다.
- HA 클러스터 배포의 경우: 로드 밸런서가 올바르게 구성되고 요청을 라우팅합니다.

### ClickHouse 마이그레이션 실행 {#run-clickhouse-migrations}

> [!note]
> 이 단계는 필수입니다. 건너뛰면 분석 대시보드에 데이터가 표시되지 않고 "데이터를 가져오지 못했습니다" 오류가 표시됩니다.

{{< tabs >}}

{{< tab title="Linux package" >}}

필요한 데이터베이스 객체를 생성하려면 다음을 실행합니다:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

마이그레이션은 [GitLab-Migrations 차트](https://docs.gitlab.com/charts/charts/gitlab/migrations/)를 사용하여 자동으로 실행됩니다.

또는 Toolbox 포드에서 다음 명령을 실행하여 마이그레이션을 실행할 수 있습니다:

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### 분석을 위해 ClickHouse 활성화 {#enable-clickhouse-for-analytics}

GitLab 인스턴스가 ClickHouse에 연결된 후 ClickHouse를 사용하는 기능을 활성화할 수 있습니다:

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.
- ClickHouse 연결이 구성되고 확인됩니다.
- 마이그레이션이 성공적으로 완료되었습니다.

분석을 위해 ClickHouse를 활성화하려면:

1. 왼쪽 사이드바 맨 아래에서 **Admin**을 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **ClickHouse**를 확장합니다.
1. **Enable ClickHouse for Analytics**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 분석을 위해 ClickHouse 비활성화 {#disable-clickhouse-for-analytics}

분석을 위해 ClickHouse를 비활성화하려면:

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

비활성화하려면:

1. 왼쪽 사이드바 맨 아래에서 **Admin**을 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **ClickHouse**를 확장합니다.
1. **Enable ClickHouse for Analytics** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 분석을 위해 ClickHouse를 비활성화하면 GitLab이 ClickHouse를 쿼리하지 못하지만 ClickHouse 인스턴스의 데이터는 삭제되지 않습니다. ClickHouse를 사용하는 분석 기능은 대체 데이터 소스로 돌아가거나 사용할 수 없게 됩니다.

## ClickHouse 업그레이드 {#upgrade-clickhouse}

### ClickHouse Cloud {#clickhouse-cloud}

ClickHouse Cloud는 버전 업그레이드 및 보안 패치를 자동으로 처리합니다. 수동 개입이 필요하지 않습니다.

업그레이드 스케줄링 및 유지보수 기간에 대한 정보는 [ClickHouse Cloud 업그레이드](https://clickhouse.com/docs/manage/updates)를 참조하세요.

> [!note]
> ClickHouse Cloud는 향후 업그레이드를 미리 알립니다. [ClickHouse Cloud 변경 로그](https://clickhouse.com/docs/whats-new/cloud)를 검토하여 새로운 기능 및 변경 사항을 최신 상태로 유지하세요.

### GitLab Self-Managed용 ClickHouse(BYOC) {#clickhouse-for-gitlab-self-managed-byoc}

GitLab Self-Managed용 ClickHouse의 경우 버전 업그레이드 계획 및 실행을 담당합니다.

전제 조건:

- ClickHouse 인스턴스에 대한 관리자 액세스가 있습니다.
- 업그레이드하기 전에 데이터를 백업합니다. [재해 복구](#disaster-recovery)를 참조하세요.

업그레이드하기 전에:

1. 변경 사항을 깨뜨리기 위해 [ClickHouse 릴리스 정보](https://clickhouse.com/docs/category/changelog)를 검토하세요.
1. GitLab 버전과의 [호환성](#supported-clickhouse-versions)을 확인하세요.
1. 비프로덕션 환경에서 업그레이드를 테스트합니다.
1. 잠재적 다운타임을 계획하거나 HA 클러스터에 대해 롤링 업그레이드 전략을 사용합니다.

ClickHouse를 업그레이드하려면:

1. 단일 노드 배포의 경우 [ClickHouse 업그레이드 설명서](https://clickhouse.com/docs/manage/updates)를 따릅니다.
1. HA 클러스터 배포의 경우 다운타임을 최소화하기 위해 롤링 업그레이드를 수행합니다:
   - 한 번에 하나의 노드를 업그레이드합니다.
   - 노드가 클러스터에 다시 조인될 때까지 기다립니다.
   - 다음 노드로 진행하기 전에 클러스터 상태를 확인합니다.

> [!warning]
> 항상 ClickHouse 버전이 GitLab 버전과 호환되도록 하세요. 호환되지 않는 버전은 인덱싱을 일시 중지하고 기능을 실패하게 할 수 있습니다. 자세한 정보는 [지원되는 ClickHouse 버전](#supported-clickhouse-versions)을 참조하세요.

자세한 업그레이드 절차는 [ClickHouse 업데이트 설명서](https://clickhouse.com/docs/manage/updates)를 참조하세요.

## 작업 {#operations}

### 마이그레이션 상태 확인 {#check-migration-status}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

ClickHouse 마이그레이션의 상태를 확인하려면:

1. 왼쪽 사이드바 맨 아래에서 **Admin**을 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **ClickHouse**를 확장합니다.
1. 사용 가능한 경우 **Migration status** 섹션을 검토합니다.

또는 Rails 콘솔을 사용하여 보류 중인 마이그레이션을 확인합니다:

```ruby
# Sign in to Rails console
# Run this to check migrations
ClickHouse::MigrationSupport::Migrator.new(:main).pending_migrations
```

### 실패한 마이그레이션 재시도 {#retry-failed-migrations}

ClickHouse 마이그레이션이 실패하면:

1. 오류 세부 정보를 로그에서 확인합니다. ClickHouse 관련 오류는 GitLab 애플리케이션 로그에 기록됩니다.
1. 근본 원인(예: 메모리 부족, 연결 이슈)을 해결합니다.
1. 마이그레이션을 다시 시도합니다:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:clickhouse:migrate

   # For self-compiled installations
   bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
   ```

> [!note]
> 마이그레이션은 멱등이며 안전하게 재시도할 수 있도록 설계되었습니다. 마이그레이션이 도중에 실패하면 다시 실행하면 중단한 위치에서 재개되거나 이미 완료된 단계를 건너뜁니다.

## ClickHouse Rake 작업 {#clickhouse-rake-tasks}

GitLab은 ClickHouse 데이터베이스를 관리하기 위한 여러 Rake 작업을 제공합니다.

다음의 Rake 작업이 사용 가능합니다:

| 작업 | 설명 |
|------|-------------|
| [`sudo gitlab-rake gitlab:clickhouse:migrate`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 보류 중인 모든 ClickHouse 마이그레이션을 실행하여 데이터베이스 스키마를 생성하거나 업데이트합니다. |
| [`sudo gitlab-rake gitlab:clickhouse:drop`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 모든 ClickHouse 데이터베이스를 삭제합니다. 이것은 모든 데이터를 삭제하므로 극도로 주의하여 사용합니다. |
| [`sudo gitlab-rake gitlab:clickhouse:create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | ClickHouse 데이터베이스가 존재하지 않는 경우 생성합니다. |
| [`sudo gitlab-rake gitlab:clickhouse:setup`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 데이터베이스를 생성하고 모든 마이그레이션을 실행합니다. `create` 및 `migrate` 작업 실행과 동등합니다. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:dump`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 현재 데이터베이스 스키마를 백업 또는 버전 관리용 파일로 덤프합니다. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:load`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | 덤프 파일에서 데이터베이스 스키마를 로드합니다. |

> [!note]
> 자체 컴파일된 설치의 경우 `sudo gitlab-rake` 대신 `bundle exec rake`를 사용하고 명령 끝에 `RAILS_ENV=production`를 추가합니다.

### 일반적인 작업 예제 {#common-task-examples}

#### ClickHouse 연결 및 스키마 확인 {#verify-clickhouse-connection-and-schema}

ClickHouse 연결이 작동하는지 확인하려면:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:info

# For self-compiled installations
bundle exec rake gitlab:clickhouse:info RAILS_ENV=production
```

이 작업은 ClickHouse 연결 및 구성에 대한 디버깅 정보를 출력합니다.

#### 모든 마이그레이션 재실행 {#re-run-all-migrations}

보류 중인 모든 마이그레이션을 실행하려면:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:migrate

# For self-compiled installations
bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
```

#### 데이터베이스 재설정 {#reset-the-database}

> [!warning]
> 이것은 ClickHouse 데이터베이스의 모든 데이터를 삭제합니다. 개발 환경이나 문제 해결 시에만 사용합니다.

데이터베이스를 삭제하고 다시 생성하려면:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:drop
sudo gitlab-rake gitlab:clickhouse:setup

# For self-compiled installations
bundle exec rake gitlab:clickhouse:drop RAILS_ENV=production
bundle exec rake gitlab:clickhouse:setup RAILS_ENV=production
```

### 환경 변수 {#environment-variables}

환경 변수를 사용하여 Rake 작업 동작을 제어할 수 있습니다:

| 환경 변수 | 데이터 유형 | 설명 |
|---------------------|-----------|-------------|
| `VERBOSE` | 부울 | 마이그레이션 중에 자세한 출력을 보려면 `true`로 설정합니다. 예: `VERBOSE=true sudo gitlab-rake gitlab:clickhouse:migrate` |

## 성능 튜닝 {#performance-tuning}

> [!note]
> 사용자 수를 기반으로 한 리소스 크기 조정 및 배포 권장 사항은 [시스템 요구 사항](#system-requirements)을 참조하세요.

ClickHouse 아키텍처 및 성능 튜닝에 대한 정보는 [ClickHouse 아키텍처 설명서](https://clickhouse.com/docs/architecture/introduction)를 참조하세요.

## 재해 복구 {#disaster-recovery}

### 백업 및 복원 {#backup-and-restore}

GitLab 애플리케이션을 업그레이드하기 전에 전체 백업을 수행해야 합니다. ClickHouse 데이터는 GitLab 백업 도구에 포함되지 않습니다.

백업 및 복원 전략은 배포 선택에 따라 달라집니다.

#### ClickHouse Cloud {#clickhouse-cloud-1}

ClickHouse Cloud는 자동으로:

- 백업 및 복원을 관리합니다.
- 일일 백업을 생성하고 유지합니다.

추가 구성을 수행할 필요가 없습니다.

자세한 정보는 [ClickHouse Cloud 백업](https://clickhouse.com/docs/cloud/manage/backups)을 참조하세요.

#### GitLab Self-Managed용 ClickHouse {#clickhouse-for-gitlab-self-managed}

자신의 ClickHouse 인스턴스를 관리하는 경우 데이터 안전을 보장하기 위해 정기적인 백업을 수행해야 합니다:

- 시스템 테이블(`metrics` 또는 `logs` 제외)의 초기 전체 백업을 [객체 저장소 버킷(예: AWS S3)](https://clickhouse.com/docs/en/operations/backup#configuring-backuprestore-to-use-an-s3-endpoint)으로 수행합니다.
- 이 초기 전체 백업 후 [증분 백업](https://clickhouse.com/docs/en/operations/backup#take-an-incremental-backup)을 수행합니다.

이것은 모든 전체 백업에 대해 데이터를 복제하지만 [가장 쉬운 데이터 복원 방법](https://clickhouse.com/docs/en/operations/backup#restore-from-the-incremental-backup)입니다.

또는 [`clickhouse-backup`](https://github.com/Altinity/clickhouse-backup)를 사용합니다. 이것은 스케줄링 및 원격 저장소 관리 같은 추가 기능을 제공하는 타사 도구입니다.

## 모니터링 {#monitoring}

GitLab 통합의 안정성을 보장하기 위해 ClickHouse 클러스터의 상태 및 성능을 모니터링해야 합니다.

### ClickHouse Cloud {#clickhouse-cloud-2}

ClickHouse Cloud는 보안 API 엔드포인트를 통해 메트릭을 노출하는 기본 [Prometheus 통합](https://clickhouse.com/docs/integrations/prometheus)을 제공합니다.

API 자격 증명을 생성한 후 ClickHouse Cloud에서 메트릭을 스크래핑하도록 수집기를 구성할 수 있습니다. 예를 들어 [Prometheus 배포](https://clickhouse.com/docs/integrations/prometheus#configuring-prometheus)입니다.

### GitLab Self-Managed용 ClickHouse {#clickhouse-for-gitlab-self-managed-1}

ClickHouse는 [Prometheus 형식의 메트릭](https://clickhouse.com/docs/operations/server-configuration-parameters/settings#prometheus)을 노출할 수 있습니다. 이를 활성화하려면:

1. `prometheus` 섹션을 `config.xml`에서 구성하여 전용 포트(기본값 `9363`)에서 메트릭을 노출합니다.

   ```xml
   <prometheus>
       <endpoint>/metrics</endpoint>
       <port>9363</port>
       <metrics>true</metrics>
       <events>true</events>
       <asynchronous_metrics>true</asynchronous_metrics>
   </prometheus>
   ```

1. Prometheus 또는 유사한 호환 서버를 `http://<clickhouse-host>:9363/metrics`을 스크래핑하도록 구성합니다.

### 모니터링할 메트릭 {#metrics-to-monitor}

GitLab 기능에 영향을 미칠 수 있는 이슈를 감지하기 위해 다음 메트릭에 대한 경고를 설정해야 합니다:

| 메트릭 이름 | 설명 | 경고 임계값(권장) |
| :--- | :--- | :--- |
| `ClickHouse_Metrics_Query` | 현재 실행 중인 쿼리의 수입니다. 갑작스러운 스파이크는 성능 병목 현상을 나타낼 수 있습니다. | 기준선 편차(예: `> 100`) |
| `ClickHouseProfileEvents_FailedSelectQuery` | 실패한 선택 쿼리의 수 | 기준선 편차(예: `> 50`) |
| `ClickHouseProfileEvents_FailedInsertQuery` | 실패한 삽입 쿼리의 수 | 기준선 편차(예: `> 10`) |
| `ClickHouse_AsyncMetrics_ReadonlyReplica` | 복제본이 읽기 전용 모드로 전환되었는지 여부를 나타냅니다(종종 ZooKeeper 연결 손실로 인함). | `> 0`(즉시 조치 취하기) |
| `ClickHouse_ProfileEvents_NetworkErrors` | 네트워크 오류(연결 재설정/시간 제한)입니다. 빈번한 오류로 인해 GitLab 백그라운드 작업이 실패할 수 있습니다. | 비율 `> 0` |

### 활성 여부 확인 {#liveness-check}

ClickHouse가 로드 밸런서 뒤에서 사용 가능한 경우 HTTP `/ping` 엔드포인트를 사용하여 활성 여부를 확인할 수 있습니다. 예상 응답은 HTTP 코드 200의 `Ok`입니다.

## 보안 및 감시 {#security-and-auditing}

데이터의 보안을 보장하고 감시 가능성을 확보하려면 다음 보안 관행을 사용하세요.

### 네트워크 보안 {#network-security}

- TLS 암호화: ClickHouse 서버를 [TLS 암호화를 사용](#network-security)하도록 구성하여 연결을 검증합니다.

  GitLab에서 연결 URL을 구성할 때 `https://` 프로토콜(예: `https://clickhouse.example.com:8443`)을 사용해야 합니다.
- IP 허용 목록: ClickHouse 포트(기본값 `8443` 또는 `9440`)에 대한 액세스를 GitLab 애플리케이션 노드 및 기타 인증된 네트워크로만 제한합니다.

### 감시 로깅 {#audit-logging}

GitLab 애플리케이션은 개별 ClickHouse 쿼리에 대한 별도의 감시 로그를 유지하지 않습니다. 데이터 액세스에 대한 특정 요구 사항(누가 무엇을 언제 쿼리했는지)을 충족하기 위해 ClickHouse 측에서 로깅을 활성화할 수 있습니다.

#### ClickHouse Cloud {#clickhouse-cloud-3}

ClickHouse Cloud에서 쿼리 로깅이 기본적으로 활성화됩니다. `system.query_log` 테이블을 쿼리하여 이러한 로그에 액세스할 수 있습니다.

#### GitLab Self-Managed용 ClickHouse {#clickhouse-for-gitlab-self-managed-2}

자체 관리 인스턴스의 경우 `query_log` 구성 매개 변수가 서버 구성에서 활성화되었는지 확인하세요:

1. `query_log` 섹션이 `config.xml` 또는 `users.xml`에 존재하는지 확인합니다:

   ```xml
   <query_log>
       <database>system</database>
       <table>query_log</table>
       <partition_by>toYYYYMM(event_date)</partition_by>
       <flush_interval_milliseconds>7500</flush_interval_milliseconds>
       <ttl>event_date + INTERVAL 30 DAY</ttl>  <!-- Keep only 30 days -->
   </query_log>
   ```

1. 활성화되면 모든 실행된 쿼리가 `system.query_log` 테이블에 기록되어 감시 추적을 허용합니다.

## 시스템 요구 사항 {#system-requirements}

권장 시스템 요구 사항은 사용자 수에 따라 변경됩니다.

### 배포 결정 행렬 빠른 참조 {#deployment-decision-matrix-quick-reference}

| 사용자 | 주요 권장 사항 | 비슷한 AWS ARM 인스턴스 | 비슷한 GCP ARM 인스턴스 | 비슷한 Azure ARM 인스턴스 | 배포 유형 |
|---|---|---|---|---|---|
| 1K | ClickHouse Cloud Basic | - | - | - | 관리됨 |
| 2K | ClickHouse Cloud Basic | `m8g.xlarge` | `c4a-standard-4` |  `Standard_D4ps_v6` | 관리됨 또는 단일 노드 |
| 3K | ClickHouse Cloud Scale | `m8g.2xlarge` | `c4a-standard-8` | `Standard_D8ps_v6` | 관리됨 또는 단일 노드 |
| 5K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | 관리됨 또는 단일 노드 |
| 10K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | 관리됨 또는 단일 노드/HA |
| 25K | ClickHouse for GitLab Self-Managed 또는 ClickHouse Cloud Scale | `m8g.8xlarge` 또는 3×`m8g.4xlarge` | `c4a-standard-32` 또는 3×`c4a-standard-16` | `Standard_D32ps_v6` 또는 3x`Standard_D16ps_v6` | 관리됨 또는 단일 노드/HA |
| 50K | ClickHouse for GitLab Self-Managed 고가용성(HA) 또는 ClickHouse Cloud Scale | 3×`m8g.4xlarge` | 3×`c4a-standard-16` | 3x`Standard_D16ps_v6` | 관리됨 또는 HA 클러스터 |

### 1K 사용자 {#1k-users}

권장 사항: ClickHouse Cloud Basic은 운영 복잡성이 없으면서도 우수한 비용 효율성을 제공합니다.

### 2K 사용자 {#2k-users}

권장 사항: ClickHouse Cloud Basic은 운영 복잡성이 없으면서도 최고의 가치를 제공합니다.

GitLab Self-Managed 배포를 위한 대체 권장 사항:

- AWS: m8g.xlarge(4 vCPU, 16GB)
- GCP: c4a-standard-4 또는 n4-standard-4(4 vCPU, 16GB)
- Azure: Standard_D4ps_v6(4 vCPU, 16GB)
- 저장소: 저-중간 성능 티어의 20GB

### 3K 사용자 {#3k-users}

권장 사항: ClickHouse Cloud Scale

GitLab Self-Managed 배포를 위한 대체 권장 사항:

- AWS: m8g.2xlarge(8 vCPU, 32GB)
- GCP: c4a-standard-8 또는 n4-standard-8(8 vCPU, 32GB)
- Azure: Standard_D8ps_v6(8 vCPU, 32GB)
- 저장소: 중간 성능 티어의 100GB

> [!note]
> HA 배포는 이 규모에서 비용 효율적이지 않습니다.

### 5K 사용자 {#5k-users}

권장 사항: ClickHouse Cloud Scale

GitLab Self-Managed 배포를 위한 대체 권장 사항:

- AWS: m8g.4xlarge(16 vCPU, 64GB)
- GCP: c4a-standard-16 또는 n4-standard-16(16 vCPU, 64GB)
- Azure: Standard_D16ps_v6(16 vCPU, 64GB)
- 저장소: 고성능 티어의 100GB
- 배포: 단일 노드 권장

### 10K 사용자 {#10k-users}

권장 사항: ClickHouse Cloud Scale

GitLab Self-Managed 배포를 위한 대체 권장 사항:

- AWS: m8g.4xlarge(16 vCPU, 64GB)
- GCP: c4a-standard-16 또는 n4-standard-16(16 vCPU, 64GB)
- Azure: Standard_D16ps_v6(16 vCPU, 64GB)
- 저장소: 고성능 티어의 200GB
- HA 옵션: 3노드 클러스터는 중요 워크로드의 경우 실행 가능합니다.

### 25K 사용자 {#25k-users}

권장 사항: ClickHouse Cloud Scale 또는 GitLab Self-Managed용 ClickHouse 두 옵션 모두 이 규모에서 경제적으로 실행 가능합니다.

GitLab Self-Managed 배포를 위한 권장 사항:

- 단일 노드:

  - AWS: m8g.8xlarge(32 vCPU, 128GB)
  - GCP: c4a-standard-32 또는 n4-standard-32(32 vCPU, 128GB)
  - Azure: Standard_D32ps_v6(32 vCPU, 128GB)
- HA 배포:

  - AWS: 3 × m8g.4xlarge(각각 16 vCPU, 64GB)
  - GCP: 3 × c4a-standard-16 또는 3 × n4-standard-16(각각 16 vCPU, 64GB)
  - Azure: 3 x Standard_D16ps_v6(각각 16 vCPU, 64GB)
- 저장소: 고성능 티어당 노드당 400GB

### 50K 사용자 {#50k-users}

권장 사항: ClickHouse for GitLab Self-Managed HA 또는 ClickHouse Cloud Scale 자체 관리 옵션이 이 규모에서 약간 더 비용 효율적입니다.

GitLab Self-Managed 배포를 위한 권장 사항:

- 단일 노드:

  - AWS: m8g.8xlarge(32 vCPU, 128GB)
  - GCP: c4a-standard-32 또는 n4-standard-32(32 vCPU, 128GB)
  - Azure: Standard_D32ps_v6(32 vCPU, 128GB)
- HA 배포(권장):

  - AWS: 3 × m8g.4xlarge(각각 16 vCPU, 64GB)
  - GCP: 3 × c4a-standard-16 또는 3 × n4-standard-16(각각 16 vCPU, 64GB)
  - Azure: 3 x Standard_D16ps_v6(각각 16 vCPU, 64GB)
- 저장소: 고성능 티어당 노드당 1000GB

#### GitLab Self-Managed 배포를 위한 HA 고려 사항 {#ha-considerations-for-clickhouse-for-gitlab-self-managed-deployment}

HA 설정은 10k 사용자 이상에서만 비용 효율적입니다.

- 최소:  쿼럼을 위한 3개의 ClickHouse 노드입니다.
- [ClickHouse Keeper](https://clickhouse.com/clickhouse/keeper): 조정을 위한 3개 노드(함께 배치하거나 별도로 배치할 수 있음)
- 로드 밸런서: 쿼리 분산에 권장합니다.
- 네트워크: 노드 간 낮은 지연 시간 연결이 중요합니다.

## 용어 해설 {#glossary}

- 클러스터: 데이터를 저장하고 처리하기 위해 함께 작동하는 노드(서버)의 모음입니다.
- MergeTree: [`MergeTree`](https://clickhouse.com/docs/engines/table-engines/mergetree-family/mergetree)는 높은 데이터 수집 속도와 대규모 데이터 볼륨을 위해 설계된 ClickHouse의 테이블 엔진입니다. ClickHouse의 핵심 저장소 엔진이며 열 형식 저장소, 사용자 정의 파티셔닝, 희소 기본 인덱스, 백그라운드 데이터 병합 지원 등의 기능을 제공합니다.
- 부분: 테이블 데이터의 일부를 저장하는 디스크의 물리적 파일입니다. 부분은 파티션과 다르며, 파티션은 파티션 키를 사용하여 생성된 테이블 데이터의 논리적 분할입니다.
- 복제: ClickHouse 데이터베이스에 저장된 데이터의 복사본입니다. 중복성 및 안정성을 위해 동일한 데이터의 복제본을 원하는 만큼 가질 수 있습니다. 복제본은 ReplicatedMergeTree 테이블 엔진과 함께 사용되며, 이를 통해 ClickHouse는 여러 서버 전체에서 여러 데이터 복사본을 동기화된 상태로 유지할 수 있습니다.
- 분할: 데이터의 부분집합입니다. ClickHouse는 항상 데이터에 대해 최소 1개의 분할을 가집니다. 여러 서버 간에 데이터를 분할하지 않는 경우 데이터가 하나의 분할에 저장됩니다. 여러 서버 간에 데이터를 분할하면 단일 서버의 용량을 초과할 때 로드를 분산하는 데 사용할 수 있습니다.
- TTL(Time To Live): Time To Live(TTL)는 특정 시간 경과 후 자동으로 열/행을 이동, 삭제 또는 롤업하는 ClickHouse 기능입니다. 더 이상 자주 액세스할 필요가 없는 데이터를 삭제, 이동 또는 보관할 수 있으므로 저장소를 더 효율적으로 관리할 수 있습니다.

## 문제 해결 {#troubleshooting}

### GitLab 18.0.0 이상에서 데이터베이스 스키마 마이그레이션 {#database-schema-migrations-on-gitlab-1800-and-earlier}

> [!warning]
> GitLab 18.0.0 이상에서는 ClickHouse 24.x 및 25.x에 대한 데이터베이스 스키마 마이그레이션 실행이 다음 오류 메시지와 함께 실패할 수 있습니다:
>
> ```plaintext
> Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
> ```
>
> 모든 마이그레이션을 실행하지 않으면 ClickHouse 통합이 작동하지 않습니다.

이 이슈를 해결하고 마이그레이션을 실행하려면:

1. [Rails 콘솔](../administration/operations/rails_console.md#starting-a-rails-console-session)에 로그인하세요.
1. 다음 명령을 실행하세요:

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. 데이터베이스를 다시 마이그레이션합니다:

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

이번에는 데이터베이스 마이그레이션이 성공적으로 완료됩니다.

### 데이터베이스 사전 읽기 지원 {#database-dictionary-read-support}

GitLab 18.8부터 GitLab은 데이터 역정규화를 위해 [ClickHouse 사전](https://clickhouse.com/docs/dictionary)을 사용하기 시작합니다. 18.8 이전의 `GRANT` 명령문은 `gitlab` 사용자에게 사전을 쿼리할 수 있는 권한을 부여하지 않으므로 수동 수정 단계가 필요합니다:

1. 로그인합니다:
   - ClickHouse Cloud의 경우 ClickHouse SQL 콘솔입니다.
   - GitLab Self-Managed용 ClickHouse의 경우 `clickhouse-client`입니다.
1. 다음 명령을 실행하여 `PASSWORD_HERE`을 생성된 비밀번호로 바꿉니다.

{{< tabs >}}

{{< tab title="Single-node or ClickHouse Cloud" >}}

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
```

{{< /tab >}}

{{< tab title="HA ClickHouse for GitLab Self-Managed" >}}

`CLUSTER_NAME_HERE`을 클러스터의 이름으로 바꿉니다:

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

권한을 부여하지 않으면 ClickHouse 마이그레이션(`CreateNamespaceTraversalPathsDict`)이 다음 오류와 함께 실패합니다:

```plaintext
DB::Exception: gitlab: Not enough privileges.
```

권한을 부여한 후 마이그레이션을 안전하게 재시도할 수 있습니다(이상적으로 분산 마이그레이션 잠금이 해제될 때까지 1-2시간 기다립니다).

### ClickHouse CI 작업 데이터 구체화된 보기 데이터 불일치 {#clickhouse-ci-job-data-materialized-view-data-inconsistencies}

GitLab 18.5 이상에서는 Sidekiq 워커가 네트워크 시간 초과 후 재시도할 때 중복 데이터가 ClickHouse 테이블(`ci_finished_pipelines` 및 `ci_finished_builds` 등)에 삽입될 수 있습니다. 이 이슈로 인해 구체화된 보기에서 분석 대시보드(러너 플릿 대시보드 포함)에 잘못된 집계 메트릭이 표시됩니다.

이 이슈는 GitLab 18.9에서 수정되었으며 18.6, 18.7, 18.8로 백포팅되었습니다. 이 이슈를 해결하려면 GitLab 18.6 이상으로 업그레이드하세요.

기존 중복 데이터가 있는 경우 영향을 받는 구체화된 보기를 재구성하는 수정이 [issue 586319](https://gitlab.com/gitlab-org/gitlab/-/issues/586319)의 GitLab 18.10에 계획되어 있습니다. 지원을 받으려면 GitLab Support에 문의하세요.
