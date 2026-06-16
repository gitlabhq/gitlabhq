---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 소프트웨어 개발 수명 주기 전반에 걸쳐 작업을 자동화하는 AI 기반 에이전트 및 플로우를 살펴봅시다.
title: GitLab Duo AI 에이전트 플랫폼
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- [베타](../../policy/development_stages_support.md)로 GitLab 18.2에서 도입되었습니다.
- 자가 호스팅 인스턴스의 GitLab Duo AI 에이전트 플랫폼([자가 호스팅 모델](../../administration/gitlab_duo_self_hosted/_index.md) 및 클라우드 연결 GitLab 모델 모두 포함)은 GitLab 18.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19213)되었으며, `self_hosted_agent_platform`라는 [기능 플래그](../../administration/feature_flags/_index.md) 를 사용하는 [실험](../../policy/development_stages_support.md#experiment)으로 제공됩니다. 기본적으로 비활성화됨.
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)되었습니다.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다.
- GitLab Duo AI 에이전트 플랫폼 및 GitLab Credits는 GitLab 18.8 이상에서 지원됩니다.
- 기능 플래그 `self_hosted_agent_platform`이 GitLab 18.9에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589)되었습니다.

{{< /history >}}

GitLab Duo AI 에이전트 플랫폼은 소프트웨어 개발 수명 주기 전반에 걸쳐 여러 지능형 어시스턴트("에이전트")를 포함하는 AI 네이티브 솔루션입니다.

- 선형 워크플로를 따르는 대신 AI 에이전트와 비동기적으로 협업하세요.
- 코드 리팩토링 및 보안 스캔부터 연구에 이르기까지 일상적인 작업을 전문화된 AI 에이전트에 위임하세요.

시작하려면 [GitLab Duo AI 에이전트 플랫폼 시작하기](../get_started/get_started_agent_platform.md)를 참조하세요.

## 필수 요구 사항 {#prerequisites}

AI 에이전트 플랫폼을 사용하려면:

- [GitLab Duo가 활성화](turn_on_off.md#turn-gitlab-duo-on-or-off)되어 있어야 합니다.
- GitLab Duo Pro 또는 Enterprise가 없는 경우 [GitLab Duo Core가 활성화](turn_on_off.md#turn-gitlab-duo-core-on-or-off)되어 있어야 합니다(최상위 그룹 또는 인스턴스).
- GitLab 버전에 따라:
  - GitLab 18.8 이상에서는 [AI 에이전트 플랫폼이 활성화](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)되어 있어야 합니다.
  - GitLab 18.7 이전에는 [베타 및 실험 기능이 활성화](turn_on_off.md#turn-on-beta-and-experimental-features)되어 있어야 합니다.
- GitLab Self-Managed의 경우 [인스턴스를 구성](../../administration/gitlab_duo/configure/gitlab_self_managed.md)하세요.
- GitLab Duo Self-Hosted의 경우 AI 에이전트 플랫폼 서비스와 함께 [AI Gateway를 설치](../../install/install_ai_gateway.md)를 하세요.

로컬 환경에서 AI 에이전트 플랫폼을 사용하려면:

- 편집기 확장을 설치하고 GitLab으로 인증하세요.
- [그룹 네임스페이스](../namespace/_index.md)에서 프로젝트를 보유해야 합니다.
- Developer, Maintainer 또는 Owner 역할을 보유해야 합니다.

## 정식 출시 기능 {#generally-available-features}

이 기능들은 일반적으로 사용 가능하며 사용할 때 [GitLab Credits](../../subscriptions/gitlab_credits.md)를 사용합니다.

GitLab.com 고객의 Free 등급에서 사용할 수 있는 기능을 사용하려면 [GitLab Credits](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)의 구매가 필요합니다.

| 기능 | Free | Premium | Ultimate |
|---------|---------|---------|---------|
| [GitLab Duo Chat (에이전틱)](../gitlab_duo_chat/agentic_chat.md) <br /> 복잡한 질문에 답하고 자율적으로 파일을 생성 및 편집합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Suggestions](code_suggestions/_index.md) <br /> 코드를 작성하는 동안 AI 기반 제안을 받습니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [사용자 지정 에이전트](agents/custom.md) <br /> 팀에 특화된 에이전트를 구축하여 고유한 개발 요구 사항을 충족합니다. | {{< yes >}} |  {{< yes >}}  | {{< yes >}} |
| [외부 에이전트](agents/external.md) <br /> 타사 통합 및 도구를 안전하게 연결하여 AI 에이전트 플랫폼 기능을 확장합니다. | {{< no >}} |  {{< yes >}}  | {{< yes >}} |
| [Planner 에이전트](agents/foundational_agents/planner.md) <br /> 작업을 계획하고, 우선 순위를 정하고, 추적합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Data Analyst 에이전트](agents/foundational_agents/data_analyst.md) <br /> 개발 메트릭과 프로젝트 데이터에서 데이터를 분석하고 인사이트를 생성합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Developer 플로우](flows/foundational_flows/developer.md) <br /> 이슈를 머지 리퀘스트로 변환합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Code Review 플로우](flows/foundational_flows/code_review.md) <br /> 코드 검토 작업을 자동화하고 팀 전체에 걸쳐 코딩 표준을 적용합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Convert to GitLab CI/CD 플로우](flows/foundational_flows/convert_to_gitlab_ci.md) <br /> 레거시 CI/CD 파이프라인을 GitLab CI/CD 파이프라인 형식으로 변환합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Fix CI/CD Pipeline 플로우](flows/foundational_flows/fix_pipeline.md) <br /> 실패한 CI/CD 파이프라인을 진단하고 자동으로 수정합니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [Software Development 플로우](flows/foundational_flows/software_development.md) <br /> 실행하기 전에 완전한 다단계 계획을 만듭니다. | {{< yes >}} | {{< yes >}}  | {{< yes >}} |
| [MCP 클라이언트](../gitlab_duo/model_context_protocol/mcp_clients.md) <br /> MCP 호환 AI 클라이언트 또는 IDE 확장에서 GitLab 리소스 및 도구에 액세스합니다. <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [SAST False Positive Detection 플로우](flows/foundational_flows/sast_false_positive_detection.md) <br /> SAST 보안 스캔에서 거짓 긍정을 자동으로 식별하고 필터링합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [SAST Vulnerability Resolution 플로우](flows/foundational_flows/agentic_sast_vulnerability_resolution.md) <br /> SAST 취약점에 대한 수정 사항 및 수정 단계를 자동으로 생성합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |
| [Security Analyst 에이전트](agents/foundational_agents/security_analyst_agent.md) <br /> 반복되는 보안 작업을 자동화합니다:  이슈를 분류하고, 취약점을 분석하고, 수정 사항을 생성합니다. | {{< no >}} | {{< no >}}  | {{< yes >}} |

