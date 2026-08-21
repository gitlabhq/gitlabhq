---
stage: Release Notes
group: Monthly Release
date: 2025-12-18
title: "GitLab 18.7 릴리스 정보"
description: "GitLab 18.7이 비밀 유효성 검사 개선 및 정식 출시됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 12월 18일에 GitLab 18.7이 다음의 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: David Aniebo {#this-months-notable-contributor-david-aniebo}

David Aniebo를 GitLab 제품 계획 기능 및 [기여자 플랫폼](https://contributors.gitlab.com)에 대한 영향력 있는 기여로 18.7 주목할 만한 기여자로 인정하게 되어 기쁩니다.

David의 [작업 항목 목록 기능 개선](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207549)에 대한 작업은 그의 기술 전문 지식과 GitLab 계획 기능에 대한 사용자 경험을 향상시키려는 헌신을 보여줍니다. 이 기여는 팀이 작업 항목을 더 잘 구성하고 관리하도록 도와주며, 수천 명의 GitLab 사용자에게 프로젝트 계획을 더욱 효율적으로 만듭니다.

코드 기여 외에도 David는 기여자 플랫폼의 일관된 지지자로서 커뮤니티 기여자의 경험을 개선하는 데 도움을 주었습니다. 그의 협력적인 접근 방식과 반응성은 다양한 그룹의 여러 팀 멤버로부터 칭찬을 받았습니다.

"David는 제품 계획 그룹 노력에 도움을 주기 위해 환상적인 작업을 해왔으며, 그의 기여에 대해 매우 감사하고 있습니다"라고 제품 계획 엔지니어링 매니저 Nick Brandt가 말했습니다.

David, GitLab에 대한 귀중한 기여와 저희 커뮤니티의 협력적인 멤버가 되어주셔서 감사합니다! 지속적인 참여를 기대합니다.

## 주요 기능 {#primary-features}

### 비밀 유효성 검사 개선 및 정식 출시 {#secret-validity-checks-improved-and-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/vulnerabilities/validity_check.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16890)

{{< /details >}}

유효한 비밀이 리포지토리 중 하나에 유출되면 빠르게 대응해야 합니다. 긴급 위협을 우선순위 지정할 수 있도록 유효성 검사는 유출된 자격 증명을 여전히 사용할 수 있는지 자동으로 확인합니다.

GitLab 18.7에서 다음을 개선했습니다:

- 공급업체 통합: Google Cloud, AWS 및 Postman과 통합했으며, GitLab 토큰에 대한 기존 지원도 함께 제공합니다.
- 보고서 필터링: 유효성 상태(활성, 비활성, 가능 활성)별로 취약성 보고서를 필터링하여 비밀 결과를 빠르게 분류하고 우선순위를 지정합니다.
- 그룹 수준 API: 단일 API 호출로 그룹의 모든 프로젝트에서 유효성 검사를 활성화하고 전체 조직에서 배포를 간소화합니다.

이 릴리스에서 유효성 검사는 정식 출시되었습니다.

### Agentic Chat 및 에이전트에 대한 별도의 모델 선택 {#separate-model-selection-for-agentic-chat-and-agents}

<!-- categories: Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/19998)

{{< /details >}}

이제 최상위 그룹 또는 인스턴스에 대해 Agentic Chat 및 다른 모든 에이전트에 대해 별도의 모델을 선택할 수 있습니다. 이는 GitLab Duo 에이전트 플랫폼의 모델 선택에 더 많은 옵션을 제공합니다.

### 개선된 GitLab Duo 및 SDLC 추세 대시보드 {#improved-gitlab-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/analytics/duo_and_sdlc_trends.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19629)

{{< /details >}}

GitLab Duo 및 SDLC 추세 대시보드는 GitLab Duo가 소프트웨어 전달에 미치는 영향을 측정하기 위한 분석 기능을 개선합니다. 대시보드는 이제 GitLab Duo 기능 채택, 파이프라인 성능 및 배포 빈도 및 병합 평균 시간과 같은 일반적인 개발 메트릭에 걸쳐 6개월 추세 분석을 제공합니다.

이제 GitLab Duo 코드 제안에 대한 코드 생성량 및 IDE 또는 언어 추세를 추적할 수 있으며, 팀이 새로운 GitLab Duo 에이전트 플랫폼 플로우를 채택할 때를 관찰할 수 있습니다. 향상된 사용자 수준 메트릭을 통해 팀은 지속적인 가치를 제공하는 주요 Duo 기능에 대해 더 깊은 통찰력을 얻을 수 있습니다.

