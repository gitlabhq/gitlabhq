---
stage: Release Notes
group: Monthly Release
date: 2026-05-21
title: GitLab 19.0
description: GitLab Duo를 위한 그룹 수준 맞춤형 검토 지침과 함께 GitLab 19.0 릴리스
---

2026년 5월 21일에 GitLab 19.0이 다음 기능과 함께 릴리스되었습니다.

이번 달의 [주목할 만한 기여자](https://contributors.gitlab.com/notable-contributors)를 발표하게 되어 기쁩니다:  Norman Debald!

[Norman](https://gitlab.com/Modjo85)은 2022년 5월부터 GitLab에 참여하여 40개 이상의 병합된 개선 사항을 제공한 레벨 3 기여자입니다.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

## 주요 기능 {#primary-features}

### GitLab Duo를 위한 그룹 수준 맞춤형 검토 지침 {#group-level-custom-review-instructions-for-gitlab-duo}

<!-- categories: Duo Code Review -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능:  GitLab Duo Enterprise
- 링크:  [설명서](../../user/gitlab_duo/customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/21504)

{{< /details >}}

이전 버전의 GitLab에서는 프로젝트 수준에서만 GitLab Duo를 위한 맞춤형 검토 지침을 정의할 수 있었습니다. 동일한 그룹의 여러 프로젝트에서 작업하는 팀은 모든 프로젝트에서 동일한 지침을 복제해야 했습니다.

이제 전체 그룹 및 하위 그룹에 대한 공유 맞춤형 검토 지침을 구성할 수 있습니다.

템플릿으로 사용할 그룹의 프로젝트를 선택합니다. GitLab Duo가 코드 검토를 수행할 때 그룹 수준 `.gitlab/duo/mr-review-instructions.yaml` 파일과 개별 프로젝트에서 정의된 모든 지침을 결합합니다.

Code Review 플로우와 GitLab Duo Code Review는 모두 그룹 수준 맞춤형 지침을 지원합니다.

### 작업 항목 유형 구성 {#configure-work-item-types}

<!-- categories: Team Planning -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/work_items/configurable_work_item_types.md) , [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/9365)

{{< /details >}}

이전에는 작업 항목 유형이 **이슈** 또는 **작업** 중 하나일 수 있었습니다. 이제 프로젝트에서 맞춤형 작업 항목 유형을 구성하여 팀이 작업을 계획하고 추적하는 방식에 맞출 수 있습니다.

**User Story**, **버그** 또는 **Maintenance**로 유형을 만들거나 이름을 바꿀 수 있습니다. 각 작업 항목은 해당 유형 이름과 고유한 아이콘으로 표시됩니다. 새로운 유형은 맞춤형 필드와 상태 수명 주기를 지원하며 저장된 보기 및 이슈 보드에 나타납니다. 최상위 그룹(GitLab.com) 또는 조직(GitLab Self-Managed)의 유형 구성은 모든 프로젝트에 계층식으로 적용됩니다.

각 프로젝트에서 사용 가능한 유형을 제어할 수도 있습니다. 모든 프로젝트에서 한 번에 유형을 활성화 또는 비활성화하거나 개별 프로젝트가 자체 유형 가시성을 관리하도록 할 수 있습니다. 프로젝트에서 유형을 비활성화해도 기존 작업 항목은 영향을 받지 않습니다.

### GitLab Secrets Manager 이제 공개 베타로 제공됨 {#gitlab-secrets-manager-now-available-in-open-beta}

<!-- categories: Secrets Management -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 링크:  [설명서](../../ci/secrets/secrets_manager/_index.md) , [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/21731)

{{< /details >}}

이전 버전의 GitLab에서는 GitLab Secrets Manager가 폐쇄 베타 사용자 그룹에만 제공되었습니다. 대부분의 팀은 HashiCorp Vault 또는 AWS Secrets Manager와 같은 외부 서비스에 의존했습니다.

GitLab Secrets Manager는 이제 GitLab.com 및 GitLab Self-Managed의 Premium 및 Ultimate 고객을 위해 공개 베타로 제공됩니다. GitLab Secrets Manager가 활성화되면 프로젝트 및 그룹 소유자는 GitLab에서 CI/CD 시크릿을 저장, 검색 및 참조할 수 있습니다. 시크릿은 프로젝트 또는 그룹으로 범위가 지정되며 명시적으로 요청하는 파이프라인 작업에만 액세스할 수 있습니다.

공개 베타 동안 GitLab Secrets Manager는 [베타 지원 정책](../../policy/development_stages_support.md#beta)을 따르며 프로덕션 사용 준비가 되지 않았을 수 있습니다.

피드백을 공유하려면 [이슈 598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100)을 참조하세요.

### 머지 리퀘스트 워크플로우를 위한 GitLab Duo Developer 개선 사항 {#gitlab-duo-developer-enhancements-for-merge-request-workflows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/duo_agent_platform/flows/foundational_flows/developer.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)

{{< /details >}}

GitLab Duo Developer는 이제 여러 트리거 방법을 지원합니다: 이슈에 할당하고, **Generate MR**을 선택하거나, 모든 이슈 또는 MR 토론 스레드에서 `@mention`하여 피드백, 할 일 항목 및 설계 질문을 코드 변경, 후속 MR 또는 연구 요약으로 변환합니다.

`AGENTS.md`과 `agent-config.yml`가 구성되면 GitLab Duo Developer는 커밋하기 전에 테스트 및 확인을 실행합니다. 최상위 그룹 또는 인스턴스 관리자가 Developer 플로우를 활성화한 후 GitLab은 적격 프로젝트에 언급 및 할당 트리거를 자동으로 추가합니다.

### SBOM을 사용한 종속성 검사 정식 출시 {#dependency-scanning-by-using-sbom-generally-available}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) , [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/20456)

{{< /details >}}

GitLab SBOM 기반 종속성 검사기가 정식으로 출시되었습니다. Maven, Gradle 및 Python 프로젝트는 직접 선언된 종속성뿐만 아니라 과도적으로 도입된 취약한 패키지를 포함하여 전체 종속성 트리에서 취약성에 완전히 가시성을 갖습니다.

분석기에는 이제 Maven, Gradle 및 Python 프로젝트에 대한 자동 종속성 해결이 포함됩니다. 잠금 파일 또는 해결된 종속성 그래프가 없으면 분석기는 검사 전에 전체 과도적 종속성 그래프를 해결하기 위해 도구를 자동으로 호출합니다. 종속성 해결은 기본적으로 활성화되며 v2 종속성 검사 템플릿을 포함하는 것 이상의 추가 구성이 거의 또는 전혀 필요하지 않습니다.

종속성 해결이 불가능한 프로젝트의 경우 분석기는 매니페스트 검사로 폴백합니다. `pom.xml`, `requirements.txt`, `build.gradle` 및 `build.gradle.kts`를 구문 분석하여 직접 종속성을 식별합니다. 매니페스트 검사는 팀이 잠금 또는 빌드 파일 없는 프로젝트의 경우에도 취약성 보장의 시작점을 항상 얻을 수 있도록 합니다.

매니페스트 검사는 기본적으로 활성화되며 직접 종속성만 반환합니다. 전체 과도적 범위를 보려면 종속성 해결을 활성화하거나 종속성 잠금 파일 또는 그래프 내보내기를 수동으로 제공하세요.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Core는 사용량 기반 청구로 이동 {#gitlab-duo-core-moves-to-usage-based-billing}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../subscriptions/subscription-add-ons.md#gitlab-duo-core) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/600144)

{{< /details >}}

GitLab 19.0부터 GitLab Duo Core는 사용량 기반 청구로 이동합니다. 웹 IDE 및 데스크톱 IDE의 코드 제안은 이제 [GitLab Credits](../../subscriptions/gitlab_credits.md)를 사용합니다.

GitLab Duo Chat도 변경되고 있습니다. GitLab Duo Core 사용자의 경우 Chat은 이제 에이전틱이며 GitLab Duo Agent Platform에서 실행됩니다. GitLab UI 또는 데스크톱 IDE에서 GitLab Duo Chat을 사용하려면 인스턴스 또는 최상위 그룹에 대해 GitLab Duo Agent Platform을 활성화하세요.

### 리포지토리별 정확한 코드 검색 결과 필터링 {#filter-exact-code-search-results-by-repository}

<!-- categories: Global Search -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 링크:  [설명서](../../user/search/exact_code_search.md#syntax) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

이제 리포지토리별 정확한 코드 검색 결과를 필터링할 수 있습니다. `repo:` 구문을 사용하면 개별 프로젝트로 이동할 필요 없이 특정 리포지토리 또는 리포지토리 패턴으로 검색 쿼리의 범위를 직접 지정할 수 있습니다.

예를 들어 `def authenticate repo:my-group/my-project`을 검색하면 해당 리포지토리의 결과만 반환됩니다. 부분 경로 또는 패턴을 사용하여 여러 리포지토리를 일치시킬 수도 있습니다.

### 머지 리퀘스트 준비 이벤트 트리거 {#merge-request-ready-event-trigger}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 링크:  [설명서](../../user/duo_agent_platform/triggers/_index.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)

{{< /details >}}

이제 **Merge request ready** 이벤트에서 플로우 및 외부 에이전트를 실행하도록 구성할 수 있습니다.

초안 머지 리퀘스트가 검토 준비로 표시되면 GitLab Duo가 자동으로 플로우 또는 외부 에이전트를 실행합니다.

트리거를 구성하려면 프로젝트에서 **AI** > **트리거**로 이동하세요.

이 기능은 `merge_request_ready_flow_trigger` 기능 플래그 뒤에 있으며 기본적으로 비활성화되어 있습니다.

### Claude Opus 4.7 이제 GitLab Duo Agent Platform에서 제공됨 {#claude-opus-47-now-available-in-gitlab-duo-agent-platform}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/duo_agent_platform/model_selection.md#supported-models) , [관련 이슈](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2177)

{{< /details >}}

Claude Opus 4.7은 이제 GitLab Duo Agent Platform에서 사용할 수 있습니다. Opus 4.7은 지속된 추론, 정확한 지침 따르기 및 결과 표시 전 자체 검증이 필요한 복잡한 다단계 작업에 의미 있는 개선을 제공합니다. 여기에는 CI/CD 파이프라인, 코드 검토, 취약성 해결 등을 지원하는 플로우가 포함됩니다.

### 자체 호스팅 Gemini 모델 지원 {#support-for-self-hosted-gemini-models}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform Self-Hosted는 이제 Gemini 모델과 호환됩니다. Gemini 모델은 Code Review 플로우, SAST Vulnerability Resolution 플로우, Fix CI/CD Pipeline 플로우 등을 포함한 여러 플로우를 지원합니다.

### GitLab Duo Agent Platform에서 확장된 오픈 소스 모델 지원 {#expanded-open-source-model-support-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform은 이제 Devstral 2 123B, GLM-5.1-FP8 등을 포함한 자체 호스팅 배포를 위한 추가 오픈 소스 모델을 지원합니다. 이는 오프라인 및 네트워크 제한 배포를 포함한 다양한 환경에서 에이전틱 워크플로우를 구동하는 데 도움이 됩니다.

### 관리자 제어 기능이 있는 세션별 도구 승인 {#per-session-tool-approvals-with-admin-controls}

<!-- categories: Duo Agent Platform, Duo Chat -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/596366)

{{< /details >}}

GitLab Duo Agentic Chat이 사용자를 대신하여 도구를 사용하기 전에 승인이 필요합니다. 각 도구 호출에는 별도의 승인이 필요합니다.

이제 신뢰할 수 있는 도구를 전체 세션에 대해 한 번 승인하고 워크플로우를 간소화할 수 있습니다.

관리자는 세션에 대한 도구 승인 사용 가능 여부를 제어합니다. 다음 설정은 인스턴스에서 그룹으로, 그룹에서 프로젝트로 계층식으로 적용됩니다:

- **기본적으로 켜짐**
- **기본적으로 꺼짐**
- **항상 꺼짐**

관리자가 **항상 꺼짐**으로 설정하지 않으면 그룹 및 하위 그룹이 설정을 수정할 수 있습니다.

기본 설정은 **기본적으로 꺼짐**이므로 관리자가 변경하지 않으면 각 도구 호출에 명시적 승인이 필요합니다.

### GitLab Duo로 머지 충돌 해결(베타) {#resolve-merge-conflicts-with-gitlab-duo-beta}

<!-- categories: Duo Agent Platform, Code Review Workflow -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/20688)

{{< /details >}}

이전 버전의 GitLab에서는 간단한 경우에도 GitLab UI 또는 명령줄에서 머지 충돌을 수동으로 해결해야 했습니다.

이제 GitLab Duo는 머지 충돌을 자동으로 분석하고, 충돌하는 파일을 편집하고, 커밋을 생성하고, 소스 브랜치로 푸시할 수 있습니다. **충돌 해결** 페이지에서 또는 머지 리퀘스트 위젯에서 직접 충돌 해결을 트리거합니다. 완료되면 GitLab Duo가 검토자가 변경 내용을 볼 수 있도록 요약 댓글을 게시합니다.

GitLab Duo는 브랜치 보호 규칙을 준수하며 보호된 브랜치로 강제 푸시하지 않습니다.

이 기능은 베타 단계이며 `mr_ai_resolve_conflicts` 기능 플래그 뒤에 있으며 기본적으로 비활성화되어 있습니다.

### AI 카탈로그를 그룹 계층 구조로 제한 {#restrict-the-ai-catalog-to-a-group-hierarchy}

<!-- categories: AI Catalog -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/duo_agent_platform/ai_catalog.md#restrict-the-ai-catalog-to-a-group-hierarchy) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617)

{{< /details >}}

최상위 그룹 소유자는 이제 AI 카탈로그를 제한하여 그룹 계층 구조 내의 프로젝트가 소유한 에이전트 및 플로우만 표시할 수 있습니다. 이 계층 구조에 없는 에이전트, 외부 에이전트 또는 플로우가 해당 그룹의 사용자가 표시되거나 활성화되는 것을 차단합니다.

### GitLab Self-Managed의 무료 티어에서 크레딧 구매 {#purchase-credits-on-the-free-tier-on-gitlab-self-managed}

<!-- categories: Subscription Management -->

{{< details >}}

- 계층:  Free
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../subscriptions/gitlab_credits.md#buy-gitlab-credits) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

GitLab Self-Managed의 무료 티어 사용자는 이제 GitLab Duo Agent Platform의 전체 성능을 잠금 해제할 수 있으며 Premium 또는 Ultimate 구독이 필요하지 않습니다. 월간 크레딧 금액을 선택하고, 연간 기간으로 약정하고, AI 기반 개발 도구에 즉시 액세스할 수 있습니다. 크레딧은 매월 자동으로 새로 고쳐지므로 팀이 항상 더 빠르고 더 똑똑하게 빌드할 수 있는 것이 있습니다.

### Agent Platform 원격 플로우를 위한 관리자 정의 네트워크 액세스 제어 {#admin-defined-network-access-controls-for-agent-platform-remote-flows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/593149)

{{< /details >}}

관리자는 이제 설정에서 직접 GitLab Duo Agent Platform 원격 플로우를 위한 중앙 집중식 네트워크 정책을 정의할 수 있습니다. GitLab.com의 최상위 그룹 관리자 및 GitLab Self-Managed 및 Dedicated의 인스턴스 관리자는 프로젝트가 자동으로 상속하는 조직 전체 도메인 거부 목록 및 허용 목록을 구성할 수 있습니다. 추가 설정은 프로젝트가 승인된 도메인 목록을 맞춤형 항목으로 확장할 수 있는지 여부를 제어합니다. 정책은 모든 원격 플로우에 걸쳐 런타임에 적용되어 보안 및 플랫폼 팀에 에이전트 네트워크 이그레스에 대한 일관된 거버넌스 계층을 제공합니다.

## 규모 및 배포 {#scale-and-deployments}

### PostgreSQL 17 최소 요구 사항 {#postgresql-17-minimum-requirement}

<!-- categories: Omnibus Package -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../administration/package_information/postgresql_versions.md) , [관련 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9792)

{{< /details >}}

이제 지원되는 최소 PostgreSQL 버전은 버전 17입니다. 패키지된 PostgreSQL 16을 사용하는 경우 GitLab 19.0을 설치하기 전에 [패키지된 PostgreSQL 서버를 업그레이드](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)하세요.

### Ubuntu 20.04에 대한 Linux 패키지 지원 중단 {#linux-package-support-for-ubuntu-2004-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../install/package/_index.md#supported-platforms) , [관련 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)

{{< /details >}}

Ubuntu 20.04는 2025년 5월에 표준 지원 종료에 도달했습니다. GitLab 19.0부터는 Ubuntu 20.04에 대한 Linux 패키지가 더 이상 제공되지 않습니다. GitLab 18.11은 이 배포판에 대한 패키지가 포함된 마지막 릴리스입니다. GitLab 19.0으로 업그레이드하기 전에 Ubuntu 22.04 또는 다른 [지원되는 운영 체제](../../install/package/_index.md#supported-platforms)로 마이그레이션하세요.

### Redis 6 지원 제거됨 {#redis-6-support-removed}

<!-- categories: Omnibus Package -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../install/requirements.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839)

{{< /details >}}

Redis 6 지원은 GitLab 19.0에서 제거됩니다. 외부 Redis 6 배포를 사용하는 경우 업그레이드하기 전에 Redis 7.2 또는 Valkey 7.2로 마이그레이션하세요. Linux 패키지에 포함된 번들 Redis는 GitLab 16.2부터 Redis 7을 사용했으며 영향을 받지 않습니다.

### Linux 패키지에서 Mattermost 제거됨 {#mattermost-removed-from-the-linux-package}

<!-- categories: Omnibus Package -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590798)