**각주**:

1. MCP 클라이언트는 직접 Credits를 사용하지 않습니다. 그러나 MCP 클라이언트를 통한 모델 요청 같은 에이전트 플랫폼 사용은 Credits를 사용할 수 있습니다.

## 베타 및 실험 기능 {#beta-and-experiment-features}

이 기능들은 베타 또는 실험 단계이며 GitLab Credits를 사용하지 않습니다.

[GitLab.com의 Free 등급 사용자](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)의 경우 베타 및 실험 기능이 Credits를 사용하지 않지만, 이들에 액세스하려면 Monthly Commitment Pool에 Credits가 필요합니다.

> [!warning]
> 기능이 일반적으로 사용 가능해지면, 모든 GitLab 버전 및 모든 오퍼링에서 해당 기능 사용이 GitLab Credits를 소비하기 시작합니다. 베타 기능은 언제든지 사용 요금이 부과되는 일반 사용 가능으로 변경될 수 있습니다.

| 기능 | Free | Premium | Ultimate |
|---------|---|---|---|
| [사용자 지정 플로우](flows/custom.md) <br /> 여러 에이전트를 결합하여 비즈니스 문제를 해결합니다. | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [MCP 서버](../gitlab_duo/model_context_protocol/mcp_server.md) <br /> AI 도구 및 응용 프로그램을 GitLab 인스턴스에 안전하게 연결합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [CI Expert 에이전트](agents/foundational_agents/ci_expert_agent.md) <br /> GitLab CI/CD 파이프라인을 만들고, 디버깅하고, 최적화합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [외부 MCP 서버](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) <br /> 사용자 지정 에이전트를 MCP 서버를 사용하여 외부 데이터 소스 및 타사 서비스에 연결합니다. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [지식 그래프](../project/repository/knowledge_graph/_index.md) <br /> AI 기능을 강화하기 위해 코드 리포지토리의 구조화되고 쿼리 가능한 표현을 만듭니다. | {{< no >}} |{{< yes >}} | {{< yes >}} |