새로운 [인스턴스 수준 AI 사용량 엔드포인트](../../api/graphql/reference/_index.md#aiinstanceusagedata)를 인스턴스 관리자가 Postgres(3개월 보존) 또는 ClickHouse에서 모든 Duo 데이터를 추출할 수 있도록 제공합니다.

[ClickHouse 통합](../../integration/clickhouse.md)으로 구동되는 이 대시보드는 수백만 개의 데이터 포인트에 걸쳐 1초 미만의 쿼리 성능을 제공합니다. 자체 관리 인스턴스의 경우 [ClickHouse 통합](../../integration/clickhouse.md)에 대한 개선된 권장 사항 및 구성 지침을 참조하세요.

### 베타 버전의 추가 Planner 에이전트 기능 {#additional-planner-agent-features-available-in-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [문서](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

Planner 에이전트는 이제 베타 버전의 생성 및 편집 기능을 포함합니다! Planner 에이전트는 제품 관리자가 GitLab에서 직접 지원하도록 구축된 기본 에이전트입니다. Planner 에이전트를 사용하여 GitLab 작업 항목을 생성, 편집 및 분석합니다.

수동으로 업데이트를 추적하거나 작업을 우선순위 지정하거나 계획 데이터를 요약하는 대신 Planner 에이전트는 백로그를 분석하고 RICE 또는 MoSCoW와 같은 프레임워크를 적용하며 실제로 주의가 필요한 사항을 표시하도록 도와줍니다. 계획 워크플로를 이해하고 더 나은 효율적인 결정을 내리기 위해 함께 작동하는 능동적인 팀원을 갖는 것과 같습니다.

[이슈 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)에서 피드백을 제공해 주세요.

### CI/CD 파이프라인의 동적 입력 옵션 {#dynamic-input-options-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/inputs/_index.md#define-conditional-input-options-with-specinputsrules) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18546)

{{< /details >}}

직관적인 웹 인터페이스를 통해 새 파이프라인을 만들 때 동적 입력 선택을 활용하도록 CI/CD 파이프라인을 설정할 수 있습니다.

이제 동적 입력 옵션을 사용하면 입력 선택 옵션이 이전 선택에 따라 동적으로 업데이트되도록 파이프라인을 구성할 수 있습니다. 예를 들어 한 드롭다운 목록에서 입력을 선택하면 두 번째 드롭다운 목록의 관련 입력 옵션 목록이 자동으로 채워집니다.

CI/CD 입력을 사용하면 다음을 수행할 수 있습니다:

- 사전 구성된 입력으로 파이프라인을 트리거하여 오류를 줄이고 배포를 간소화합니다.
- 사용자가 드롭다운 메뉴에서 기본값과 다른 입력을 선택할 수 있도록 합니다.
- 이제 옵션이 이전 선택을 기반으로 동적으로 업데이트되는 캐스케이딩 드롭다운 목록을 사용할 수 있습니다.

이 동적 기능을 통해 파이프라인 생성 프로세스를 안내하는 더 지능적이고 상황을 고려한 입력 구성을 만들 수 있으므로 오류를 줄이고 유효한 입력 조합만 선택되도록 할 수 있습니다.

### AI 기반 SAST 거짓 양성 탐지(베타) {#sast-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/application_security/vulnerabilities/false_positive_detection.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18977)

{{< /details >}}

보안 팀은 거짓 양성으로 판명되는 SAST 결과를 조사하는 데 상당한 시간을 소비하며, 실제 보안 위험으로부터의 주의를 전환합니다.

GitLab 18.7에서는 팀이 중요한 취약성에 집중할 수 있도록 AI 기반 SAST 거짓 양성 탐지를 소개합니다. 보안 검사가 실행되면 GitLab Duo는 각 심각한 수준 및 높은 심각도 SAST 취약성을 자동으로 분석하여 거짓 양성일 가능성을 결정합니다.

AI 평가는 취약성 보고서에 직접 나타나며, 보안 엔지니어가 더 빠르고 확신 있는 분류 결정을 내리기 위한 즉시 컨텍스트를 제공합니다.

주요 기능은 다음을 포함합니다:

- 자동 분석: 거짓 양성 탐지는 각 보안 검사 후 수동 트리거 없이 자동으로 실행됩니다.
- 수동 트리거 옵션: 사용자는 취약성 세부 정보 페이지에서 개별 취약성에 대해 거짓 양성 탐지를 수동으로 트리거할 수 있습니다.
- 높은 영향 결과에 집중: 신호 대 잡음 개선을 최대화하기 위해 중요 및 높은 심각도 취약성으로 범위가 지정됩니다.
- 상황별 AI 추론: 각 평가에는 코드 컨텍스트 및 취약성 특성을 기반으로 결과가 실제 양성일 수도 있고 아닐 수도 있는 이유에 대한 설명이 포함되어 있습니다.
- 원활한 워크플로우 통합: 결과는 기존 심각도, 상태 및 수정 정보와 함께 취약성 보고서에 직접 표시됩니다.

이 기능은 Ultimate 고객을 위한 무료 베타로 제공되며 그룹 또는 프로젝트 설정에서 활성화해야 합니다. [이슈 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)에서 피드백을 환영합니다.

### 기본적으로 활성화된 새로운 보안 대시보드 {#new-security-dashboards-enabled-by-default}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/security_dashboard/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/20213)

{{< /details >}}

새 보안 대시보드가 업데이트되고 현대화되었습니다. 대시보드는 이전에 GitLab.com에서 사용 가능했으며 이제 GitLab Dedicated 및 GitLab Self-Managed에서 기본적으로 활성화됩니다.

새 기능은 다음을 포함합니다:

- 다음을 지원하는 시간 경과에 따른 취약성 차트:
  - 프로젝트 또는 보고서 유형을 기반으로 필터링합니다.
  - 보고서 유형 및 심각도별로 그룹화합니다.
  - 취약성 보고서의 취약성에 대한 직접 링크입니다.
- GitLab 알고리즘을 기반으로 그룹 또는 프로젝트의 추정 위험을 계산하는 위험 점수 모듈입니다.

새 대시보드를 사용하려면 Elasticsearch이 필요합니다.

### CI/CD 카탈로그에 구성 요소 게시를 제어하는 인스턴스 설정 {#instance-setting-to-control-publishing-of-components-to-the-cicd-catalog}

<!-- categories: Pipeline Composition, Component Catalog -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../administration/settings/continuous_integration.md#restrict-cicd-catalog-publishing) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/582044)

{{< /details >}}

GitLab Self-Managed 및 GitLab Dedicated의 관리자는 이제 CI/CD 카탈로그에 구성 요소를 게시할 수 있는 프로젝트를 제한할 수 있습니다. 이 새로운 설정을 통해 조직은 게시할 수 있는 구성 요소를 제어하여 검증되고 신뢰할 수 있는 CI/CD 카탈로그를 유지할 수 있습니다.

관리자는 이제 구성 요소를 게시할 권한이 있는 프로젝트의 허용 목록을 지정할 수 있습니다. 허용 목록이 프로젝트로 채워지면 해당 프로젝트만 구성 요소를 게시할 수 있습니다. 이렇게 하면 승인되지 않은 또는 미승인 구성 요소가 게시된 구성 요소 목록에서 혼란을 야기하지 않으며 모든 구성 요소가 조직 표준 및 보안 요구 사항을 충족하도록 합니다.

이는 CI/CD 구성 요소 생태계에 대한 제어를 유지하면서 팀이 승인된 구성 요소를 발견하고 재사용할 수 있도록 하려는 엔터프라이즈 고객의 주요 거버넌스 과제를 해결합니다.

## 에이전틱 코어 {#agentic-core}

### 머지 리퀘스트 설명 및 댓글 모두에 사용 가능한 고급 검색 {#advanced-search-available-for-both-merge-request-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/search/advanced_search.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)

{{< /details >}}

고급 검색은 이제 머지 리퀘스트 설명과 댓글 모두에서 일치하는 결과를 반환합니다. 이전에는 사용자가 머지 리퀘스트 설명과 댓글을 별도로 검색해야 했습니다.

이 개선사항은 GitLab 머지 리퀘스트에 대한 더욱 간소화되고 포괄적인 검색 워크플로를 제공합니다.

### `AGENTS.md`에 대한 GitLab Duo Chat(에이전틱) 지원(IDE) {#support-for-agentsmd-with-gitlab-duo-chat-agentic-in-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/customize/agents_md.md)

{{< /details >}}

GitLab Duo Chat은 이제 `AGENTS.md` 사양을 지원합니다. 이는 AI 코딩 어시스턴트에 컨텍스트 및 지침을 제공하기 위한 새로운 표준입니다.

GitLab Duo에만 사용 가능한 사용자 지정 규칙과 달리 `AGENTS.md` 파일은 다른 AI 코딩 도구도 사용할 수 있습니다. 이렇게 하면 빌드 명령, 테스트 지침, 코드 스타일 가이드라인 및 프로젝트 특정 컨텍스트를 사양을 지원하는 모든 AI 도구에서 사용할 수 있습니다.

GitLab Duo Chat은 IDE에서 사용자 또는 워크스페이스 수준에서 설정된 리포지토리의 `AGENTS.md` 파일에서 사용 가능한 지침을 자동으로 적용합니다. 모노레포의 경우 `AGENTS.md` 파일을 하위 디렉터리에 배치하여 다양한 구성 요소에 대한 맞춤형 지침을 제공할 수 있습니다.

### AI 에이전트 및 플로우 버전 관리 {#ai-agent-and-flow-versioning}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/duo_agent_platform/ai_catalog.md#agent-and-flow-versions) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /details >}}

프로젝트에서 AI 카탈로그에서 에이전트 또는 플로우를 활성화할 때 GitLab은 이제 이를 특정 버전으로 고정합니다.

이는 카탈로그 항목이 발전해도 AI 기반 워크플로가 안정적이고 예측 가능하게 유지되므로 업그레이드하기 전에 새 버전을 테스트하고 검증할 수 있습니다.

### AI 게이트웨이 시간 초과 설정 {#ai-gateway-timeout-setting}

<!-- categories: Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-timeout-for-the-ai-gateway) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/579183)

