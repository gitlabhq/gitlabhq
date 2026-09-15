---
stage: Release Notes
group: Monthly Release
date: 2026-03-19
title: "GitLab 18.10 릴리스 정보"
description: "GitLab Duo Agent Platform으로 SAST 오탐 탐지 기능이 포함된 GitLab 18.10 릴리스"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026년 3월 19일에 GitLab 18.10이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Harshith Sudar {#this-months-notable-contributor-harshith-sudar}

Harshith는 현재 레벨 3 기여자이며, 트리어지 자동화 및 기여자 인식부터 [GitLab Duo](https://about.gitlab.com/gitlab-duo-agent-platform/) 사용 인사이트에 이르기까지 커뮤니티 도구 및 분석 개선에 영향력 있는 기여를 했습니다.

Harshith의 기여는 먼저 GitLab의 DevRel Engineering 풀스택 엔지니어인 [Lee Tickett](https://gitlab.com/leetickett-gitlab)에게 인정받았으며, 그가 그를 추천했습니다. 그의 작업은 자동화 및 기여자를 대상으로 한 경험 개선을 통해 백그라운드에서 기여자를 지원하는 방식을 강화했습니다. 예를 들어, 그는 [`IssueSummary` 프로세서를 여러 프로젝트와 함께 작동하도록 업데이트](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/3589)하여 트리어지 자동화를 확장했으며, [contributors.gitlab.com](https://contributors.gitlab.com)을 포함하여 더 많은 커뮤니티 프로젝트를 일관되게 요약하고 표시하기 쉽게 만들었습니다. 또한 [새로운 "콘텐츠 추가" 버튼 및 플로우](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1250)를 통해 커뮤니티가 만든 콘텐츠를 인식하는 것을 도왔으며, 이를 통해 기여자들이 자신의 프로필에서 직접 블로그 게시물, 비디오 및 기타 콘텐츠를 기록하고 보상을 받을 수 있습니다.

Harshith는 또한 분석 및 GitLab Duo 사용 인사이트에 기여했습니다. 주요 내용에는 [GitLab Duo 사용 방식 개선](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207511), [180일 기본값 제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218870)를 통해 시간에 따른 AI 영향을 살펴보는 방식 개선, [DORA 지표 날짜 범위 상수 통합](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216715), 그리고 [Value Stream Analytics 사용자 지정 스테이지 레이블 선택기에 무한 스크롤 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207796)와 같은 개선을 통한 규모 있는 분석 강화가 포함됩니다. 이러한 변경 사항들은 팀이 GitLab이 실제 프로젝트에서 어떻게 사용되는지 더 잘 이해하는 데 도움이 됩니다.

본인의 말로:

> "기여하면서 정말 즐거웠던 점은 커뮤니티 내에서 아이디어가 얼마나 신중하게 논의되는지입니다. [MR !1288](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1288)에 대한 논의와 같이 제안이 협력적으로 탐색되는 것을 보는 것이 권장되며, 이는 훌륭한 학습 경험이 되었습니다. 이 커뮤니티의 일부가 될 수 있어서 정말 행복하며 앞으로 더 많은 기여를 하기를 기대합니다."

Harshith, GitLab 코드베이스와 기여자 경험을 개선하기 위한 지속적인 작업에 감사드립니다!

Harshith와 연결하고 그의 기여에 대해 더 알고 싶으신가요? Harshith의 [GitLab 프로필](https://gitlab.com/official.harshith1) 및 [LinkedIn 프로필](https://www.linkedin.com/in/harshith-s-a44169282/)을 방문하세요.

## 주요 기능 {#primary-features}

### GitLab Duo Agent Platform을 사용한 SAST 오탐 탐지 {#sast-false-positive-detection-with-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/application_security/vulnerabilities/false_positive_detection.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/19789)

{{< /details >}}

GitLab 18.7에서 처음 베타로 도입된 SAST 오탐 탐지는 이제 GitLab 18.10에서 일반적으로 제공됩니다.

보안 스캔이 실행되면 GitLab Duo Agent Platform은 각 치명적 및 높은 심각도 SAST 취약성을 분석하고 오탐일 가능성을 결정합니다. 평가는 취약성 보고서에 직접 나타나므로 팀이 불확실함 없이 자신감을 가지고 분류할 수 있는 컨텍스트를 제공합니다.

주요 기능은 다음을 포함합니다:

- 자동 분석: 오탐 탐지는 각 보안 스캔 후 자동으로 실행되며 수동 개입이 필요하지 않습니다.
- 수동 옵션: 사용자는 취약성 세부 정보 페이지에서 개별 취약성에 대해 오탐 탐지를 수동으로 실행하여 온디맨드 분석을 수행할 수 있습니다.
- 영향도가 높은 결과에 집중: 분석을 치명적 및 높은 심각도 SAST 취약성으로 제한하면 가장 중요한 곳에서 노이즈를 제거합니다.
- 상황별 AI 추론: 각 평가는 코드 컨텍스트, 데이터 흐름 및 정적 분석에 특화된 취약성 특성을 고려하여 발견이 오탐일 수 있는지 여부를 설명합니다.
- 원활한 워크플로우 통합: 결과는 기존 심각도, 상태 및 수정 정보와 함께 취약성 보고서에 직접 나타나므로 기존 워크플로우를 변경할 필요가 없습니다.

이 기능은 GitLab Duo Agent Platform이 있는 Ultimate 고객을 위해 제공됩니다. 기능을 그룹 또는 프로젝트 설정에서 활성화해야 합니다. [이슈 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)에서 피드백을 환영합니다.

### GitLab.com의 Free 티어에서 GitLab Credits 구매 {#purchase-gitlab-credits-on-the-free-tier-on-gitlabcom}

<!-- categories: Subscription Management -->

{{< details >}}

- 티어: Free
- 제공 서비스: GitLab.com
- 추가 기능: GitLab Credits
- 링크: [설명서](../../subscriptions/gitlab_credits.md#for-the-free-tier) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

GitLab.com의 Free 티어 그룹 소유자는 이제 GitLab Credits로 AI를 잠금 해제할 수 있습니다. 월간 크레딧 금액을 구매하고 연간 약정을 하면 [GitLab Duo Agent Platform 에이전트 및 플로우](../../subscriptions/gitlab_credits.md#for-the-free-tier)에 접근할 수 있습니다. 크레딧은 매월 자동으로 새로 고쳐지므로 팀이 항상 더 빠르고 더 스마트하게 빌드할 수 있습니다.

주요 내용:

- **Usage-based pricing**: 기본 요금제 구독이 필요 없이 월간 크레딧 약정을 구매하세요.
- **Self-service purchasing**: GitLab 구매 흐름을 통해 크레딧을 구매하세요.
- **Seamless upgrade path**: 나중에 Premium 또는 Ultimate으로 업그레이드하면 크레딧 약정이 전환됩니다.
- **Consumption tracking**: GitLab Credits 대시보드를 통해 크레딧 사용을 모니터링하세요.

이 [구매 옵션](../../subscriptions/gitlab_credits.md#buy-gitlab-credits)은 현재 무료 GitLab.com 최상위 그룹에서만 사용할 수 있습니다.

### 패스키로 안전하게 로그인 {#sign-in-securely-with-passkeys}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../auth/passkeys.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/10897)

{{< /details >}}

GitLab은 이제 패스키를 지원하여 암호 없는 로그인 및 피싱에 저항하는 2단계 인증(2FA) 방법으로 제공합니다. 패스키는 공개 키 암호화 및 생체 인증(지문, 얼굴 인식) 또는 기기 PIN을 사용하여 계정에 안전하게 접근합니다.

패스키는 다음과 같은 이점을 제공합니다:

- **Passwordless convenience**: 암호를 기억하는 대신 기기의 생체 인증 또는 PIN으로 로그인하세요.
- **Multi-device support**: 데스크톱 브라우저, 모바일 기기(iOS 16 이상, Android 9 이상) 및 FIDO2/WebAuthn 호환 하드웨어 보안 키에서 패스키를 사용하세요.
- **Phishing-resistant security**: 개인 키는 기기를 떠나지 않습니다. GitLab은 공개 키만 저장하므로 GitLab 서버가 손상되어도 계정을 보호합니다.
- **Automatic 2FA integration**: 2FA가 활성화된 계정의 경우 패스키는 기본 2FA 방법으로 사용할 수 있게 됩니다.

시작하려면 계정 설정에 패스키를 추가하세요. [366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/366758)) 이슈에서 질문과 피드백을 환영합니다.

### 작업 항목 목록 및 저장된 보기 소개 {#introducing-the-work-items-list-and-saved-views}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/work_items/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17530)

{{< /details >}}

GitLab 계획 경험은 작업 항목 목록 및 저장된 보기로 상당히 업그레이드되고 있으며, 오래 요청된 두 가지 기능을 함께 제공합니다:

- 작업 항목 목록은 에픽, 이슈 및 기타 작업 항목을 단일 통합 목록으로 결합하므로 여러 작업 항목 유형에 대해 별도 페이지 간 전환할 필요가 없습니다. 이를 통해 계획 객체 간 관계를 이해하기가 더 쉬워집니다.
- 저장된 보기를 사용하면 필터, 정렬 순서 및 표시 옵션을 포함한 사용자 지정 목록 구성을 만들고 저장할 수 있습니다. 이를 통해 정기적인 확인이 더 효율적이 되고 팀 전체에서 표준화된 작업 보기 방식을 지원합니다.

이것은 GitLab 작업 항목 여정의 다음 단계이며 GitLab 계획 도구 전반에서 일관성을 제공하고 새로운 기능을 잠금 해제하도록 설계된 통합 아키텍처입니다.

[이슈 590689](https://gitlab.com/gitlab-org/gitlab/-/work_items/590689)에서 의견과 피드백을 공유하세요.

### 사용자 지정 에이전트는 MCP를 사용하여 외부 데이터에 접근할 수 있습니다 {#custom-agents-can-use-mcp-to-access-external-data}

<!-- categories: AI Catalog -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)

{{< /details >}}

이제 AI 카탈로그의 사용자 지정 에이전트를 Model Context Protocol(MCP)을 통해 외부 데이터 소스 및 도구에 연결할 수 있으며 GitLab을 떠나지 않고도 가능합니다.

이 기능은 실험입니다. [이슈 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219)에서 피드백을 공유하세요.

### 정규식으로 머지 리퀘스트 제목 명명 규칙 적용 {#enforce-merge-request-title-naming-conventions-with-regex}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/merge_requests/title_validation.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20108)

{{< /details >}}

일관된 머지 리퀘스트 제목을 유지하는 것은 구조화된 명명 규칙에 의존하는 팀에게 중요합니다. Conventional Commits 형식을 따르거나 내부 추적 시스템에 연결하는 것이든 간에 말입니다. 팀은 이전에 이러한 규칙을 적용하기 위해 외부 도구 또는 사용자 지정 CI/CD 파이프라인 작업이 필요했지만 이 접근 방식에는 치명적인 간격이 있었습니다. 파이프라인이 실행된 후 누군가 머지 리퀘스트 제목을 변경한 경우 재검증이 없었으며 MR은 여전히 비호환 제목으로 병합될 수 있었습니다.

이제 프로젝트 설정에서 머지 리퀘스트에 필요한 제목 정규식을 구성할 수 있습니다. 구성되면 GitLab은 머지 리퀘스트 제목을 병합 가능성 확인으로 패턴에 비해 평가합니다. 제목이 마지막으로 변경된 때와 관계없이 제목이 준수하도록 업데이트될 때까지 병합을 차단합니다.

이를 설정하려면 프로젝트의 **설정 > 머지 리퀘스트**로 이동하여 **Merge request title must match regex** 필드에 정규식 패턴을 입력하세요.

기존 머지 리퀘스트 워크플로우는 이전과 같이 계속 작동합니다. 이 확인은 명시적으로 제목 정규식을 구성한 프로젝트에만 적용됩니다.

### AI를 사용한 스크릿 오탐 탐지(베타) {#secret-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management, Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/application_security/vulnerabilities/secret_false_positive_detection.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20152)

{{< /details >}}

보안 팀은 오탐으로 판명되는 시크릿 탐지 결과를 조사하는 데 상당한 시간을 소비합니다. 예를 들어, 테스트 자격 증명, 예제 값 및 자리 표시자 토큰이 실제 시크릿으로 잘못 표시됩니다. 오탐은 경보 피로를 유발하고, 스캔 결과에 대한 신뢰를 훼손하며, 실제 보안 위험으로부터 주의를 돌립니다.

GitLab 18.10은 실제 중요한 시크릿에 초점을 맞추기 위해 AI 기반 시크릿 오탐 탐지(베타)를 도입합니다. 보안 스캔이 실행되면 GitLab Duo는 각 **치명적** 및 **높음** 심각도 시크릿 탐지 취약성을 자동으로 분석하여 오탐인지 여부를 결정합니다.

AI 평가는 취약성 보고서에 직접 나타나므로 보안 엔지니어가 더 빠르고 자신감 있는 분류 결정을 내릴 수 있는 즉각적인 컨텍스트를 제공합니다.

주요 기능은 다음을 포함합니다:

- 자동 분석: 오탐 탐지는 각 보안 스캔 후 자동으로 실행되며 수동 트리거가 필요하지 않습니다.
- 수동 트리거 옵션: 취약성 세부 정보 페이지에서 개별 취약성에 대해 오탐 탐지를 수동으로 트리거하여 온디맨드 분석을 수행할 수 있습니다.
- 영향도가 높은 결과에 집중: 신호 대 잡음 개선을 극대화하기 위해 **치명적** 및 **높음** 심각도 취약성 범위를 지정합니다.
- 상황별 AI 추론: 각 평가에는 코드 컨텍스트 및 취약성 특성을 기반으로 결과가 실제 양성일 수도 있고 아닐 수도 있는 이유에 대한 설명이 포함되어 있습니다.
- 신뢰도 점수: 각 탐지에는 모델의 확실성을 기반으로 검토 우선순위를 지정하는 데 도움이 되는 신뢰도 점수가 포함됩니다.
- 원활한 워크플로우 통합: 결과는 기존 심각도, 상태 및 수정 정보와 함께 취약성 보고서에 직접 표시됩니다.

이 기능은 Ultimate 고객을 위한 무료 베타로 제공되며 그룹 또는 프로젝트 설정에서 활성화해야 합니다. [이슈 592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861)에서 피드백을 공유하세요.

### CI/CD 작업에서 런타임 입력값 사용 {#use-runtime-inputs-with-cicd-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../ci/jobs/job_inputs.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17833)

{{< /details >}}

동적 작업 구성에 CI/CD 변수를 사용하는 것은 어려울 수 있습니다. 변수는 복잡한 재정의 계층을 따르므로 관리하기 어렵고 다양한 사용 사례에 사용할 수 없습니다.

이제 `inputs`을 사용하여 작업 수준에서 명시적인 유형화된 입력값을 정의할 수 있습니다. 작업 입력값을 사용하여 작업이 런타임에 수용하는 값을 정의하고 제어합니다. 작업 입력값을 사용하면 다음을 얻습니다:

- 유형 안전(문자열, 숫자, 부울, 배열).
- 정적이거나 기존 변수를 참조할 수 있는 기본값.
- 사용할 수 있는 값의 엄격한 목록을 정의하는 옵션.
- 입력값을 검증하기 위한 정규식 지원.

작업 입력값은 사용자 상호 작용 없이 기본값을 사용할 수 있지만 작업을 재시도하거나 수동 작업을 실행할 때 값을 수정할 수 있습니다.

## 에이전틱 코어 {#agentic-core}

### 그룹 및 인스턴스 코드 검색을 위한 GitLab Blob Search {#gitlab-blob-search-for-group-and-instance-code-search}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/agents/tools.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/593221)

{{< /details >}}

[`[gitlab_blob_search](../../user/duo_agent_platform/agents/tools.md)`](../../user/duo_agent_platform/agents/tools.md) 도구는 이제 GitLab AI 에이전트가 코드를 검색할 수 있게 합니다:

- 그룹의 모든 프로젝트 전체.
- 인스턴스의 모든 접근 가능한 프로젝트 전체.

이전에는 blob 검색이 단일 프로젝트로 제한되었거나 명시적 프로젝트 ID 지정이 필요했습니다. 이 변경 사항은 AI 기반 워크플로우가 여러 관련 프로젝트에 걸쳐 분산된 코드를 더 쉽게 발견하고 재사용할 수 있게 합니다.

### 파이프라인 관리를 위한 GitLab MCP 서버 도구 {#gitlab-mcp-server-tool-for-pipeline-management}

<!-- categories: MCP Server -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#manage_pipeline) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)

{{< /details >}}

이제 새로운 `manage_pipeline` 도구를 사용하여 GitLab 프로젝트에서 CI/CD 파이프라인을 관리할 수 있습니다. 이 GitLab MCP 서버 도구를 사용하면 AI 에이전트가 단일 호출로 파이프라인을 만들고, 취소하고, 재시도하고, 삭제하고, 파이프라인 메타데이터를 업데이트할 수 있습니다. 이 도구를 사용하면 파이프라인 워크플로우를 자동화하기 위해 더 이상 여러 단계를 함께 연결할 필요가 없습니다.

다른 GitLab MCP 서버 도구를 보고 싶으시면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/566375)에서 알려주세요.

### 프로젝트 관리자는 사용자 지정 에이전트 및 플로우를 활성화할 수 있습니다 {#project-maintainers-can-enable-custom-agents-and-flows}

<!-- categories: AI Catalog -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/flows/custom.md#enable-a-flow) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590573)

{{< /details >}}

이전에는 AI 카탈로그에서 AI 에이전트 및 플로우를 활성화하려면 최상위 그룹 권한이 필요했습니다.

이제 탐색 수준 또는 프로젝트 수준에서 AI 카탈로그를 탐색할 때 프로젝트 관리자는 자신의 프로젝트에서 직접 에이전트 및 플로우를 활성화할 수 있습니다.

### 프로젝트의 원격 플로우에 대한 네트워크 접근 제어 구성 {#configure-network-access-control-for-remote-flows-in-projects}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/593560)

{{< /details >}}

이제 프로젝트에서 GitLab 러너를 사용하는 플로우에 대해 [네트워크 접근 제어](../../user/duo_agent_platform/environment_sandbox.md)를 구성할 수 있습니다.

이는 안전한 외부 통합을 제공하면서 네트워크 목적지에 대한 제어를 유지합니다. 또한 프로젝트 관리자에게 필요한 API 연결, MCP 서버 및 타사 서비스를 허용하는 유연성을 제공하면서 보안 경계를 적용합니다.

[네트워크 접근 제어](../../user/duo_agent_platform/environment_sandbox.md)를 `network_policy` 섹션의 `agent-config.yml`에서 구성합니다. `agent-config.yml`는 브랜치 보호 규칙 및 MR 승인 워크플로우로 보호됩니다.

### GitLab Duo Agent Platform을 위한 자체 호스팅 Vertex AI {#self-hosted-vertex-ai-for-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#configure-authentication-with-gemini-enterprise-agent-platform) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/591604)

{{< /details >}}

이제 Vertex AI는 GitLab Duo Agent Platform 자체 호스팅 내에서 지원되는 LLM 플랫폼입니다.

고객은 이제 GitLab Duo Agent Platform 기능과 함께 사용하기 위해 Vertex AI에 호스팅된 Anthropic 모델을 구성할 수 있습니다.

### 사용자는 프로젝트에서 직접 에이전트 및 플로우를 활성화할 수 있습니다 {#users-can-enable-agents-and-flows-directly-from-projects}

<!-- categories: AI Catalog -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/duo_agent_platform/agents/custom.md#enable-an-agent) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/588012)

{{< /details >}}

이제 관리자 및 소유자는 현재 컨텍스트에서 벗어나지 않고 프로젝트 또는 탐색 페이지에서 직접 에이전트 및 플로우를 활성화할 수 있습니다.

최상위 그룹 소유자는 자신의 그룹과 에이전트 및 플로우를 활성화하려는 특정 프로젝트를 선택할 수도 있으므로 워크플로우 설정을 간소화합니다.

### IDE 및 CI/CD 파이프라인에서 Agent Skills 지원 {#support-for-agent-skills-in-ides-and-cicd-pipelines}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/customize/agent_skills.md) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1984)

{{< /details >}}

GitLab Duo Agent Platform은 이제 [Agent Skills 명세](https://agentskills.io/specification)를 지원하며, 이는 AI 에이전트에 새로운 기능 및 전문 지식을 제공하기 위한 새로운 표준입니다.

프로젝트의 워크스페이스 수준에서 Agent Skills를 정의하여 특정 작업(예: 특정 프레임워크에서 테스트 작성)에 대한 전문 지식 및 워크플로우를 에이전트에 제공할 수 있습니다. 에이전트는 일치하는 작업을 만날 때 관련 스킬을 자동으로 발견하고 로드합니다.

이름, 파일 경로 또는 사용자 지정 슬래시 명령으로 스킬을 수동으로 트리거할 수도 있습니다. Agent Skills는 IDE의 플로우 및 에이전트 채팅, CI/CD 파이프라인에서 실행되는 플로우에 접근할 수 있습니다. 또한 명세를 지원하는 다른 AI 도구와도 작동합니다.

## 규모 및 배포 {#scale-and-deployments}

### CSV로 크레딧 사용 데이터 다운로드 {#download-credit-usage-data-as-csv}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../subscriptions/gitlab_credits.md#export-usage-data) \| [관련 이슈](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)

{{< /details >}}

청구 관리자는 이제 Customers Portal의 GitLab Credits 대시보드에서 직접 CSV 파일로 크레딧 사용 데이터를 다운로드할 수 있습니다.

내보내기는 약정, 면제, 평가판, 온디맨드 및 포함된 크레딧 사용을 포함하여 현재 청구 월의 크레딧 소비에 대한 일일 작업별 분석을 제공합니다.

재무 및 운영 팀은 이 데이터를 사용하여 수동 데이터 수집 또는 지원 요청 없이 Excel, Google Sheets 또는 BI 도구에서 비용 할당, 청구 환급 보고 및 사용 분석을 수행할 수 있습니다.

### GitLab Duo Agent Platform 세션에 크레딧 사용 연결 {#link-credit-usage-to-gitlab-duo-agent-platform-sessions}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/579139)

{{< /details >}}

GitLab Credits 대시보드는 이제 크레딧 소비를 생성한 GitLab Duo Agent Platform 세션과 직접 연결합니다.

사용자별 드릴다운 보기에서 **조치** 열(예: **에이전트 채팅** 또는 **Foundational Agents**)은 이제 해당 세션 세부 정보로 이동하는 클릭 가능한 하이퍼링크입니다.

이 링크는 청구에서 AI 세션 동작으로의 직접 감사 추적을 제공하므로 관리자는 별도 시스템에서 타임스탬프를 수동으로 상관시키지 않고 크레딧 사용, 지원 에스컬레이션 및 규정 준수 검토를 조사할 수 있습니다.

### GitLab Credits 대시보드에서 사용자 정렬 {#sort-users-in-the-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) \| [관련 이슈](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15608)

{{< /details >}}

엔터프라이즈 관리자는 이제 GitLab Credits 대시보드의 **Usage by User** 테이블을 사용한 총 크레딧 또는 사용자명으로 정렬할 수 있습니다.

기본 정렬 순서는 소비된 총 크레딧(높음 우선)이므로 상단 소비자가 스크롤 없이 즉시 표시됩니다.

이 보기를 통해 수천 명의 GitLab Duo 사용자를 관리하는 관리자는 비용 할당, 청구 환급 보고 및 라이선스 활용 감사를 위해 높은 사용량의 개인을 빠르게 식별할 수 있습니다.

### 탐색의 프로젝트에 대한 새로운 네비게이션 경험 {#new-navigation-experience-for-projects-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/13786)

{{< /details >}}

**탐색**의 프로젝트 페이지를 간소화하여 불필요한 옵션을 제거했습니다. 간소화된 인터페이스는 이제 두 가지 핵심 보기에 중점을 둡니다:

- **활성** 탭: 최근 활동 및 진행 중인 개발이 있는 프로젝트를 발견하세요.
- **비활성** 탭: 보관된 프로젝트 및 삭제 예정인 프로젝트에 접근하세요.

제거된 중복 탭:

- **Most starred** 프로젝트는 **활성** 또는 **비활성** 탭을 별 개수로 정렬하여 찾을 수 있습니다.
- **전체** 프로젝트는 **활성** 및 **비활성** 탭을 모두 보면 볼 수 있습니다.
- **Trending** 탭은 기능이 제한되고 사용량이 낮아 GitLab 19.0에서 완전히 제거될 예정입니다.

깔끔한 디자인은 시각적 일관성을 위해 다른 프로젝트 목록과 일치합니다. 더 논리적인 조직 및 유연한 정렬 옵션을 통해 모든 동일한 콘텐츠에 접근할 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Java Gradle 빌드 파일에 대한 SBOM 지원이 있는 종속성 검사 {#dependency-scanning-with-sbom-support-for-java-gradle-build-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788)

{{< /details >}}

SBOM을 사용한 GitLab 종속성 검사는 이제 Java `build.gradle` 및 `build.gradle.kts` 빌드 파일 검사를 지원합니다.

이전에는 Gradle을 사용하는 Java 프로젝트의 종속성 검사에 잠금 파일이 있어야 했습니다. 이제 잠금 파일을 사용할 수 없으면 분석기는 자동으로 `build.gradle` 및 `build.gradle.kts` 파일을 검사하여 직접 종속성만 추출 및 보고하므로 취약성 분석을 수행합니다. 이 개선 사항은 Gradle을 사용하는 Java 프로젝트가 잠금 파일을 요구하지 않고 종속성 검사를 활성화하기가 더 쉬워집니다.

매니페스트 대체를 활성화하려면 `DS_ENABLE_MANIFEST_FALLBACK` CI/CD 변수를 `"true"`로 설정합니다.

### 종속성 검사 SBOM 기반 검사가 자체 관리로 확장 {#dependency-scanning-sbom-based-scanning-extended-to-self-managed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/546429)

{{< /details >}}

GitLab 18.10에서는 새로운 SBOM 기반 종속성 검사 기능에 대해 제한적 출시 상태를 자체 관리 인스턴스로 확장하고 있습니다.

이 기능은 처음에 GitLab 18.5에서 `dependency_scanning_sbom_scan_api` 기능 플래그 뒤에서만 GitLab.com에 대해 제한적 출시로 릴리스되었으며 기본적으로 비활성화되었습니다.

추가 개선 및 수정으로 이제 새로운 SBOM 스캐닝 내부 API를 안정적으로 사용하고 이 기능 플래그를 기본적으로 활성화할 수 있습니다. 이 내부 API를 사용하면 종속성 검사 분석기가 모든 컴포넌트 취약성을 포함하는 종속성 검사 보고서를 생성할 수 있습니다. CI/CD 파이프라인 완료 후 SBOM 보고서를 처리한 이전 동작(베타)과 달리, [이 개선된 프로세스](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#how-it-scans-an-application)는 CI/CD 작업 중에 즉시 스캔 결과를 생성하므로 사용자가 사용자 지정 워크플로우를 위한 취약성 데이터에 즉시 접근할 수 있습니다.

이슈가 발생한 자체 관리 고객은 `dependency_scanning_sbom_scan_api` 기능 플래그를 비활성화할 수 있습니다. 분석기는 이전 동작으로 폴백됩니다.

이 기능을 사용하려면 v2 종속성 검사 템플릿 `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`을 가져오세요.

이 기능에 대한 피드백을 환영합니다. 질문, 의견이 있거나 당사 팀과 소통하고 싶으시면 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)에 연락해 주세요.

### Pub 패키지 관리자를 사용하는 Dart/Flutter 프로젝트에 대한 라이선스 검사 지원 {#license-scanning-support-for-dartflutter-projects-using-pub-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#data-sources) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/18351)

{{< /details >}}

GitLab은 이제 `pub` 패키지 관리자를 사용하는 Dart 및 Flutter 프로젝트에 대한 라이선스 검사를 지원합니다. 이전에는 Dart 또는 Flutter로 구축하는 팀이 GitLab 내에서 직접 오픈 소스 종속성의 라이선스를 식별할 수 없었으므로 라이선스 정책 요구 사항이 있는 조직의 규정 준수 사각지대가 발생했습니다.

라이선스 데이터는 공식 Dart 패키지 리포지토리인 [pub.dev](https://pub.dev)에서 직접 확보되며 결과는 다른 지원되는 생태계와 함께 표시됩니다. Dart/Flutter 종속성 검사 및 취약성 탐지는 이미 지원되었습니다.

### Conan 2.0 패키지 레지스트리 지원(베타) {#conan-20-package-registry-support-beta}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/packages/conan_2_repository/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/585819)

{{< /details >}}

Conan을 패키지 관리자로 사용하는 C 및 C++ 개발 팀은 오랫동안 GitLab에서 레지스트리 지원을 요청했습니다. 이전에는 Conan 패키지 레지스트리가 실험 단계였으며 Conan 1.x 클라이언트만 지원하므로 최신 Conan 2.0 도구 체인으로 마이그레이션한 팀의 도입을 제한했습니다.

Conan 패키지 레지스트리는 이제 Conan 2.0을 지원하며 실험 단계에서 베타로 승격되었습니다. 이 릴리스는 전체 v2 API 호환성, 레시피 수정 지원, 개선된 검색 기능 및 `--force` 플래그를 포함한 업로드 정책의 적절한 처리를 포함합니다. 팀은 표준 Conan 클라이언트 워크플로우를 사용하여 GitLab에서 직접 Conan 2.0 패키지를 게시하고 설치할 수 있으므로 JFrog Artifactory와 같은 외부 아티팩트 관리 솔루션의 필요성을 줄입니다.

이 업데이트를 통해 C 및 C++ 종속성을 관리하는 플랫폼 엔지니어링 팀은 소스 코드, CI/CD 파이프라인 및 보안 검사와 함께 GitLab 내에서 패키지 관리를 통합할 수 있습니다. Conan 레지스트리는 프로젝트 수준 및 인스턴스 수준 끝점을 모두 지원하며 인증을 위해 개인 액세스 토큰, 배포 토큰 및 CI/CD 작업 토큰을 사용합니다.

일반 가용성을 향해 나아가면서 피드백을 환영합니다. [에픽](https://gitlab.com/groups/gitlab-org/-/work_items/6816)에서 경험을 공유하세요.

### 전용 UI로 컨테이너 가상 레지스트리 관리(베타) {#manage-container-virtual-registries-with-a-dedicated-ui-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/packages/virtual_registry/container/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/19283)

{{< /details >}}

지난 마일스톤에서 컨테이너 가상 레지스트리가 베타로 시작했을 때 플랫폼 엔지니어는 여러 업스트림 컨테이너 레지스트리(Docker Hub, Harbor, Quay 등)를 단일 풀 끝점 뒤에 집계할 수 있었습니다. 그러나 모든 구성에는 직접 API 호출이 필요했으므로 팀이 레지스트리를 생성 및 관리하고, 업스트림을 구성하고, 시간 경과에 따른 변경 사항을 처리하기 위해 스크립트 또는 수동 curl 명령을 유지해야 했습니다. 이로 인해 운영 오버헤드가 증가했으며 API를 직접 사용하기가 불편한 사용자에게 기능에 접근할 수 없게 되었습니다.

컨테이너 가상 레지스트리는 이제 GitLab UI에서 직접 생성하고 관리할 수 있습니다. 그룹 수준 컨테이너 레지스트리 페이지에서 새 가상 레지스트리를 만들고, 인증 자격 증명으로 업스트림 소스를 구성하고, 기존 구성을 편집하고, 더 이상 필요하지 않은 레지스트리를 삭제할 수 있습니다. GitLab을 떠나거나 단일 API 호출을 작성할 필요 없이 모두 가능합니다. UI는 기존 컨테이너 레지스트리 경험과 원활하게 통합되므로 가상 레지스트리가 그룹의 아티팩트 관리 워크플로우의 일급 부분이 됩니다.

이 기능은 베타 단계입니다. 피드백을 공유하려면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)에 의견을 남겨주세요.

### GitLab Helm Chart 레지스트리 일반 가용성 {#gitlab-helm-chart-registry-generally-available}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/packages/helm_repository/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/573715)

{{< /details >}}

Helm을 사용하여 Kubernetes 애플리케이션 배포를 관리하는 팀은 이제 프로덕션 워크로드를 위해 GitLab Helm Chart 레지스트리를 신뢰할 수 있습니다. 이전에는 베타 단계였던 레지스트리는 주요 아키텍처 및 안정성 문제 해결 후 이제 일반적으로 제공됩니다.

GA 경로에는 `index.yaml` 끝점이 1,000개 이상의 차트를 반환하지 못하도록 하는 하드 제한 해결, 새로 게시된 차트 버전이 인덱스에서 누락되도록 하는 백그라운드 인덱싱 버그 수정, 완전한 AppSec 보안 검토 완료, GitLab Geo를 실행하는 자체 관리 고객의 높은 가용성을 보장하기 위해 Helm 메타데이터 캐시에 대한 Geo 복제 지원 추가가 포함되었습니다.

플랫폼 및 DevOps 팀은 표준 Helm 클라이언트 워크플로우를 사용하여 GitLab에서 직접 Helm 차트를 게시 및 설치할 수 있으며 프로젝트 수준 끝점과 개인 액세스 토큰, 배포 토큰 및 CI/CD 작업 토큰을 사용한 인증을 지원합니다. 이제 소스 코드, 파이프라인 및 그에 따라 달라지는 보안 검사와 함께 차트를 유지할 수 있습니다.

### Markdown 테이블에서 작업 항목 지원 {#task-item-support-in-markdown-tables}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [문서](../../user/markdown.md#task-lists-in-tables) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/21506)

{{< /details >}}

이제 Markdown 테이블 셀에서 직접 작업 항목 확인란 구문을 사용할 수 있습니다.

이전에는 이를 달성하려면 원시 HTML 및 Markdown의 조합이 필요했으므로 번거롭고 유지 관리하기 어려웠습니다.

이 개선 사항은 이슈, 에픽 및 기타 콘텐츠의 구조화된 테이블 레이아웃 내에서 직접 작업 완료를 추적하기가 더 쉬워집니다.

### 보안 구성 프로필의 파이프라인 시크릿 탐지 {#pipeline-secret-detection-in-security-configuration-profiles}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

GitLab 18.9에서 **Secret Detection - Default** 프로필과 함께 보안 구성 프로필을 도입했으며 푸시 보호로 시작했습니다. 이 프로필을 사용하여 단일 CI/CD 구성 파일을 건드리지 않고 수백 개의 프로젝트에 표준화된 시크릿 스캐닝을 적용합니다.

**Secret Detection - Default** 프로필은 이제 파이프라인 기반 스캐닝도 포함하므로 전체 개발 워크플로우에서 시크릿 탐지에 대한 통합 제어 표면을 제공합니다.

프로필은 세 가지 스캔 트리거를 활성화합니다:

- **Push Protection**: 모든 Git 푸시 이벤트를 스캔하고 시크릿이 탐지된 푸시를 차단하여, 시크릿이 코드베이스에 유입되는 것을 원천적으로 방지합니다.
- **머지 리퀘스트 파이프라인**: 열려 있는 머지 리퀘스트가 있는 브랜치에 새 커밋이 푸시될 때마다 스캔을 자동으로 실행합니다. 결과는 머지 리퀘스트에 의해 도입된 새로운 취약성만 포함합니다.
- **브랜치 파이프라인(기본값만)**: 변경 사항이 기본 브랜치에 병합되거나 푸시될 때 자동으로 실행되므로 기본 브랜치의 시크릿 탐지 태세에 대한 완전한 보기를 제공합니다.

프로필을 적용하려면 YAML 구성이 필요하지 않습니다. 그룹에 적용하여 그룹의 모든 프로젝트에 걸쳐 적용 범위를 전파하거나 개별 프로젝트에 적용하여 더 세밀한 제어를 할 수 있습니다.

### macOS Tahoe 26 및 Xcode 26 작업 이미지 {#macos-tahoe-26-and-xcode-26-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 링크: [설명서](../../ci/runners/hosted_runners/macos.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-com/gl-infra/-/work_items/1694)

{{< /details >}}

이제 macOS Tahoe 26 및 Xcode 26을 사용하여 Apple 기기의 최신 세대를 위한 애플리케이션을 만들고, 테스트하고, 배포할 수 있습니다.

[macOS의 호스팅 러너](../../ci/runners/hosted_runners/macos.md)를 사용하면 개발 팀이 GitLab CI/CD와 통합된 안전한 온디맨드 빌드 환경에서 macOS 애플리케이션을 더 빠르게 구축하고 배포할 수 있습니다.

`macos-26-xcode-26` 이미지를 `.gitlab-ci.yml` 파일에서 사용하여 오늘 시도해 보세요.

### GitLab Runner 18.10 {#gitlab-runner-1810}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/runner/)

{{< /details >}}

GitLab Runner 18.10도 오늘 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [빌드 pod의 Pod 수준 리소스를 정의하기 위해 k8s 러너 허용](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39085)
- [모든 Runner 프로젝트의 Go 버전 및 패키지를 업데이트하는 자동화 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39192)

#### 버그 수정 {#bug-fixes}

- [S3 캐시(RoleARN)는 존재하지 않는 캐시에 대해 404 대신 403을 반환합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39105)
- [`gitlab-runner-helper:x86_64-v16.11.1-nanoserver21H2` 도우미 이미지 사용으로 `init-permissions` 오류 발생](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37872)
- [macOS: LaunchAgent - M1 아키텍처에서 서비스를 초기화할 수 없음](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/28136)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.10)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