{{< /details >}}

번들 Mattermost는 GitLab 19.0의 Linux 패키지에서 제거됩니다. 현재 번들 Mattermost를 사용하는 경우 마이그레이션 지침에 대해 [Linux 패키지에서 Mattermost Standalone으로 마이그레이션](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)을 참조하세요. 번들 Mattermost를 사용하지 않는 고객은 영향을 받지 않습니다.

### SUSE 배포판에 대한 Linux 패키지 지원 중단됨 {#linux-package-support-for-suse-distributions-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../install/docker/installation.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590801)

{{< /details >}}

SUSE 배포판에 대한 Linux 패키지 지원은 GitLab 19.0에서 종료되며, openSUSE Leap 15.6, SUSE Linux Enterprise Server 12.5 및 SUSE Linux Enterprise Server 15.6에 영향을 줍니다. GitLab 18.11은 이러한 배포판에 대한 Linux 패키지가 포함된 마지막 버전입니다. SUSE 배포판을 계속 사용하려면 [GitLab의 Docker 배포](../../install/docker/installation.md)로 마이그레이션하세요.

### Linux 패키지 및 GitLab Helm 차트에서 Spamcheck 제거됨 {#spamcheck-removed-from-linux-package-and-gitlab-helm-chart}

<!-- categories: Omnibus Package, Cloud Native Installation -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](../../administration/reporting/spamcheck.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590796)