{{< /details >}}

GitLab Duo Self-Hosted의 경우 이제 자체 호스팅 모델에 대한 요청의 시간 초과 값을 구성할 수 있습니다.

이 값은 60초에서 600초 사이의 범위입니다.

### 관리자에게 에이전트 및 플로우 보고 {#report-agents-and-flows-to-administrators}

<!-- categories: AI Catalog -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/report_abuse.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/578591)

{{< /details >}}

이제 문제가 있는 콘텐츠가 발견되면 에이전트 및 플로우를 인스턴스 관리자에게 보고할 수 있습니다. 피드백이 포함된 악용 보고서를 제출하면 관리자가 해로운 항목을 숨기거나 삭제할 수 있습니다.

이 기능을 사용하여 전체 조직에서 에이전트 및 플로우를 안전하게 유지합니다.

### 기본 에이전트 가용성 구성 {#configure-foundational-agent-availability}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/583815)

{{< /details >}}

이제 최상위 그룹 또는 인스턴스에서 사용 가능한 기본 에이전트를 제어할 수 있습니다.

모든 기본 에이전트를 기본적으로 설정하거나 해제하거나 개별 에이전트를 토글하여 조직의 보안 및 거버넌스 정책에 맞춥니다.

## 규모 및 배포 {#scale-and-deployments}

