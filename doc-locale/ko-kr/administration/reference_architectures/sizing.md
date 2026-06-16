---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 참조 아키텍처 크기 및 구성 요소별 조정을 정의하는 가이드입니다.
title: 참조 아키텍처 크기 평가
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

적절한 참조 아키텍처를 선택하려면 참조 아키텍처를 기반으로 GitLab 환경을 평가하고 크기를 조정하는 체계적인 접근 방식을 사용해야 합니다.

적절한 참조 아키텍처와 필요한 구성 요소별 조정을 결정하려면 다음 정보를 분석하는 데 도움이 됩니다:

- 초당 요청 수(RPS) 패턴입니다.
- 워크로드 특성입니다.
- 리소스 포화도입니다.

## 시작하기 전에 {#before-you-begin}

복잡한 환경이 있는 경우 이 정보를 사용하여 적절한 참조 아키텍처를 선택할 수 있습니다. 이 수준의 세부 정보가 필요하지 않을 수 있으며 [덜 복잡한 환경에 대한 정보](_index.md)를 사용하여 환경의 크기를 평가할 수 있습니다.

> [!note]
> 전문가의 지도가 필요하신가요? 아키텍처를 올바르게 크기 조정하는 것은 최적의 성능을 위해 매우 중요합니다. 저희 [Professional Services](https://about.gitlab.com/professional-services/) 팀은 특정 아키텍처를 평가하고 성능, 안정성 및 가용성 최적화를 위한 맞춤형 권장 사항을 제공할 수 있습니다.

이 설명서를 따르려면 GitLab 인스턴스와 함께 Prometheus 모니터링을 배포해야 합니다. Prometheus는 적절한 크기 조정 평가에 필요한 정확한 메트릭을 제공합니다.

아직 Prometheus를 구성하지 않았다면:

1. [Prometheus](../monitoring/prometheus/_index.md)를 사용하여 모니터링을 구성합니다. 참조 아키텍처 설명서는 각 환경 크기에 대한 Prometheus 구성에 대한 세부 정보를 제공합니다. 클라우드 네이티브 GitLab의 경우 [`kube-prometheus-stack`](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) Helm 차트를 사용하여 메트릭 스크래핑을 구성할 수 있습니다.
1. 7~14일 동안 데이터를 수집하여 의미 있는 데이터 패턴을 수집합니다.
1. 나머지 정보를 읽으세요.

Prometheus 모니터링을 구성할 수 없는 경우:

- [현재 환경](#analyze-current-environment-and-validate-recommendations) 사양을 가장 가까운 참조 아키텍처와 비교하여 크기를 추정합니다.
- [GitLab RPS Analyzer](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/gitlab-rps-analyzer#gitlab-rps-analyzer)를 사용하여 GitLabSOS 또는 KubeSOS 로그를 사용하여 참조 아키텍처 크기를 평가합니다. 그러나 이것은 메트릭보다 신뢰성이 낮다는 점에 유의하세요.

다른 플랫폼에서 마이그레이션하는 경우 기존 GitLab 메트릭 없이는 다음 PromQL 쿼리를 적용할 수 없습니다. 그러나 일반적인 평가 방법론은 여전히 유효합니다:

1. 예상 워크로드를 기반으로 가장 가까운 참조 아키텍처를 추정합니다.
1. 예상되는 [추가 워크로드](_index.md#additional-workloads)를 식별합니다.
1. 대규모 리포지토리의 수를 평가합니다.
1. 성장 예측을 포함합니다.
1. [적절한 버퍼](_index.md#if-in-doubt-start-large-monitor-and-then-scale-down)가 있는 참조 아키텍처를 선택합니다.

### PromQL 쿼리 실행 {#running-promql-queries}

PromQL 쿼리 실행은 사용하는 모니터링 솔루션에 따라 다릅니다. [Prometheus 모니터링 설명서](../monitoring/prometheus/_index.md#how-prometheus-works)에서 언급한 대로 Prometheus에 직접 연결하거나 Grafana와 같은 대시보드 도구를 사용하여 모니터링 데이터에 액세스할 수 있습니다.

## 기준선 크기 결정 {#determine-your-baseline-size}

초당 요청 수(RPS)는 GitLab 인프라 크기 조정을 위한 주요 메트릭입니다. 다양한 트래픽 유형(API, 웹, Git 작업)은 다양한 구성 요소에 스트레스를 주므로 각각을 별도로 분석하여 실제 용량 요구 사항을 찾습니다.

### 피크 트래픽 메트릭 추출 {#extract-peak-traffic-metrics}

최대 부하를 이해하기 위해 이러한 쿼리를 실행합니다. 이러한 쿼리는 다음을 표시합니다:

- 절대 피크는 본 적이 있는 가장 높은 스파이크입니다. 절대 피크는 최악의 경우 시나리오를 표시합니다.
- 지속 피크는 95번째 백분위수이며 전형적인 "바쁜" 수준으로 간주됩니다. 지속 피크는 일반적인 높은 부하 기간을 드러냅니다.

절대 피크가 드문 이상인 경우 지속 부하에 대한 크기 조정이 적절할 수 있습니다.

보존 기간을 기반으로 쿼리의 시간 범위를 조정합니다(`[7d]`를 더 오래된 기록이 있는 경우 `[30d]`로 변경).

> [!note]
> 높은 활동 환경의 경우 `max_over_time` 또는 `quantile_over_time` 쿼리가 시간 초과될 수 있습니다. 이 경우 외부 집계 함수를 제거하고 내부 쿼리를 그래프로 시각화합니다. 예를 들어 API 트래픽 피크의 경우 다음을 사용합니다:
>
> ```prometheus
> sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*"}[1m]))
> ```
>
> 그래프 결과에서 모니터링 기간 동안 피크 값을 시각적으로 식별합니다.

#### 절대 피크 쿼리 {#query-absolute-peaks}

지정된 시간 기간 동안 관찰된 최대 RPS를 식별하려면:

1. 다음 쿼리를 실행합니다:

   - API 트래픽 피크는 자동화, 외부 도구 및 웹후크에서 피크 API 요청을 측정합니다:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - 웹 트래픽 피크는 브라우저의 사용자로부터 피크 UI 상호 작용을 측정합니다:

     ```prometheus
     max_over_time(
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Git 풀 및 클론 피크는 피크 리포지토리 클론 및 페치 작업을 측정합니다:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Git 푸시 피크는 피크 코드 푸시 작업을 측정합니다:

     ```prometheus
     max_over_time(
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 결과를 기록합니다.

#### 지속 피크 쿼리 {#query-sustained-peaks}

드문 스파이크를 필터링하여 전형적인 높은 부하 수준을 식별하려면:

1. 다음 쿼리를 실행합니다:

   - API 지속 피크:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller=~"Grape", action!~".*/internal/.*", action!="POST /api/jobs/request"}[1m]))[7d:1m]
     )
     ```

   - 웹 지속 피크:

     ```prometheus
     quantile_over_time(0.95,
       sum(rate(gitlab_transaction_duration_seconds_count{controller!~"Grape|HealthController|MetricsController|Repositories::GitHttpController|GraphqlController"}[1m]))[7d:1m]
     )
     ```

   - Git 풀 및 클론 지속 피크:

     ```prometheus
     quantile_over_time(0.95,
       (sum(rate(gitlab_transaction_duration_seconds_count{action="git_upload_pack"}[1m])) or vector(0) +
       sum(rate(gitaly_service_client_requests_total{grpc_method="SSHUploadPack"}[1m])) or vector(0))[7d:1m]
     )
     ```

   - Git 푸시 지속 피크:

     ```prometheus
     quantile_over_time(0.95,
      (sum(rate(gitlab_transaction_duration_seconds_count{action="git_receive_pack"}[1m])) or vector(0) +
      sum(rate(gitaly_service_client_requests_total{grpc_method="SSHReceivePack"}[1m])) or vector(0))[7d:1m]
     )
     ```

1. 결과를 기록합니다.

### 참조 아키텍처로 트래픽 매핑 {#map-traffic-to-reference-architectures}

이전에 기록한 결과를 사용하여 참조 아키텍처로 트래픽을 매핑하려면:

1. [사용 가능한 참조 아키텍처](_index.md#available-reference-architectures)를 참고하여 각 트래픽 유형을 제안하는 참조 아키텍처를 확인합니다.
1. 분석 테이블을 작성합니다. 다음 테이블을 가이드로 사용하세요:

   | 트래픽 유형       | 피크 RPS | 피크 제안 RA     | 지속 RPS | 지속 제안 RA |
   |:-------------------|:---------|:----------------------|:--------------|:-----------------------|
   | API                | ________ | _____ (최대 ___ RPS) | _____________ | _____ (최대 ____ RPS) |
   | 웹                | ________ | _____ (최대 ___ RPS) | _____________ | _____ (최대 ____ RPS) |
   | Git 풀 및 클론 | ________ | _____ (최대 ___ RPS) | _____________ | _____ (최대 ____ RPS) |
   | Git 푸시           | ________ | _____ (최대 ___ RPS) | _____________ | _____ (최대 ____ RPS) |

1. **Peak Suggested RA** 열의 모든 참조 아키텍처를 비교하고 가장 큰 크기를 선택합니다. **Sustained Suggested RA** 열에 대해 반복합니다.
1. 기준선을 문서화합니다:
   - 가장 큰 피크 RA 제안됨.
   - 가장 큰 지속 RA 제안됨.

### 참조 아키텍처 선택 {#choose-a-reference-architecture}

이 시점에서 두 개의 후보 참조 아키텍처 크기가 있습니다:

- 절대 피크를 기반으로 합니다.
- 지속 부하를 기반으로 합니다.

참조 아키텍처를 선택하려면:

1. 피크와 지속이 동일한 RA를 제안하면 해당 RA를 사용합니다.
1. 피크가 지속보다 더 큰 RA를 제안하는 경우. 간격을 계산합니다. 피크 RPS가 지속 RA의 상한의 10-15% 이내입니까?

일반 지침:

- 피크 RPS가 지속 RA 한도를 10-15% 미만으로 초과하는 경우 참조 아키텍처에 기본 제공되는 헤드룸이 있으므로 지속 RA를 수용 가능한 위험으로 간주할 수 있습니다.
- 15% 이상인 경우 피크 기반 RA로 시작한 후 메트릭이 다운사이징을 지원할 경우 모니터링하고 조정합니다.
  - 예제 1:  피크가 110 RPS, 대형 RA가 "최대 100 RPS"를 처리합니다 → 10% 초과 → 대형이 충분해야 합니다(참조 아키텍처에는 기본 제공되는 헤드룸이 있습니다).
  - 예제 2:  피크가 150 RPS, 대형 RA가 "최대 100 RPS"를 처리합니다 → 50% 초과 → X-Large(최대 200 RPS)를 사용합니다.
  - 예제 3:  피크는 100 RPS(대형/100 RPS)이지만 지속은 50 RPS(중형/60 RPS)입니다. 원시 RPS 그래프는 자동화 스파이크가 피크를 유발하지만 대부분 시간에 부하가 <50 RPS 미만임을 보여줍니다. 사용자는 보수적으로 대형으로 시작한 후 축소할지, 아니면 [워크로드별 크기 조정](#identify-component-adjustments)(더 높은 위험)으로 중형으로 시작할지 평가합니다.

40 RPS 이하의 환경이고 고가용성(HA)이 요구 사항인 경우 [고가용성 섹션](_index.md#high-availability-ha)을 참고하여 지원되는 감소를 포함한 60 RPS / 3,000명 사용자 아키텍처로 전환이 필요한지 확인합니다.

### 계속하기 전에 {#before-you-proceed}

이 섹션을 완료한 후에는 기준 참조 아키텍처 크기를 설정했습니다. 이것은 기초를 형성하지만 다음 섹션은 특정 워크로드가 표준 구성 이상의 구성 요소 조정을 요구하는지 여부를 식별합니다.

계속하기 전에 이 섹션에서 수집한 세부 정보를 문서화했는지 확인하세요. 다음을 가이드로 사용할 수 있습니다:

```markdown
Reference architecture assessment summary:

- Selected reference architecture: _____
- Justification based on _____ RPS [absolute/sustained]

| Traffic Type       | Peak RPS | Sustained RPS (95th) |
|:-------------------|:---------|:---------------------|
| API                | ________ | ____________________ |
| Web                | ________ | ____________________ |
| Git pull and clone | ________ | ____________________ |
| Git push           | ________ | ____________________ |

Highest RPS Peak timestamp for workload analysis: _____
```

## RPS 구성 및 워크로드 패턴 이해 {#understanding-rps-composition-and-workload-patterns}

전체 RPS는 주요 크기 조정 메트릭이지만 워크로드 구성은 구성 요소 리소스 요구 사항에 크게 영향을 줍니다. 다양한 요청 유형은 다양한 강도로 다양한 구성 요소에 스트레스를 줍니다.

### 요청 유형별 RPS 분석 {#rps-breakdown-by-request-type}

참조 아키텍처 RPS 대상은 프로덕션 데이터를 기반으로 전형적인 워크로드 구성을 가정합니다:

- **API requests**(전체 RPS의 ~80%) - 자동화, 통합, 웹후크 및 API 기반 도구
- **Web requests**(전체 RPS의 ~10%) - UI 상호 작용, 페이지 탐색 및 사용자 기반 작업
- **Git operations**(전체 RPS의 ~10%) - 리포지토리 클론 및 풀, 낮은 푸시 속도

**Atypical compositions** \- 한 가지 요청 유형이 전형적인 비율을 크게 초과하는 환경(대상 RPS 범위 내에서도 구성 요소별 조정이 필요할 수 있음)

### 비정형 워크로드 패턴 식별 {#identifying-atypical-workload-patterns}

[피크 트래픽 메트릭 추출](#extract-peak-traffic-metrics)에서 RPS 추출 쿼리를 사용하여 워크로드 구성을 파악합니다. 배포를 전형적인 패턴과 비교합니다:

**API-heavy workloads**(API >전체 RPS의 90%):

- 많은 자동화, 광범위한 통합 또는 API 기반 도구
- 주요 영향:  Rails(웹서비스), PostgreSQL, Gitaly
- 고려:  증가된 웹서비스/Rails 용량, 데이터베이스 읽기 복제본

**Web-heavy workloads**(웹 >전체 RPS의 20%):

- 광범위한 UI 상호 작용을 통한 대규모 활성 사용자 기반
- 주요 영향:  Rails(웹서비스), PostgreSQL
- 고려:  증가된 웹서비스 용량, 데이터베이스 최적화

**Git-intensive workloads**(Git >전체 RPS의 15% 또는 풀 속도가 크기에 비해 현저하게 높음):

- 빈번한 풀, 모노레포 패턴 또는 리포지토리 클론을 사용한 CI/CD 중심 워크플로우를 사용하는 대규모 팀
- 주요 영향:  Gitaly, 네트워크 대역폭
- 고려:  Gitaly 수직 확장, 리포지토리 최적화, 네트워크 강화 VM

### 평가 접근법 {#assessment-approach}

1. 제공된 PromQL 쿼리를 사용하여 RPS 분석을 추출합니다.
1. 각 요청 유형의 전체 백분율을 계산합니다.
1. 전형적인 비율을 상당히 초과하는 유형이 있는지 식별합니다.
1. 비정형인 경우 [구성 요소 조정 식별](#identify-component-adjustments)을 참고하여 확장 지침을 확인합니다.

> [!note]
> 작은 변동(모든 범주에서 5~10 RPS 차이)은 아키텍처 변경이 필요하지 않습니다. RPS 비교만을 기반으로 의사 결정하기보다는 프로덕션에서 실제 구성 요소 포화도 메트릭(CPU, 메모리, 큐 깊이)을 모니터링합니다. 70% 미만의 지속적인 사용률을 가진 구성 요소는 일반적으로 사소한 RPS 변동에 관계없이 충분한 용량을 갖추고 있습니다.

## 구성 요소 조정 식별 {#identify-component-adjustments}

워크로드 평가는 기본 참조 아키텍처 이상의 구성 요소 조정을 요구하는 특정 사용 패턴을 식별합니다. RPS가 전체 크기를 결정하지만 워크로드 패턴이 형태를 결정합니다. 동일한 RPS를 가진 두 환경은 매우 다른 리소스 요구 사항을 가질 수 있습니다.

다양한 워크로드는 GitLab 아키텍처의 다양한 부분에 스트레스를 줍니다:

- CI/CD 중심 환경은 수천 개의 작업을 처리하면서 중간 RPS를 유지하므로 Sidekiq 및 Gitaly에 스트레스를 줍니다.
- 광범위한 API 자동화를 사용하는 환경은 높은 RPS를 표시하지만 데이터베이스 및 Rails 계층에 부하를 집중시킵니다.

### 피크 부하 중 최상위 엔드포인트 분석 {#analyze-top-endpoints-during-peak-load}

이전 섹션의 피크 타임스탬프를 사용하여 최대 부하 중에 가장 많은 트래픽을 받은 엔드포인트를 식별합니다.

> [!note]
> RPS 메트릭이 업무 외 시간에 일관되게 높은 트래픽을 보이는 경우(피크의 >50%) 이는 전형적인 패턴을 벗어난 많은 자동화를 나타냅니다. 예를 들어 업무 시간에 100 RPS에 도달했지만 밤과 주말에 50+ RPS를 유지하는 피크 트래픽은 상당한 자동화된 워크로드를 나타냅니다. [구성 요소 조정을 평가할](#determine-component-adjustments) 때 이를 고려하세요.

1. 시각화를 활성화한 상태에서 이 쿼리를 실행합니다(시간에 따른 분포용 막대 차트 또는 일반 분포용 원형 차트):

   ```prometheus
   topk(20,
     sum by (controller, action) (
       rate(gitlab_transaction_duration_seconds_count{controller!~"HealthController|MetricsController", action!~".*/internal/.*"}[1m])
     )
   )
   ```

1. 절대 RPS 피크 중 최상위 엔드포인트의 분포에 대한 결과를 검토합니다. 결과는 다음을 포함할 수 있습니다:

   - 보이는 엔드포인트 패턴이 없습니다. 이 경우 이전에 선택한 참조 아키텍처를 계속 진행합니다. 워크로드 변경의 영향을 측정하기 위해 강력한 모니터링이 제대로 작동하는지 확인합니다.
   - 비 Git 트래픽에 대한 많은 API 사용이 대부분입니다. 이 경우 웹후크 및 이슈, 그룹 및 프로젝트 API 호출은 데이터베이스 집약적 패턴을 나타냅니다.
   - Git 또는 Sidekiq 관련 엔드포인트의 대부분입니다. 이 경우 머지 리퀘스트 차이, 파이프라인 작업, 브랜치, 커밋, 파일 작업, CI/CD 작업, 보안 스캔 및 가져오기 작업은 Sidekiq/Gitaly 집약적 패턴을 나타냅니다.

1. 결과를 기록합니다:

   ```markdown
   Workload pattern identified:

   - [ ] Database-intensive
   - [ ] Sidekiq- or Gitaly-intensive
   - [ ] None detected
   ```

### 구성 요소 조정 결정 {#determine-component-adjustments}

위의 표시기는 추가 워크로드의 초기 신호를 제공합니다. 참조 아키텍처에 기본 제공되는 헤드룸 때문에 이러한 워크로드를 조정 없이 처리할 수 있습니다. 그러나 강한 표시기가 있고 높은 수준의 자동화가 알려진 경우 다음 조정을 고려하세요.

이전에 식별된 워크로드 패턴을 기반으로 다양한 구성 요소를 확장해야 합니다:

| 워크로드 유형              | 적용 시기                                                                                                                                                                                | 확장할 구성 요소 |
|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------------------|
| 데이터베이스 집약적         | <ul><li>비 Git 트래픽에 대한 많은 API 사용(웹후크, 이슈, 그룹 및 프로젝트)</li><li>알려진 [광범위한 자동화 또는 통합 워크로드](_index.md#additional-workloads)</li></ul> | <ul><li>Rails 리소스를 늘립니다.</li><li>[데이터베이스 확장](#database-scaling)</li></ul> |
| Sidekiq/Gitaly 집약적\** | <ul><li>많은 Git 작업, CI/CD 작업, 보안 스캔, 가져오기 작업 및 Git 서버 훅</li><li>알려진 CI/CD 중심 사용 패턴</li></ul>                                      | <ul><li>Sidekiq 사양을 늘립니다.</li><li>Gitaly 수직 확장</li><li>[데이터베이스 확장](#database-scaling)</li><li>고급:  특정 [작업 클래스](../sidekiq/processing_specific_job_classes.md) 구성</li></ul> |

#### 확장 지침 {#scaling-guidance}

리소스 조정은 워크로드 강도 및 포화도 메트릭에 따라 다릅니다:

1. 현재 리소스의 1.25x-1.5x로 시작합니다.
1. 구현 후 모니터링 데이터를 기반으로 조정합니다.

클라우드 네이티브 GitLab을 배포할 계획이라면 이 평가에서 식별된 워크로드 패턴은 Kubernetes 구성에 추가 영향을 미칩니다:

- 높은 업무 외 시간 트래픽입니다. 조용한 기간 동안 스케일 투 제로를 허용하지 않고 기준 부하에 충분한 최소 포드 개수를 확인합니다. 예를 들어 업무 시간에는 100 RPS, 자동화로 인한 밤 시간에는 일관된 50 RPS의 경우 최소 포드 개수 구성을 기준선 오프 시간 부하와 정렬해야 합니다.
- 빠른 트래픽 스파이크입니다. 기본 HPA 설정은 충분히 빠르게 확장되지 않을 수 있습니다. 초기 롤아웃 중에 포드 확장 동작을 모니터링하여 이러한 전환 중에 요청 대기열을 방지합니다. 예를 들어 조용함에서 작업 시간으로 상향식 조정 또는 특정 자동화 스파이크로 인한 50RPS에서 200RPS로의 빠른 스파이크.

##### 데이터베이스 확장 {#database-scaling}

데이터베이스 확장 전략은 워크로드 특성에 따라 다르며 여러 접근 방식이 필요할 수 있습니다:

1. 즉시 용량 제약을 해결하기 위한 수직 확장으로:
   - 복제본이 기본 부하를 줄이지 않으므로 쓰기 집약적 워크로드에 필요합니다.
   - 읽기 및 쓰기 작업 모두에 대한 즉시 용량 증가를 제공합니다.
1. [데이터베이스 로드 밸런싱](../postgresql/database_load_balancing.md)(권장) 읽기 복제본과 함께:
   - 읽기 집약적 워크로드(85-95% 읽기)에 특히 유익합니다.
   - 여러 노드에 읽기 트래픽을 분산합니다.
   - 수직 확장과 함께 조합으로 추가할 수 있습니다.
1. 쓰기 성능이 병목이 되는 경우 수직 확장을 계속합니다.

이 Prometheus 쿼리를 사용하여 읽기/쓰기 분포를 식별합니다:

```prometheus
# Percentage of READ operations
(
  (sum(rate(gitlab_transaction_db_count_total[5m])) - sum(rate(gitlab_transaction_db_write_count_total[5m]))) /
  sum(rate(gitlab_transaction_db_count_total[5m]))
) * 100
```

### 계속하기 전에 {#before-you-proceed-1}

이 섹션을 완료한 후에는 워크로드 패턴을 식별했고 필요한 구성 요소 조정을 결정했습니다.

계속하기 전에 완전한 워크로드 평가를 기록합니다:

```markdown
Workload pattern identified:

- [ ] Database-intensive
- [ ] Sidekiq- or Gitaly-intensive
- [ ] None detected
- Component adjustments needed: _____
```

다음 섹션에서는 추가 인프라 고려 사항이 필요할 수 있는 특수 데이터 특성을 평가합니다.

## 특수 인프라 요구 사항 평가 {#assess-special-infrastructure-requirements}

리포지토리 특성 및 네트워크 사용 패턴은 RPS 메트릭이 드러내는 것 이상으로 GitLab 성능에 크게 영향을 미칠 수 있습니다.

대규모 모노레포, 광범위한 바이너리 파일 및 네트워크 집약적 작업은 표준 크기 조정이 고려하지 않는 인프라 조정이 필요합니다.

### 대규모 모노레포 {#large-monorepos}

대규모 모노레포(수 기가바이트 이상)는 Git 작업 수행 방식을 근본적으로 변경합니다. 10GB 리포지토리의 단일 클론은 전형적인 리포지토리의 수백 개 클론보다 더 많은 리소스를 사용합니다.

이러한 리포지토리는 워크로드에 따라 Gitaly뿐만 아니라 Rails, Sidekiq 및 데이터베이스에도 영향을 미칩니다.

프로파일링 프로세스는 전형적인 크기를 크게 초과하는 리포지토리를 식별하는 데 중점을 두고 있습니다:

- 중간 모노레포:  2GB - 10GB입니다. 이러한 경우 적당한 조정이 필요합니다.
- 대규모 모노레포: >10GB입니다. 이러한 경우 상당한 인프라 변경이 필요합니다.

리포지토리 크기를 식별하려면:

1. 프로젝트의 [사용량 할당량](../../user/storage_usage_quotas.md#view-storage)으로 이동합니다.
1. [**리포지토리** 저장소 유형](../../user/project/repository/repository_size.md)을 검토합니다.
1. 2GB보다 크고 10GB보다 큰 리포지토리를 가진 프로젝트 수를 계산합니다.
1. 결과를 기록합니다:

   ```plaintext
   Number of medium monorepos (2GB - 10GB): _____
   Number of large monorepos (>10GB): _____
   ```

#### 모노레포에 대한 인프라 조정 {#infrastructure-adjustments-for-monorepos}

대규모 리포지토리는 수직 확장 및 운영 조정이 모두 필요합니다. 이러한 리포지토리는 Git 작업 및 CPU 사용량부터 메모리 소비 및 네트워크 대역폭까지 전체 스택의 성능에 영향을 미칩니다.

| 시나리오                 | 구성 요소 조정 |
|:-------------------------|:----------------------|
| 여러 중간 모노레포 | <ul><li>Gitaly:  1.5x-2x 사양</li><li>Rails:  1.25x-1.5x 사양</li></ul> |
| 대형 모노레포          | <ul><li>Gitaly:  2x-4x 사양</li><li>Rails:  1.5x-2x 사양</li><li>모노레포를 전용 Gitaly 노드로 분할하는 것을 고려하세요.</li></ul> |

모노레포 환경에 대한 추가 최적화 전략은 [모노레포 성능 개선](../../user/project/repository/monorepos/_index.md)에 문서화되어 있으며 바이너리 파일의 Git LFS 및 얕은 복제를 포함합니다.

### 네트워크 집약적 워크로드 {#network-heavy-workloads}

네트워크 포화는 진단하기 어려운 고유한 문제를 야기합니다. 특정 작업에 영향을 미치는 CPU 또는 메모리 병목과 달리 네트워크 포화는 모든 GitLab 기능에서 임의의 시간 초과를 유발할 수 있습니다.

공통 네트워크 부하 원본:

- 많은 컨테이너 레지스트리 사용(큰 이미지, 자주 풀링)입니다.
- LFS 작업(바이너리 파일, 미디어 자산)입니다.
- 대규모 CI/CD 아티팩트(빌드 출력, 테스트 결과)입니다.
- 모노레포 클론(특히 CI/CD 파이프라인에서)입니다.

#### 네트워크 사용 측정 {#measure-network-usage}

잠재적 병목을 식별하기 위해 피크 및 기준 네트워크 소비를 계산합니다. 둘 다 평가하여 가끔 스파이크(버스트 용량으로 처리됨)와 지속적인 높은 트래픽(네트워크 강화 VM 필요) 간을 구분합니다.

1. 다음 쿼리를 실행합니다:

   ```prometheus
   # Outbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))


   # Inbound traffic (Gbps) - top 10 nodes
   topk(10, sum by (instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]) * 8 / 1000000000))

   ```

1. 모니터링 기간에 관찰된 피크 스파이크 및 일반적인 기준선을 모두 기록합니다:

   ```plaintext
   Peak outbound traffic: _____ Gbps (baseline: _____ Gbps)
   Peak inbound traffic: _____ Gbps (baseline: _____ Gbps)
   ```

#### 네트워크 용량 요구 사항 {#network-capacity-requirements}

아래 임계값은 근사 가이드라인일 뿐입니다. 실제 네트워크 대역폭 보장은 클라우드 공급자 및 VM 유형에 따라 크게 다릅니다. 워크로드 패턴과 일치하도록 특정 인스턴스 유형의 네트워크 사양(기준 및 버스트 제한)을 항상 확인합니다.

아웃바운드 및 인바운드 트래픽 측정을 기반으로:

| 네트워크 부하 | 임계값 | 이 임계값인 이유                                                 | 필수 조치 |
|:-------------|:----------|:-------------------------------------------------------------------|:----------------|
| 표준     | <1Gbps   | 대부분의 표준 인스턴스의 기준 대역폭 이내               | 표준 인스턴스 충분 |
| 중간     | 1-3Gbps  | AWS 기준을 초과할 수 있지만 GCP/Azure 표준 인스턴스 내에서    | <ul><li>AWS:  스로틀링 모니터링, 네트워크 강화 필요할 수 있음</li><li>GCP/Azure:  표준 인스턴스는 일반적으로 충분합니다.</li></ul> |
| 높음         | 3-10Gbps | AWS 기준을 초과합니다. 일부 표준 인스턴스의 한계에 근접 | <ul><li>AWS:  네트워크 강화 VM 필요</li><li>GCP/Azure:  인스턴스 대역폭 사양 확인</li></ul> |
| 매우 높음    | >10Gbps  | 대부분의 표준 인스턴스 기능을 초과합니다.                        | <ul><li>모든 공급자에 걸쳐 네트워크 강화 VM 필요</li><li>대규모 아티팩트의 경우 [객체 프록시 다운로드](../object_storage.md#proxy-download) 비활성화</li></ul> |

### 계속하기 전에 {#before-you-proceed-2}

계속하기 전에 완전한 데이터 프로파일링 평가를 기록합니다:

```txt
Data Profile Summary:
- Medium monorepos (2GB-10GB): _____
- Large monorepos (>10GB): _____
- Gitaly adjustments needed: _____
- Rails adjustments needed: _____
- Peak outbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Peak inbound traffic: _____ Gbps (sustained baseline: _____ Gbps)
- Network infrastructure changes: _____
```

## 현재 환경 분석 및 권장 사항 검증 {#analyze-current-environment-and-validate-recommendations}

기존 환경을 이해하면 권장 사항에 대한 중요한 컨텍스트를 제공합니다:

- 현재 환경이 성능 이슈 없이 워크로드를 처리하는 경우 크기 조정 추정치에 대한 중요한 검증으로 사용됩니다.
- 반대로 성능 문제가 있는 환경은 부정적인 크기 조정을 영구화하지 않도록 신중한 분석이 필요합니다.

### 현재 환경 문서화 {#document-the-current-environment}

현재 상태를 설정하기 위해 포괄적인 환경 데이터를 수집합니다:

- 아키텍처 세부 정보:
  - 유형: 고가용성(HA) 또는 비고가용성(비HA)입니다.
  - 배포 방법:  Linux 패키지 또는 클라우드 네이티브 GitLab입니다.
- 구성 요소 사양:
  - 각 구성 요소의 노드 수 및 사양입니다.
  - 사용자 지정 구성 또는 편차입니다.

### 가장 가까운 참조 아키텍처 식별 {#identify-the-nearest-reference-architecture}

1. 현재 환경을 [사용 가능한 참조 아키텍처](_index.md)와 비교합니다. 다음을 고려합니다:

   - 구성 요소당 총 계산 리소스입니다.
   - 노드 분포 및 아키텍처 패턴(HA 대 비HA)입니다.
   - 참조 아키텍처 크기에 상대적인 구성 요소 사양입니다.

1. 결과를 기록합니다:

   ```plaintext
   Nearest Reference Architecture: _____
   Custom configurations or deviations:
   - _____
   - _____
   ```

### 현재 환경을 권장 아키텍처와 비교 {#compare-current-environment-to-recommended-architecture}

현재 환경을 이전 섹션에서 개발한 권장 참조 아키텍처와 비교합니다. 현재 환경이:

- 성능 이슈 없음 및 현재 리소스 < 권장 RA:
  - 권장 사항은 보수적이며 향후 헤드룸을 제공합니다.
  - 권장 RA로 진행합니다.
  - 구현 후 잠재적 최적화 기회에 대해 모니터링합니다.
- 성능 이슈 없음 및 현재 리소스 ≈ 권장 RA:
  - 크기 조정 평가의 강력한 검증입니다.
  - 현재 환경은 권장 크기가 적절함을 확인합니다.
- 성능 이슈 없음 및 현재 리소스 > 권장 RA:
  - 현재 환경이 과다 프로비저닝되었거나 분석이 필요한 추가 리소스에 대한 유효한 이유가 있을 수 있습니다. Rails, Gitaly, 데이터베이스 및 Sidekiq에서 CPU/메모리 [리소스 사용률](../monitoring/prometheus/_index.md#sample-prometheus-queries)을 확인합니다.

    낮은 사용률(<40%)은 과다 프로비저닝을 시사합니다. 높은 사용률은 RPS 분석에서 캡처되지 않은 특정 워크로드 요구 사항을 나타낼 수 있습니다.
  - 발견되지 않은 요구 사항을 조정해야 하는지 검토합니다.

현재 환경에 성능 이슈가 있는 경우:

- 현재 사양을 최소 기준선으로만 사용합니다. 이전 섹션의 권장 사항은 현재 사양을 초과해야 합니다.
- 권장 사항이 현재보다 현저하게 낮은 경우 조사합니다:
  - 평가에서 캡처되지 않은 워크로드 패턴입니다.
  - 대상 확장이 필요한 구성 요소별 병목입니다.

### 계속하기 전에 {#before-you-proceed-3}

이 섹션을 완료한 후에는 현재 환경을 분석했고 권장 사항과 비교했습니다.

계속하기 전에 완전한 환경 비교를 기록합니다:

```plaintext
Current Environment Analysis:
- Current RA (nearest): _____
- Recommended RA (from RPS and workload analysis): _____
- Resource comparison: [ ] Current < Recommended [ ] Current ≈ Recommended [ ] Current > Recommended
- Performance status: [ ] No issues [ ] Has issues
- Adjustments needed: _____
- Notes: _____
```

다음 섹션에서는 크기 조정이 시간이 지남에 따라 적절하게 유지되도록 성장 예측을 평가합니다.

## 향후 용량 계획 {#plan-for-future-capacity}

인프라 변경에는 조달, 마이그레이션 및 테스트를 위한 상당한 리드 타임이 필요합니다. 성장 추정은 권장 아키텍처가 구현 기간과 그 이후에 실행 가능하게 유지되도록 합니다.

비즈니스 계획과 결합된 과거 추세는 가장 정확한 성장 예측을 제공합니다.

### 과거 성장 패턴 분석 {#analyze-historical-growth-patterns}

과거 성장 패턴은 비즈니스 예측보다 향후 궤적을 더 잘 예측하는 데 도움이 될 수 있습니다:

1. [기준선 크기](#determine-your-baseline-size)의 정보를 사용하여 6~12개월 전 현재 RPS를 비교합니다.
1. 성장 가속 또는 감속 추세를 식별합니다.

### 비즈니스 계획 요소 포함 {#incorporate-business-planning-factors}

인프라 요구 사항에 영향을 미치는 예상 비즈니스 변경 사항:

- 팀 확장 또는 통합입니다.
- 새로운 프로젝트 개발입니다.
- 기존 프로젝트의 개발 활동 증가입니다.

이러한 요소 또는 기타 조직 변경이 환경에 대한 부하에 영향을 미치고 인프라 조정이 필요한지 평가합니다. 관련 변경 사항 및 예상 타임라인을 문서화합니다.

#### 성장 버퍼 전략 결정 {#determine-growth-buffer-strategy}

과거 추세 및 비즈니스 예측을 기반으로 적절한 성장 수용 전략을 선택합니다:

- 안정적이거나 최소한의 성장:  모니터링을 계속합니다. 참조 아키텍처에는 기본 제공되는 헤드룸이 포함됩니다.
- 중간 성장:  예상되는 향후 RPS를 처리하도록 크기 조정된 RA를 계획합니다.
- 상당한 성장 예상:  현재 RPS보다는 예상되는 향후 RPS를 위해 크기 조정하는 것을 고려합니다.

### 계속하기 전에 {#before-you-proceed-4}

이 섹션을 완료한 후에는 성장 예측이 크기 조정 의사 결정에 통합됩니다.

완전한 성장 분석을 기록합니다:

```plaintext
Growth Assessment Summary:
- Historical RPS comparison: _____
- Business growth factors: _____
- Growth category: [ ] Stable/Minimal [ ] Moderate [ ] Significant
- Strategy: [ ] Current RA sufficient [ ] Size for projected growth
```

다음 섹션에서는 모든 결과를 최종 아키텍처 권장 사항으로 컴파일합니다.

## 결과 컴파일 {#compile-findings}

모든 이전 섹션의 결과를 컴파일하여 최적의 참조 아키텍처 및 필수 조정을 결정합니다.

### 최종 아키텍처 결정 {#determine-final-architecture}

크기 조정 의사 결정을 형성하기 위해 각 섹션의 주요 출력을 수집합니다:

1. [RPS 분석](#determine-your-baseline-size)을 기반으로 식별된 참조 아키텍처로 시작합니다.
1. [워크로드 패턴](#identify-component-adjustments) 및 [데이터 특성](#assess-special-infrastructure-requirements)을 기반으로 필요한 구성 요소 조정을 적용합니다. 패턴이 식별되지 않았거나 표준 구성이 충분한 경우 이 단계를 건너뜁니다.
1. [현재 상태](#analyze-current-environment-and-validate-recommendations)에 대해 검증합니다. 현재 환경이 잘 수행되지만 권장 사항을 초과하는 경우 이유를 문서화합니다. 성능 이슈가 있으면 권장 사항이 현재 사양을 초과하는지 확인합니다.
1. [향후 용량 계획에서 성장](#plan-for-future-capacity)을 수용합니다. 현재 RA가 충분한지 또는 예상되는 성장을 위해 크기 조정이 필요한지 결정합니다.

### 최종 권장 사항 문서화 {#document-final-recommendation}

포괄적인 평가를 기반으로 완전한 아키텍처 권장 사항을 기록합니다:

```plaintext
Final Architecture Recommendation
==================================

- Selected RA: [Size] based on [Absolute/Sustained] Peak RPS of [value]
- Component adjustments required:
  - [ ] No adjustments needed - standard RA configuration sufficient
  - [ ] Adjustments required:
      - Rails: _____
      - Sidekiq: _____
      - Database: _____
      - Gitaly: _____
      - Network considerations: □ Standard instances □ Network-optimized instances
- Selected RA is aligned with existing environment: [Yes/No/Not applicable]
- Growth accommodation: [Current RA sufficient / Sized up for growth]

Assessment Summary:
├── RPS Analysis
│   ├── Absolute Peak RPS: _____ → Baseline RA: _____
│   └── Sustained Peak RPS: _____ → Sustained RA: _____
├── Workload Type
│   └── Type: [ ] Database-Intensive [ ] Sidekiq-Intensive [ ] None
├── Data Profile
│   ├── Large repos (>2GB): _____ | Monorepos (>10GB): _____
│   └── Network: Peak _____ Gbps | Baseline _____ Gbps
├── Current State
│   ├── Nearest RA: _____
|   └── Discrepancies and customizations: _____
└── Growth
    ├── Growth projection: _____
    └── Growth buffer strategy: _____
```

모든 섹션을 완료한 후에는 크기 조정 평가가 완료됩니다. 최종 권장 사항에 포함:

- 기본 참조 아키텍처 크기입니다.
- 구성 요소별 조정
- 성장 수용 전략입니다.

워크로드 패턴이 진화함에 따라 가정을 검증하고 인프라를 조정하려면 정기적인 모니터링이 필수적입니다.
