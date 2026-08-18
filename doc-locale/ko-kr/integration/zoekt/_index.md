---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoekt
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  제한적 출시

{{< /details >}}

{{< history >}}

- [GitLab 15.9에서](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) [베타](../../policy/development_stages_support.md#beta)로 [기능 플래그](../../administration/feature_flags/_index.md) `index_code_with_zoekt`, `search_code_with_zoekt`로 도입되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 16.6에서 [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/388519).
- 전역 코드 검색이 GitLab 16.11에서 [기능 플래그](../../administration/feature_flags/_index.md) `zoekt_cross_namespace_search`로 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077). 기본적으로 비활성화되었습니다.
- GitLab 17.1에서 기능 플래그 `index_code_with_zoekt` 및 `search_code_with_zoekt` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378).
- 기능 플래그 `zoekt_rollout_worker`이 GitLab 17.9에서 [추가되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175666). 기본적으로 비활성화되었습니다.
- GitLab 18.6에서 베타에서 제한적 출시로 [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/17918).
- 기능 플래그 [`zoekt_cross_namespace_search`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) 및 [`zoekt_rollout_worker`](https://gitlab.com/gitlab-org/gitlab/-/issues/519660)가 GitLab 18.7에서 제거되었습니다.

{{< /history >}}

> [!warning]
> 이 기능은 [제한적 출시](../../policy/development_stages_support.md#limited-availability) 상태입니다. 자세한 내용은 [에픽 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)를 참조하세요. [이슈 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)에서 피드백을 제공하세요.

Zoekt는 특별히 코드를 검색하기 위해 설계된 오픈 소스 검색 엔진입니다.

이 통합을 통해 GitLab에서 코드를 검색하기 위해 [고급 검색](../../user/search/advanced_search.md) 대신 [정확한 코드 검색](../../user/search/exact_code_search.md)을 사용할 수 있습니다. 정확한 일치 및 정규 표현식 모드를 사용하여 그룹 또는 리포지토리에서 코드를 검색할 수 있습니다.

> [!note]
> Zoekt는 코드 검색만 처리하며 [Elasticsearch 또는 OpenSearch](../advanced_search/elasticsearch.md)를 대체하지 않습니다. 주석, 커밋, 에픽, 이슈, 머지 리퀘스트, 마일스톤, 프로젝트, 사용자 및 위키를 포함한 다른 모든 검색 범위에는 Elasticsearch 또는 OpenSearch가 여전히 필요합니다.

## 버전 호환성 {#version-compatibility}

각 GitLab 버전에는 특정 `gitlab-zoekt-indexer` 및 `gitlab-zoekt` 차트 버전이 포함됩니다.

| GitLab 버전 | `gitlab-zoekt-indexer` 버전 | `gitlab-zoekt` 차트 버전 |
|----------------|--------------------------------|------------------------------|
| 19.1           | 1.16.1                         | 4.1.0                        |
| 19.0           | 1.14.2                         | 4.0.0                        |
| 18.11          | 1.13.1                         | 3.11.0                       |
| 18.10          | 1.11.2                         | 3.10.0                       |
| 18.9           | 1.8.2                          | 3.9.0                        |
| 18.8           | 1.8.0                          | 3.8.0                        |
| 18.6 및 18.7  | 1.7.6                          | 3.7.1                        |

## Zoekt 설치 {#install-zoekt}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

GitLab에서 [정확한 코드 검색](#enable-exact-code-search)을 활성화하려면 인스턴스에 연결된 Zoekt 노드가 최소 하나 있어야 합니다. Zoekt에서 지원되는 설치 방법은 다음과 같습니다:

- [Zoekt 차트](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/) (GitLab Helm 차트의 독립 실행형 차트 또는 하위 차트로)
- [GitLab Operator](https://docs.gitlab.com/operator/) (`gitlab-zoekt.install=true` 포함)

다음 설치 방법은 테스트용이며 프로덕션 용도로는 지원되지 않습니다:

- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Ansible 플레이북](https://gitlab.com/gitlab-org/search-team/code-search/ansible-gitlab-zoekt)

## 정확한 코드 검색 활성화 {#enable-exact-code-search}

### GitLab UI에서 {#from-the-gitlab-ui}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.
- [Zoekt 설치됨](#install-zoekt).

GitLab UI에서 [정확한 코드 검색](../../user/search/exact_code_search.md)을 활성화하려면 다음과 같이 하세요:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱싱 활성화** 및 **검색 활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### Rake 작업 포함 {#with-rake-tasks}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/580121)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.
- [Zoekt 설치됨](#install-zoekt).

Rake 작업으로 [정확한 코드 검색](../../user/search/exact_code_search.md)을 관리할 수 있습니다.

#### 인덱싱 및 검색 활성화 {#enable-indexing-and-search}

인덱싱 및 검색을 활성화하려면 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:index
```

이 작업은 `zoekt_indexing_enabled`, `zoekt_search_enabled` 및 `zoekt_auto_index_root_namespace`을 활성화합니다. `RolloutWorker`은 모든 루트 네임스페이스를 자동으로 인덱싱하고 인덱스가 준비되면 검색을 사용할 수 있습니다.

#### 인덱싱 및 검색 비활성화 {#disable-indexing-and-search}

인덱싱 및 검색을 비활성화하려면 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:disable
```

이 작업은 `zoekt_indexing_enabled` 및 `zoekt_search_enabled`를 모두 비활성화합니다.

#### 인덱싱 일시 중지 및 재개 {#pause-and-resume-indexing}

인덱싱을 일시 중지하려면 (예: 유지 관리 중) 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

인덱싱을 재개하려면 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### 스토리지 요구 사항 추정 {#estimate-storage-requirements}

Zoekt 노드에 필요한 스토리지를 추정하려면 이 Rake 작업을 실행합니다:

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

자세한 내용은 [스토리지 요구 사항 추정](#estimate-requirements)을 참조하세요.

#### 실패한 리포지토리 인덱싱 재시도 {#retry-indexing-of-failed-repositories}

{{< history >}}

- GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239608)되었습니다.

{{< /history >}}

모든 `failed` Zoekt 리포지토리 레코드를 다시 인덱싱하려면 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:reindex_failed_projects
```

이 작업은 모든 `failed` `zoekt_repository` 레코드를 `pending` 상태로 이동하고 `retries_left`을 `1`로 설정하므로 다음 인덱싱 주기에 선택됩니다.

특정 프로젝트만 다시 인덱싱하려면 쉼표로 구분된 프로젝트 ID 목록을 전달합니다:

```shell
gitlab-rake "gitlab:zoekt:reindex_failed_projects[1,2,3]"
```

## 인덱싱 상태 확인 {#check-indexing-status}

{{< history >}}

- Zoekt 노드 스토리지가 중요 워터마크를 초과할 때 인덱싱 중지는 GitLab 17.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/504945)되었으며 [기능 플래그](../../administration/feature_flags/_index.md) `zoekt_critical_watermark_stop_indexing` 포함합니다. 기본적으로 비활성화되었습니다.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/505334) (GitLab 18.0).
- GitLab 18.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/505334)합니다. `zoekt_critical_watermark_stop_indexing` 기능 플래그가 제거되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인덱싱 성능은 Zoekt 인덱서 노드의 CPU 및 메모리 제한에 따라 다릅니다. 인덱싱 상태를 확인하려면 다음을 수행합니다:

{{< tabs >}}

{{< tab title="GitLab 17.10 및 이후 버전" >}}

이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:info
```

데이터가 매 10초마다 자동으로 새로 고침되도록 하려면 대신 이 Rake 작업을 실행합니다:

```shell
gitlab-rake "gitlab:zoekt:info[10]"
```

{{< /tab >}}

{{< tab title="GitLab 17.9 및 이전 버전" >}}

[Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행합니다:

```ruby
Search::Zoekt::Index.group(:state).count
Search::Zoekt::Repository.group(:state).count
Search::Zoekt::Task.group(:state).count
```

{{< /tab >}}

{{< /tabs >}}

### 샘플 출력 {#sample-output}

`gitlab:zoekt:info` Rake 작업은 다음과 유사한 출력을 반환합니다:

```console
Exact Code Search
GitLab version:                                                 19.1.0
Enable indexing:                                                yes
Enable searching:                                               yes
Pause indexing:                                                 no
Index root namespaces automatically:                            yes
Cache search results for five minutes:                          yes
Indexing CPU to tasks multiplier:                               1.0
Probability of random force reindexing (percentage):            0.25
Number of parallel processes per indexing task:                 1
Number of namespaces per indexing rollout:                      32
Offline nodes automatically deleted after:                      20m
Indexing timeout per project:                                   30m
Maximum number of files per project to be indexed:              500000
Maximum file size for indexing:                                 1MB
Maximum trigrams per file:                                      20000
Retry interval for failed namespaces:                           1d
Number of replicas per namespace:                               1
Maximum number of projects for legacy search:                   1000
Maximum number of process restarts within 15 minutes for nodes: 3

Nodes
# Number of Zoekt nodes and their status
Node count:                   2 (online: 2, offline: 0)
Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
Max schema_version:           2601
Storage reserved / usable:    71.1 MiB / 124 GiB (0.06%)
Storage indexed / reserved:   42.7 MiB / 71.1 MiB (60.0%)
Storage used / total:         797 GiB / 921 GiB (86.54%)
Online node watermark levels: 2
  - low: 2

Indexing status
Group count:                      8
# Number of enabled namespaces and their status
EnabledNamespace count:           8 (without indices: 0, rollout blocked: 0, with search disabled: 0)
Replicas count:                   8
  - ready: 8
Indices count:                    8
  - ready: 8
Indices watermark levels:         8
  - healthy: 8
Repositories count:               10
  - ready: 10
Tasks count:                      10
  - done: 10
Tasks pending/processing by type: (none)
Storage buffer factor:            0.831× [dynamic (observed)]

Feature Flags (Non-Default Values)
Feature flags:  none

Feature Flags (Default Values)
Feature flags:  none

Node Details
Node 1 - test-zoekt-hostname-1:
  Status:                       Online
  Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  # Zoekt build version on the node. Must match GitLab version.
  Zoekt version:                2026.04.15-v1.4.0-1-g89a8871
  Schema version:               2601
Node 2 - test-zoekt-hostname-2:
  Status:                       Online
  Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  Zoekt version:                2026.04.15-v1.4.0-1-g89a8871
  Schema version:               2601
```

## 상태 확인 실행 {#run-a-health-check}

{{< history >}}

- GitLab 18.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203671)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

상태 확인을 실행하여 다음을 포함한 Zoekt 인프라의 상태를 파악합니다:

- 온라인 및 오프라인 노드
- 인덱싱 및 검색 설정
- 검색 API 엔드포인트
- JSON 웹 토큰 생성

상태 확인을 실행하려면 다음 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:health
```

이 작업은 다음을 제공합니다:

- 전체 상태: `HEALTHY`, `DEGRADED` 또는 `UNHEALTHY`
- 감지된 문제를 해결하기 위한 권장 사항
- 자동화 및 모니터링 통합을 위한 종료 코드: `0=healthy`, `1=degraded` 또는 `2=unhealthy`

### 자동으로 확인 실행 {#run-checks-automatically}

상태 확인을 매 10초마다 자동으로 실행하려면 다음 작업을 실행합니다:

```shell
gitlab-rake "gitlab:zoekt:health[10]"
```

출력에는 색상 상태 표시기가 포함되며 다음이 표시됩니다:

- 온라인 및 오프라인 노드 수, 스토리지 사용 경고 및 연결 문제
- 핵심 설정 유효성 검사 및 네임스페이스 및 리포지토리 인덱싱 상태
- 결합된 상태 평가를 포함한 전체 상태: `HEALTHY`, `DEGRADED` 또는 `UNHEALTHY`
- 문제 해결을 위한 권장 사항

## 프로젝트 재인덱싱 강제 {#force-reindex-projects}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/478814)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

프로젝트 범위를 강제 재인덱싱하려면 이 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:reindex_projects ID_FROM=10 ID_TO=20
```

`ID_FROM` 및 `ID_TO`는 프로젝트 ID의 범위를 나타냅니다.

하나의 프로젝트만 강제 재인덱싱하려면 `ID_FROM` 및 `ID_TO`에 대해 동일한 값을 사용합니다. 모든 프로젝트를 강제 재인덱싱하려면 이러한 환경 변수를 사용하지 마세요.

## 인덱싱 일시 중지 {#pause-indexing}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

[정확한 코드 검색](../../user/search/exact_code_search.md)에 대한 인덱싱을 일시 중지하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱싱 일시 정지** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

정확한 코드 검색에 대한 인덱싱을 일시 중지하면 리포지토리의 모든 변경 사항이 대기열에 추가됩니다. 인덱싱을 재개하려면 **Pause indexing for exact code search** 확인란을 선택 해제합니다.

## 루트 네임스페이스를 자동으로 인덱싱 {#index-root-namespaces-automatically}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/455533)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

기존 및 새 루트 네임스페이스를 자동으로 인덱싱할 수 있습니다. 모든 루트 네임스페이스를 자동으로 인덱싱하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **루트 네임스페이스를 자동으로 색인화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정을 활성화하면 GitLab은 다음 모든 프로젝트에 대한 인덱싱 작업을 생성합니다:

- 모든 그룹 및 하위 그룹
- 새 루트 네임스페이스

프로젝트가 인덱싱되면 GitLab은 리포지토리 변경이 감지될 때만 증분 인덱싱을 생성합니다.

이 설정을 비활성화하면 다음과 같습니다:

- 기존 루트 네임스페이스는 계속 인덱싱됩니다.
- 새 루트 네임스페이스는 더 이상 인덱싱되지 않습니다.

## 검색 결과 캐시 {#cache-search-results}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/523213)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

더 나은 성능을 위해 검색 결과를 캐시할 수 있습니다. 이 기능은 기본적으로 활성화되어 있으며 5분 동안 결과를 캐시합니다.

검색 결과를 캐시하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **Cache search results for five minutes** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 동시 인덱싱 작업 설정 {#set-concurrent-indexing-tasks}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481725)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

Zoekt 노드에 대한 CPU 용량에 상대적인 동시 인덱싱 작업의 수를 설정할 수 있습니다.

배수가 높을수록 더 많은 작업을 동시에 실행할 수 있으며 인덱싱 처리량이 증가하지만 CPU 사용량이 증가합니다. 기본값은 `1.0` (CPU 코어당 하나의 작업)입니다.

노드의 성능 및 워크로드에 따라 이 값을 조정할 수 있습니다. 동시 인덱싱 작업의 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **CPU를 작업 배수로 인덱싱** 텍스트 상자에 값을 입력합니다.

   예를 들어, Zoekt 노드에 `4` CPU 코어가 있고 배수가 `1.5`인 경우, 노드의 동시 작업 수는 `6`입니다.
1. **변경 사항 저장**을 선택합니다.

## 랜덤 포스 재인덱싱의 확률 정의 {#define-the-probability-of-random-force-reindexing}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222273)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

프로젝트가 증분 인덱싱 대신 강제 재인덱싱되는 확률을 정의할 수 있습니다. 기본값은 `0.25` (0.25%)입니다.

강제 재인덱싱은 메모리 맵(mmap) 핸들러가 정기적으로 처음부터 인덱스를 다시 빌드하여 부족해지는 것을 방지합니다. 높은 백분율은 특히 매우 큰 리포지토리의 경우 인덱싱 로드를 증가시킵니다.

랜덤 포스 재인덱싱의 확률을 정의하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **랜덤 포스 재색인 확률 (백분율)** 텍스트 상자에 `0`과 `100` 사이의 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱 작업당 병렬 프로세스의 수 설정 {#set-the-number-of-parallel-processes-per-indexing-task}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인덱싱 작업당 병렬 프로세스의 수를 설정할 수 있습니다.

높은 수는 인덱싱 시간을 개선하지만 CPU 및 메모리 사용량이 증가합니다. 기본값은 `1` (인덱싱 작업당 하나의 프로세스)입니다.

노드의 성능 및 워크로드에 따라 이 값을 조정할 수 있습니다. 인덱싱 작업당 병렬 프로세스의 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱식 작업당 병렬 프로세스의 개수** 텍스트 상자에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱 롤아웃당 네임스페이스의 수 설정 {#set-the-number-of-namespaces-per-indexing-rollout}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/536175)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

초기 인덱싱을 위한 `RolloutWorker` 작업당 네임스페이스의 수를 설정할 수 있습니다. 기본값은 `32`입니다. 노드의 성능 및 워크로드에 따라 이 값을 조정할 수 있습니다.

인덱싱 롤아웃당 네임스페이스의 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱싱 롤아웃 당 네임스페이스의 개수** 텍스트 상자에 0보다 큰 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 오프라인 노드가 자동으로 삭제되는 시점 정의 {#define-when-offline-nodes-are-automatically-deleted}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/487162)되었습니다.
- **Delete offline nodes after 12 hours** 확인란이 GitLab 18.1에서 **오프라인 노드는 다음 시간 후에 자동으로 삭제됨** 텍스트 상자로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/issues/536178)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

관련된 인덱스, 리포지토리 및 작업과 함께 특정 기간 후에 오프라인 Zoekt 노드를 자동으로 삭제할 수 있습니다. 기본값은 `12h` (12시간)입니다.

이 설정을 사용하여 Zoekt 인프라를 관리하고 고아 리소스를 방지합니다. 오프라인 노드가 자동으로 삭제되는 시점을 정의하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **오프라인 노드는 다음 시간 후에 자동으로 삭제됨** 텍스트 상자에 (예: `30m` (30분), `2h` (2시간) 또는 `1d` (1일)) 값을 입력합니다. 자동 삭제를 비활성화하려면 `0`으로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트에 대한 인덱싱 타임아웃 정의 {#define-the-indexing-timeout-for-a-project}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

프로젝트에 대한 인덱싱 타임아웃을 정의할 수 있습니다. 기본값은 `30m` (30분)입니다.

프로젝트에 대한 인덱싱 타임아웃을 정의하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **프로젝트당 인덱싱 타임아웃** 텍스트 상자에 (예: `30m` (30분), `2h` (2시간) 또는 `1d` (1일)) 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트에서 인덱싱할 파일의 최대 수 설정 {#set-the-maximum-number-of-files-in-a-project-to-be-indexed}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/539526)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

프로젝트에서 인덱싱할 수 있는 파일의 최대 수를 설정할 수 있습니다. 기본 브랜치에서 이 제한보다 많은 파일이 있는 프로젝트는 인덱싱되지 않습니다. 기본값은 `500,000`입니다.

노드의 성능 및 워크로드에 따라 이 값을 조정할 수 있습니다. 프로젝트에서 인덱싱할 파일의 최대 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **프로젝트당 인덱싱될 파일의 최대 개수** 텍스트 상자에 0보다 큰 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱을 위한 최대 파일 크기 설정 {#set-maximum-file-size-for-indexing}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/581176)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인덱싱할 파일의 최대 크기를 설정할 수 있습니다. 기본값은 `1MB`입니다.

지정된 크기를 초과하는 파일의 경우 파일 이름만 인덱싱됩니다. 이러한 파일은 파일 이름으로만 검색할 수 있습니다.

인덱싱을 위한 최대 파일 크기를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱싱을 위한 최대 파일 크기** 텍스트 상자에 (예: `512B`, `50KB`, `2MB` 또는 `1GB`) 값을 입력합니다. 값은 소문자로도 지정할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

## 인덱싱을 위한 최대 트라이그램 개수 설정 {#set-the-maximum-trigram-count-for-indexing}

{{< history >}}

- GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/584506)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인덱싱할 파일에 대한 최대 트라이그램 수를 설정할 수 있습니다. 기본값은 `20,000`입니다.

트라이그램은 Zoekt가 효율적인 코드 검색에 사용하는 3글자 시퀀스입니다. 이 트라이그램 제한을 초과하는 파일의 경우 파일 이름만 인덱싱됩니다. 높은 제한은 인덱싱 및 검색 성능에 모두 영향을 미칩니다.

인덱싱을 위한 최대 트라이그램 개수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **파일당 최대 트라이그램 수** 텍스트 상자에 0보다 큰 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 실패한 네임스페이스에 대한 재시도 간격 정의 {#define-the-retry-interval-for-failed-namespaces}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이전에 실패한 네임스페이스의 재시도 간격을 정의할 수 있습니다. 기본값은 `1d` (1일)입니다. `0`의 값은 실패한 네임스페이스가 절대 재시도되지 않음을 의미합니다.

실패한 네임스페이스에 대한 재시도 간격을 정의하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **실패한 네임스페이스에 대한 재시도 간격** 텍스트 상자에 (예: `30m` (30분), `2h` (2시간) 또는 `1d` (1일)) 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 네임스페이스당 복제본의 수 설정 {#set-the-number-of-replicas-per-namespace}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214067)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

네임스페이스당 복제본의 수를 설정할 수 있습니다. 기본값은 `1` (네임스페이스당 하나의 복제본)입니다.

네임스페이스당 복제본 수를 늘리면 여러 Zoekt 노드 간에 로드를 분산하여 검색 가용성이 향상됩니다. 복제본이 많을수록 스토리지 요구 사항이 증가합니다.

네임스페이스당 복제본의 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **네임스페이스 당 복제품의 개수** 텍스트 상자에 0보다 큰 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 기존 검색에 대한 최대 프로젝트 수 설정 {#set-the-maximum-number-of-projects-for-legacy-search}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224337)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

순회 ID 인덱싱이 아직 진행 중일 때 그룹에서 검색할 최대 프로젝트 수를 설정할 수 있습니다. 기본값은 `1,000`입니다.

순회 ID 인덱싱이 완료되기 전에 그룹에서 검색하면 GitLab은 이 제한까지 처음 프로젝트(프로젝트 ID 기준)만 검색하고 일부 프로젝트가 결과에 포함되지 않음을 나타내는 경고를 표시합니다. 순회 ID 인덱싱이 완료되면 GitLab은 그룹의 모든 프로젝트를 검색합니다.

기존 검색에 대한 최대 프로젝트 수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **기존 검색에 대한 최대 프로젝트 수** 텍스트 상자에 0보다 큰 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 노드에 대해 프로세스를 다시 시작할 수 있는 최대 횟수 설정 {#set-the-maximum-number-of-process-restarts-for-nodes}

{{< history >}}

- GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/593556)되었습니다.
- Zoekt 1.16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/merge_requests/911)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

노드가 검색 라우팅에서 제외되기 전에 15분 내에 프로세스를 다시 시작할 수 있는 최대 횟수를 설정할 수 있습니다. 기본값은 `2`입니다.

GitLab은 이 설정을 사용하여 크래시루핑 인덱서 또는 웹 서버 프로세스를 감지합니다. 노드에 15분 내에 더 많은 프로세스 재시작이 있으면 노드는 재시작 수가 범위로 돌아올 때까지 검색에서 제외됩니다. `0`의 값은 노드가 단일 재시작 후 제외됨을 의미합니다.

모든 온라인 노드가 제외되면 GitLab은 검색 중단을 방지하기 위해 온라인 노드의 전체 집합으로 돌아갑니다.

노드에 대해 프로세스를 다시 시작할 수 있는 최대 횟수를 설정하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **노드에 대해 15분 이내에 프로세스를 다시 시작할 수 있는 최대 횟수** 텍스트 상자에 0 이상의 숫자를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 별도의 서버에서 Zoekt 실행 {#run-zoekt-on-a-separate-server}

{{< history >}}

- Zoekt에 대한 인증이 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/389749)되었습니다.

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

Zoekt를 GitLab과 다른 서버에서 실행하려면 다음을 수행합니다:

1. [Gitaly 수신 대기 인터페이스 변경](../../administration/gitaly/configure_gitaly.md#change-the-gitaly-listening-interface).
1. [Zoekt 설치](#install-zoekt).

## 크기 조정 권장 사항 {#sizing-recommendations}

다음 권장 사항은 일부 배포에 대해 과도하게 프로비저닝될 수 있습니다. 배포를 모니터링하여 다음을 확인합니다:

- 메모리 부족 이벤트가 발생하지 않습니다.
- CPU 스로틀이 과도하지 않습니다.
- 인덱싱 성능이 요구 사항을 충족합니다.

다음을 포함한 특정 워크로드 특성에 따라 리소스를 조정합니다:

- 리포지토리 크기 및 복잡성
- 활성 개발자 수
- 코드 변경 빈도
- 인덱싱 패턴

### 메모리 아키텍처 {#memory-architecture}

웹 서버와 인덱서는 다양한 메모리 사용 패턴을 가집니다.

웹 서버는 디스크에서 인덱스 샤드를 가상 메모리로 메모리 맵합니다. 운영 체제는 검색이 제공될 때 물리 메모리로 샤드 데이터를 페이징합니다. 상주 메모리 사용량은 활성 작업 집합에 따라 증가합니다. 더 큰 인덱스 또는 더 높은 쿼리 볼륨이 있는 노드는 페이지 스래싱 및 메모리 부족 조건을 방지하기 위해 더 많은 웹 서버 메모리가 필요합니다.

인덱서가 인덱스를 빌드하거나 다시 빌드할 때 인덱서는 메모리에서 Git 객체 데이터를 처리합니다. 큰 리포지토리가 인덱싱되거나 여러 작업이 병렬로 실행될 때 메모리 사용량이 증가합니다. [인덱싱 작업당 병렬 프로세스의 개수](#set-the-number-of-parallel-processes-per-indexing-task) 및 [동시 인덱싱 작업](#set-concurrent-indexing-tasks)의 수를 조정하여 피크 인덱서 메모리를 제어할 수 있습니다.

VM 및 베어 메탈 배포에서 웹 서버와 인덱서는 동일한 시스템 메모리를 공유합니다.

### 노드 {#nodes}

최적의 성능을 위해서는 Zoekt 노드의 적절한 크기 조정이 매우 중요합니다. 크기 조정 권장 사항은 리소스가 할당되고 관리되는 방식으로 인해 Kubernetes와 VM 배포 간에 다릅니다.

#### Kubernetes 배포 {#kubernetes-deployments}

다음 표는 인덱스 스토리지 요구 사항을 기반으로 Kubernetes 배포에 대한 노드당(StatefulSet 포드당) 권장 리소스를 보여줍니다. StatefulSet의 각 포드는 독립적인 리소스 할당 및 인덱스 스토리지용 자체 지속적 볼륨이 있는 자체 웹 서버 및 인덱서 컨테이너를 실행합니다. 여러 노드를 실행하는 경우 이러한 리소스에 노드 수를 곱하여 총 클러스터 리소스를 계산합니다.

| 디스크   | 웹 서버 CPU | 웹 서버 메모리  | 인덱서 CPU | 인덱서 메모리 |
|--------|---------------|-------------------|-------------|----------------|
| 128 GB | 1             | 16 GiB            | 1           | 6 GiB  |
| 256 GB | 1.5           | 32 GiB            | 1           | 8 GiB  |
| 512 GB | 2             | 64 GiB            | 1           | 12 GiB |
| 1 TB   | 3             | 128 GiB           | 1.5         | 24 GiB |
| 2 TB   | 4             | 256 GiB           | 2           | 32 GiB |

리소스를 더 세밀하게 관리하려면 CPU와 메모리를 다른 컨테이너에 별도로 할당할 수 있습니다.

Kubernetes 배포의 경우:

- Zoekt 컨테이너에 대한 CPU 제한을 설정하지 마세요. CPU 제한은 인덱싱 버스트 중에 불필요한 스로틀링을 유발할 수 있으며 성능에 심각한 영향을 미칩니다. 대신 최소 CPU 가용성을 보장하고 필요할 때 컨테이너가 추가 CPU를 사용하도록 하는 리소스 요청을 사용합니다.
- 리소스 경합 및 메모리 부족 조건을 방지하기 위해 적절한 메모리 제한을 설정합니다.
- 더 나은 인덱싱 성능을 위해 고성능 스토리지 클래스를 사용합니다. GitLab.com은 GCP에서 `pd-balanced`을 사용하며 성능과 비용의 균형을 맞춥니다. 동등한 옵션은 AWS의 `gp3` 및 Azure의 `Premium_LRS`을 포함합니다.

#### VM 및 베어 메탈 배포 {#vm-and-bare-metal-deployments}

다음 표는 인덱스 스토리지 요구 사항을 기반으로 VM 및 베어 메탈 배포에 대한 노드당 권장 리소스를 보여줍니다. 여러 노드를 실행하는 경우 이러한 리소스에 노드 수를 곱하여 총 클러스터 리소스를 계산합니다.

| 디스크   | VM 크기  | 총 CPU | 총 메모리 | AWS          | GCP             | Azure |
|--------|----------|-----------|--------------|--------------|-----------------|-------|
| 128 GB | 소형    | 2개 코어   | 16 GB        | `r5.large`   | `n1-highmem-2`  | `Standard_E2s_v3`  |
| 256 GB | 중간   | 4개 코어   | 32GB        | `r5.xlarge`  | `n1-highmem-4`  | `Standard_E4s_v3`  |
| 512 GB | 대형    | 4개 코어   | 64 GB        | `r5.2xlarge` | `n1-highmem-8`  | `Standard_E8s_v3`  |
| 1 TB   | X-Large  | 8개 코어   | 128 GB       | `r5.4xlarge` | `n1-highmem-16` | `Standard_E16s_v3` |
| 2 TB   | 2X-Large | 16개 코어  | 256 GB       | `r5.8xlarge` | `n1-highmem-32` | `Standard_E32s_v3` |

이러한 리소스를 전체 노드에만 할당할 수 있습니다.

VM 및 베어 메탈 배포의 경우:

- CPU, 메모리 및 디스크 사용량을 모니터링하여 병목 현상을 식별합니다.
- 더 나은 인덱싱 성능을 위해 SSD 스토리지 사용을 고려합니다.
- GitLab과 Zoekt 노드 간의 데이터 전송을 위해 적절한 네트워크 대역폭을 보장합니다.

### 스토리지 {#storage}

Zoekt 스토리지 요구 사항은 Git 리포지토리의 크기 및 복제본 구성에 따라 다릅니다. Zoekt는 Git 객체 데이터(소스 코드 및 커밋 기록)만 인덱싱합니다. LFS 파일, CI/CD 아티팩트, 패키지, 위키 또는 기타 스토리지 구성 요소는 인덱싱하지 않습니다.

#### 요구 사항 추정 {#estimate-requirements}

스토리지 요구 사항을 추정하려면 이 Rake 작업을 실행합니다:

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

이 작업은 GitLab 데이터베이스를 쿼리하고 현재 리포지토리 크기 및 복제본 구성을 기반으로 스토리지 추정치를 출력합니다.

수동으로 스토리지 요구 사항을 계산하려면 대신 다음 공식을 사용합니다:

```plaintext
storage_per_replica = sum(repository_git_size) × buffer_factor
total_cluster_storage = storage_per_replica × number_of_replicas
```

`repository_git_size`은 각 리포지토리의 Git 객체 크기입니다. 이 값에는 LFS 객체, 위키, 아티팩트 또는 패키지가 포함되지 않습니다. `buffer_factor`은 초기 인덱싱 중 여유 공간입니다. `Search::Zoekt::Index.global_buffer_factor`로 이 값을 계산할 수 있으며 기본적으로 대부분 `3`입니다.

`repository_git_size`을 보려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다.
1. **리포지토리** 열에서 Git 객체 크기를 봅니다.

초기 프로비저닝 대상의 경우 전체 `repository_git_size`의 3배에 복제본 수를 곱한 값부터 시작합니다. 예를 들어:

- 100GB의 Git 리포지토리 데이터 및 하나의 복제본: 300GB의 Zoekt 스토리지.
- 100GB의 Git 리포지토리 데이터 및 두 복제본: 600GB의 Zoekt 스토리지.

GitLab은 Zoekt이 인덱싱 중에 여유 공간을 가질 수 있도록 이 버퍼를 내부적으로 예약합니다. 초기 인덱싱이 완료된 후 실제 디스크 사용량은 일반적으로 GitLab.com에서 관찰된 데이터를 기반으로 `repository_git_size`의 절반에 가깝습니다. 필요할 때만 수직 또는 수평으로 확장합니다.

현재 버퍼 팩터를 보려면 이 Rake 작업을 실행합니다:

```shell
sudo gitlab-rake gitlab:zoekt:info
```

출력에는 **Storage buffer factor**가 포함되며 플래너가 사용 중인 동적 값을 보여줍니다.

Zoekt 노드 스토리지를 모니터링하려면 [인덱싱 상태 확인](#check-indexing-status)을 참조하세요. 네임스페이스가 디스크 공간 부족으로 인해 인덱싱되지 않으면 노드를 추가하거나 디스크 용량을 늘립니다.

## 보안 및 인증 {#security-and-authentication}

Zoekt는 GitLab, Zoekt 인덱서 및 Zoekt 웹 서버 구성 요소 간의 통신을 보호하기 위해 다층 인증 시스템을 구현합니다. 모든 통신 채널에서 인증이 적용됩니다.

모든 인증 방법은 GitLab Shell 시크릿을 사용합니다. 실패한 인증 시도는 `401 Unauthorized` 응답을 반환합니다.

### Zoekt 인덱서에서 GitLab로 {#zoekt-indexer-to-gitlab}

Zoekt 인덱서는 인덱싱 작업을 검색하고 완료 콜백을 보내기 위해 JSON 웹 토큰(JWT)으로 GitLab에 인증합니다.

이 방법은 `.gitlab_shell_secret`을 서명 및 검증에 사용합니다. 토큰은 `Gitlab-Shell-Api-Request` 헤더에서 전송됩니다. 다음 엔드포인트를 사용할 수 있습니다:

- 작업 검색을 위한 `GET /internal/search/zoekt/:uuid/heartbeat`
- 상태 업데이트를 위한 `POST /internal/search/zoekt/:uuid/callback`

이 방법은 Zoekt 인덱서 노드와 GitLab 간의 안전한 폴링 및 상태 보고를 보장합니다.

### GitLab에서 Zoekt 웹 서버로 {#gitlab-to-the-zoekt-webserver}

#### JWT 인증 {#jwt-authentication}

{{< history >}}

- JWT 인증이 GitLab Zoekt 1.0.0에서 [도입](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/releases/v1.0.0)되었습니다.

{{< /history >}}

GitLab은 검색 쿼리를 실행하기 위해 JSON 웹 토큰(JWT)으로 Zoekt 웹 서버에 인증합니다. JWT 토큰은 다른 GitLab 인증 패턴과 일치하는 시간 제한 암호화 서명 인증을 제공합니다.

이 방법은 `Gitlab::Shell.secret_token` 및 HS256 알고리즘(HMAC 포함 SHA-256)을 사용합니다. 토큰은 `Authorization: Bearer <jwt_token>` 헤더에서 전송되며 노출을 제한하기 위해 5분 후에 만료됩니다.

엔드포인트는 `/webserver/api/search` 및 `/webserver/api/v2/search`를 포함합니다. JWT 클레임은 발급자(`gitlab`) 및 대상(`gitlab-zoekt`)입니다.
