---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Software Development 플로우
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.4에서 비공개 베타로 도입](https://gitlab.com/groups/gitlab-org/-/epics/14153)되었으며 [기능 플래그](../../../../administration/feature_flags/_index.md) `duo_workflow`가 포함됩니다. GitLab 팀 멤버만 사용할 수 있습니다.
- GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었으며 GitLab 18.2에서 베타로 변경되었습니다.
- GitLab 18.8에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)되었습니다. `duo_workflow` 기능 플래그가 제거되었습니다.
- GitLab 18.10부터 GitLab.com의 Free 티어에서 GitLab Credits를 사용하여 이용 가능합니다.

{{< /history >}}

Software Development 플로우를 사용하면 소프트웨어 개발 수명 주기 전반의 작업에 대해 AI 생성 솔루션을 만들 수 있습니다. 이전에 GitLab Duo Workflow로 알려진 이 플로우:

- IDE에서 실행되므로 컨텍스트나 도구를 전환할 필요가 없습니다.
- 프롬프트에 응답하여 계획을 생성하고 진행합니다.
- 제안된 변경 사항을 프로젝트의 리포지토리에 저장합니다. 제안을 수락, 수정 또는 거부할 시기를 제어합니다.
- 프로젝트 구조, 코드베이스 및 기록의 컨텍스트를 이해합니다. 관련 GitLab 이슈나 머지 리퀘스트 등 고유한 컨텍스트를 추가할 수도 있습니다.

