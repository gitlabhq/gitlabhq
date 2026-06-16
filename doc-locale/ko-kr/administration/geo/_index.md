---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo
description: GitLab을 지리적으로 분산하세요.
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Geo는 광범위하게 분산된 개발 팀을 위한 솔루션이며 재해 복구 전략의 일부로 웜 스탠바이를 제공합니다. Geo는 바로 사용할 수 있는 HA 솔루션이 **아닙니다**.

> [!warning]
> Geo는 릴리스마다 상당한 변경 사항이 발생합니다. 업그레이드는 지원되며 [문서화됩니다](#upgrading-geo). 단, 설치에 올바른 문서 버전을 사용하고 있는지 확인해야 합니다.

올바른 문서 버전을 사용하고 있는지 확인하려면 [GitLab.com의 Geo 페이지](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/geo/_index.md)로 이동하여 **브랜치/태그 전환** 드롭다운 목록에서 적절한 릴리스를 선택하세요. 예를 들어, [`v15.7.6-ee`](https://gitlab.com/gitlab-org/gitlab/-/blob/v15.7.6-ee/doc/administration/geo/_index.md).

큰 리포지토리를 가져오는 작업은 단일 GitLab 인스턴스에서 멀리 떨어진 팀과 러너의 경우 오랜 시간이 걸릴 수 있습니다.

Geo는 지리적으로 원격 팀에 가까운 곳에 배치할 수 있는 로컬 캐시를 제공하며, 이를 통해 읽기 요청을 처리할 수 있습니다. 이를 통해 대용량 리포지토리를 복제하고 가져오는 데 걸리는 시간을 줄일 수 있으며, 개발 속도를 높이고 원격 팀의 생산성을 향상할 수 있습니다.

Geo 세컨더리 사이트는 쓰기 요청을 프라이머리 사이트로 투명하게 프록시합니다. 모든 Geo 사이트는 단일 GitLab URL에 응답하도록 구성할 수 있으므로, 사용자가 어느 사이트에 접속하든 일관성 있고 원활한 포괄적인 환경을 제공합니다.

Geo는 [Geo 용어집](glossary.md)에 설명된 정의된 용어 집합을 사용합니다. 이러한 용어에 대해 충분히 숙지하세요.

## 사용 사례 {#use-cases}

Geo 구현은 여러 사용 사례를 해결합니다. 이 섹션은 의도된 사용 사례 중 일부를 제공하고 그 장점을 강조합니다.

### 지역 재해 복구 {#regional-disaster-recovery}

Geo를 [재해 복구](disaster_recovery/_index.md) 솔루션으로 사용하면 프라이머리 사이트와 다른 지역에 웜 스탠바이 세컨더리 사이트를 확보할 수 있습니다. 데이터는 세컨더리 사이트에 지속적으로 동기화되어 항상 최신 상태를 유지합니다. 데이터 센터 또는 네트워크 중단 또는 하드웨어 장애와 같은 재해가 발생한 경우, 완전히 작동하는 세컨더리 사이트로 페일오버할 수 있습니다. [계획된 페일오버](disaster_recovery/planned_failover.md)를 통해 재해 복구 프로세스 및 인프라를 테스트할 수 있습니다.

이점:

- 지역 재해 발생 시 비즈니스 연속성.
- 낮은 복구 시간 목표(RTO) 및 복구 시점 목표(RPO).
- GitLab Environment Toolkit(GET)을 사용한 자동화된(단, 자동이 아닌) 페일오버.
- 최소한의 운영 노력 - 무인의 지속적인 복제 및 검증을 통해 세컨더리 사이트가 최신 상태이고 복제된 데이터가 전송 중 또는 저장 중에 손상되지 않도록 합니다.

### 원격 팀 가속화 {#remote-team-acceleration}

Geo 세컨더리 사이트를 원격 팀에 지리적으로 더 가깝게 설정하여 읽기 작업을 가속화하는 로컬 캐시를 제공합니다. 여러 Geo 세컨더리 사이트를 보유할 수 있으며, 각각은 원격 팀이 필요로 하는 프로젝트만 동기화하도록 맞춤설정할 수 있습니다. [투명한 프록시](secondary_proxy/_index.md) 및 [통합 URL](replication/location_aware_git_url.md)을 사용한 지리적 라우팅은 일관성 있고 원활한 개발자 환경을 보장합니다.

이점:

- 지리적으로 분산된 팀을 위한 GitLab 환경을 개선합니다. Geo는 세컨더리 사이트에서 완전한 GitLab 환경을 제공합니다. 하나의 프라이머리 GitLab 사이트를 유지하면서 분산된 각 팀에 대해 읽기-쓰기 액세스 및 완전한 UI 환경을 가진 세컨더리 사이트를 활성화합니다.
- 분산된 개발자가 대용량 리포지토리 및 프로젝트를 복제하고 가져오는 데 걸리는 시간을 분 단위에서 초 단위로 줄입니다.
- 모든 개발자가 위치에 관계없이 아이디어를 공유하고 병렬로 작업할 수 있도록 합니다.
- 프라이머리 및 세컨더리 사이트 간의 읽기 로드를 균형있게 분산합니다.
- 원격 사무소 간의 느린 연결을 극복하고, 분산된 팀의 속도를 개선하여 시간을 절약합니다.
- 자동화된 작업, 사용자 지정 통합 및 내부 워크플로우의 로딩 시간을 단축합니다.

### CI/CD 트래픽 오프로드 {#cicd-traffic-offload}

CI/CD 러너를 구성하여 [Geo 세컨더리 사이트에서 복제](secondary_proxy/runners.md)할 수 있습니다. 세컨더리 사이트를 러너 워크로드의 요구에 맞게 조정할 수 있으며, 프라이머리 사이트를 미러링할 필요가 없습니다. 지원되는 읽기 요청은 세컨더리 사이트의 캐시된 데이터로 처리되며, 세컨더리 사이트의 데이터가 오래되었거나 사용할 수 없을 때 요청은 프라이머리 사이트로 투명하게 전달됩니다.

이점:

- 트래픽을 세컨더리 사이트로 이동하여 프라이머리 사이트에서 CI/CD 트래픽이 사용자 환경에 미치는 영향을 줄입니다.
- 크로스 리전 트래픽을 줄이고 CI/CD 컴퓨팅 시간을 조직에 가장 경제적인 위치에 배치합니다. 데이터의 단일 크로스 리전 사본을 생성하고 세컨더리 사이트에 대한 반복된 읽기 요청에 사용 가능하게 합니다.

### 추가 사용 사례 {#additional-use-cases}

#### 인프라 마이그레이션 {#infrastructure-migrations}

Geo를 사용하여 새로운 인프라로 마이그레이션할 수 있습니다. GitLab 인스턴스를 새 서버 또는 데이터 센터로 이동하는 경우, Geo를 사용하여 이전 인스턴스가 계속 사용자에게 서비스를 제공하는 동안 백그라운드에서 GitLab 데이터를 새 인스턴스로 마이그레이션할 수 있습니다. 활성 GitLab 데이터에 대한 모든 변경 사항이 새 인스턴스에 복사되므로 전환 중에 데이터 손실이 없습니다.

Geo를 사용하여 PostgreSQL 데이터베이스를 한 운영 체제에서 다른 운영 체제로 마이그레이션할 수 없습니다. [PostgreSQL의 운영 체제 업그레이드](../postgresql/upgrading_os.md)를 참조하세요.

이점:

- 백업 및 복원 마이그레이션 방법과 비교하여 마이그레이션 중 다운타임을 크게 줄입니다. 활성 GitLab 인스턴스를 중지하기 전의 전환 다운타임 창 없이 백그라운드에서 새 인스턴스에 데이터를 복사합니다.

#### GitLab Dedicated로 마이그레이션 {#migration-to-gitlab-dedicated}

Geo를 사용하여 GitLab Self-Managed를 [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)로 마이그레이션할 수도 있습니다. GitLab Dedicated로의 마이그레이션은 인프라 마이그레이션과 유사합니다.

더 많은 정보는 [Geo를 사용하여 GitLab Dedicated로 마이그레이션](../dedicated/geo_migration.md)을 참조하세요.

이점:

- 훨씬 낮은 다운타임으로 더 원활한 온보딩 경험. 데이터 마이그레이션이 백그라운드에서 진행되는 동안 팀은 GitLab Self-Managed를 계속 사용할 수 있습니다.

## Geo가 해결하도록 설계되지 않은 것 {#what-geo-is-not-designed-to-address}

Geo는 모든 사용 사례를 해결하도록 설계되지 않았습니다. 이 섹션은 Geo가 적절한 솔루션이 아닌 사용 사례의 예를 제공합니다.

### 데이터 내보내기 규정 준수 시행 {#enforce-data-export-compliance}

Geo의 [선택적 동기화](replication/selective_synchronization.md) 기능을 사용하면 세컨더리 사이트에 동기화되는 프로젝트를 제한할 수 있지만, 이는 내보내기 규정 준수를 강제하지 않고 크로스 리전 트래픽 및 저장소 요구 사항을 줄이기 위해 설계되었습니다. 개인정보 보호, 사이버 보안 및 적용 가능한 무역 통제법과 관련된 법적 의무를 지속적으로 독립적으로 결정해야 합니다. 솔루션과 문서 모두 변경 대상입니다.

### 접근 제어 제공 {#provide-access-control}

Geo [읽기 전용 세컨더리 사이트](secondary_proxy/_index.md#disable-secondary-site-git-proxying) 기능은 최고 수준의 기능이 아니며 향후 지원되지 않을 수 있습니다. 접근 제어 목적으로 이 기능을 사용하지 않아야 합니다. GitLab은 이 목적을 더 잘 제공하는 [인증 및 권한 부여](../auth/_index.md) 제어를 제공합니다.

### 무중단 업그레이드에 대한 대안 {#an-alternative-to-zero-downtime-upgrades}

Geo는 [무중단 업그레이드](../../update/zero_downtime.md)를 위한 솔루션이 아닙니다. 세컨더리 사이트를 업그레이드하기 전에 프라이머리 Geo 사이트를 업그레이드해야 합니다.

### 악의적이거나 의도하지 않은 손상으로부터 보호 {#protect-against-malicious-or-unintentional-corruption}

Geo는 프라이머리 사이트의 손상을 모든 세컨더리 사이트에 복제합니다. 악의적이거나 의도하지 않은 손상으로부터 보호하려면 Geo를 [백업](../backup_restore/_index.md)으로 보완해야 합니다.

### 액티브-액티브, 고가용성 구성 {#active-active-high-availability-configuration}

Geo는 액티브-패시브 고가용성 솔루션으로 설계되었습니다. 최종적으로 일관성이 있는 동기화 모델을 운영합니다. 즉, 세컨더리 사이트가 프라이머리 사이트와 긴밀하게 동기화되지 않습니다. 세컨더리 사이트는 프라이머리를 약간 지연하여 따라가며, 재해 후 소량의 데이터 손실이 발생할 수 있습니다. 재해 발생 시 세컨더리 사이트로의 페일오버에는 인적 개입이 필요합니다. 다만, 세컨더리 사이트를 프라이머리로 승격하는 프로세스의 대부분은 [GitLab Environment Toolkit(GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit)에 의해 자동화되며, GET을 사용하여 모든 사이트를 배포할 경우입니다.

## Gitaly Cluster(Praefect) {#gitaly-cluster-praefect}

Geo를 [Gitaly Cluster(Praefect)](../gitaly/praefect/_index.md)와 혼동하지 않아야 합니다. Geo와 Gitaly Cluster(Praefect)의 차이에 대한 더 많은 정보는 [Geo로의 비교](../gitaly/praefect/_index.md#comparison-to-geo)를 참조하세요.

## Geo 작동 방식 {#how-geo-works}

이는 GitLab 환경에서 Geo가 어떻게 작동하는지에 대한 간단한 요약입니다. 더 많은 정보는 Geo 개발 문서를 참조하세요.

Geo 인스턴스는 프로젝트 복제 및 가져오기에 추가로 모든 데이터를 읽는 데 사용할 수 있습니다. 이는 대용량 리포지토리를 큰 거리에서 작업하는 것을 훨씬 더 빠르게 만듭니다.

![Geo 개요](img/geo_overview_v11_5.png)

Geo가 활성화되면:

- 원래 인스턴스는 **프라이머리** 사이트로 알려져 있습니다.
- 복제 사이트는 **세컨더리** 사이트로 알려져 있습니다.

다음 사항을 유의하세요:

- **세컨더리** 사이트는 **프라이머리** 사이트와 통신합니다:
  - 로그인을 위한 사용자 데이터 가져오기(API).
  - 리포지토리, LFS 객체 및 첨부 파일 복제(HTTPS + JWT).
- **프라이머리** 사이트는 복제 세부 정보를 보기 위해 **세컨더리** 사이트와 통신합니다. **프라이머리**는 동기화 및 검증 데이터에 대해 **세컨더리** 사이트에 대해 GraphQL 쿼리를 수행합니다(API).
- **세컨더리** 사이트에 직접 푸시할 수 있으며(HTTP 및 SSH 모두, Git LFS 포함), 요청이 **프라이머리** 사이트에 프록시됩니다.
- Geo를 사용할 때 일부 [알려진 문제](#known-issues)가 있습니다.

### 아키텍처 {#architecture}

다음 다이어그램은 Geo의 기본 아키텍처를 보여줍니다.

![Geo 아키텍처](img/geo_architecture_v13_8.png)

이 다이어그램에서:

- **프라이머리** 사이트 및 하나의 **세컨더리** 사이트의 세부 정보가 있습니다.
- 데이터베이스에 대한 쓰기는 **프라이머리** 사이트에서만 수행할 수 있습니다. **세컨더리** 사이트는 [PostgreSQL 스트리밍 복제](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION)를 사용하여 데이터베이스 업데이트를 수신합니다.
- 있는 경우 [LDAP 서버](#ldap) 를 구성하여 [재해 복구](disaster_recovery/_index.md) 시나리오를 위해 복제해야 합니다.
- **세컨더리** 사이트는 JWT로 보호되는 특별한 권한을 사용하여 **프라이머리** 사이트에 대해 다양한 유형의 동기화를 수행합니다:
  - 리포지토리는 HTTPS를 통한 Git을 통해 복제/업데이트됩니다.
  - 첨부 파일, LFS 객체 및 기타 파일은 프라이빗 API 엔드포인트를 사용하여 HTTPS를 통해 다운로드됩니다.

Git 작업을 수행하는 사용자의 관점에서:

- **프라이머리** 사이트는 완전한 읽기-쓰기 GitLab 인스턴스로 작동합니다.
- **세컨더리** 사이트는 완전한 읽기-쓰기 GitLab 인스턴스로 작동합니다. **세컨더리** 사이트는 **프라이머리** 사이트로 모든 작업을 투명하게 프록시하며, [일부 주목할 만한 예외](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites)가 있습니다. 특히 Git 페치는 **세컨더리** 사이트가 최신 상태일 때 처리됩니다.

GitLab UI를 탐색하거나 API를 사용하는 사용자의 관점에서:

- **프라이머리** 사이트는 완전한 읽기-쓰기 GitLab 인스턴스로 작동합니다.
- **세컨더리** 사이트는 완전한 읽기-쓰기 GitLab 인스턴스로 작동합니다. **세컨더리** 사이트는 **프라이머리** 사이트로 모든 작업을 투명하게 프록시하며, [일부 주목할 만한 예외](secondary_proxy/_index.md#features-accelerated-by-secondary-geo-sites)가 있습니다. 특히 웹 UI 자산은 **세컨더리** 사이트에서 처리됩니다.

다이어그램을 단순화하기 위해 일부 필요한 구성 요소가 생략되어 있습니다.

- SSH를 통한 Git은 [`gitlab-shell`](https://gitlab.com/gitlab-org/gitlab-shell)를 필요로 합니다.
- HTTPS를 통한 Git은 [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab-workhorse)를 필요로 합니다.

**세컨더리** 사이트는 두 가지 다른 PostgreSQL 데이터베이스가 필요합니다:

- 주 GitLab 데이터베이스에서 데이터를 스트리밍하는 읽기 전용 데이터베이스 인스턴스.
- [읽기/쓰기 데이터베이스 인스턴스(추적 데이터베이스)](#geo-tracking-database)는 **세컨더리** 사이트에서 내부적으로 복제된 데이터를 기록하는 데 사용됩니다.

**세컨더리** 사이트도 추가 데몬을 실행합니다:  [Geo Log Cursor](#geo-log-cursor).

## Geo 실행을 위한 요구 사항 {#requirements-for-running-geo}

다음은 Geo를 실행하기 위해 필요합니다:

- OpenSSH 6.9 이상을 지원하는 운영 체제(데이터베이스에서 권한이 있는 SSH 키의 [빠른 조회](../operations/fast_ssh_key_lookup.md)에 필요). 다음 운영 체제는 현재 버전의 OpenSSH를 제공하는 것으로 알려져 있습니다:
  - [CentOS](https://www.centos.org) 7.4 이상
  - [Ubuntu](https://ubuntu.com) 16.04 이상
- 가능하면, 모든 Geo 사이트에서 동일한 운영 체제 버전을 사용해야 합니다. Geo 사이트 간에 다른 운영 체제 버전을 사용하는 경우, 데이터베이스 인덱스의 무시 손상을 방지하기 위해 Geo 사이트 전체에서 [OS 로케일 데이터 호환성을 확인](replication/troubleshooting/common.md#check-os-locale-data-compatibility) **must** 합니다.
- GitLab 릴리스의 [지원되는 PostgreSQL 버전](https://handbook.gitlab.com/handbook/engineering/data-engineering/database-excellence/database-frameworks/postgresql-upgrade-cadence/) 과 [스트리밍 복제](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION).
  - [PostgreSQL 논리적 복제](https://www.postgresql.org/docs/16/logical-replication.html)는 지원되지 않습니다.
- 모든 사이트는 [동일한 PostgreSQL 버전](setup/database.md#postgresql-replication)을 실행해야 합니다.
- Git 2.9 이상
- LFS를 사용할 때 사용자 측에서 Git-lfs 2.4.2 이상
- 모든 사이트는 정확히 동일한 GitLab 버전을 실행해야 합니다. [주 버전, 부 버전 및 패치 버전](../../policy/maintenance.md#versioning)이 모두 일치해야 합니다.
- 모든 사이트는 동일한 [리포지토리 저장소](../repository_storage_paths.md)를 정의해야 합니다.
- Geo에서 컨테이너 레지스트리를 사용할 때 각 사이트에서 컨테이너 레지스트리 메타데이터 데이터베이스를 위해 별도의 외부 PostgreSQL 인스턴스를 구성해야 합니다. 자세한 내용은 [세컨더리 사이트의 컨테이너 레지스트리](replication/container_registry.md)를 참조하세요.

또한 GitLab [최소 요구 사항](../../install/requirements.md)을 확인하고, 더 나은 환경을 위해 최신 버전의 GitLab을 사용하세요.

Geo는 기본 GitLab 설치 위에 추적 데이터베이스 및 복제 메타데이터를 추가하므로, 리포지토리 데이터가 없는 최소 Geo 배포를 위해 사이트당 최소 40GB의 디스크 공간을 계획합니다. 자세한 내용은 [저장소 요구 사항](../../install/requirements.md#storage)을 참조하세요.

### 방화벽 규칙 {#firewall-rules}

다음 표는 Geo의 **프라이머리** 및 **세컨더리** 사이트 간에 열려 있어야 하는 기본 포트를 나열합니다. 페일오버를 단순화하려면 양방향으로 포트를 열어야 합니다.

| 소스 사이트 | 소스 포트 | 대상 사이트 | 대상 포트 | 프로토콜    |
|-------------|-------------|------------------|------------------|-------------|
| 프라이머리     | 모두         | 세컨더리        | 80               | TCP (HTTP)  |
| 프라이머리     | 모두         | 세컨더리        | 443              | TCP (HTTPS) |
| 세컨더리   | 모두         | 프라이머리          | 80               | TCP (HTTP)  |
| 세컨더리   | 모두         | 프라이머리          | 443              | TCP (HTTPS) |
| 세컨더리   | 모두         | 프라이머리          | 5432             | TCP         |
| 세컨더리   | 모두         | 프라이머리          | 5000             | TCP (HTTPS) |

GitLab에서 사용되는 전체 포트 목록은 [패키지 기본값](../package_information/defaults.md)을 참조하세요.

> [!warning]
> Geo 사이트 간의 PostgreSQL 복제를 위해 내부 VPC 피어링과 같은 프라이빗 네트워크 연결을 사용해야 합니다. PostgreSQL 포트를 인터넷에 노출하지 마세요. PostgreSQL 포트를 인터넷에 노출하면 GitLab 데이터베이스에 대한 완전한 쓰기 권한으로 무단 액세스가 발생할 수 있으며, 전체 GitLab 인스턴스 및 모든 관련 데이터가 손상될 수 있습니다.

또한:

- [웹 터미널](../../ci/environments/_index.md#web-terminals-deprecated) 지원을 위해 로드 밸런서가 WebSocket 연결을 올바르게 처리해야 합니다. HTTP 또는 HTTPS 프록시를 사용할 때 로드 밸런서는 `Connection` 및 `Upgrade` 홉 간 헤더를 통과하도록 구성해야 합니다. 자세한 내용은 [웹 터미널](../integration/terminal.md) 통합 가이드를 참조하세요.
- 포트 443에 HTTPS 프로토콜을 사용할 때 로드 밸런서에 SSL 인증서를 추가해야 합니다. 대신 GitLab 애플리케이션 서버에서 SSL을 종료하려면 TCP 프로토콜을 사용하세요.
- 외부/내부 URL에 `HTTPS`만 사용하는 경우 방화벽에서 포트 80을 열 필요가 없습니다.

#### 내부 URL {#internal-url}

모든 Geo 세컨더리 사이트에서 프라이머리 Geo 사이트로의 HTTP 요청은 프라이머리 Geo 사이트의 내부 URL을 사용합니다. 이것이 **운영자** 영역의 프라이머리 Geo 사이트 설정에서 명시적으로 정의되지 않은 경우, 프라이머리 사이트의 공개 URL이 사용됩니다.

전제 조건:

- 관리자 액세스.

프라이머리 Geo 사이트의 내부 URL을 업데이트하려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 프라이머리 사이트에서 **편집**을 선택합니다.
1. **내부 URL**을 변경한 후 **변경사항 저장**을 선택합니다.

### Geo 추적 데이터베이스 {#geo-tracking-database}

추적 데이터베이스 인스턴스는 로컬 인스턴스에서 업데이트해야 할 사항을 제어하기 위해 메타데이터로 사용됩니다. 예를 들어:

- 새 자산을 다운로드합니다.
- 새 LFS 객체를 가져옵니다.
- 최근에 업데이트된 리포지토리의 변경 사항을 가져옵니다.

복제된 데이터베이스 인스턴스가 읽기 전용이므로, 각 **세컨더리** 사이트에 이 추가 데이터베이스 인스턴스가 필요합니다.

### Geo 로그 커서 {#geo-log-cursor}

이 데몬:

- **프라이머리** 사이트에서 **세컨더리** 데이터베이스 인스턴스로 복제된 이벤트 로그를 읽습니다.
- 실행해야 할 변경 사항으로 Geo 추적 데이터베이스 인스턴스를 업데이트합니다.

추적 데이터베이스 인스턴스에서 무언가가 업데이트되도록 표시되면, **세컨더리** 사이트에서 실행되는 비동기 작업이 필요한 작업을 실행하고 상태를 업데이트합니다.

이 새로운 아키텍처를 통해 GitLab은 사이트 간의 연결 문제에 복원력을 가질 수 있습니다. **세컨더리** 사이트가 **프라이머리** 사이트에서 얼마나 오래 연결이 끊어졌든 관계없이, 올바른 순서로 모든 이벤트를 재생할 수 있으며 **프라이머리** 사이트와 다시 동기화될 수 있습니다.

## 알려진 이슈 {#known-issues}

> [!warning]
> 이러한 알려진 문제는 최신 버전의 GitLab만 반영합니다. 이전 버전을 사용하는 경우 추가 문제가 존재할 수 있습니다.

- 세컨더리 Geo 사이트를 통한 SSH를 통한 Git은 안정적으로 작동하지 않습니다. 더 많은 정보는 [이슈 #413109](https://gitlab.com/gitlab-org/gitlab/-/issues/413109) , [이슈 #417186](https://gitlab.com/gitlab-org/gitlab/-/issues/417186) , [이슈 #454707](https://gitlab.com/gitlab-org/gitlab/-/issues/454707) 및 [이슈 585913](https://gitlab.com/gitlab-org/gitlab/-/issues/585913)을 참조하세요.
- **세컨더리** 사이트에 직접 푸시하면 요청이 [직접 처리](https://gitlab.com/gitlab-org/gitlab/-/issues/1381) 대신 **프라이머리** 사이트로 리디렉션(HTTP의 경우) 또는 프록시됩니다(SSH의 경우). 예를 들어 `https://user:personal-access-token@secondary.tld`와 같이 URI에 자격 증명이 포함된 HTTP를 통한 Git을 사용할 수 없습니다. 더 많은 정보는 [Geo 사이트 사용 방법](replication/usage.md)을 참조하세요.
- **프라이머리** 사이트는 OAuth 로그인이 발생하기 위해 온라인이어야 합니다. 기존 세션 및 Git은 영향을 받지 않습니다. **세컨더리** 사이트가 프라이머리와는 독립적으로 OAuth 공급자를 사용할 수 있도록 하는 지원이 [계획 중입니다](https://gitlab.com/gitlab-org/gitlab/-/issues/208465).
- 설치에는 상황에 따라 약 1시간이 걸릴 수 있는 여러 수동 단계가 필요합니다. [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) Terraform 및 Ansible 스크립트를 사용하여 [참조 아키텍처](../reference_architectures/_index.md)를 기반으로 프로덕션 GitLab 인스턴스를 배포 및 운영하고, 일반적인 일일 작업의 자동화를 포함하는 것을 고려하세요. [에픽 1465](https://gitlab.com/groups/gitlab-org/-/epics/1465)는 Geo 설치를 더욱 향상시킬 것을 제안합니다.
- 이슈/머지 리퀘스트의 실시간 업데이트(예: 긴 폴링을 통해)는 [HTTP 프록시가 비활성화된](secondary_proxy/_index.md#disable-secondary-site-http-proxying) **세컨더리** 사이트에서는 작동하지 않습니다.
- [선택적 동기화](replication/selective_synchronization.md)는 복제되는 리포지토리와 파일만 제한합니다. 전체 PostgreSQL 데이터가 여전히 복제됩니다. 선택적 동기화는 규정 준수/내보내기 제어 사용 사례를 수용하도록 구축되지 않았습니다.
- [Pages 접근 제어](../../user/project/pages/pages_access_control.md)는 세컨더리에서는 작동하지 않습니다. 더 많은 정보는 [이슈 9336](https://gitlab.com/gitlab-org/gitlab/-/issues/9336)을 참조하세요.
- 여러 세컨더리 사이트가 있는 배포에 대한 [재해 복구](disaster_recovery/_index.md)는 모든 승격되지 않은 세컨더리에서 PostgreSQL 스트리밍 복제를 다시 초기화하여 새로운 프라이머리 사이트를 따라야 하기 때문에 다운타임을 초래합니다.
- SSH를 통한 Git의 경우, 어느 사이트를 탐색하든 프로젝트 복제 URL이 올바르게 표시되도록 하려면 세컨더리 사이트가 프라이머리와 동일한 포트를 사용해야 합니다. 더 많은 정보는 [이슈 339262](https://gitlab.com/gitlab-org/gitlab/-/issues/339262)를 참조하세요.
- 백업은 [Geo 세컨더리 사이트에서 실행할 수 없습니다](replication/troubleshooting/postgresql_replication.md#message-error-canceling-statement-due-to-conflict-with-recovery).
- Geo 세컨더리 사이트는 대부분의 경우 파이프라인의 첫 번째 단계에 대한 복제 요청을 가속화(처리)하지 않습니다. 이후 단계도 세컨더리 사이트에 의해 처리된다는 보장이 없습니다. 예를 들어 Git 변경이 크거나 대역폭이 작거나 파이프라인 단계가 짧은 경우입니다. 일반적으로 이후 단계에 대한 복제 요청을 처리합니다. [이슈 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176)은 이에 대한 이유를 논의하고 러너 복제 요청이 세컨더리 사이트에서 처리될 가능성을 높이기 위한 개선 사항을 제안합니다.
- 단일 Git 리포지토리가 충분히 높은 속도로 푸시를 받으면 세컨더리 사이트의 로컬 사본이 영구적으로 오래된 상태가 될 수 있습니다. 이로 인해 해당 리포지토리의 모든 Git 페치가 프라이머리 사이트로 전달됩니다. 더 많은 정보는 [이슈 455870](https://gitlab.com/gitlab-org/gitlab/-/issues/455870)을 참조하세요.
- [프록시](secondary_proxy/_index.md)는 Puma 서비스 또는 Web 서비스의 GitLab 애플리케이션에서만 구현되므로 다른 서비스는 이 동작의 이점을 누리지 못합니다. 요청이 항상 프라이머리로 전송되도록 하려면 [별도 URL](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site)을 사용해야 합니다. 이 서비스에는 다음이 포함됩니다:
  - GitLab 컨테이너 레지스트리 - [별도의 도메인을 사용하도록 구성](../packages/container_registry.md#configure-container-registry-under-its-own-domain)할 수 있습니다. 예: `registry.example.com`. 세컨더리 사이트 컨테이너 레지스트리는 재해 복구 전용으로 사용됩니다. 데이터가 프라이머리 사이트에 전파되지 않기 때문에 사용자를 라우팅하면 안 되며, 특히 푸시의 경우 더욱 그렇습니다.
  - GitLab Pages - [GitLab Pages 실행을 위한 필수 사항](../pages/_index.md#prerequisites)의 일부로 항상 별도의 도메인을 사용해야 합니다.
- [통합 URL](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)을 사용할 때, Let's Encrypt는 동일한 도메인을 통해 두 IP에 도달할 수 없으면 인증서를 생성할 수 없습니다. Let's Encrypt에서 TLS 인증서를 사용하려면 도메인을 Geo 사이트 중 하나로 수동으로 가리키고, 인증서를 생성한 후 다른 모든 사이트에 복사할 수 있습니다.
- [세컨더리 사이트가 별도 URL을 사용](secondary_proxy/_index.md#set-up-a-separate-url-for-a-secondary-geo-site) 할 때 프라이머리 사이트와 다르면, [SAML을 사용하여 세컨더리 사이트에 로그인](replication/single_sign_on.md#saml-with-separate-url-with-proxying-enabled)은 SAML Identity Provider(IdP)가 애플리케이션을 여러 콜백 URL로 구성할 수 있는 경우에만 지원됩니다.
- 옵션 `--depth`이 포함된 Git 복제 및 페치 요청은 세컨더리 사이트에 대해 SSH를 통해 작동하지 않으며, 세컨더리 사이트가 요청 시점에 최신 상태가 아닌 경우 무기한 중지됩니다. 이는 프록시 중 Git SSH를 Git https로 변환하는 것과 관련된 문제 때문입니다. 더 많은 정보는 [이슈 391980](https://gitlab.com/gitlab-org/gitlab/-/issues/391980)을 참조하세요. 위에서 언급한 변환 단계를 포함하지 않는 새로운 워크플로우가 이제 Linux 패키지 GitLab Geo 세컨더리 사이트에 사용 가능하며 기능 플래그로 활성화할 수 있습니다. 자세한 내용은 [이슈 454707의 댓글](https://gitlab.com/gitlab-org/gitlab/-/issues/454707#note_2102067451)을 참조하세요. Cloud Native GitLab Geo 세컨더리 사이트의 수정은 [이슈 5641](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5641)에서 추적됩니다.
- GitLab Geo에서 [상대 URL](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab)을 사용하지 마세요. 사이트 간의 프록시가 끊어집니다. 더 많은 정보는 [이슈 456427](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)을 참조하세요.

### 복제된 데이터 유형 {#replicated-data-types}

모든 GitLab [데이터 유형](replication/datatypes.md) 및 [복제된 데이터 유형](replication/datatypes.md#replicated-data-types)의 완전한 목록이 있습니다.

## 설치 후 문서 {#post-installation-documentation}

**세컨더리** 사이트에 GitLab을 설치하고 초기 구성을 수행한 후, 설치 후 정보에 대해 다음 문서를 참조하세요.

### Geo 설정 {#setting-up-geo}

Geo 구성에 대한 정보는 [Geo 설정](setup/_index.md)을 참조하세요.

### Geo와 Object Storage 구성 {#configuring-geo-with-object-storage}

Geo와 Object storage 구성에 대한 정보는 [Geo와 Object storage](replication/object_storage.md)를 참조하세요.

### 컨테이너 레지스트리 복제 {#replicating-the-container-registry}

컨테이너 레지스트리를 복제하는 방법에 대한 자세한 정보는 [**세컨더리** 사이트용 컨테이너 레지스트리](replication/container_registry.md)를 참조하세요.

### Geo 사이트의 통합 URL 설정 {#set-up-a-unified-url-for-geo-sites}

AWS Route53 또는 Google Cloud DNS로 단일 위치 인식 URL을 설정하는 방법의 예는 [Geo 사이트의 통합 URL 설정](secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)을 참조하세요.

### Single Sign On(SSO) {#single-sign-on-sso}

Single Sign-On(SSO) 구성에 대한 더 많은 정보는 [Geo와 Single Sign-On(SSO)](replication/single_sign_on.md)을 참조하세요.

#### LDAP {#ldap}

LDAP 구성에 대한 더 많은 정보는 [Geo와 Single Sign-On(SSO) > LDAP](replication/single_sign_on.md#ldap)을 참조하세요.

### Geo 튜닝 {#tuning-geo}

Geo 튜닝에 대한 더 많은 정보는 [Geo 튜닝](replication/tuning.md)을 참조하세요.

### 복제 일시 중지 및 재개 {#pausing-and-resuming-replication}

더 많은 정보는 [복제 일시 중지 및 재개](replication/pause_resume_replication.md)를 참조하세요.

### 백필 {#backfill}

**세컨더리** 사이트가 설정되면, **프라이머리** 사이트에서 누락된 데이터를 **backfill** 프로세스로 알려진 복제하기 시작합니다. **프라이머리** 사이트의 **Geo Nodes** 대시보드에서 브라우저의 각 Geo 사이트에서 동기화 프로세스를 모니터링할 수 있습니다.

백필 중에 발생하는 오류는 백필 끝에 재시도되도록 예약됩니다.

### 러너 {#runners}

- 표준 모범 사례인 [러너 플릿](https://docs.gitlab.com/runner/fleet_scaling/) 배포 외에도 러너를 구성하여 Geo 세컨더리에 연결하고 작업 로드를 분산할 수 있습니다. [세컨더리에 대한 러너 등록](secondary_proxy/runners.md)을 참조하세요.
- [페일오버 중 러너 연결](disaster_recovery/planned_failover.md#runner-connectivity-during-failover)을 처리하는 방법도 참조하세요.

### Geo 업그레이드 {#upgrading-geo}

Geo 사이트를 최신 GitLab 버전으로 업데이트하는 방법에 대한 정보는 [Geo 사이트 업그레이드](replication/upgrading_the_geo_sites.md)를 참조하세요.

### 보안 검토 {#security-review}

Geo 보안에 대한 더 많은 정보는 [Geo 보안 검토](replication/security_review.md)를 참조하세요.

## Geo 사이트 제거 {#remove-geo-site}

Geo 사이트 제거에 대한 더 많은 정보는 [**세컨더리** Geo 사이트 제거](replication/remove_geo_site.md)를 참조하세요.

## Geo 비활성화 {#disable-geo}

Geo를 비활성화하는 방법을 알아보려면 [Geo 비활성화](replication/disable_geo.md)를 참조하세요.

## 로그 파일 {#log-files}

Geo는 `geo.log` 파일에 구조화된 로그 메시지를 저장합니다.

Geo 로그에 액세스하고 사용하는 방법에 대한 더 많은 정보는 [로그 시스템 문서의 Geo 섹션](../logs/_index.md#geolog)을 참조하세요.

## 재해 복구 {#disaster-recovery}

재해 복구 상황에서 Geo를 사용하여 데이터 손실을 완화하고 서비스를 복구하는 방법에 대한 정보는 [재해 복구](disaster_recovery/_index.md)를 참조하세요.

## 자주 묻는 질문 {#frequently-asked-questions}

일반적인 질문에 대한 답변은 [Geo FAQ](replication/faq.md)를 참조하세요.

## 문제 해결 {#troubleshooting}

- Geo 문제 해결 단계는 [Geo 문제 해결](replication/troubleshooting/_index.md)을 참조하세요.
- 재해 복구 문제 해결 단계는 [Geo 페일오버 문제 해결](disaster_recovery/failover_troubleshooting.md)을 참조하세요.
