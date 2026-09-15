---
stage: Release Notes
group: Monthly Release
date: 2025-10-16
title: "GitLab 18.5 릴리스 정보"
description: "GitLab 18.5가 GitLab Duo Planner, 특화된 에이전트 및 Product Manager 팀 멤버(베타)와 함께 출시됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 10월 16일에 GitLab 18.5가 다음 기능과 함께 출시되었습니다.

또한 이번 달의 주목할 만한 기여자를 포함하여 모든 기여자에게 감사드립니다.

## 이번 달 주목할 만한 기여자: Jose Gabriel Companioni Benitez {#this-months-notable-contributor-jose-gabriel-companioni-benitez}

그의 블로그 게시물 ["How GitLab Can Boost Your Professional Career"](https://compacompila.com/posts/gitlab-open-source-community/)에서 Jose는 다음과 같이 말합니다: "저에게는 전문적 개발 관점에서 GitLab이 제공하는 가장 큰 장점은 오픈 소스라는 점입니다." 그는 "GitLab에게는 누구나 기여할 수 있다는 것이 중요하며, 이러한 이유로 기여자 온보딩 프로세스를 매우 진지하게 받아들이고 있습니다."라고 덧붙였습니다.

Jose가 9월의 첫 번째 기여자에서 10월의 주목할 만한 기여자로 성장한 경험은 GitLab 협업 커뮤니티의 힘을 보여줍니다. 커뮤니티 오피스 아워, Discord 토론, 페어링 세션에 적극적으로 참여함으로써 Jose는 [문서](https://gitlab.com/gitlab-org/cli/-/merge_requests/2392), [코드](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2690), 그리고 커뮤니티 지원을 포함한 다양한 기여를 통해 레벨 3 기여자로 빠르게 성장할 수 있는 지원 환경을 찾았습니다.

GitLab 커뮤니티는 기여자들이 서로를 지원하고 함께 성장할 수 있는 환영하는 공간을 제공합니다. 오픈 소스 여정을 시작하려는 분이든 기술을 심화하려는 분이든, 저희 커뮤니티는 여러분의 성공을 돕기 위해 여기 있습니다.

기여에 대해 자세히 알아보려면 [GitLab Contributor Platform](https://contributors.gitlab.com/)을 참조하세요.

Jose님, 귀중한 기여를 해주셔서 감사합니다! 🚀

## 주요 기능 {#primary-features}

### GitLab Duo Planner, 특화된 에이전트 및 Product Manager 팀 멤버(베타) {#gitlab-duo-planner-a-specialized-agent-and-product-manager-team-member-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

GitLab Duo Planner와 협력하세요. GitLab Duo Planner는 GitLab 내에서 제품 관리자를 직접 지원하도록 구축된 GitLab Duo 에이전트입니다. 수동으로 업데이트를 추적하거나 작업의 우선순위를 정하거나 계획 데이터를 요약하는 대신, GitLab Duo Planner는 백로그를 분석하고 RICE 또는 MoSCoW와 같은 프레임워크를 적용하며 진정으로 주의가 필요한 것을 드러내는 데 도움을 줍니다. 당신의 계획 워크플로를 이해하고 더 나은 빠른 결정을 내릴 수 있도록 당신과 함께 일하는 적극적인 팀원을 가지고 있는 것 같습니다. 이 기능은 현재 베타 상태입니다. [이슈 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)에서 피드백을 제공해 주세요.

### GitLab Security Analyst Agent for Duo Agent Catalog(베타) {#gitlab-security-analyst-agent-for-duo-agent-catalog-beta}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/agents/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Duo Agent Platform의 에이전트는 GitLab 내에서 작업을 수행하고 복잡한 질문에 답하는 데 사용할 수 있습니다. 사용자는 머지 리퀘스트 생성이나 코드 검토와 같은 특정 작업을 수행하기 위해 사용자 지정 에이전트를 만들거나 AI 카탈로그를 사용하여 GitLab 에이전트를 검색할 수 있습니다.

GitLab 18.5에서는 AI 카탈로그에서 사용할 수 있는 베타 기능으로 GitLab Security Analyst 에이전트를 출시합니다. 특정 프로젝트에서 GitLab Security Analyst 에이전트를 사용하려면 GitLab Duo Agentic Chat에서 에이전트를 선택하고 활성화하세요. 이 에이전트는 다음 작업을 수행할 수 있습니다:

- 주어진 프로젝트의 모든 취약성을 나열합니다.
- CVE 데이터 및 EPSS 점수를 포함한 자세한 취약성 정보를 가져옵니다.
- 취약성을 확인하고 해제합니다.
- 취약성 심각도 수준을 업데이트합니다.
- 취약성 상태를 `detected`로 되돌립니다.
- 취약성 이슈를 생성하거나 취약성을 기존 이슈에 연결합니다.

GitLab Security Analyst 에이전트를 사용하면 사용자는 AI 기반 자동화 및 지능형 분석을 통해 번거로운 보안 워크플로를 수행하여 엔지니어가 실제 위협에 집중하고 GitLab Security Analyst 에이전트가 반복적인 평가 및 문서화를 처리할 수 있습니다. GitLab Duo Chat을 사용하는 GitLab Security Analyst 에이전트는 GitLab Duo 추가 기능이 있는 Ultimate 고객만 사용할 수 있습니다.

이 기능은 베타 상태이며 [이슈 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)에서 피드백을 환영합니다.

### Maven 가상 레지스트리는 이제 베타로 사용 가능 {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/packages/virtual_registry/maven/_index.md#manage-virtual-registries) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

GitLab 18.5는 Maven 가상 레지스트리 관리를 위한 포괄적인 웹 기반 인터페이스를 제공합니다. 이전에는 플랫폼 엔지니어가 API 호출을 통해서만 가상 레지스트리를 구성하고 관리할 수 있었으므로 일상적인 유지 관리 작업이 번거롭고 전문 지식이 필요했습니다.

이 웹 기반 접근 방식은 플랫폼 엔지니어링 팀의 운영 오버헤드를 크게 줄입니다. 오래된 캐시 항목 지우기, 성능 최적화를 위한 업스트림 재정렬, 연결 테스트와 같은 일반적인 작업은 이제 클릭 한 번으로 수행됩니다. 개발 팀은 종속성 구성에 대한 가시성을 향상시켜 빌드 성능 및 보안 정책에 대해 더 많은 정보를 얻은 논의를 할 수 있습니다.

Maven 가상 레지스트리는 GitLab Premium 및 Ultimate 고객을 위해 베타 상태로 남아 있습니다. 현재 베타 제한 사항에는 최상위 그룹당 최대 20개의 가상 레지스트리와 가상 레지스트리당 20개의 업스트림이 포함됩니다.

최종 릴리스를 형성하는 데 도움이 되도록 엔터프라이즈 고객이 Maven 가상 레지스트리 베타 프로그램에 참여하도록 초대합니다. [이슈 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)에서 피드백 및 제안을 공유하는 것을 고려해 주세요.

### 새 개인 홈페이지에서 중단한 부분부터 시작하기 {#pick-up-where-you-left-off-on-the-new-personal-homepage}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../tutorials/personal_homepage/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16657)

{{< /details >}}

이제 모든 중요한 GitLab 활동을 한 곳에 통합하는 새로운 개인 홈페이지에 액세스하여 중단한 부분부터 쉽게 시작할 수 있습니다. 홈페이지는 할 일 항목, 할당된 이슈, 머지 리퀘스트, 검토 요청 및 최근에 본 콘텐츠를 모아 GitLab의 넓은 표면을 탐색하고 가장 중요한 것에 집중하는 데 도움을 줍니다.

### GPT-5는 이제 GitLab Duo Agentic Chat의 모델 옵션으로 사용 가능 {#gpt-5-now-available-as-a-model-option-for-gitlab-duo-agentic-chat}

<!-- categories: Model Personalization -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/agentic_chat.md#select-a-model) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19124)

{{< /details >}}

OpenAI GPT-5는 이제 GitLab Duo Agent Platform의 모델을 선택할 때 GitLab AI Vendor 모델로 사용할 수 있습니다. GitLab.com의 최상위 그룹 소유자 및 Self-Managed와 Dedicated의 인스턴스 관리자로 구성하면 최종 사용자가 GitLab Duo 기능과 함께 GPT-5를 사용하도록 선택할 수 있습니다. 최상위 소유자와 관리자는 네임스페이스 또는 인스턴스 설정을 통해 조직 전체 모델 기본 설정을 계속 설정하거나 최종 사용자가 사용 가능한 모든 GitLab AI Vendor 모델 중에서 선택할 수 있도록 허용할 수 있습니다.

GPT-5 사용을 시작하려면 GitLab Duo Chat의 모델 드롭다운 목록에서 선호하는 모델을 선택하세요.

### 인스턴스 전체 규정 준수 및 보안 정책 관리 {#instance-wide-compliance-and-security-policy-management}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../security/compliance_security_policy_management.md)

{{< /details >}}

엔터프라이즈 사용자는 여러 최상위 그룹에서 [규정 준수 프레임워크](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) 및 [보안 정책](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)을 관리하기를 원합니다. 이는 인스턴스의 모든 그룹이 다음과 같은 경우에 종종 발생합니다:

- 동일한 규정 준수 프레임워크를 공유합니다. 예를 들어 그룹의 모든 프로젝트가 ISO 27001 표준을 준수해야 하는 경우입니다.
- 유사한 보안 정책을 적용합니다. 예를 들어, 모든 그룹이 동일한 파이프라인 실행 정책을 공유할 때입니다.

GitLab 18.5를 사용하면 GitLab Self-Managed 및 Dedicated 인스턴스에 대해 인스턴스에서 보안 정책 및 규정 준수 프레임워크의 관리를 중앙 집중화하는 규정 준수 및 보안 정책 그룹을 도입합니다. 이 릴리스에서는 이제 단일 최상위 그룹에서 규정 준수 프레임워크 및 보안 정책을 생성, 구성 및 할당하고 인스턴스 전체의 다른 모든 최상위 그룹에 적용할 수 있습니다.

규정 준수 및 보안 정책 그룹을 사용하면 규정 준수 프레임워크 및 보안 정책을 관리하고 편집할 수 있는 단일 정보 소스를 갖게 됩니다. 그룹 내의 보안 및 규정 준수 사용자는 인스턴스 전체의 모든 프로젝트에 규정 준수 프레임워크 및 보안 정책을 적용할 수 있습니다.

규정 준수 및 보안 정책 그룹을 통해 인스턴스 전체에서 규정 준수 및 보안 요구사항을 더 쉽게 관리하고 적용할 수 있습니다. 다만, 그룹은 그룹 내에서 발생할 수 있는 특정 상황이나 워크플로를 해결하기 위해 자체 규정 준수 프레임워크 및 보안 정책을 만들 수 있는 능력을 유지합니다.

이 기능은 GitLab Self-Managed 및 Dedicated 고객을 위한 것입니다. GitLab.com 고객은 보안 정책 프로젝트를 사용하여 단일 최상위 그룹 또는 네임스페이스 내에서 프레임워크 및 정책을 중앙에서 관리할 수 있습니다.

[규정 준수 프레임워크](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) 및 [보안 정책](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)에 대한 규정 준수 및 보안 정책 그룹에 대해 자세히 알아보세요.

### DAST 인증 스크립트 {#dast-authentication-scripts}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dast/browser/configuration/authentication_scripts.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17018)

{{< /details >}}

이제 CI/CD 구성에 스크립트를 추가하여 DAST 인증 워크플로를 자동화할 수 있습니다. 인증 스크립트는 시간 기반, 일회용 비밀번호(OTP MFA) 지원을 포함한 복잡한 인증 흐름을 자동화합니다.

이 향상 기능은 팀이 철저한 자동화된 보안 검사를 수행하면서 중요한 보안 제어를 유지하는 데 도움이 됩니다. 실제 인증 시나리오를 지원함으로써 스크립트는 마찰을 줄이고 프로덕션 소프트웨어의 정확한 보안 평가를 보장합니다.

## 에이전틱 코어 {#agentic-core}

### CLI 에이전트의 추가 트리거 {#additional-triggers-for-cli-agents}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/duo_agent_platform/triggers/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)

{{< /details >}}

이제 추가 이벤트를 사용하여 CLI 에이전트를 트리거하여 프로젝트 전체에서 에이전트가 작용하는 위치와 시기에 대해 더 많은 유연성과 제어를 할 수 있습니다. 기존 **mention** 트리거와 함께 다음을 사용할 수 있습니다:

- **할당**: 머지 리퀘스트 또는 이슈가 할당될 때 에이전트를 트리거합니다.
- **검토자 할당**: 검토자가 머지 리퀘스트에 추가될 때 에이전트를 트리거합니다.

### GitLab Duo Agent Platform for GitLab Duo Self-Hosted는 이제 베타 {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-now-in-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)

{{< /details >}}

GitLab Duo Agent Platform은 이제 GitLab Duo Self-Hosted의 베타 상태입니다. 이 기능은 모든 Self-Managed GitLab Duo Enterprise 고객이 사용할 수 있습니다. AWS Bedrock 또는 Azure OpenAI를 사용하는 Self-Managed 인스턴스 관리자는 GitLab Duo Agent Platform과 함께 사용할 Anthropic Claude 또는 OpenAI GPT 모델을 구성할 수 있습니다. Self-Hosted 관리자는 또한 구성할 수 있습니다

[호환되는 모델](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)

GitLab Duo Agent Platform과 함께 사용합니다.

### Codestral은 이제 GitLab Duo Chat(Classic)에 지원됨 {#codestral-now-supported-for-gitlab-duo-chat-classic}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/550266)

{{< /details >}}

이제 Mistral Codestral을

GitLab Duo Self-Hosted

에서 사용할 수 있습니다. 이 모델은 GitLab Self-Managed 인스턴스의 GitLab Duo Self-Hosted 고객을 위해 지원됩니다.

### GPT OSS 모델은 GitLab Duo Self-Hosted를 사용하는 GitLab Duo Agent Platform과 호환 가능 {#gpt-oss-models-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19348)

{{< /details >}}

이제 GitLab Duo Self-Hosted와 함께 GitLab Duo Agent Platform에서 GPT OSS 모델을 사용할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### 향상된 **운영자** 영역 그룹 목록 {#enhanced-admin-area-groups-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../administration/admin_area.md#administering-groups) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17783)

{{< /details >}}

**운영자** 영역 그룹 목록을 업그레이드하여 GitLab 관리자에게 더 일관된 환경을 제공합니다:

- 지연된 삭제 보호: 그룹 삭제는 이제 GitLab 전체에서 사용되는 동일한 안전한 삭제 흐름을 따르므로 실수로 인한 데이터 손실을 방지합니다.
- 더 빠른 상호작용: 페이지를 다시 로드하지 않고 그룹을 필터링, 정렬 및 페이지 매김할 수 있어 더 빠른 응답 속도를 경험할 수 있습니다.
- 일관된 인터페이스: 그룹 목록은 이제 GitLab 전체의 다른 그룹 목록의 모양과 동작과 일치합니다.

이 업데이트는 관리자 환경을 GitLab 디자인 표준에 맞게 조정하고 데이터를 보호하기 위한 중요한 보안 기능을 추가합니다. 향후 그룹 관리 개선 사항은 플랫폼 전체의 모든 그룹 목록에 자동으로 나타납니다.

### 그룹의 업데이트된 탐색 환경 {#updated-navigation-experience-for-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/group/_index.md#view-a-group) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13790)

{{< /details >}}

그룹 개요 목록을 변경하여 GitLab 전체에서 더 일관되고 효율적인 환경을 제공합니다. 이러한 개선 사항을 통해 그룹 및 프로젝트를 더 쉽게 탐색하고 한 눈에 더 많은 가치 있는 정보를 얻을 수 있습니다:

- 더 풍부한 프로젝트 정보: 프로젝트는 이제 별, 포크, 이슈, 머지 리퀘스트 및 관련 날짜를 표시하므로 한 눈에 완전한 활동 개요를 얻을 수 있습니다.
- 간소화된 작업: 작업 메뉴를 사용하여 개요에서 직접 그룹 및 프로젝트를 편집하거나 삭제합니다. 보관된 항목 및 삭제 대기 중인 항목은 **비활성** 탭에 나타납니다.
- 일관된 환경: 그룹 개요는 이제 GitLab 전체의 다른 그룹 및 프로젝트 목록의 모양과 동작과 일치하므로 더 직관적인 환경을 제공합니다.

이러한 개선 사항은 손끝에 있는 더 많은 정보와 작업으로 시간을 절약합니다. 이 업데이트는 또한 대량 편집 및 고급 필터링 옵션과 같은 향후 기능의 기초를 마련합니다.

### 그룹 및 프로젝트에 대한 개선된 비활성 항목 관리 {#improved-inactive-item-management-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/project/working_with_projects.md#view-inactive-projects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/526211)

{{< /details >}}

**비활성** 탭은 이제 GitLab 전체의 한 위치에 모든 비활성 항목을 일관되게 표시합니다. 여기에는 보관된 프로젝트, 삭제 대기 중인 프로젝트, 삭제 대기 중인 그룹이 포함됩니다. 이 탭은 그룹 개요 페이지뿐만 아니라 **귀하의 작업**, **탐색** 및 **운영자** 영역 전체의 그룹 및 프로젝트 목록에서 사용할 수 있습니다. 적절한 권한이 있는 모든 사용자는 비활성 항목을 볼 수 있지만 그룹 소유자 및 프로젝트 소유자와 관리자만 추가 작업을 수행할 수 있습니다. 이 업데이트의 일부로 Projects 및 Groups REST API와 GraphQL API에서 새로운 `active` 매개변수를 사용할 수 있습니다.

비활성 콘텐츠 관리는 GitLab 인스턴스를 유지 관리하는 데 중요한 부분입니다. 이 업데이트를 통해 보관되었거나 삭제 대기 중인 콘텐츠를 더 쉽게 찾고 복구할 수 있으므로 GitLab 리소스를 더 잘 제어하고 귀중한 작업을 실수로 잃을 위험을 줄일 수 있습니다. 활성 콘텐츠와 비활성 콘텐츠의 명확한 분리는 GitLab의 모든 영역에서 그룹 및 프로젝트를 탐색할 때도 더 집중된 검색 환경을 제공합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### GitLab Duo Agentic Chat의 새로운 취약성 관리 기능 {#new-vulnerability-management-features-in-gitlab-duo-agentic-chat}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Core, Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/agentic_chat.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19639)

{{< /details >}}

GitLab Duo Agentic Chat는 GitLab Duo Chat의 향상된 버전입니다. GitLab 프로젝트 전체의 여러 소스에서 정보를 검색, 검색 및 결합하여 더 철저하고 관련성 있는 답변을 제공합니다. 사용 사례 중 일부에는 프로젝트를 검색하고, 파일을 읽고 나열하며, GitLab Duo Chat에 제공된 프롬프트를 기반으로 자율적으로 파일을 생성하고 변경할 수 있는 기능이 포함됩니다.

GitLab 18.5에서 Agentic Chat 사용 사례는 보안 스캐너에서 취약성 관리를 포함하도록 확장됩니다. 취약성 관리 도구를 Agentic Chat에 추가함으로써 AI 기반 자동화 및 지능형 분석을 통해 번거로운 보안 워크플로를 변환하여 보안 전문가가 자연어 명령을 통해 취약성을 효율적으로 분류, 관리 및 수정할 수 있습니다. 이는 취약성 대시보드를 통한 수동 클릭의 시간을 제거하고 이전에 사용자 정의 스크립트 또는 번거로운 수동 작업이 필요했던 복잡한 대량 작업을 간소화합니다.

GitLab Duo Chat에 추가된 새로운 취약성 관리 도구를 사용하면 GitLab Duo를 가진 Ultimate 사용자는 다음을 수행할 수 있습니다:

- 주어진 프로젝트의 모든 취약성을 나열합니다.
- CVE 데이터 및 EPSS 점수를 포함한 자세한 취약성 정보를 가져옵니다.
- 취약성을 확인하고 해제합니다.
- 취약성 심각도 수준을 업데이트합니다.
- 취약성 상태를 `detected`로 되돌립니다.
- 취약성 이슈를 생성하거나 취약성을 기존 이슈에 연결합니다.

이러한 도구는 보안 워크플로를 반응형 수동 분류에서 지능형 수정으로 변환하여 엔지니어가 실제 위협에 집중하고 AI가 반복적인 평가 및 문서화를 처리하도록 합니다. GitLab Duo Chat을 사용한 취약성 관리는 GitLab Duo 추가 기능이 있는 Ultimate 고객만 사용할 수 있습니다.

### Advanced SAST의 C/C++ 지원 {#cc-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/sast/advanced_sast_cpp.md)

{{< /details >}}

GitLab Advanced SAST에 C/C++의 베타 지원을 추가했습니다.

이 새로운 파일 간 교차 함수 검사 지원을 사용하려면 [C/C++ 지원을 활성화](../../user/application_security/sast/advanced_sast_cpp.md)하세요.

이 기능에 대한 피드백을 환영합니다. 질문, 의견이 있거나 팀과 협력하고 싶다면 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/575671)를 참조하세요.

### 시크릿 유효성 검사는 베타 상태 {#secret-validity-checks-is-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerabilities/validity_check.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16927)

{{< /details >}}

파이프라인 시크릿 검색은 프로젝트에서 암호 또는 API 키와 같은 노출된 자격 증명을 알려줍니다. 그러나 GitLab 18.5까지는 각 감지가 활성 토큰을 나타내는지 여부를 수동으로 확인해야 했습니다. 이로 인해 감지를 효과적으로 분류하기가 어렵고 시간이 많이 걸릴 수 있습니다.

이제 유효성 검사가 베타 상태이므로 활성화하여 감지된 GitLab 시크릿의 상태를 표시하세요. 활성 시크릿을 사용하여 정당한 활동을 사칭할 수 있으므로 가능한 한 빨리 회전해야 합니다. 작동 중인 유효성 검사를 보려면 [유효성 검사 재생 목록](https://www.youtube.com/playlist?list=PL05JrBw4t0Ko8uOgubcYqmTTMGs0zWQRt)을 참조하세요.

### 보안 푸시 보호 및 파이프라인 시크릿 검색에 대한 증가된 규칙 커버리지 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/secret_detection/detected_secrets.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/573973)

{{< /details >}}

GitLab 파이프라인 시크릿 검색에 새 규칙이 추가되었습니다. 기존 규칙 중 일부도 품질을 개선하고 거짓 양성을 줄이기 위해 업데이트되었습니다. 이러한 변경 사항은 시크릿 분석기의 [버전 7.15.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.15.0)에서 출시됩니다.

### Advanced SAST의 사용자 지정 가능한 감지 로직 {#customizable-detection-logic-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/sast/customize_rulesets.md)

{{< /details >}}

이제 GitLab Advanced SAST로 조직의 특정 보안 요구사항 및 코딩 패턴에 맞춘 사용자 지정 규칙 집합 보안 감지 규칙을 만들 수 있습니다. 이 기능을 통해 보안 팀은 미리 정의된 규칙 집합을 초과하는 사용자 지정 취약성 패턴을 정의할 수 있으므로 애플리케이션별 보안 이슈를 감지할 수 있습니다.

자세한 내용은 [규칙 집합 사용자 지정](../../user/application_security/sast/customize_rulesets.md)을 참조하세요.

### 머지 리퀘스트에서 Advanced SAST 차이 기반 검사 {#advanced-sast-diff-based-scanning-in-merge-requests}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/gitlab_advanced_sast.md#diff-based-scanning)

{{< /details >}}

이제 GitLab Advanced SAST로 머지 리퀘스트의 코드 변경만 분석하는 차이 기반 검사를 수행할 수 있으므로 전체 리포지토리 검사에 비해 검사 시간을 크게 줄일 수 있습니다. 전체 코드베이스가 아닌 Git 차이만 검사하면 팀이 속도를 희생하거나 머지 리퀘스트 프로세스에 마찰을 추가하지 않고도 개발 워크플로에 보안 테스트를 더 원활하게 통합할 수 있습니다.

이 성능 개선을 기본적으로 활성화하기 위해 작업 중입니다. 이는 [이슈 546359](https://gitlab.com/gitlab-org/gitlab/-/issues/546359)에서 추적됩니다.

### 외부 제어 상태에 대한 제어 요청 {#control-requests-for-external-control-statuses}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/compliance/compliance_frameworks/_index.md#ping-enabled-setting) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

외부 제어는 GitLab에서 규정 준수 프레임워크를 생성할 때 요구사항에 첨부될 수 있습니다.

기본적으로 GitLab은 규정 준수 검사 중에 12시간마다 자동으로 외부 시스템에서 외부 제어의 상태를 요청하여 제어 상태를 '보류 중'으로 설정합니다. 외부 시스템은 외부 제어 API를 사용하여 상태를 '통과' 또는 '실패'로 업데이트하여 응답합니다.

GitLab 18.5에서는 외부 제어를 구성할 때 **Ping enabled** 설정을 끄면 이 자동 12시간 핑을 비활성화할 수 있습니다. 12시간 핑이 비활성화되면:

- GitLab은 외부 시스템에서 상태 업데이트를 자동으로 요청하지 않습니다.
- 외부 제어는 규정 준수 프레임워크 UI에 **비활성화됨** 배지를 표시합니다.
- 외부 제어 API를 사용하여 외부 제어 상태를 업데이트하는 시기를 완전히 제어합니다.

이는 시스템이 외부 제어 상태를 '보류 중'으로 재설정하는 것을 방지하고 상태 업데이트 타이밍에 대한 완전한 제어를 제공합니다.

### 제한적 출시 중인 종속성 검사 {#dependency-scanning-in-limited-availability}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15961)

{{< /details >}}

GitLab 18.5에서는 종속성 검사 분석기와 작동하는 새 종속성 검사 템플릿을 출시했습니다. 분석기는 이제 모든 구성 요소 취약성을 포함하는 종속성 검사 보고서를 생성합니다. 검사 실행 정책(SEP) 및 파이프라인 실행 정책(PEP)은 새 템플릿을 지원합니다.

새 템플릿을 사용하려면 `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`을 가져옵니다.

이 기능은 GitLab.com 및 자체 관리 인스턴스에서 사용할 수 있지만 자체 관리에 대한 공식 지원이 아직 없기 때문에 제한적 출시로 표시됩니다. GitLab.com 사용자는 즉시 사용할 수 있습니다.

이 기능에 대한 피드백을 환영합니다. 질문, 의견이 있거나 팀과 협력하고 싶다면 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)를 참조하세요.

### 환경 `deployment_tier`에서 변수 확장 {#variable-expansion-in-environment-deployment_tier}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../ci/yaml/_index.md#environmentdeployment_tier) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)

{{< /details >}}

이제 `environment:deployment_tier` 필드에서 CI/CD 변수를 사용할 수 있으므로 파이프라인 조건에 따라 배포 티어를 동적으로 구성하기가 더 쉬워졌습니다.

### 이슈 및 작업의 상태 수명 주기 구성 {#configure-status-lifecycles-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/work_items/status.md#lifecycles) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/555528)

{{< /details >}}

이전에는 이슈와 작업이 구성된 상태의 동일한 집합을 공유해야 했습니다. 이 릴리스에서는 상태 수명 주기 구성 지원을 추가하여 프로젝트에서 이슈 및 작업에 대해 고유한 워크플로를 정의할 수 있습니다. 워크플로에 내장된 상태 매핑을 사용하면 작업 항목 유형을 변경할 때 대량 편집이 필요 없이 이슈 또는 작업을 새 상태 집합으로 원활하게 전환할 수 있습니다.

사용 사례 및 제안과 함께 [피드백 이슈에 기여](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)하여 피드백을 공유하고 기능 개선을 도와주세요.

### 일반 텍스트 편집기에서 Markdown 테이블 포맷 {#format-markdown-tables-in-the-plain-text-editor}

<!-- categories: Markdown -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/markdown.md#tables)

{{< /details >}}

정렬되지 않은 Markdown 테이블은 올바르게 렌더링되더라도 읽고 편집하기가 어렵습니다.

일반 텍스트 편집기의 도구 모음의 새로운 **테이블 재포매팅** 기능은 한 번의 클릭으로 테이블 열을 정렬하여 정렬 설정 및 들여쓰기를 유지합니다. 사용 방법:

- 위키 페이지, 이슈 또는 머지 리퀘스트에서 Markdown 테이블을 선택합니다.
- **추가 옵션** 메뉴에서 **테이블 재포매팅**을 선택합니다.

이를 통해 복잡한 테이블로 작업할 때 문서 유지 관리를 더 빠르고 협업을 더 쉽게 만들 수 있습니다.

### 이슈에서 하위 항목 작업 완료 보기 {#view-child-task-completion-in-issues}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/tasks.md#view-tasks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/520886)

{{< /details >}}

이제 하위 항목 위젯에서 직접 이슈의 진행 상황을 추적하여 한 눈에 상태 개요를 얻을 수 있습니다. 이 향상 기능은 작업이 이미 진행 중일 때 잠재적인 병목 현상에 대한 실시간 가시성을 제공하므로 스프린트 마감일이 위협을 받기 전에 위험한 항목을 빠르게 식별하고 적절한 조정을 할 수 있습니다.

### 취약성 API에서 원본 심각도 노출 {#expose-original-severity-from-the-vulnerabilities-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../api/graphql/reference/_index.md#pipelinesecurityreportfinding) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/557940)

{{< /details >}}

취약성 GraphQL API는 이제 취약성의 원본 심각도를 노출합니다. 이를 통해 심각도 재정의를 적용하기 전에 취약성의 심각도가 무엇인지 확인할 수 있습니다.

### 머지 리퀘스트 승인 정책에 대한 시간 윈도우 {#time-windows-for-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#security_report_time_window) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)

{{< /details >}}

보안 취약성 비교에서 추가 유연성을 제공하기 위해 머지 리퀘스트 승인 정책에 시간 윈도우를 도입했습니다. 최근 기준선의 보안 보고서를 아직 사용할 수 없는 경우 이 새로운 정책 구성을 통해 시간 윈도우로 지정한 나이보다 오래되지 않은 한 이전에 완료된 보안 보고서를 사용할 수 있습니다.

개발 팀은 이제 기준선 보안 검사가 중단되거나 너무 오래 걸리는 경우, 예를 들어 매우 바쁜 프로젝트에서 불필요한 지연을 피할 수 있습니다. 시간 윈도우를 구성하면 새로운 취약성을 도입하지 않는 머지 리퀘스트는 최신 파이프라인이 완료될 때까지 기다리지 않고 진행할 수 있으므로 워크플로 효율성이 향상됩니다.

이 기능을 사용하려면 머지 리퀘스트 승인 정책을 생성 또는 편집하고 승인 정책 구성에서 `security_report_time_window` 매개변수(분 단위)를 지정하세요.

시스템은 지정된 시간 윈도우 내에서 생성된 보안 보고서를 사용하여 머지 리퀘스트의 보안 결과를 최신 파이프라인과 비교하므로 새로운 취약성이 도입되지 않으면 더 빠른 승인이 가능합니다.

### 파이프라인 **보안** 탭의 새로고침된 보안 발견 상태 {#refreshed-security-finding-statuses-in-the-pipeline-security-tab}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/detect/security_scanning_results.md#change-status) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/554078)

{{< /details >}}

이전에는 파이프라인의 **보안** 탭에서 취약성을 해제하면 취약성이 목록에서 즉시 제거되지 않았습니다.

이제 파이프라인 페이지의 보안 탭의 상태 업데이트가 변경된 후 업데이트됩니다.

### 머지 리퀘스트 승인 정책을 우회하기 위한 예외 {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

조직은 이제 머지 리퀘스트 승인 정책을 우회할 수 있는 특정 사용자, 그룹, 역할 또는 사용자 지정 역할을 지정할 수 있습니다. 이 기능은 포괄적인 감사 추적 및 거버넌스 제어를 유지하면서 긴급 대응 유연성을 제공합니다.

**Emergency bypass with accountability**: 지정된 사용자는 중요 인시던트, 보안 핫픽스 또는 긴급 프로덕션 이슈 중에 승인 요구사항을 우회할 수 있습니다. 긴급 상황이 발생하면 권한이 있는 담당자는 시스템이 규정 준수 검토를 위해 자세한 정당성 및 감사 정보를 캡처하는 동안 즉시 변경 사항을 병합하거나 푸시할 수 있습니다.

주요 기능:

- **Documented bypass process**: 권한이 있는 사용자가 정책 우회를 호출할 때 직관적인 모달 인터페이스를 사용하여 자세한 이유를 제공해야 하므로 모든 예외가 적절히 문서화되고 컨텍스트와 함께 기록됩니다.
- **Comprehensive audit integration**: 모든 우회는 사용자 ID, 정책 컨텍스트, 이유 및 타임스탬프를 포함하는 자세한 감사 이벤트를 생성하므로 예외 사용 패턴을 완전히 가시화합니다.
- **Flexible configuration**: 개별 사용자, GitLab 그룹, 표준 역할 및 사용자 지정 역할을 지원하는 YAML 또는 UI 구성을 사용하여 정책에 대한 예외 권한을 정의합니다.
- **Git-based push exceptions**: 사전 승인된 정책 예외가 있는 사용자는 푸시 우회 옵션 `security_policy.bypass_reason`을 호출할 때 직접 푸시할 수 있습니다.

이 기능을 통해 긴급 상황 중에 보안 정책을 완전히 비활성화할 필요가 없으므로 조직의 거버넌스 및 감사 요구사항을 유지하면서 긴급 변경에 대한 제어된 경로를 제공합니다.

### 종속성 목록에 활성 취약성만 표시 {#show-only-active-vulnerabilities-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dependency_list/_index.md#vulnerabilities) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/353487)

{{< /details >}}

이전에는 종속성 목록에 일부 해제된 취약성이 포함되어 있었습니다.

종속성 목록의 취약성에 대한 더 유용한 표현을 제공하기 위해 프로젝트 종속성 목록에는 이제 `detected` 및 `confirmed` 상태의 활성 취약성만 포함됩니다.

### 제한적 출시 중인 정적 연결 가능성 및 실험적 Java 지원 {#static-reachability-in-limited-availability-and-experimental-java-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dependency_scanning/static_reachability.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15780)

{{< /details >}}

GitLab 18.5에서는 정적 연결 가능성에 대한 제한적 출시 지원을 출시했습니다. 이 릴리스는 JS/TS 커버리지 지원 개선, 버그 수정 및 Java의 실험적 지원을 제공하는 데 중점을 둡니다. 정적 연결 가능성은 프로젝트 소스 코드를 검사하여 사용 중인 오픈 소스 종속성을 식별함으로써 SCA(Software Composition Analysis) 결과를 강화합니다. 정적 연결 가능성으로 생성된 데이터는 사용자의 분류 및 수정 결정 결정의 일부로 사용될 수 있습니다. 정적 연결 가능성 데이터는 CVSS 및 EPSS 점수뿐만 아니라 KEV 지표와 함께 사용하여 식별된 취약성에 대한 더 중점적인 보기를 제공할 수도 있습니다.

이 기능에 대한 피드백을 환영합니다. 질문, 의견이 있거나 팀과 협력하고 싶다면 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)를 참조하세요.

### GitLab 러너 18.5 {#gitlab-runner-185}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38976)

{{< /details >}}

저희도 오늘 GitLab 러너 18.5를 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

버그 수정:

- [러너 업데이트가 1.39에서 1.41로 러너 연산자를 업데이트한 후 바닐라 Kubernetes에서 실패](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/259)
- [일부 컨테이너 레이블에 중복 접두사 있음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38674)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.5)
- [지원 중단 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