### Self-Managed를 위한 향상된 활성 체험판 경험 {#enhanced-active-trial-experience-for-self-managed}

<!-- categories: Acquisition -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../subscriptions/free_trials.md#view-remaining-trial-period-days)

{{< /details >}}

GitLab Self-Managed의 Ultimate 체험판 사용자는 이제 왼쪽 사이드바에서 활성 체험판 상태, 남은 일 수, 액세스 가능한 기능 및 만료 알림을 확인할 수 있습니다.

이러한 개선사항은 체험판 기간에 대한 혼동을 없애고 구매 전에 유료 기능을 평가하기가 더 쉬워집니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Self-Managed 및 Dedicated 환경에서 사용 가능한 고급 취약성 관리 {#advanced-vulnerability-management-available-in-self-managed-and-dedicated-environments}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

고급 취약성 관리는 모든 Ultimate 고객을 위해 제공되며 다음 기능을 포함합니다:

- 프로젝트 또는 그룹의 취약성 보고서에서 OWASP 2021 카테고리별로 데이터를 그룹화합니다.
- 프로젝트 또는 그룹의 취약성 보고서에서 취약성 식별자를 기반으로 필터링합니다.
- 프로젝트 또는 그룹의 취약성 보고서에서 도달 가능성 값을 기반으로 필터링합니다.
- 정책 위반 우회 이유로 필터링합니다.

### GLQL 기반 Data Analyst 기본 에이전트(베타) {#data-analyst-foundational-agent-powered-by-glql-beta}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)

{{< /details >}}

Data Analyst 에이전트는 GitLab 플랫폼 전체에서 데이터를 쿼리, 시각화 및 표시하는 데 도움이 되는 전문화된 AI 어시스턴트입니다. GitLab Query Language(GLQL)를 사용하여 데이터를 검색 및 분석한 다음 프로젝트에 대한 명확하고 실행 가능한 통찰력을 제공합니다.

설명서에서 예제 프롬프트 및 사용 사례를 찾을 수 있습니다.

이 에이전트는 현재 베타 상태이므로 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)에서 의견을 공유해 주시면 개선에 도움이 되고 다음에 어디로 갈지에 대한 통찰력을 제공하는 데 도움이 됩니다.

