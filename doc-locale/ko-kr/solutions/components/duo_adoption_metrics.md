---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "CI 기반 데이터 수집 파이프라인, GraphQL API 클라이언트, Duo 분석 대시보드를 사용하여 GitLab Duo 채택 및 사용을 측정하고 시각화합니다."
title: GitLab Duo 채택 지표 및 분석
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## GitLab Duo 채택 지표 및 분석 {#gitlab-duo-adoption-metrics--analytics}

이 프로젝트는 엔드투엔드 GitLab Duo 사용 분석을 제공하며, 다음을 결합합니다:

- **Duo GraphQL Data Collection** – GitLab GraphQL API 클라이언트가 지원하는 Duo 수집기 스크립트를 호출하는 일반 Python 오케스트레이터입니다.
- **Duo Usage Metrics Pipeline** – GitLab 그룹의 Duo 사용 데이터를 주기적으로 수집하고 집계하는 CI 작업입니다.
- **Duo Analytics Dashboard** – Duo 채택, 사용 강도, 참여 추세를 보여주는 GitLab Pages 호스팅 대시보드입니다.

## 시작하기 {#getting-started}

다음과 같은 **Project CI/CD Variables**를 설정하여 실행할 분석 파이프라인을 제어할 수 있습니다:

| 변수 | Duo 설정 | 설명 |
|----------|-----------|-------------|
| `ENABLE_DUO_METRICS` | `"true"` | Duo AI 지표 파이프라인을 활성화/비활성화합니다. |
| `ENABLE_PROJECT_METRICS` | `"false"` | Duo 채택만 중요한 경우 기존 프로젝트 중심 지표를 비활성화합니다. |
| `DUO_TOKEN` | `TOKEN VALUE` | `read_api` 및 `ai_features` 권한이 있는 개인 액세스 토큰으로 Duo 사용 수집을 진행합니다. |
| `GROUP_PATH` | `example_group` | Duo 지표를 수집할 최상위 그룹 또는 하위 그룹 경로입니다. |

**Steps for Quick Start**

1. 이 포크를 수행합니다.
1. **Project Settings → CI/CD → Variables**로 이동합니다.
1. 환경에 맞는 값으로 위의 변수를 추가합니다.
1. 선호하는 간격으로 **scheduled pipeline**을 구성합니다. Duo 사용 수집은 부하가 많을 수 있으므로 **once per day** 실행하는 것이 좋습니다.
1. 예약된 파이프라인을 수동으로 실행하거나 일정을 기다립니다.
1. 파이프라인이 완료되면 **Pages** 응용 프로그램을 **Deploy → Pages**에서 열어 Duo 분석 대시보드에 액세스합니다.

## GitLab Pages 배포(Duo 지표) {#gitlab-pages-deployment-duo-metrics}

Duo 지표가 활성화되면 Duo 파이프라인이 완료된 후 Pages 배포가 자동으로 수행됩니다:

- **Duo Metrics Pipeline** → `https://your-username.gitlab.io/project-name/duo-metrics/`와 같은 URL로 배포합니다.
- **Main Landing Page** → `https://your-username.gitlab.io/project-name/`에서 사용 가능하며, 사용 가능한 대시보드로의 링크가 포함되어 있습니다.

랜딩 페이지는 어느 대시보드가 있는지 자동으로 감지하고 `ENABLE_DUO_METRICS="true"`일 때 Duo 관련 링크를 표시합니다.

## 로컬 개발 및 테스트 {#local-development--testing}

Duo 분석의 로컬 테스트(CI 없음):

1. Python 및 종속성이 설치되어 있는지 확인합니다(예: 리포지토리 루트에서 `poetry install` 통해).
1. 로컬 `.env` 또는 셸 세션에서 필수 환경 변수를 설정합니다:
   - `DUO_TOKEN`
   - `GROUP_PATH`
1. 일반 오케스트레이터 스크립트를 실행하여 원본 Duo 사용 데이터를 수집합니다:

