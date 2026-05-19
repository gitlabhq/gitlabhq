---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 소프트웨어 개발 라이프사이클 전반에 걸쳐 작업을 자동화하는 AI 기반 에이전트와 플로우를 살펴보세요.
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2에서 [베타](../../policy/development_stages_support.md)로 도입되었습니다.
- 셀프 매니지드 인스턴스의 GitLab Duo Agent Platform([자체 호스팅 모델](../../administration/gitlab_duo_self_hosted/_index.md) 및 클라우드 연결 GitLab 모델 모두)은 GitLab 18.4에서 `self_hosted_agent_platform`이라는 [기능 플래그](../../administration/feature_flags/_index.md)와 함께 [실험](../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19213)되었습니다. 기본적으로 비활성화되어 있습니다.
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)되었습니다.
- GitLab 18.8에서 [정식 출시](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)되었습니다.
- GitLab Duo Agent Platform 및 GitLab Credits는 GitLab 18.8 이상에서 지원됩니다.
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589)되었습니다.

{{< /history >}}

GitLab Duo Agent Platform은 소프트웨어 개발 라이프사이클 전반에 걸쳐 여러 지능형 어시스턴트("에이전트")를 내장한 AI 네이티브 솔루션입니다.

- 선형적인 워크플로우를 따르는 대신, AI 에이전트와 비동기적으로 협업할 수 있습니다.
- 코드 리팩토링, 보안 스캔, 리서치 등 반복적인 작업을 전문화된 AI 에이전트에 위임하세요.

시작하려면 [GitLab Duo Agent Platform 시작하기](../get_started/get_started_agent_platform.md)를 참조하세요.

## 사전 요구 사항 {#prerequisites}

Agent Platform을 사용하려면 다음이 필요합니다.