{{< /details >}}

[Spamcheck](../../administration/reporting/spamcheck.md)은 GitLab 19.0의 Linux 패키지 및 GitLab Helm 차트에서 제거됩니다. 현재 Spamcheck을 사용하지 않는 고객은 영향을 받지 않습니다. 번들 Spamcheck을 사용하는 경우 [Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)를 사용하여 별도로 배포할 수 있습니다. 데이터 마이그레이션이 필요하지 않습니다.

### NGINX Ingress가 Envoy Gateway를 사용한 Gateway API로 대체됨 {#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](https://docs.gitlab.com/charts/) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590800)

{{< /details >}}

Gateway API와 Envoy Gateway는 GitLab 19.0의 GitLab Helm 차트에서 기본 네트워킹 구성이 되며 2026년 3월에 수명이 끝난 NGINX Ingress를 대체합니다. Envoy Gateway로의 마이그레이션이 즉시 불가능한 경우 번들 NGINX Ingress를 명시적으로 다시 활성화할 수 있으며, GitLab 20.0에서 계획된 제거까지 계속 사용할 수 있습니다. 이 변경은 Linux 패키지에서 사용되는 NGINX 또는 외부 관리 Ingress 또는 Gateway API 컨트롤러를 사용하는 Helm 차트 인스턴스에는 영향을 주지 않습니다.