```shell
python ai_raw_data_collection.py
```

1. 로컬 `public/` 또는 `docs/` 폴더에서 생성된 지표를 엽니다(설정에 따라 다름). 또는 솔루션 구성 요소 프로젝트 설명서에 설명된 대로 대시보드를 로컬로 실행합니다.

## Duo 대시보드 기능 {#duo-dashboard-features}

Duo 분석 대시보드는 GitLab Duo 채택 및 AI 사용 패턴에 중점을 두고 있으며, 다음을 포함합니다:

- **License & Adoption Analytics** – 몇 명의 사용자가 Duo 액세스를 가지고 있고 몇 명이 적극적으로 사용하는지 추적합니다.
- **Code Suggestions Analytics** – AI 지원 코딩의 수락률, 제안 량, 언어 분포를 모니터링합니다.
- **Duo Chat Analytics** – 채팅 상호 작용, 사용자 집단, 대화 량을 봅니다.
- **User Engagement Analytics** – 사용 수준(비활성, 실험 중, 정규, 많음)별로 사용자를 분류합니다.
- **Language & Workflow Performance** – 프로그래밍 언어 또는 워크플로별로 Duo 효과(예: 수락률, 제안 사용)를 분석합니다.

이 지표는 전적으로 Duo 관련 신호에서 파생됩니다. 이 대시보드를 사용하는 데 기존 프로젝트 지표가 필요하지 않습니다.

## Duo 사용 데이터 수집 파이프라인 {#duo-usage-data-collection-pipeline}

Duo 채택 지표는 다음에 의존하는 CI 기반 데이터 수집 파이프라인에 의해 생성됩니다:

- A **generic Python orchestrator**: `ai_raw_data_collection.py`
- 재사용 가능한 **GitLab GraphQL API client**: `gitlab_graphql_api`

### 오케스트레이터: `ai_raw_data_collection.py` {#orchestrator-ai_raw_data_collectionpy}

스크립트 `ai_raw_data_collection.py`은 다음을 담당합니다:

- 환경/CI 변수 읽기(예: `GROUP_PATH`, `DUO_TOKEN`, 파이프라인 구성).
- 구체적인 Duo 사용 쿼리를 구현하는 하나 이상의 **collector scripts**를 호출합니다.
- 조정:
  - 그룹 및 프로젝트 전체의 페이지 매김.
  - Duo 사용 이벤트의 날짜/시간 창 또는 샘플링 전략.
  - 결과를 일관되고 분석 친화적인 형식(예: CSV/JSON)으로 정규화합니다.
- 수집된 데이터를 Duo 대시보드 및 다운스트림 집계 단계가 사용하는 위치로 작성합니다.

원본 Duo 사용 데이터를 수집하기 위한 **generic entry point**으로 작동하므로 다음을 수행할 수 있습니다:

- CI 구성을 변경하지 않고 새로운 Duo 관련 수집기를 추가합니다.
- 환경 변수 또는 CI 작업을 통해 실행할 수집기를 제어합니다.

### GitLab GraphQL API 클라이언트 및 컬렉션 {#gitlab-graphql-api-client--collections}

모든 Duo 관련 GraphQL 논리는 `gitlab_graphql_api` Python 패키지에 캡슐화되어 있으며, 특히 다음 아래에 있습니다:

- `gitlab_graphql_api > collections`

핵심 개념:

- **GraphQL client abstraction** – 중앙 클라이언트는 GitLab GraphQL 엔드포인트에 대한 인증, 페이지 매김, 오류 처리를 처리합니다.
- **Collection classes** – `collections` 모듈은 구조화된 데이터를 검색하기 위한 메서드를 노출하는 더 높은 수준의 추상화(예: "프로젝트 컬렉션" 또는 "사용자 컬렉션")를 제공합니다. Duo 수집기는 이를 사용하여:
  - 주어진 `GROUP_PATH`에 대한 그룹 및 프로젝트를 가져옵니다.
  - Duo 사용 필드 및 AI 관련 활동을 쿼리합니다.