이 플로우는 VS Code, Visual Studio 및 JetBrains에서 사용할 수 있습니다.

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 사전 요구 사항](../../_index.md#prerequisites)을 충족합니다.
- IDE용 [편집기 확장 프로그램](../../../../editor_extensions/_index.md)을 설치하고 구성합니다.

## 플로우 및 채팅 비교 {#flow-and-chat-comparison}

Software Development 플로우와 GitLab Duo Chat은 모두 IDE에서 여러 탭으로 사용할 수 있습니다.

복잡한 개발 작업을 위해 Software Development 플로우를 사용합니다.

- 플로우는 포괄적인 컨텍스트를 수집하고, 검토할 수 있는 자세한 계획을 생성하며, 작업을 체계적으로 진행합니다.
- 플로우는 큰 컨텍스트 윈도우가 필요한 더 길고 깊은 세션에 이상적이며 반복이 필요한 코드 생성에 더 나은 결과를 생성하는 구조화된 접근 방식을 사용합니다.
- 각 플로우에는 시작과 끝이 있습니다. 새 플로우를 시작할 때 컨텍스트를 다시 수집하고 프로젝트의 현재 상태에 따라 새 계획을 만듭니다.

방향을 안내하는 대화형 상호 작용을 위해 GitLab Duo Chat을 사용합니다.

- 채팅은 정보를 수집하여 질문에 답변하고, 제안을 제공하며, 프롬프트에 응답하여 자동으로 사용자 대신 작업을 수행할 수 있습니다.
- 채팅은 지속적인 대화를 유지하므로 진행 중인 모든 논의로 돌아가서 중단한 부분부터 계속할 수 있습니다.

둘 다 유사한 작업을 돕는 데 도움이 될 수 있지만 작동 방식이 다릅니다. 플로우는 포괄적인 컨텍스트를 미리 수집하고 최소한의 인간 상호 작용으로 실행됩니다. 채팅은 사용자와의 지속적인 피드백 루프로 작동하며 대화 중 필요에 따라 컨텍스트를 수집합니다. 예를 들어 플로우는 접근 방식을 제안하기 전에 다양한 솔루션을 고려하는 반면 채팅은 빠른 결과를 제공하기 위해 첫 번째 실행 가능한 경로로 이동합니다.

## Software Development 플로우 사용 {#use-the-software-development-flow}

플로우를 사용하려면:

1. IDE에서 **GitLab Duo 에이전트 플랫폼**({{< icon name="duo-agentic-chat" >}})을 선택합니다.
1. **플로우** 탭을 선택합니다.
1. 텍스트 상자에서 코드 작업을 자세히 지정합니다.
   - 플로우는 프로젝트 브랜치에서 Git에 사용할 수 있는 모든 파일을 인식합니다.
   - 채팅을 위해 추가 [컨텍스트](../../context.md#gitlab-duo-agentic-chat)를 제공할 수 있습니다.
   - 플로우는 외부 소스 또는 웹에 액세스할 수 없습니다.
   - 예를 들어:

     ```plaintext
     I have a large Ruby class that is used in a few places and I want to break it down.
     Analyze this class and see what sub-methods or properties can be delegated to a
     separate class. Then, propose a transition plan to implement this new sub-class
     and update all of the required tests.
     ```

1. **시작**을 선택합니다.

작업을 설명한 후 플로우가 계획을 생성하고 실행합니다. 플로우를 일시 중지하거나 계획을 조정하도록 요청할 수 있습니다.

## 지원되는 언어 {#supported-languages}

Software Development 플로우는 공식적으로 다음 언어를 지원합니다:

- CSS
- Go
- HTML
- Java
- JavaScript
- 마크다운
- Python
- Ruby
- TypeScript

## 플로우가 액세스할 수 있는 API {#apis-that-the-flow-has-access-to}

솔루션을 만들고 문제의 컨텍스트를 이해하기 위해 플로우는 여러 GitLab API에 액세스합니다.

구체적으로 `ai_workflows` 범위가 있는 OAuth 토큰은 다음 API에 액세스할 수 있습니다:

- [프로젝트 API](../../../../api/projects.md)
- [검색 API](../../../../api/search.md)
- [CI 파이프라인 API](../../../../api/pipelines.md)
- [CI 작업 API](../../../../api/jobs.md)
- [머지 리퀘스트 API](../../../../api/merge_requests.md)
- [에픽 API](../../../../api/epics.md)
- [이슈 API](../../../../api/issues.md)
- [메모 API](../../../../api/notes.md)
- [사용 현황 데이터 API](../../../../api/usage_data.md)
- [메타데이터 API](../../../../api/metadata.md)(더 이상 사용되지 않는 `/version` 엔드포인트 포함)

## 감사 로그 {#audit-log}

Software Development 플로우는 각 API 요청에 대한 감사 이벤트를 생성합니다. GitLab Self-Managed 인스턴스에서 [인스턴스 감사 이벤트](../../../../administration/compliance/audit_event_reports.md#instance-audit-events) 페이지에서 이러한 이벤트를 볼 수 있습니다.

## 위험 {#risks}

Software Development 플로우는 GitLab 계정을 사용하여 작업을 수행할 수 있는 AI 에이전트를 사용합니다. 대규모 언어 모델을 기반으로 한 AI 도구는 예측 불가능할 수 있습니다. 사용 전에 잠재적 위험을 검토합니다.

VS Code, JetBrains IDE 및 Visual Studio의 Software Development 플로우는 로컬 워크스테이션에서 워크플로우를 실행합니다. 이 제품을 활성화하기 전에 문서화된 모든 위험을 고려합니다. 주요 위험은 다음과 같습니다:

- Software Development 플로우는 Git에서 추적하지 않거나 `.gitignore`에서 제외된 파일을 포함하여 프로젝트의 로컬 파일 시스템에 있는 파일에 액세스할 수 있습니다. 여기에는 `.env` 파일의 자격 증명과 같은 민감한 정보가 포함될 수 있습니다.
- Software Development 플로우에는 사용자 ID에 연결된 `ai_workflows` 범위가 있는 시간 제한 GitLab OAuth 토큰이 제공됩니다. 이 토큰은 워크플로우 기간 동안 지정된 GitLab API에 액세스할 수 있습니다. 기본적으로 명시적 승인 없이 읽기 작업만 수행되지만 권한에 따라 쓰기 작업이 가능합니다.
- Software Development 플로우에 추가 자격 증명이나 비밀(예: 메시지 또는 목표)을 제공하지 마세요. 이러한 정보가 의도하지 않게 사용되거나 코드 또는 API 호출에 노출될 수 있습니다.