### 규정 준수 위반 필터링 및 댓글 {#filter-and-comment-on-compliance-violations}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

규정 준수 위반 보고서는 조직의 프로젝트 전체에서 모든 규정 준수 위반을 중앙 집중식으로 볼 수 있습니다. 보고서는 제어 위반, 관련 감사 이벤트에 대한 포괄적인 세부 정보를 표시하며 팀이 위반 상태를 효과적으로 추적할 수 있습니다.

GitLab 18.7에서는 가장 중요한 위반을 빠르게 찾을 수 있도록 강력한 필터링 기능을 도입했습니다. 이제 다음을 기준으로 필터링할 수 있습니다:

- 상태
- 프로젝트
- 제어

팀은 이제 댓글을 통해 위반 해결에 직접 협력할 수 있습니다. 위반 레코드 자체 내에서 팀은 다음을 수행할 수 있습니다:

- 조사를 위해 팀 멤버 태그 지정
- 수정 방법 논의
- 문서화 결과 - 모든 것이 위반 레코드 자체 내에서.

이 기능들은 함께 규정 준수 위반 보고서를 동적 협업 플랫폼으로 진화시키므로 조직이 그룹 및 프로젝트에서 규정 준수 위반을 효율적으로 발견, 분석 및 해결할 수 있습니다.

### 규정 준수 프레임워크 제어가 정확한 검사 상태를 표시 {#compliance-framework-controls-show-accurate-scan-status}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)

{{< /details >}}

GitLab 규정 준수 제어를 규정 준수 프레임워크에서 사용할 수 있습니다. 제어는 규정 준수 프레임워크에 할당된 프로젝트의 구성 또는 동작에 대한 검사입니다.

이전에는 스캐너와 관련된 제어(예: SAST가 활성화되어 있는지 확인)는 규정 준수 센터가 제어의 성공 또는 실패 상태를 표시하기 전에 프로젝트가 기본 브랜치에서 통과 파이프라인을 가져야 했습니다.

GitLab 18.7에서는 이 동작을 변경했으므로 전체 파이프라인 상태와 관계없이 검사 완료만을 기준으로 제어가 성공했는지 실패했는지를 표시합니다. 규정 준수 상태가 전체 파이프라인이 통과했는지가 아니라 보안 검사가 실행되고 완료되었는지를 반영하므로 혼동을 없애는 데 도움이 됩니다.

### 제목 앵커 링크의 접근성 개선 {#accessibility-improvements-for-heading-anchor-links}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/markdown.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/463385)

{{< /details >}}

제목 앵커 링크는 이제 해당 제목과 동일한 텍스트로 공지되어 화면 판독기 사용자의 경험을 개선합니다. 링크도 제목 텍스트 뒤에 나타나므로 시각적 표현이 더 깔끔합니다.

이러한 변경사항은 모든 사용자가 설명서, 이슈 및 기타 콘텐츠의 특정 섹션을 이해하고 탐색하기가 더 쉬워집니다.

### 머지 리퀘스트 승인 정책에서 경고 모드 {#warn-mode-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

보안 팀은 이제 경고 모드를 사용하여 보안 정책을 적용하기 전에 보안 정책의 영향을 테스트하고 검증하거나 보안 프로그램을 가속화하기 위해 소프트 게이트를 배포할 수 있습니다. 경고 모드는 보안 정책 롤아웃 중에 개발자 마찰을 줄이는 동시에 감지된 취약성이 해결되도록 합니다.