- **Versioned API usage** – GitLab이 오케스트레이터를 변경하지 않고 Duo 관련 GraphQL 필드를 개선하거나 확장할 때 동일한 컬렉션 API를 확장할 수 있습니다.

Duo 수집기는 이러한 컬렉션 클래스를 가져오고 필요한 특정 쿼리를 정의합니다(예: AI 코드 제안, 채팅 사용 이벤트 또는 사용자 수준 채택 통계의 개수 가져오기).

> **참고:** Duo 사용을 위한 GraphQL 스키마 및 필드 이름은 `gitlab_graphql_api > collections`의 컬렉션 클래스와 함께 문서화됩니다. Duo 지표에 대해 수집된 데이터를 확장하거나 사용자 지정할 때 해당 문서를 사용합니다.

## Duo 데이터 수집 구성 {#configuring-duo-data-collection}

파이프라인을 사용자 지정할 수 있지만, 일반적인 Duo 전용 설정은 다음이 필요합니다:

- **Minimal CI configuration**:
  - `ENABLE_DUO_METRICS="true"`을 설정하여 Duo 파이프라인을 활성화합니다.
  - 선택적으로 `ENABLE_PROJECT_METRICS="false"`을 설정하여 Duo 이외의 파이프라인을 비활성화합니다.
- `ai_raw_data_collection.py`에서 사용하는 **Environment variables**:

| 변수 | 설명 | 예제 |
|----------|-------------|---------|
| `DUO_TOKEN` | Duo GraphQL 쿼리에 사용되는 `read_api` + `ai_features` 권한이 있는 토큰입니다. | `glpat-xxxx` |
| `GROUP_PATH` | Duo 사용을 측정해야 할 그룹 또는 하위 그룹입니다. | `"gitlab-org/your-group"` |
| `DUO_METRICS_OUTPUT_DIR` | 원본 Duo 사용 데이터의 선택적 출력 디렉터리입니다. | `"duo-metrics/raw"` |

이 설정이 되면 `ai_raw_data_collection.py`을 실행하는 CI 작업은:

1. `gitlab_graphql_api` 컬렉션을 사용하여 지정된 그룹의 Duo 사용 데이터를 쿼리합니다.
1. 다음과 같이 할 수 있는 원본 Duo 사용 아티팩트를 작성합니다:
   - 보고서로 집계합니다.
   - Duo 대시보드에서 직접 로드합니다.

## Duo 지표 확장 {#extending-duo-metrics}

Duo 채택 지표를 추가하거나 개선하려면:

1. **Identify** – 새로운 Duo 신호와 관련된 GitLab GraphQL 필드(예: 추가 사용 카운터 또는 새로운 AI 기능).
1. **Update or add** – 수집기 스크립트:
   - `gitlab_graphql_api > collections` 추상화를 사용합니다.
   - 기존 Duo 수집기와 일치하는 형식으로 데이터를 작성합니다.
1. **Wire the collector**합니다 `ai_raw_data_collection.py`로(또는 환경 변수를 통해 제어합니다).
1. **Update the dashboard**하여 새로운 필드를 사용하고 시각화합니다(필요한 경우).

GraphQL 액세스 및 페이지 매김 논리가 `gitlab_graphql_api` 내부에 캡슐화되어 있기 때문에 Duo 지표를 확장하면 일반적으로 다음을 의미합니다:

- 오케스트레이터에서 최소한의 변경.
- 새로운 지표 모델링 및 대시보드 업데이트에 중점을 두십시오.

## 리소스 {#resources}

- [GitLab Duo 채택 지표 솔루션 구성 요소 프로젝트](https://gitlab.com/gitlab-com/product-accelerator/work-streams/packaging/gitlab-graphql-api)
- `gitlab_graphql_api` 패키지 및 `collections` 모듈(Duo GraphQL 사용 패턴의 경우)