- [GitLab Duo가 켜져 있어야](turn_on_off.md#turn-gitlab-duo-on-or-off) 합니다.
- GitLab Duo Pro 또는 Enterprise가 없는 경우, 최상위 그룹 또는 인스턴스에 대해 [GitLab Duo Core가 켜져 있어야](turn_on_off.md#turn-gitlab-duo-core-on-or-off) 합니다.
- GitLab 버전에 따라 다음 중 하나를 충족해야 합니다.
  - GitLab 18.8 이상: [Agent Platform이 켜져 있어야](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) 합니다.
  - GitLab 18.7 이하: [베타 및 실험적 기능이 켜져 있어야](turn_on_off.md#turn-on-beta-and-experimental-features) 합니다.
- GitLab Self-Managed의 경우, [인스턴스를 구성](../../administration/gitlab_duo/configure/gitlab_self_managed.md)해야 합니다.
- GitLab Duo Self-Hosted의 경우, Agent Platform 서비스와 함께 [AI Gateway를 설치](../../install/install_ai_gateway.md)해야 합니다.

로컬 환경에서 Agent Platform을 사용하려면 다음이 필요합니다.

- 에디터 확장 프로그램을 설치하고 GitLab으로 인증해야 합니다.
- [그룹 네임스페이스](../namespace/_index.md)에 프로젝트가 있어야 합니다.
- Developer, Maintainer, 또는 Owner 역할이 있어야 합니다.

## 정식 출시 기능 {#generally-available-features}

다음 기능은 정식 출시되었으며, 사용 시 [GitLab Credits](../../subscriptions/gitlab_credits.md)를 소비합니다.

프리 티어에서 사용 가능한 기능은 [GitLab Credits](../../subscriptions/gitlab_credits.md#for-the-free-tier) 구매가 필요합니다.

| 기능 | Free | Premium | Ultimate |
|---------|---------|---------|---------|
| [GitLab Duo Chat (에이전틱)](../gitlab_duo_chat/agentic_chat.md) <br /> 복잡한 질문에 답하고 파일을 자율적으로 생성 및 편집합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Suggestions](code_suggestions/_index.md) <br /> 코드 작성 시 AI 기반 제안을 받습니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [커스텀 에이전트](agents/custom.md) <br /> 고유한 개발 요구 사항에 맞는 팀 전용 에이전트를 빌드합니다. | {{< yes >}} |  {{< yes >}}  | {{< yes >}} |
| [외부 에이전트](agents/external.md) <br /> 서드파티 통합 및 도구를 안전하게 연결하여 Agent Platform 기능을 확장합니다. | {{< no >}} |  {{< yes >}}  | {{< yes >}} |
| [Planner Agent](agents/foundational_agents/planner.md) <br /> 작업을 계획, 우선순위 지정 및 추적합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Data Analyst Agent](agents/foundational_agents/data_analyst.md) <br /> 개발 측정항목 및 프로젝트 데이터에서 데이터를 분석하고 인사이트를 생성합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Developer Flow](flows/foundational_flows/developer.md) <br /> 이슈를 머지 리퀘스트로 변환합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Review Flow](flows/foundational_flows/code_review.md) <br /> 코드 리뷰 작업을 자동화하고 팀 전체에 코딩 표준을 적용합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Convert to GitLab CI/CD Flow](flows/foundational_flows/convert_to_gitlab_ci.md) <br /> 레거시 CI/CD 파이프라인을 GitLab CI/CD 형식으로 변환합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Fix CI/CD Pipeline Flow](flows/foundational_flows/fix_pipeline.md) <br /> 실패한 CI/CD 파이프라인을 진단하고 자동으로 수정합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Software Development Flow](flows/foundational_flows/software_development.md) <br /> 실행 전에 전체 다단계 계획을 수립합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md) <br /> MCP 호환 AI 클라이언트 또는 IDE 확장 프로그램에서 GitLab 리소스와 도구에 액세스합니다. <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [SAST False Positive Detection Flow](flows/foundational_flows/sast_false_positive_detection.md) <br /> SAST 보안 스캔에서 오탐(false positive)을 자동으로 식별하고 필터링합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [SAST Vulnerability Resolution Flow](flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <br /> SAST 취약성에 대한 수정 사항 및 해결 단계를 자동으로 생성합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [Security Analyst Agent](agents/foundational_agents/security_analyst_agent.md) <br /> 반복적인 보안 작업을 자동화합니다. 이슈를 분류하고, 취약성을 분석하며, 수정 사항을 생성합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |

**각주**:

1. MCP 클라이언트는 크레딧을 직접 소비하지 않습니다. 단, MCP 클라이언트를 통한 모델 요청 등 Agent Platform 사용은 크레딧을 소비할 수 있습니다.

## 베타 및 실험 기능 {#beta-and-experiment-features}

다음 기능은 베타 또는 실험 단계이며 GitLab Credits를 소비하지 않습니다.

[프리 티어 사용자](../../subscriptions/gitlab_credits.md#for-the-free-tier)의 경우, 베타 및 실험적 기능은 크레딧을 소비하지 않지만 액세스하려면 월간 약정 풀에 크레딧이 있어야 합니다.

> [!warning]
> 기능이 정식 출시되면, 모든 GitLab 버전 및 모든 오퍼링에서 해당 기능 사용 시 GitLab Credits가 소비되기 시작합니다.
> 베타 기능은 언제든지 사용 과금이 적용되는 정식 출시로 전환될 수 있습니다.

| 기능 | Free | Premium | Ultimate |
|---------|---|---|---|
| [커스텀 플로우](flows/custom.md) <br /> 여러 에이전트를 결합하여 비즈니스 문제를 해결합니다. | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [MCP server](../gitlab_duo/model_context_protocol/mcp_server.md) <br /> AI 도구와 애플리케이션을 GitLab 인스턴스에 안전하게 연결합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [CI Expert Agent](agents/foundational_agents/ci_expert_agent.md) <br /> GitLab CI/CD 파이프라인을 생성, 디버그 및 최적화합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [외부 MCP 서버](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) <br /> MCP 서버를 사용하여 커스텀 에이전트를 외부 데이터 소스 및 서드파티 서비스에 연결합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Knowledge Graph](../project/repository/knowledge_graph/_index.md) <br /> AI 기능을 지원하기 위해 코드 저장소의 구조화된 쿼리 가능한 표현을 생성합니다. | {{< no >}} |{{< yes >}} | {{< yes >}} |
| [머지 충돌 해결](../project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo) <br /> 머지 충돌을 자율적으로 분석하고, 충돌 파일을 편집하며, 해결 커밋을 push합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
