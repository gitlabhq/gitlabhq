---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 모델 컨텍스트 프로토콜과 사용 방법을 설명합니다
title: 모델 컨텍스트 프로토콜
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

모델 컨텍스트 프로토콜(MCP)은 AI 어시스턴트를 기존 도구 및 데이터 소스에 연결하는 개방형 표준입니다. MCP는 범용 어댑터로 작동합니다. 각 소프트웨어 플랫폼에 대해 별도의 사용자 지정 연결을 만드는 대신, 시스템 통신을 위해 단일 표준화된 프로토콜을 사용할 수 있습니다.

예를 들어, AI 어시스턴트는 CRM에서 고객 데이터를 가져오고, GitLab에서 프로젝트 상태를 확인하고, 같은 프로토콜을 통해 wiki의 문서를 참조할 수 있습니다. 이러한 접근 방식은 개발자의 구성을 줄이고 필요한 컨텍스트에 액세스할 수 있는 더욱 강력한 AI 어시스턴트를 만듭니다.

GitLab은 두 가지 방식으로 MCP를 지원합니다:

- [MCP 클라이언트](mcp_clients.md): GitLab Duo Agentic Chat 같은 GitLab Duo 기능을 외부 MCP 서버에 연결하여 다른 시스템의 데이터 및 도구에 액세스하고 더욱 포괄적인 지원을 제공합니다.

- [MCP 서버](../../model_context_protocol/mcp_server.md): 외부 AI 도구를 GitLab 인스턴스에 연결합니다. 연결된 도구는 프로젝트, 이슈, 머지 리퀘스트, 및 기타 GitLab 데이터에 안전하게 액세스할 수 있습니다.

## 관련 항목 {#related-topics}

- [MCP 시작하기](https://modelcontextprotocol.io/docs/getting-started/intro)
