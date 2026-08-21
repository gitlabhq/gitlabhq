---
stage: Release Notes
group: Monthly Release
date: 2026-01-15
title: "GitLab 18.8 릴리스 정보"
description: "GitLab Duo Agent Platform이 이제 일반 제공되는 GitLab 18.8 릴리스"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026년 1월 15일에 GitLab 18.8이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Wesley Yarde {#this-months-notable-contributor-wesley-yarde}

이달의 주목할 만한 기여자는 [Wesley Yarde](https://gitlab.com/WYarde)로, 조직이 엔터프라이즈 사용자를 위해 SSH 키를 비활성화할 수 있게 해주는 기본 새로운 기능을 구축했습니다.

Wesley의 기여가 눈에 띄는 이유는 여러 가지입니다:

- **보안 및 규정 준수**: 이 기능을 통해 조직은 SSH 키 요구 사항을 시행하고 전사적으로 보안을 강화할 수 있습니다.
- **Foundational work**: 기존 구현이 없었기 때문에 Wesley는 처음부터 요구 사항과 아키텍처를 정의하기 위해 GitLab 팀과 광범위하게 협력해야 했습니다.
- **First contribution**: 놀랍게도 이것이 Wesley의 GitLab에 대한 첫 기여였으며, 복잡한 코드베이스를 탐색하고 어려운 기능을 처리할 수 있는 뛰어난 능력을 보여주었습니다.
- **Enables future development**: 이 작업은 인스턴스 수준의 SSH 키 비활성화 및 서비스 계정 제어와 같은 유사한 기능의 기초를 마련합니다.

구현은 여러 [!205020](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205020), [!210482](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210482) 머지 리퀘스트에 걸쳐 있었으며 철저한 검토 주기가 포함되었습니다. 복잡성에도 불구하고 Wesley는 전체 프로세스 동안 뛰어난 협력과 인내심을 보여주었습니다.

"이 기능 요청에 대해 Wesley와 협력하는 것이 즐거웠습니다! 기여자와 검토자 모두 검토 프로세스가 압도적이라고 느낄 수 있었지만, 구현이 견고하고 완전한지 확인하기 위해 양쪽 모두 이해하고 뛰어난 협력을 보여주었습니다." — [Bogdan Denkovych](https://gitlab.com/bdenkovych), Wesley를 이 인정으로 추천했습니다.

Wesley님께 축하를 드리며, GitLab에 대한 귀중한 기여에 감사드립니다!

## 주요 기능 {#primary-features}

### GitLab Duo Agent Platform이 이제 일반 제공 {#gitlab-duo-agent-platform-now-generally-available}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/585273)

{{< /details >}}

GitLab Duo Agent Platform이 이제 일반 제공되며, 전체 소프트웨어 개발 수명 주기에 걸쳐 에이전트형 AI 오케스트레이션을 제공합니다. 개별 작업을 단독으로 속도를 높이는 AI 도구와 달리 Agent Platform은 팀이 계획, 구축, 보안 및 소프트웨어 배송 전반에 걸쳐 AI 에이전트를 조율하는 데 도움이 되며, 더 빠른 개별 작업과 소프트웨어 전달의 협업적 다단계 현실 사이의 격차를 좁힙니다.

플랫폼은 팀이 조직 전체에서 에이전트와 플로우를 발견하고, 관리하고, 공유할 수 있는 중앙 AI 카탈로그를 제공합니다. Planner, Security Analyst, Data Analyst와 같은 기본 제공 기본 에이전트는 핵심 의사 결정 지점에서 구조화된 작업을 처리하며, 사용자 지정 가능한 플로우는 이슈에서 머지 리퀘스트, CI/CD 마이그레이션, 파이프라인 이슈 해결 및 코드 검토까지 개발 워크플로우의 다단계 에이전트와 작업을 자동화합니다.

거버넌스 제어, 사용 현황 가시성 및 오프라인 환경용 자체 호스팅 모델을 포함한 유연한 배포 옵션을 통해 조직은 필요한 투명성과 제어를 통해 대규모로 AI를 채택할 수 있습니다.

GitLab Premium 및 Ultimate 사용자는 이제 GitLab.com 및 GitLab Self-Managed 인스턴스에서 프로모션 [GitLab Credits](../../subscriptions/gitlab_credits.md)를 사용하여 Agent Platform 사용을 시작할 수 있습니다.

### GitLab Duo Planner Agent가 이제 일반 제공 {#gitlab-duo-planner-agent-now-generally-available}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)

{{< /details >}}

Planner Agent가 이제 일반 제공됩니다! Planner 에이전트는 제품 관리자가 GitLab에서 직접 지원하도록 구축된 기본 에이전트입니다.

Planner 에이전트를 사용하여 GitLab 작업 항목을 생성, 편집 및 분석합니다. 수동으로 업데이트를 추적하거나 작업을 우선순위 지정하거나 계획 데이터를 요약하는 대신 Planner 에이전트는 백로그를 분석하고 RICE 또는 MoSCoW와 같은 프레임워크를 적용하며 실제로 주의가 필요한 사항을 표시하도록 도와줍니다. 계획 워크플로를 이해하고 더 나은 효율적인 결정을 내리기 위해 함께 작동하는 능동적인 팀원을 갖는 것과 같습니다.

의견을 [이슈 583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)에서 제공해 주세요.

### GitLab Duo Security Analyst Agent가 이제 일반 제공 {#gitlab-duo-security-analyst-agent-now-generally-available}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Duo Security Analyst Agent는 [GitLab 18.5에서 베타로 출시](https://about.gitlab.com/releases/2025/10/16/gitlab-18-5-released/#gitlab-security-analyst-agent-for-duo-agent-catalog-beta)되었으며, 이제 GitLab 18.8에서 일반 제공됩니다.

Security Analyst Agent를 통해 엔지니어는 GitLab Duo Agentic Chat에서 자연어 명령으로 취약성을 관리할 수 있습니다. 수동으로 취약성 대시보드를 클릭하거나 대량 작업을 위한 사용자 지정 스크립트를 작성하는 대신 보안 팀은 이제 Chat 대화에서 취약성을 분류하고, 평가하고, 지침을 제공할 수 있습니다.

기본 에이전트인 Security Analyst Agent는 GitLab Duo Agentic Chat에서 기본적으로 사용할 수 있으며, 수동 설정이 필요하지 않습니다.

### 취약성 관리 정책으로 관련 없는 취약성 자동 무시 {#auto-dismiss-irrelevant-vulnerabilities-with-vulnerability-management-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/policies/vulnerability_management_policy.md#auto-dismiss-policies) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10894)

{{< /details >}}

보안 팀은 이제 취약성 관리 정책을 사용하여 조직에 적용되지 않는 취약성을 자동으로 무시할 수 있습니다. 조직과 무관한 취약성을 무시하면 노이즈를 줄이고 개발자가 실제 위험을 초래하는 취약성에 집중하도록 도움을 줍니다.

다음을 기반으로 취약성을 자동 무시하는 정책을 생성할 수 있습니다:

- 파일 경로
- 디렉터리
- 식별자(CVE, CWE 또는 OWASP)

자동으로 무시된 취약성은 **Auto-dismissed** 레이블이 있는 머지 리퀘스트의 보안 위젯에 표시되며 감사 목적으로 무시 이유와 함께 취약성 보고서 활동에서 추적됩니다.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Agent Platform 켜기 또는 끄기 {#turn-the-gitlab-duo-agent-platform-on-or-off}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/583980)

{{< /details >}}

이제 최상위 그룹 또는 전체 인스턴스에 대해 GitLab Duo Agent Platform, GitLab Duo Chat(Agentic), 에이전트 및 플로우를 켜거나 끌 수 있습니다. 이 설정을 끄면 이러한 기능을 사용할 수 없습니다.

### GitLab Duo 기능에 대한 그룹 액세스 제어 {#group-access-control-for-gitlab-duo-features}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../administration/gitlab_duo/configure/access_control.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/585355)

{{< /details >}}

이제 그룹 액세스 규칙을 정의하여 GitLab Duo 기능을 사용할 수 있는 사람을 제어할 수 있으며, 즉시 조직 전체 액세스에서 단계적 롤아웃까지 유연한 채택 전략을 지원합니다.

이 기능은 세분화된 거버넌스 제어를 제공하므로 보안 및 규정 준수를 유지하면서 자신의 속도에 맞춰 채택을 확장할 수 있습니다.

### GitLab Duo Self-Hosted(오프라인 라이선싱)용 GitLab Duo Agent Platform이 이제 일반 제공 {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-offline-licensing-now-generally-available}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/19125)

{{< /details >}}

GitLab Duo Agent Platform이 이제 Duo Self-Hosted에 일반 제공됩니다. 이 기능은 오프라인 라이선스가 있는 GitLab Self-Managed 고객이 사용할 수 있으며, 사용자별 가격 책정을 사용합니다.

Self-Managed 관리자는 GitLab Duo Agent Platform과 함께 사용할 [호환 모델](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)을 구성할 수 있습니다. AWS Bedrock 또는 Azure OpenAI를 사용하는 관리자는 Anthropic Claude 또는 OpenAI GPT 모델도 구성할 수 있습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Advanced SAST에서 C/C++ 지원이 이제 일반 제공 {#cc-support-in-advanced-sast-now-generally-available}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/sast/advanced_sast_cpp.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/18369)

{{< /details >}}

C/C++에 대한 교차 파일, 교차 함수 스캔 지원이 이제 GitLab Advanced SAST에서 일반 제공됩니다.

### 여러 컨테이너 스캔 {#multiple-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](../../user/application_security/container_scanning/multi_container_scanning.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/work_items/3139)

{{< /details >}}

GitLab 18.8에서 다중 컨테이너 스캔이 베타로 릴리스되었습니다.

사용자는 이제 많은 컨테이너 스캔 작업의 일부로 스캔할 이미지 배열을 전달할 수 있습니다.

### 그룹 소유자를 위한 중앙 집중식 자격 증명 관리 API {#centralized-credential-management-api-for-group-owners}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../api/groups.md#credentials-inventory-management) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16343)

{{< /details >}}

자격 증명 인벤토리 API는 이제 GitLab.com의 엔터프라이즈 사용자에게 제공됩니다. 이는 이전에 자체 호스팅 인스턴스에서만 사용 가능했던 자격 증명 관리 기능을 추가하며, 조직이 인증 토큰과 키를 더 잘 관리하고 보호할 수 있도록 합니다.

자격 증명 인벤토리 API는 다음을 포함하여 조직 전체에서 자격 증명을 볼 수 있는 프로그래밍 방식의 액세스를 제공합니다:

- 개인 액세스 토큰(PAT)
- 그룹 액세스 토큰(GrAT)
- 프로젝트 액세스 토큰(PrAT)
- SSH 키
- GPG 키

이 API는 기존 자격 증명 인벤토리 UI를 보완하며, 엔터프라이즈 관리자가 이전에 수동 개입이 필요했던 자격 증명 관리 작업을 자동화할 수 있도록 합니다. 자격 증명 인벤토리 API를 사용하면 다음을 수행할 수 있습니다:

- 보안 워크플로우 자동화: 자격 증명을 모니터링, 감사 및 취소하는 자동화된 프로세스를 구축합니다.
- 자격 증명 정책 적용: 사용하지 않거나 만료된 토큰을 식별하고 취소합니다.
- 보안 태세 개선: 정기적인 감사를 통해 자격 증명 오용의 위험을 줄입니다.
- 작업 간소화: 자격 증명 관리를 기존 보안 도구 및 워크플로우에 통합합니다.

### 그룹 소유자가 엔터프라이즈 사용자에 대해 SSH 키를 비활성화할 수 있음 {#group-owners-can-disable-ssh-keys-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/ssh_advanced.md#disable-ssh-keys-for-enterprise-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)

{{< /details >}}

그룹 소유자는 이제 그룹의 모든 엔터프라이즈 사용자에 대해 SSH 키를 비활성화할 수 있습니다. 비활성화되면 사용자는 새 SSH 키를 추가할 수 없으며 기존 키가 비활성화됩니다. 이는 소유자 역할이 있는 사용자를 포함하여 그룹의 모든 엔터프라이즈 사용자에게 적용됩니다.

[Wesley Yarde](https://gitlab.com/WYarde)가 이 기능 구축을 도와주셔서 감사합니다!

### 러너 18.8 {#gitlab-runner-188}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 러너 18.8도 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [작업 입력 보간 오류에 대한 개선된 오류 메시지](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39163)

#### 버그 수정 {#bug-fixes}

- [`WaitForServicesTimeout`은 더 이상 `-1`을 지원하지 않아 타임아웃을 비활성화합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39172)
- [사용자 지정 URL이 `insteadOf` 규칙으로 서브모듈 인증을 중단합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39170)
- [Windows 2025의 사용자 지정 러너 단축 토큰이 8자 대신 9자를 사용합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39122)
- [GitLab Runner 17.8.3의 Docker 실행기에 대한 PowerShell 기본 도우미 이미지 누락](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38669)
- [Docker Autoscaler가 있는 GitLab Runner는 사용 가능한 캐시 볼륨을 재사용하지 않습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37906)
- [VirtualBox는 직업이 취소될 때 고아 VM을 남깁니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37344)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.8)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