[머지 리퀘스트 승인 정책](../../user/application_security/policies/merge_request_approval_policies.md)을 만들거나 편집할 때 `warn` 또는 `enforce` 적용 옵션 중에서 선택할 수 있습니다.

경고 모드의 정책은 머지 리퀘스트를 차단하지 않고 정보 제공 봇 댓글을 생성합니다. 선택적 승인자를 정책 질문에 대한 연락처로 지정할 수 있습니다. 이 접근 방식을 통해 보안 팀은 정책 영향을 평가하고 투명하고 점진적인 정책 채택을 통해 개발자 신뢰를 구축할 수 있습니다.

머지 리퀘스트의 명확한 표시기는 정책이 `warn` 또는 `enforce` 모드인 경우를 사용자에게 알려주며, 감사 이벤트는 규정 준수 보고를 위해 정책 위반 및 거부를 추적합니다. 개발자는 정책 거부에 대한 이유를 제공하여 검사 결과 및 라이선스 정책 위반을 우회할 수 있으므로 개발자와 보안 팀 간의 협업 피드백 루프가 더 효과적인 정책 활성화를 위해 생성됩니다.

정책 위반이 프로젝트의 기본 브랜치에서 감지되면 정책이 프로젝트 및 그룹의 취약성 보고서에서 정책을 위반하는 취약성을 식별합니다. 프로젝트의 종속성 목록도 라이선스 규정 준수 정책 위반을 나타내는 배지를 표시합니다.

또한 API를 사용하여 프로젝트의 기본 브랜치에서 필터링된 정책 위반 목록을 쿼리할 수 있습니다.

### GitLab.com에서 체험판 중에 서비스 계정 사용 가능 {#service-accounts-available-during-trials-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/profile/service_accounts.md)

{{< /details >}}

서비스 계정은 이제 체험판 기간 중에 사용 가능하므로 구매하기 전에 자동화 및 통합 워크플로를 테스트할 수 있습니다.

### GitLab 러너 18.7 {#gitlab-runner-187}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

우리는 또한 오늘 GitLab Runner 18.7을 릴리스하고 있습니다!

GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [구성 가능한 taskscaler 예약 제한](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39161)
- [`FF_TIMESTAMPS`를 기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38378)

#### 버그 수정 {#bug-fixes}

- [상대 `builds_dir`가 지정된 경우 기존 Git 리포지토리에서 쉘 실행기가 실패합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39150)
- [이후 파이프라인 실행에서 GitLab Runner 18.6.0의 인증 실패(SSH 실행기)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39140)
- [이후 파이프라인 실행에서 GitLab Runner 18.6.0의 인증 실패(쉘 실행기)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39123)
- [Docker 29 API 호환성 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39129)
- [파일 변수를 참조하는 변수가 쉘 실행기와 함께 GitLab Runner 18.6.0에서 더 이상 작동하지 않습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39124)
- [GitLab Runner는 이제 Windows 11 2025(25H2)를 지원합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39050)
- [ECR 자격 증명 도우미가 Docker Autoscaler 실행기와 작동하지 않습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38365)
- [작업 시간 제한이 GitLab Runner에서 제대로 적용됩니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27040)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/CHANGELOG.md).md)에 있습니다.

### 머지 리퀘스트에서 자식 파이프라인 보고서 보기 {#view-child-pipeline-reports-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18311)

{{< /details >}}

부모-자식 CI/CD 파이프라인을 사용하는 팀은 이전에 테스트 결과, 코드 품질 보고서 및 인프라 변경 사항을 확인하기 위해 여러 파이프라인 페이지를 탐색해야 했으므로 머지 리퀘스트 검토 워크플로를 방해했습니다.

이제 단위 테스트, 코드 품질 검사, Terraform 계획 및 사용자 지정 메트릭을 포함한 모든 보고서를 통합 보기에서 보고 다운로드할 수 있으며 머지 리퀘스트를 떠나지 않습니다.

이렇게 하면 컨텍스트 전환이 제거되고 머지 리퀘스트 속도가 빨라져 팀이 품질을 손상시키지 않으면서 기능을 더 빠르게 제공할 수 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.7)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
