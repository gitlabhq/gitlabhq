---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 개발 수명 주기 전반에 걸쳐 AI 네이티브 기능을 사용합니다.
title: GitLab Duo Agent Platform 시작하기
---

GitLab Duo AI 에이전트 플랫폼은 소프트웨어 개발 수명 주기 전반에 걸쳐 여러 지능형 어시스턴트("에이전트")를 포함하는 AI 네이티브 솔루션입니다.

- 선형 워크플로를 따르는 대신 AI 에이전트와 비동기적으로 협업하세요.
- 코드 리팩토링 및 보안 스캔부터 연구에 이르기까지 일상적인 작업을 전문화된 AI 에이전트에 위임하세요.

Agent Platform은 여러 기능으로 구성되어 있으며, GitLab UI 및 IDE에서 사용할 수 있습니다.

## 1단계:  GitLab Duo Chat 액세스 {#step-1-access-gitlab-duo-chat}

GitLab Duo Agentic Chat은 UI 또는 로컬 환경에서 질문을 하고 에이전트와 상호 작용하기 위한 인터페이스입니다. 조언을 제공할 수 있을 뿐만 아니라 솔루션을 제안하고 구현할 수도 있습니다.

Chat은 이슈, 머지 리퀘스트, 커밋 및 CI/CD 파이프라인을 포함한 프로젝트에 액세스할 수 있으며, 대화 전반에 걸쳐 컨텍스트를 유지합니다. 복잡성을 점차 늘리고, 이전 응답을 참조하며, 원하는 결과에 도달할 때까지 반복할 수 있습니다.

GitLab Duo Chat은 GitLab UI 및 다양한 IDE에서 사용할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md).

## 2단계:  에이전트로 작업 {#step-2-work-with-agents}

에이전트는 특정 워크플로를 위해 설계된 전문 AI 어시스턴트입니다.

- 기본 에이전트는 기본적으로 사용 가능하며 일반적인 개발 작업을 처리합니다. GitLab Duo Agent는 질문, 설명 및 코드 탐색을 위한 일반적인 지원을 제공합니다. 다른 기본 에이전트는 릴리스 계획 또는 코드 보안과 같은 작업을 돕습니다.
- 사용자 지정 에이전트는 조직에서 팀별 워크플로를 처리하기 위해 생성됩니다. 코드 검토 표준, 규정 준수 확인, 배포 자동화 또는 팀 고유의 워크플로를 위한 에이전트를 구축할 수 있습니다.
- 외부 에이전트는 GitLab을 이미 사용 중인 AI 모델 제공자와 통합합니다. 이슈, 에픽 및 머지 리퀘스트에서 외부 에이전트를 트리거합니다.

자세한 정보는 다음을 참조하세요:

- [에이전트 개요](../duo_agent_platform/agents/_index.md).
- [기본 에이전트](../duo_agent_platform/agents/foundational_agents/_index.md).
- [사용자 지정 에이전트](../duo_agent_platform/agents/custom.md).
- [외부 에이전트](../duo_agent_platform/agents/external.md).

## 3단계:  플로우에서 여러 에이전트를 함께 사용 {#step-3-use-multiple-agents-together-in-a-flow}

플로우는 작업을 완료하기 위해 함께 작동하는 하나 이상의 에이전트의 조합입니다. 플로우는 일반적으로 도구 또는 팀원 간의 수동 조정이 필요한 다단계 워크플로를 자동화하는 데 도움이 됩니다.

예를 들어 머지 리퀘스트에서 플로우를 트리거할 수 있으며, 플로우는 보안 스캔을 수행하고, 코드를 검토하며, 테스트를 생성하고, 문서를 작성할 수 있습니다.

GitLab은 IDE의 소프트웨어 개발 플로우 또는 CI/CD 파이프라인을 변환하거나 수정하는 것과 같은 작업을 수행하는 UI의 기본 플로우를 제공합니다. 사용자 지정 플로우를 생성할 수도 있습니다.

AI 카탈로그는 에이전트 및 플로우를 검색 및 생성하고 프로젝트에서 사용하도록 설정하는 중앙 위치입니다.

자세한 정보는 다음을 참조하세요:

- [플로우](../duo_agent_platform/flows/_index.md).
- [AI 카탈로그](../duo_agent_platform/ai_catalog.md).
- [트리거](../duo_agent_platform/triggers/_index.md).

## 4단계:  에이전트 활동 모니터링 및 검토 {#step-4-monitor-and-review-agent-activity}

에이전트가 수행하는 작업은 로그가 있는 세션에서 추적됩니다. 세션은 디버깅을 지원하고, 학습을 촉진하며, 감사 요구 사항을 지원하는 데 도움이 될 수 있습니다.

세션을 보려면 프로젝트로 이동하여 **AI** > **세션**을 선택하세요.

자세한 정보는 다음을 참조하세요:

- [세션](../duo_agent_platform/sessions/_index.md).

## 5단계:  통합으로 기능 확장 {#step-5-extend-capabilities-with-integrations}

AI 에이전트의 지식을 늘리려면 지식 그래프를 사용하세요. 코드 리포지토리의 구조화된 표현을 생성하고 에이전트 및 팀이 파일, 함수 및 종속성 간의 관계를 더 잘 이해하는 데 도움이 됩니다.

외부 도구 및 데이터 소스와 연결하여 플랫폼을 GitLab 너머로 확장할 수도 있습니다.

- GitLab Duo 기능(예: Agentic Chat)을 외부 MCP 서버에 연결하여 다른 MCP 클라이언트가 더 포괄적인 지원을 제공할 수 있도록 합니다.
- MCP 서버는 반대 방향으로 작동합니다. Claude Desktop 또는 Cursor와 같은 외부 AI 도구가 GitLab 인스턴스에 안전하게 연결되어 이러한 도구가 GitLab 데이터에 액세스할 수 있게 합니다.

자세한 정보는 다음을 참조하세요:

- [지식 그래프](../project/repository/knowledge_graph/_index.md).
- [MCP 클라이언트](../gitlab_duo/model_context_protocol/mcp_clients.md).
- [MCP 서버](../gitlab_duo/model_context_protocol/mcp_server.md).

## 리소스 {#resources}

- 8부 튜토리얼:  [GitLab Duo Agent Platform 시작하기: 전체 가이드](https://about.gitlab.com/blog/gitlab-duo-agent-platform-complete-getting-started-guide/)
- 블로그:  [GitLab 엔지니어: AI로 온보딩 경험을 개선한 방법](https://about.gitlab.com/blog/gitlab-engineer-how-i-improved-my-onboarding-experience-with-ai/)
- 강연 녹화:  [GitLab Duo Agent Platform의 Agentic AI | 사용 사례 및 모범 사례 | DACH Roadshow Vienna 2025](https://www.youtube.com/watch?v=amJQkKhe5ys) ([슬라이드](https://docs.google.com/presentation/d/e/2PACX-1vTX-DcBV9Rw6HQ7vNew8EWRv1NMGtKfRbb5eATRb9tENrOUbnbPdZJwXnub2OMnqv-nIV_v0hIQB6Ew/pub?start=false&loop=false&delayms=3000&slide=id.g38ddaede31e_0_36))
<!-- Video published on 2025-12-09 -->