### GitLab Helm 차트에서 번들 PostgreSQL, Redis 및 MinIO 제거됨 {#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 링크:  [설명서](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/590797)

{{< /details >}}

번들 Bitnami PostgreSQL, Bitnami Redis 및 MinIO 차트는 GitLab 19.0의 GitLab Helm 차트 및 GitLab Operator에서 제거되며 대체품이 없습니다. 이 구성 요소는 개념 증명 및 테스트 환경에만 사용되도록 의도되었으며 프로덕션 사용은 권장되지 않습니다. 이러한 번들 서비스 중 하나를 사용하는 인스턴스를 실행 중인 경우 GitLab 19.0으로 업그레이드하기 전에 [마이그레이션 가이드](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)를 따라 외부 서비스를 구성하세요.

### 대규모 그룹을 위한 안정적인 SCIM 사용자 프로비저닝 해제 {#reliable-scim-user-deprovisioning-for-large-groups}

<!-- categories: User Management -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com
- 링크:  [설명서](../../development/internal_api/_index.md#group-scim-api) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/521324)

{{< /details >}}

SCIM을 통해 많은 수의 사용자를 관리하는 조직의 경우 그룹 구성원 프로비저닝 해제 시 시간 초과 및 `500` 오류가 발생할 수 있습니다. SCIM `DELETE` 및 `PATCH` 요청은 이제 즉시 성공 응답을 반환합니다. 멤버십 제거는 비동기적으로 처리되므로 ID 제공자 및 SCIM 클라이언트는 일관된 성공 응답을 받습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 취약한 종속성에 대한 자동 수정(실험) {#auto-remediation-for-vulnerable-dependencies-experiment}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com
- 링크:  [설명서](../../user/application_security/remediate/auto_remediation.md) , [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/17403)

{{< /details >}}

종속성에 대한 자동 수정은 이제 GitLab 19.0에서 실험으로 사용 가능합니다. 종속성 검사에서 알려진 수정이 있는 취약한 Ruby 종속성을 감지하면 GitLab은 자동으로 머지 리퀘스트를 열어 사람의 개입 없이 안전한 버전으로 업데이트합니다. 실험에서는 Ruby 프로젝트만 지원됩니다.

각 파이프라인 후 GitLab은 사용 가능한 패치 또는 부 버전 업그레이드가 있는 최고 심각도 취약성을 식별합니다. GitLab은 매니페스트 파일 변경을 생성하고 서비스 계정을 통해 머지 리퀘스트를 엽니다. 머지 리퀘스트는 프로젝트의 표준 검토 및 승인 워크플로우를 거칩니다.

실험 중에 프로젝트당 최대 3개의 자동 수정 머지 리퀘스트를 한 번에 열 수 있습니다.

피드백을 공유하거나 실험을 시도하도록 요청하려면 [에픽 600511](https://gitlab.com/gitlab-org/gitlab/-/work_items/600511)에 댓글을 남기세요. 프로젝트에서 실험을 활성화하려면 GitLab 팀 구성원이 프로젝트에 대해 `dependency_management_auto_remediation` 기능 플래그를 활성화해야 합니다.

### 보안 구성 프로파일의 종속성 검사 {#dependency-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../user/application_security/configuration/security_configuration_profiles.md) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/19952)

{{< /details >}}

GitLab 18.11은 SAST 및 시크릿 검색에 대한 보안 구성 프로파일을 도입했습니다. 이제 종속성 검사도 **Dependency Scanning - Default** 프로파일과 함께 사용할 수 있습니다. 이 프로파일은 단일 CI/CD 구성 파일을 편집하지 않고도 모든 프로젝트에 표준화된 SCA 범위를 적용할 수 있는 통합 제어 표면을 제공합니다.

프로파일은 두 가지 검사 트리거를 활성화합니다:

- **머지 리퀘스트 파이프라인**:  열려 있는 머지 리퀘스트가 있는 브랜치로 새로운 커밋이 푸시될 때마다 자동으로 종속성 검사 검사를 실행합니다. 결과에는 머지 리퀘스트에 의해 도입된 새로운 취약성만 포함됩니다.
- **브랜치 파이프라인 (기본값 만)**:  변경 사항이 기본 브랜치로 병합되거나 푸시될 때 자동으로 실행되어 기본 브랜치의 종속성 상태를 완전히 볼 수 있습니다.

### Gradle SBOM 검사를 위한 종속성 해결 {#dependency-resolution-for-gradle-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/590734)

{{< /details >}}

SBOM을 사용한 GitLab 종속성 검사는 이제 Gradle 프로젝트에 대한 종속성 그래프(`gradle.graph.txt`)를 자동으로 생성합니다. 이전에 Gradle 종속성 검사에서는 빌드의 일부로 종속성 그래프를 수동으로 생성해야 했습니다. 이제 그래프 파일을 사용할 수 없으면 분석기가 자동으로 하나를 생성하여 Gradle을 사용하는 Java 및 Kotlin 프로젝트에 대한 이 수동 단계를 제거합니다.

### CI/CD 입력에 대한 향상된 배열 지원 {#improved-array-support-for-cicd-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../ci/inputs/_index.md#access-individual-array-elements) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CD 입력은 이제 배열로 작업하기 위한 향상된 지원이 있습니다. 배열 인덱스 연산자 `[]`를 사용하여 배열 입력 내의 특정 요소에 액세스합니다. 이 개선 사항은 파이프라인 구성에서 더 유연하고 강력한 입력 보간 기능을 제공하여 추가 처리 단계 없이 개별 배열 항목을 직접 참조할 수 있도록 합니다.

### 파이프라인 입력을 위해 여러 값 선택 {#select-multiple-values-for-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../ci/inputs/_index.md#array-inputs-with-options) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

이전에는 UI에서 입력 옵션을 선택할 때 단일 값만 선택할 수 있었으므로 더 복잡한 옵션이 있는 파이프라인의 유연성이 제한되었습니다.

이제 UI에서 입력을 사용하여 파이프라인을 실행할 때 드롭다운 목록에서 여러 값을 선택할 수 있으며 선택된 값이 배열로 결합됩니다(예: `["option1","option2"]`). 이렇게 하면 여러 인스턴스에서 서비스를 다시 시작하고, 여러 Docker 이미지를 빌드하고, 여러 태그 조합으로 테스트를 실행하거나, 단일 파이프라인 실행에서 여러 대상에 걸쳐 작업을 수행하기가 쉬워집니다.

### 상세한 CI/CD 카탈로그 구성 요소 사용량 분석 {#detailed-cicd-catalog-component-usage-analytics}

<!-- categories: Component Catalog -->

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../ci/components/_index.md#view-component-usage-details) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460)

{{< /details >}}

GitLab 카탈로그에서 CI/CD 구성 요소를 관리할 때 사용량 세부 정보는 업그레이드 관리, 규정 준수 적용 및 주요 변경 사항 전달에 매우 중요합니다. 프로젝트에서 구성 요소를 사용하고 사용 중인 버전을 알아야 합니다. 이전에는 이 정보를 사용할 수 없어 올바른 유지관리자에게 알리고, 안전하게 중단을 계획하고, 프로젝트가 최신 보안 패치로 최신 상태를 유지하도록 하기가 어려웠습니다.

카탈로그 리소스 페이지의 구성 요소 사용량 세부 정보 보기는 이제 각 구성 요소를 사용하는 정확한 프로젝트, 실행 중인 버전 및 최신 버전 또는 오래된 버전 여부를 표시합니다. 이전 버전을 사용하는 프로젝트가 맨 위에 표시되므로 아웃리치의 우선 순위를 지정하고, 보안 수정 사항의 채택을 주도하고, 조직 전체에서 순조로운 업그레이드 경로를 보장할 수 있습니다.

### 머지 트레인을 위한 병렬 파이프라인 제한 구성 {#configure-parallel-pipeline-limits-for-merge-trains}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../administration/instance_limits.md#merge-train-parallel-pipeline-limit) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/374188)

{{< /details >}}

이전 버전의 GitLab에서는 머지 트레인의 최대 20개 병렬 파이프라인을 변경할 수 없었으므로 러너를 과부하시키거나 머지 트레인을 완전히 건너뛰어야 했습니다. 이제 머지 트레인당 병렬 파이프라인 제한을 구성하여 러너 부하와 머지 처리량을 균형 있게 조정할 수 있습니다. 프로젝트당 또는 인스턴스 전체에서 제한을 설정할 수 있습니다. 제한을 1로 설정하면 각 머지 리퀘스트가 한 번에 하나씩 깨끗한 대상 브랜치에 대해 실행됩니다.

이 커뮤니티 기여에 대해 [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85)에게 감사합니다.

### 기본 머지 리퀘스트 제목 사용자 지정 {#customize-default-merge-request-titles}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 링크:  [설명서](../../user/project/merge_requests/title_templates.md) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/16080)

{{< /details >}}

이전 버전의 GitLab에서는 새로운 머지 리퀘스트의 기본 제목이 소스 브랜치 또는 첫 커밋에서 제공되었으며 프로젝트 전체에서 일관된 명명 규칙을 적용할 수 없었습니다.

이제 프로젝트당 기본 머지 리퀘스트 제목 템플릿을 구성할 수 있습니다. 템플릿은 소스 브랜치, 대상 브랜치, 첫 커밋 제목, 연결된 이슈 ID, 이슈 제목 및 소스 브랜치 이름의 사람이 읽을 수 있는 버전에 대한 변수를 지원합니다. 예를 들어 템플릿 `Resolve %{issue_id} "%{issue_title}"`은 `Resolve 123 "Fix login bug"`과 같은 제목을 생성합니다. 머지 리퀘스트를 생성하기 전에 제목을 계속 편집할 수 있습니다.

### HMAC 서명 토큰으로 웹훅 보안 {#secure-webhooks-with-hmac-signing-tokens}

<!-- categories: Importers -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../user/project/integrations/webhooks.md#signing-tokens) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

기존 `X-Gitlab-Token` 헤더는 일반 텍스트로 정적 시크릿을 보내므로 웹훅이 차단 및 재생 공격에 취약합니다.

이제 모든 웹훅에 서명 토큰을 추가할 수 있습니다. GitLab은 서명 토큰을 사용하여 다음에 대한 HMAC-SHA256 서명을 계산합니다:

- 고유한 웹훅 ID입니다.
- 요청 타임스탬프입니다.
- 웹훅 페이로드입니다.

GitLab은 `webhook-signature` 헤더에 `webhook-id` 및 `webhook-timestamp` 헤더와 함께 결과를 전송하여 [Standard Webhooks](https://www.standardwebhooks.com/) 사양을 따릅니다.

서명을 다시 계산하여 요청이 GitLab에서 정말로 온 것이고 페이로드가 수정되지 않았는지 확인할 수 있습니다. 타임스탬프도 검증하면 재생된 요청을 거부할 수 있습니다.

커뮤니티 기여를 위해 [Van Anderson](https://gitlab.com/van.m.anderson) 과 [Norman Debald](https://gitlab.com/Modjo85)에게 감사합니다!

### CI/CD 작업 토큰을 사용한 교차 프로젝트 푸시 {#cross-project-pushes-using-cicd-job-tokens}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](../../ci/jobs/ci_job_token.md#allow-cross-project-git-push-requests-from-allowlisted-projects) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/479907)

{{< /details >}}

이전 버전의 GitLab에서는 CI/CD 작업 토큰(`CI_JOB_TOKEN`)을 사용하여 파이프라인이 실행되는 동일한 리포지토리로만 푸시할 수 있었습니다. 교차 프로젝트 푸시에는 개인 액세스 토큰 또는 배포 토큰이 필요했습니다.

이제 다음 경우에 작업 토큰을 사용하여 다른 프로젝트로 푸시할 수 있습니다:

1. 대상 프로젝트가 옵트인합니다.
1. 파이프라인을 시작하는 사용자는 대상 프로젝트에서 최소 Developer 역할을 가지고 있습니다.

이 기능은 `allow_push_to_allowlisted_projects` 기능 플래그 뒤에 있으며 GitLab 19.0에서 기본적으로 비활성화되어 있습니다. 관리자에게 이를 활성화하도록 요청하세요.

### Mermaid 다이어그램 렌더링이 버전 11로 업그레이드됨 {#mermaid-diagram-rendering-upgraded-to-version-11}

<!-- categories: Markdown -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크:  [설명서](../../user/markdown.md#mermaid) , [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/491514)

{{< /details >}}

GitLab은 이제 Markdown에서 다이어그램을 렌더링하기 위해 [Mermaid 버전 11](../../user/markdown.md#mermaid)을 사용합니다.

이전에는 GitLab이 Mermaid 버전 10을 지원했습니다. 이 업그레이드를 통해 Mermaid 11에서 도입된 모든 새로운 다이어그램 유형, 구문 개선 및 버그 수정에 액세스할 수 있으며, 순서도 및 시퀀스 다이어그램 등의 렌더링이 향상됩니다.

### 머지 리퀘스트 검토를 위한 빠른 Diff(베타) {#rapid-diffs-for-merge-request-reviews-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 링크:  [설명서](../../user/project/merge_requests/changes.md#rapid-diffs) , [관련 이슈](https://gitlab.com/groups/gitlab-org/-/work_items/18457)

{{< /details >}}

이전 버전의 GitLab에서는 검토를 시작하기 전에 **변경사항** 탭이 모든 파일을 로드할 때까지 기다려야 했으므로 큰 검토가 느려졌습니다.

이제 Rapid Diffs를 사용하여 더 빠른 초기 로드, 더 부드러운 스크롤 및 더 반응적인 파일 상호 작용으로 머지 리퀘스트를 검토할 수 있습니다. Rapid Diffs는 커밋 페이지를 구동하는 동일한 기술을 사용합니다.

Rapid Diffs는 베타 단계입니다. 클래식 diff 환경의 일부 기능은 아직 사용할 수 없습니다. 언제든지 다시 전환할 수 있습니다.

[개요 비디오 보기](https://www.youtube.com/watch?v=S-IzJnhoH6U) 를 하고 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/596236)에서 경험을 공유하세요.

### GitLab Runner 19.0 {#gitlab-runner-190}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크:  [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab Runner 19.0도 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [러너 계측: 기능 협상, OTLP 내보내기 클라이언트 및 첫 `job_execution` 스팬](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [러너 구성에 구성 가능한 준비 단계 타임아웃 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

#### 버그 수정 {#bug-fixes}

- [`FF_SCRIPTS_TO_STEPS` 기능 플래그 구현에 대한 포괄적인 수정](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [S3 캐시 다운로드 시 `SignatureDoesNotMatch` 오류](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [GitLab Runner가 S3 캐시를 사용하여 AWS에서 실행할 때 런타임 오류](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [GitLab Runner 18.9.0 이상에서 `amd64`, `arm64`, `arm` 및 `armhf`에 대한 손상된 RPM S3 다운로드 링크](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [음수 종료 코드가 Windows에서 잘못 보고됨](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [부정확한 Kubernetes 실행기 서비스 컨테이너 명명 설명서](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md)에 있습니다.
