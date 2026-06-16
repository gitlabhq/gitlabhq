---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Gateway
---

AI Gateway는 AI 기반 GitLab Duo 기능에 대한 액세스를 제공하는 독립 실행형 서비스입니다.

GitLab은 클라우드 기반 AI Gateway 인스턴스를 운영합니다. 이 인스턴스는 GitLab.com, [GitLab Self-Managed](configure/gitlab_self_managed.md), GitLab Dedicated에서 사용됩니다.

GitLab Self-Managed에서 [GitLab Duo Self-Hosted](../gitlab_duo_self_hosted/_index.md)를 통해 자체 호스팅 AI Gateway 인스턴스를 사용할 수도 있습니다.

## 지역 지원 {#region-support}

### GitLab.com {#gitlabcom}

GitLab.com의 경우 라우팅 메커니즘은 사용자의 인스턴스 위치 대신 GitLab 인스턴스 위치를 기반으로 합니다.

GitLab.com이 `us-east1`에 단일 위치하므로 AI Gateway에 대한 요청은 거의 모든 경우에 `us-east4`로 라우팅됩니다. 라우팅이 항상 모든 사용자에 대해 가장 가까운 배포를 제공하지는 않을 수 있습니다.

### GitLab Self-Managed 및 GitLab Dedicated {#gitlab-self-managed-and-gitlab-dedicated}

GitLab Self-Managed 및 GitLab Dedicated의 경우 GitLab이 지역 선택을 관리합니다. AI Gateway의 배포 지역을 선택할 수 없습니다. 자세한 내용은 [Runway](https://gitlab.com/gitlab-com/gl-infra/platform/runway) 서비스 매니페스트의 [사용 가능한 지역](https://schemas.runway.gitlab.com/RunwayService/#spec_regions)을 참조하세요.

Runway는 GitLab 내부 개발자 플랫폼이며 외부 고객에게는 제공되지 않습니다.

## 자동 데이터 라우팅 {#automatic-data-routing}

GitLab은 Cloudflare 및 Google Cloud Platform(GCP) 로드 밸런서를 사용하여 AI Gateway 요청을 가장 가까운 사용 가능한 배포로 자동으로 라우팅합니다. 이 라우팅 메커니즘은 낮은 지연 시간과 사용자 요청의 효율적인 처리를 우선시합니다.

이 라우팅 프로세스를 수동으로 제어할 수 없습니다. 다음 요소가 데이터 라우팅 위치에 영향을 미칩니다:

- 네트워크 지연 시간:  주요 라우팅 메커니즘은 지연 시간 최소화에 중점을 둡니다. 네트워크 조건이 요구하는 경우 데이터가 가장 가까운 지역 이외의 지역에서 처리될 수 있습니다.
- 서비스 가용성:  지역 중단 또는 서비스 중단이 발생한 경우 요청이 중단 없는 서비스를 보장하기 위해 자동으로 다시 라우팅될 수 있습니다.
- 타사 종속성:  GitLab AI 인프라는 Google Vertex AI와 같은 타사 모델 제공자에 의존하며, 이들은 자신만의 데이터 처리 관행을 가지고 있습니다.

### 직접 및 간접 연결 {#direct-and-indirect-connections}

IDE는 기본적으로 GitLab 모놀리스를 우회하여 AI Gateway와 직접 통신합니다. 이 직접 연결은 라우팅 효율성을 개선합니다.

이 동작을 변경하려면 Code Suggestions에 대해 [직접 및 간접 연결](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections)을 구성하세요.

### 특정 지역에 대한 요청 추적 {#tracing-requests-to-specific-regions}

AI 요청을 특정 지역으로 직접 추적할 수 없습니다.

특정 요청을 추적하는 데 지원이 필요한 경우 GitLab Support에서 Cloudflare 헤더 및 인스턴스 UUID가 포함된 로그에 액세스하고 분석할 수 있습니다. 이 로그는 라우팅 경로에 대한 통찰력을 제공하고 요청이 처리된 지역을 식별하는 데 도움이 될 수 있습니다.

## 데이터 주권 {#data-sovereignty}

다중 지역 AI Gateway 배포는 엄격한 데이터 주권을 시행하지 않습니다. 요청이 특정 지역으로 가거나 해당 지역에 남아있다는 보장이 없습니다.

이 서비스는 데이터 상주 솔루션이 아닙니다.

### 배포 지역 {#deployment-regions}

GitLab은 AI Gateway를 다음 지역에 배포합니다:

- 북미(`us-east4`)
- 유럽(`europe-west2`, `europe-west3`, `europe-west9`)
- 아시아 태평양(`asia-northeast1` 및 `asia-northeast3`)

최신 정보는 [Runway 구성 파일](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12)을 참조하세요.

AI Gateway에서 사용하는 LLM 모델의 정확한 위치는 타사 모델 제공자에 의해 결정됩니다. 모델이 AI Gateway 배포와 같은 지리적 지역에 있다는 보장이 없습니다. AI Gateway가 다른 지역에서 초기 요청을 처리하는 경우에도 데이터가 모델 제공자가 운영하는 다른 지역으로 흐를 수 있습니다. 데이터는 성능 및 가용성에 따라 가장 최적의 지역으로 라우팅됩니다.
