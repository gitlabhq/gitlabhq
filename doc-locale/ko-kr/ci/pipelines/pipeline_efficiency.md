---
stage: Verify
group: Pipeline Execution
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: 파이프라인 효율성
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[CI/CD 파이프라인](_index.md)은 [GitLab CI/CD](../_index.md)의 기본 구성 요소입니다. 파이프라인 효율성을 높이면 개발자 시간을 절약할 수 있습니다:

- DevOps 프로세스를 가속화합니다
- 비용을 절감합니다
- 개발 피드백 루프를 단축합니다

신규 팀이나 프로젝트는 느리고 비효율적인 파이프라인으로 시작한 후 시행착오를 통해 설정을 개선하는 것이 일반적입니다. 더 나은 방법은 처음부터 효율성을 개선하는 파이프라인 기능을 사용하고 더 빠른 소프트웨어 개발 수명 주기를 더 일찍 확보하는 것입니다.

먼저 [GitLab CI/CD 기본 사항](../_index.md)에 익숙해지고 [빠른 시작 가이드](../quick_start/_index.md)를 이해하는지 확인하세요.

## 병목 지점 및 일반적인 오류 식별 {#identify-bottlenecks-and-common-failures}

비효율적인 파이프라인을 확인하는 가장 쉬운 지표는 작업, 스테이지 및 파이프라인 자체의 총 실행 시간입니다. 전체 파이프라인 기간은 다음 요소의 영향을 받습니다:

- [리포지토리 크기](../../user/project/repository/monorepos/_index.md)
- 스테이지 및 작업의 총 개수입니다.
- 작업 간의 종속성입니다.
- 파이프라인의 최소 및 최대 기간을 나타내는 ["임계 경로"](#needs-dependency-visualization)입니다.

주의할 추가 사항은 [GitLab 러너](../runners/_index.md)와 관련됩니다:

- 러너의 가용성 및 프로비저닝된 리소스입니다.
- 빌드 종속성, 설치 시간 및 스토리지 공간 요구 사항입니다.
- [컨테이너 이미지 크기](#docker-images)입니다.
- 네트워크 지연 및 느린 연결입니다.

파이프라인이 자주 불필요하게 실패하면 개발 수명 주기가 느려질 수도 있습니다. 실패한 작업의 문제 패턴을 찾아야 합니다:

- 무작위로 실패하거나 신뢰할 수 없는 테스트 결과를 생성하는 불안정한 단위 테스트입니다.
- 테스트 커버리지 저하 및 해당 동작과 관련된 코드 품질입니다.
- 안전하게 무시할 수 있지만 파이프라인을 중지하는 오류입니다.
- 긴 파이프라인의 끝에서 실패하지만 더 이른 스테이지에 있을 수 있는 테스트로, 피드백이 지연됩니다.

## 파이프라인 분석 {#pipeline-analysis}

파이프라인 성능을 분석하여 효율성을 개선할 수 있는 방법을 찾습니다. 분석을 통해 CI/CD 인프라에서 가능한 차단 요소를 식별할 수 있습니다. 여기에는 다음을 분석하는 것이 포함됩니다:

- 작업 워크로드입니다.
- 실행 시간의 병목 지점입니다.
- 전체 파이프라인 아키텍처입니다.

파이프라인 워크플로를 이해하고 문서화하고 가능한 작업 및 변경 사항을 논의하는 것이 중요합니다. 파이프라인 리팩토링은 DevSecOps 수명 주기의 팀 간에 신중한 상호 작용이 필요할 수 있습니다.

파이프라인 분석은 비용 효율성 관련 문제를 식별하는 데 도움이 될 수 있습니다. 예를 들어, 유료 클라우드 서비스로 호스팅되는 [러너](../runners/_index.md)는 다음과 같이 프로비저닝될 수 있습니다:

- CI/CD 파이프라인에 필요한 것보다 더 많은 리소스로, 비용을 낭비합니다.
- 리소스가 부족하여 런타임이 느리고 시간을 낭비합니다.

### 파이프라인 인사이트 {#pipeline-insights}

[파이프라인 성공 및 기간 차트](_index.md#pipeline-success-and-duration-charts)는 파이프라인 런타임 및 실패한 작업 수에 대한 정보를 제공합니다.

[단위 테스트](../testing/unit_test_reports.md), 통합 테스트, 엔드투엔드 테스트, [코드 품질](../testing/code_quality.md) 테스트 등의 테스트는 CI/CD 파이프라인에서 자동으로 문제를 찾도록 합니다. 긴 런타임을 초래하는 많은 파이프라인 스테이지가 있을 수 있습니다.

같은 스테이지에서 다양한 것을 테스트하는 작업을 병렬로 실행하여 전체 런타임을 단축하는 방식으로 런타임을 개선할 수 있습니다. 단점은 병렬 작업을 지원하기 위해 더 많은 러너가 동시에 실행되어야 한다는 것입니다.

### `needs` 종속성 시각화 {#needs-dependency-visualization}

[전체 파이프라인 그래프](_index.md#group-jobs-by-stage-or-needs-configuration)에서 `needs` 종속성을 보면 파이프라인의 임계 경로를 분석하고 가능한 차단 요소를 이해하는 데 도움이 될 수 있습니다.

### 파이프라인 모니터링 {#pipeline-monitoring}

전체 파이프라인 상태는 작업 및 파이프라인 기간과 함께 모니터링해야 할 핵심 지표입니다. [CI/CD 분석](_index.md#pipeline-success-and-duration-charts)은 파이프라인 상태의 시각적 표현을 제공합니다.

인스턴스 관리자는 추가 [성능 메트릭 및 자체 모니터링](../../administration/monitoring/_index.md)에 접근할 수 있습니다.

[API](../../api/rest/_index.md)에서 특정 파이프라인 상태 메트릭을 가져올 수 있습니다. 외부 모니터링 도구는 API를 폴링하고 파이프라인 상태를 확인하거나 장기 SLA 분석을 위한 메트릭을 수집할 수 있습니다.

예를 들어 Prometheus용 [GitLab CI 파이프라인 익스포터](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter)는 API 및 파이프라인 이벤트에서 메트릭을 가져옵니다. 프로젝트의 브랜치를 자동으로 확인하고 파이프라인 상태 및 기간을 가져올 수 있습니다. Grafana 대시보드와 함께 이를 통해 운영 팀을 위한 실행 가능한 보기를 구축할 수 있습니다. 메트릭 그래프를 사건에 포함시켜 문제 해결을 더 쉽게 만들 수도 있습니다. 또한 작업 및 환경에 대한 메트릭을 내보낼 수도 있습니다.

GitLab CI 파이프라인 익스포터를 사용하는 경우 [예제 구성](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter/blob/main/docs/configuration_syntax.md)으로 시작해야 합니다.

![CI 실행 상태 및 빈도와 실패율을 포함한 과거 통계를 보여주는 Grafana 대시보드입니다.](img/ci_efficiency_pipeline_health_grafana_dashboard_v13_7.png)

또는 [`check_gitlab`](https://gitlab.com/6uellerBpanda/check_gitlab) 같은 스크립트를 실행할 수 있는 모니터링 도구를 사용할 수 있습니다.

#### 러너 모니터링 {#runner-monitoring}

호스트 시스템이나 Kubernetes 같은 클러스터에서 [CI 러너를 모니터링](https://docs.gitlab.com/runner/monitoring/)할 수도 있습니다. 여기에는 다음을 확인하는 것이 포함됩니다:

- 디스크 및 디스크 IO
- CPU 사용량
- 메모리
- 러너 프로세스 리소스

[Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/)는 Linux 호스트에서 러너를 모니터링할 수 있고, [`kube-state-metrics`](https://github.com/kubernetes/kube-state-metrics)는 Kubernetes 클러스터에서 실행됩니다.

클라우드 공급자와 함께 [GitLab 러너 자동 크기 조정](https://docs.gitlab.com/runner/configuration/autoscale/)을 테스트할 수도 있고, 오프라인 시간을 정의하여 비용을 절감할 수 있습니다.

#### 대시보드 및 사건 관리 {#dashboards-and-incident-management}

기존 모니터링 도구와 대시보드를 사용하여 CI/CD 파이프라인 모니터링을 통합하거나 처음부터 구축합니다. 런타임 데이터가 팀에서 실행 가능하고 유용한지 확인하고 운영/SRE가 충분히 조기에 문제를 식별할 수 있도록 합니다. [사건 관리](../../operations/incident_management/_index.md)는 포함된 메트릭 차트 및 문제를 분석할 수 있는 모든 중요한 세부 정보를 사용하여 여기서도 도움이 될 수 있습니다.

### 스토리지 사용량 {#storage-usage}

비용 및 효율성을 분석하기 위해 다음의 스토리지 사용량을 검토합니다:

- [작업 아티팩트](../jobs/job_artifacts.md) 및 해당 [`expire_in`](../yaml/_index.md#artifactsexpire_in) 구성입니다. 너무 오래 보관하면 스토리지 사용량이 증가하고 파이프라인 속도가 느려질 수 있습니다.
- [컨테이너 레지스트리](../../user/packages/container_registry/_index.md) 사용량입니다.
- [패키지 레지스트리](../../user/packages/package_registry/_index.md) 사용량입니다.

## 파이프라인 구성 {#pipeline-configuration}

파이프라인 속도를 높이고 리소스 사용량을 줄이기 위해 파이프라인을 구성할 때 신중하게 선택합니다. 여기에는 파이프라인이 더 빠르고 효율적으로 실행되도록 하는 GitLab CI/CD의 내장 기능을 활용하는 것이 포함됩니다.

### 작업 실행 빈도 줄이기 {#reduce-how-often-jobs-run}

모든 상황에서 실행할 필요가 없는 작업을 찾아 파이프라인 구성을 사용하여 실행을 중지합니다:

- [`interruptible`](../yaml/_index.md#interruptible) 키워드를 사용하여 더 새로운 파이프라인으로 대체되었을 때 이전 파이프라인을 중지합니다.
- [`rules`](../yaml/_index.md#rules)를 사용하여 필요 없는 테스트를 건너뜁니다. 예를 들어, 프론트엔드 코드만 변경되었을 때 백엔드 테스트를 건너뜁니다.
- 필수가 아닌 [예정된 파이프라인](schedules.md)을 덜 자주 실행합니다.
- [`cron` 일정](schedules.md#distribute-pipeline-schedules-to-prevent-system-load)을 시간 전체에 걸쳐 고르게 배포합니다.

### 빠르게 실패 {#fail-fast}

CI/CD 파이프라인에서 초기에 오류가 감지되도록 합니다. 매우 오래 걸리는 작업은 작업이 완료될 때까지 파이프라인이 실패 상태를 반환하지 못하도록 합니다.

[빠르게 실패](../testing/fail_fast_testing.md)할 수 있는 작업이 더 일찍 실행되도록 파이프라인을 설계합니다. 예를 들어, 초기 스테이지를 추가하고 구문, 스타일 린팅, Git 커밋 메시지 검증 및 유사한 작업을 그곳으로 이동합니다.

더 빠른 작업에서 더 빠른 피드백을 얻기 전에 긴 작업이 초기에 실행되는 것이 중요한지 결정합니다. 초기 오류는 파이프라인의 나머지가 실행되지 않아야 한다는 점을 명확히 하여 파이프라인 리소스를 절약할 수 있습니다.

### `needs` 키워드 {#needs-keyword}

기본 구성에서 작업은 항상 실행되기 전에 이전 스테이지의 다른 모든 작업이 완료될 때까지 기다립니다. 이것은 가장 간단한 구성이지만 대부분의 경우 가장 느립니다. [`needs` 키워드가 있는 파이프라인](../yaml/needs.md) 및 [상위-하위 파이프라인](downstream_pipelines.md#parent-child-pipelines)은 더 유연하고 더 효율적일 수 있지만 파이프라인을 이해하고 분석하기 더 어렵게 만들 수 있습니다.

### 캐싱 {#caching}

또 다른 최적화 방법은 종속성을 [캐시](../caching/_index.md)하는 것입니다. 종속성이 [NodeJS `/node_modules`](../caching/examples.md#nodejs) 같이 거의 변경되지 않으면 캐싱이 파이프라인 실행을 훨씬 빠르게 할 수 있습니다.

작업이 실패해도 다운로드한 종속성을 캐시하기 위해 [`cache:when`](../yaml/_index.md#cachewhen)를 사용할 수 있습니다.

### Docker 이미지 {#docker-images}

Docker 이미지 다운로드 및 초기화는 작업의 전체 런타임의 큰 부분이 될 수 있습니다.

Docker 이미지가 작업 실행을 느리게 하는 경우 기본 이미지 크기와 레지스트리 네트워크 연결을 분석합니다. GitLab이 클라우드에서 실행 중인 경우 공급자가 제공하는 클라우드 컨테이너 레지스트리를 찾으세요. 이 외에도 GitLab 인스턴스에서 다른 레지스트리보다 더 빠르게 접근할 수 있는 [GitLab 컨테이너 레지스트리](../../user/packages/container_registry/_index.md)를 활용할 수 있습니다.

#### Docker 이미지 최적화 {#optimize-docker-images}

큰 Docker 이미지는 많은 공간을 차지하고 느린 연결 속도로 다운로드하는 데 오래 걸리기 때문에 최적화된 Docker 이미지를 빌드합니다. 가능하면 모든 작업에 하나의 큰 이미지를 사용하지 마세요. 각 특정 작업을 위해 더 빠르게 다운로드하고 실행되는 여러 개의 작은 이미지를 사용합니다.

소프트웨어가 미리 설치된 사용자 지정 Docker 이미지를 사용해 보세요. 일반적으로 일반 이미지를 사용하고 매번 소프트웨어를 설치하는 것보다 더 크고 미리 구성된 이미지를 다운로드하는 것이 훨씬 빠릅니다. Docker [Dockerfile 작성 모범 사례 문서](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)에는 효율적인 Docker 이미지 빌드에 대한 더 많은 정보가 있습니다.

Docker 이미지 크기를 줄이는 방법:

- `debian-slim` 같은 작은 기본 이미지를 사용합니다.
- vim이나 curl 같은 편의 도구를 꼭 필요하지 않으면 설치하지 마세요.
- 전용 개발 이미지를 만듭니다.
- 패키지에서 설치한 맨 페이지 및 문서를 비활성화하여 공간을 절약합니다.
- `RUN` 레이어를 줄이고 소프트웨어 설치 단계를 통합합니다.
- 빌더 패턴을 사용하는 여러 Dockerfile을 하나의 Dockerfile로 병합하기 위해 [다단계 빌드](https://blog.alexellis.io/mutli-stage-docker-builds/)를 사용하여 이미지 크기를 줄일 수 있습니다.
- `apt`을 사용하는 경우 불필요한 패키지를 피하기 위해 `--no-install-recommends`을 추가합니다.
- 더 이상 필요하지 않은 캐시 및 파일을 끝에서 정리합니다. 예를 들어 Debian 및 Ubuntu의 경우 `rm -rf /var/lib/apt/lists/*`, RHEL 및 CentOS의 경우 `yum clean all`입니다.
- [dive](https://github.com/wagoodman/dive) 또는 [DockerSlim](https://github.com/docker-slim/docker-slim) 같은 도구를 사용하여 이미지를 분석하고 축소합니다.

Docker 이미지 관리를 단순화하기 위해 [Docker 이미지](../docker/_index.md)를 관리하기 위해 전용 그룹을 만들고 CI/CD 파이프라인으로 테스트, 빌드 및 게시할 수 있습니다.

## 테스트, 문서화 및 학습 {#test-document-and-learn}

파이프라인 개선은 반복적인 프로세스입니다. 작은 변경을 수행하고, 효과를 모니터링한 다음 다시 반복합니다. 많은 작은 개선이 파이프라인 효율성의 큰 증가로 이어질 수 있습니다.

파이프라인 설계 및 아키텍처를 문서화하는 것이 도움이 될 수 있습니다. GitLab 리포지토리에서 직접 [Mermaid 차트를 Markdown에 포함](../../user/markdown.md#mermaid)하여 이를 수행할 수 있습니다.

CI/CD 파이프라인 문제 및 사건을 이슈에 문서화합니다. 수행된 연구 및 발견된 솔루션을 포함합니다. 이것은 새 팀 구성원의 온보딩을 돕고 CI 파이프라인 효율성의 반복 문제를 식별하는 데도 도움이 됩니다.

### 관련 항목 {#related-topics}

- [CI 모니터링 웨비나 슬라이드](https://docs.google.com/presentation/d/1ONwIIzRB7GWX-WOSziIIv8fz1ngqv77HO1yVfRooOHM/edit?usp=sharing)
- GitLab.com 모니터링 핸드북
- [운영 가시성을 위한 대시보드 구축](https://aws.amazon.com/builders-library/building-dashboards-for-operational-visibility/)
