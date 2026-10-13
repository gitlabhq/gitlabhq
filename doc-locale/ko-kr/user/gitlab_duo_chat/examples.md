---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Chat 질문하기
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../gitlab_duo/model_selection.md#default-models)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.6에서 기본 LLM을 Claude Sonnet 4.5로 업데이트했습니다.
- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

GitLab Duo Chat은 다음을 포함한 다양한 작업을 수행하는 데 도움이 될 수 있습니다:

- 코드, 오류 및 GitLab 기능에 대한 설명을 얻습니다.
- 코드를 생성하거나 리팩터링하고, 테스트를 작성하며, 문제를 해결합니다.
- CI/CD 구성을 생성하고 작업 실패를 문제 해결합니다.
- 이슈, 에픽 및 머지 리퀘스트를 요약합니다.
- 보안 취약성을 해결합니다.

[슬래시 명령어](#gitlab-duo-chat-slash-commands)를 포함한 이 페이지의 예제는 의도적으로 일반적입니다. Chat에서 현재 목표에 특정한 질문을 하면 더 유용한 응답을 받을 수 있습니다. 예를 들어, `How does the clean_missing_data function in data_cleaning.py decide which rows to drop?`입니다.

추가 실용적인 예제는 [GitLab Duo 사용 사례](../gitlab_duo/use_cases.md)를 참조하세요.

## Chat 기능에서 크레딧 사용 {#use-of-credits-with-chat-features}

다음 Chat 기능은 [GitLab Credits](../../subscriptions/gitlab_credits.md)를 소비하는 에이전트 버전과 GitLab Credits을 소비하지 않는 비에이전트 버전이 있습니다:

- 선택한 코드를 설명합니다.
- 근본 원인 분석으로 실패한 CI/CD 작업을 문제 해결합니다.
- 취약성을 설명합니다.
- GitLab UI의 슬래시 명령어입니다.

에이전트 Chat과 비에이전트 Chat 모두에 액세스할 수 있는 경우, 기본 기능 버전은 사용하는 도구에 따라 달라집니다:

- GitLab UI에서는 기본 Chat 버전이 GitLab Duo 사이드바에서 마지막으로 선택한 버전입니다.
- 지원되는 IDE에서는 기본 Chat 버전이 설정에 따라 결정됩니다.

에이전트 Chat에 액세스할 수 없으므로 GitLab Duo 에이전트 플랫폼에 액세스할 수 없으면, 기능 버전이 비에이전트 버전으로 기본 설정됩니다.

## GitLab에 대해 질문하기 {#ask-about-gitlab}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.0에서 GitLab Self-Managed에 대해 문서 관련 질문을 하는 기능을 도입했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/451215) [기능 플래그](../../administration/feature_flags/_index.md) `ai_gateway_docs_search` 기본적으로 활성화됨.
- [GitLab 17.1에서 일반 공개되고 기능 플래그가 제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154876).
- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

GitLab의 작동 방식에 대한 질문을 할 수 있습니다. 예를 들면:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

GitLab Duo Chat은 [GitLab 리포지토리](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)의 GitLab 문서를 소스로 사용합니다.

Chat을 문서와 최신 상태로 유지하기 위해 지식 기반은 매일 업데이트됩니다.

- GitLab.com에서는 가장 최근 버전의 문서가 사용됩니다.
- GitLab Self-Managed 및 GitLab Dedicated에서는 인스턴스 버전의 문서가 사용됩니다.

## 특정 이슈에 대해 질문하기 {#ask-about-a-specific-issue}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

특정 GitLab 이슈에 대해 질문할 수 있습니다. 예를 들어:

- `Generate a summary for the issue identified via this link: <link to your issue>`
- GitLab에서 이슈를 보고 있을 때 다음과 같이 물을 수 있습니다 `Generate a concise summary of the current issue.`
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

> [!note]
> 이슈에 대량의 텍스트(40,000단어 이상)가 포함된 경우 GitLab Duo Chat은 모든 단어를 고려하지 못할 수도 있습니다. AI 모델은 한 번에 처리할 수 있는 입력량에 제한이 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab Duo Chat으로 이슈 및 에픽의 생산성을 향상시키는 방법에 대한 팁은 [GitLab Duo Chat으로 생산성 향상](https://youtu.be/RJezT5_V6dI)을 참조하세요.
<!-- Video published on 2024-04-17 -->

## 특정 에픽에 대해 질문하기 {#ask-about-a-specific-epic}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

특정 GitLab 에픽에 대해 질문할 수 있습니다. 예를 들어:

- `Generate a summary for the epic identified via this link: <link to your epic>`
- GitLab에서 에픽을 보고 있을 때 다음과 같이 물을 수 있습니다 `Generate a concise summary of the opened epic.`
- `What are the unique use cases raised by commenters in <link to your epic>?`

> [!note]
> 에픽에 대량의 텍스트(40,000단어 이상)가 포함된 경우 GitLab Duo Chat은 모든 단어를 고려하지 못할 수도 있습니다. AI 모델은 한 번에 처리할 수 있는 입력량에 제한이 있습니다.

## 특정 머지 리퀘스트에 대해 질문하기 {#ask-about-a-specific-merge-request}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- 편집기: GitLab UI

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/464587).
- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

보고 있는 머지 리퀘스트에 대해 GitLab에 질문할 수 있습니다. 다음에 대해 질문할 수 있습니다:

- 제목 또는 설명입니다.
- 댓글 및 스레드입니다.
- **변경사항** 탭의 내용입니다.
- 레이블, 소스 브랜치, 작성자, 마일스톤 등의 메타데이터입니다.

머지 리퀘스트를 열고 Chat에 질문을 입력합니다. 예를 들어:

- `Why was the .vue file changed?`
- `What do the reviewers say about this merge request?`
- `How can this merge request be improved?`
- `Which files and changes should I review first?`

## 특정 커밋에 대해 질문하기 {#ask-about-a-specific-commit}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- 편집기: GitLab UI

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/468460)되었습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

특정 GitLab 커밋에 대해 질문할 수 있습니다. 예를 들어:

- `Generate a summary for the commit identified with this link: <link to your commit>`
- `How can I improve the description of this commit?`
- GitLab에서 커밋을 보고 있을 때 다음과 같이 물을 수 있습니다 `Generate a summary of the current commit.`

## 특정 파이프라인 작업에 대해 질문하기 {#ask-about-a-specific-pipeline-job}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- 편집기: GitLab UI

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/468461)되었습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

특정 GitLab 파이프라인 작업에 대해 질문할 수 있습니다. 예를 들어:

- `Generate a summary for the pipeline job identified via this link: <link to your pipeline job>`
- `Can you suggest ways to fix this failed pipeline job?`
- `What are the main steps executed in this pipeline job?`
- GitLab에서 파이프라인 작업을 보고 있을 때 다음과 같이 물을 수 있습니다 `Generate a summary of the current pipeline job.`

## 특정 작업 항목에 대해 질문하기 {#ask-about-a-specific-work-item}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194302)되었습니다.

{{< /history >}}

특정 GitLab 작업 항목에 대해 질문할 수 있습니다. 예를 들어:

- `Generate a summary for the work item identified via this link: <link to your work item>`
- GitLab에서 작업 항목을 보고 있을 때 다음과 같이 물을 수 있습니다 `Generate a concise summary of the current work item.`
- `How can I improve the description of <link to your work item> so that readers understand the value and problems to be solved?`

> [!note]
> 작업 항목에 대량의 텍스트(40,000단어 이상)가 포함된 경우 GitLab Duo Chat은 모든 단어를 고려하지 못할 수도 있습니다. AI 모델은 한 번에 처리할 수 있는 입력량에 제한이 있습니다.

## 선택한 코드 설명 {#explain-selected-code}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기 - GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

GitLab Duo Chat에 선택한 코드를 설명하도록 요청할 수 있습니다:

1. IDE에서 코드를 선택합니다.
1. GitLab Duo Chat에서 `/explain`을(를) 입력합니다.

   ![/explain 슬래시 명령어를 사용하여 코드를 선택하고 GitLab Duo Chat에 설명을 요청합니다.](img/code_selection_duo_chat_v17_4.png)

고려할 추가 지침을 추가할 수도 있습니다. 예를 들어:

- `/explain the performance`
- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance` (클래스, 객체 지향)
- `/explain why a static variable is used here` (C++)
- `/explain how this function would cause a segmentation fault` (C)
- `/explain how concurrency works in this context` (Go)
- `/explain how the request reaches the client` (REST API, 데이터베이스)

자세한 정보는 다음을 참조하세요.

- [VS Code에서 GitLab Duo Chat 사용](_index.md#use-gitlab-duo-chat-in-vs-code).
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo를 사용한 애플리케이션 현대화 (C++ to Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z).
  <!-- Video published on 2025-03-18 -->

GitLab UI에서 다음 항목의 코드를 설명할 수도 있습니다:

- [파일](../project/repository/code_explain.md).
- [머지 리퀘스트](../project/merge_requests/changes.md#explain-code-in-a-merge-request).

## 코드 요청 또는 생성 {#ask-about-or-generate-code}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

해당 코드를 Chat 창에 붙여넣어 GitLab Duo Chat에 코드에 대한 질문을 할 수 있습니다. 예를 들어:

```plaintext
Provide a clear explanation of this Ruby code: def sum(a, b) a + b end.
Describe what this code does and how it works.
```

Chat에 코드 생성을 요청할 수도 있습니다. 예를 들어:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a regular expression for parsing IPv4 and IPv6 addresses in Python.`
- `Generate code for parsing a syslog log file in Java. Use regular expressions when possible, and store the results in a hash map.`
- `Create a product-consumer example with threads and shared memory in C++. Use atomic locks when possible.`
- `Generate Rust code for high performance gRPC calls. Provide a source code example for a server and client.`

## 후속 질문 질문하기 {#ask-follow-up-questions}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

후속 질문을 하여 주제 또는 작업을 더 깊이 있게 탐색할 수 있습니다. 이를 통해 추가 설명, 상세 설명 또는 추가 지원 여부와 관계없이 특정 요구 사항에 맞는 더 자세하고 정확한 응답을 얻을 수 있습니다.

`Write a Ruby function that prints 'Hello, World!' when called` 질문에 대한 후속 질문은 다음과 같을 수 있습니다:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

`How to start a C# project?` 질문에 대한 후속 질문은 다음과 같을 수 있습니다:

- `Can you also explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

## 오류에 대해 질문하기 {#ask-about-errors}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

소스 코드를 컴파일해야 하는 프로그래밍 언어는 암호화된 오류 메시지를 발생시킬 수 있습니다. 마찬가지로 스크립트 또는 웹 애플리케이션은 스택 추적을 발생시킬 수 있습니다. 복사한 오류 메시지 앞에 `Explain this error message:`을(를) 붙여서 GitLab Duo Chat에 물을 수 있습니다. 프로그래밍 언어와 같은 특정 컨텍스트를 추가합니다.

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

## IDE의 특정 파일에 대해 질문하기 {#ask-about-specific-files-in-the-ide}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.7에서 도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/477258) [기능 플래그](../../administration/feature_flags/_index.md) `duo_additional_context` 및 `duo_include_context_file` 이름입니다. 기본적으로 사용 중지됩니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- [GitLab 17.9에서 GitLab.com 및 GitLab Self-Managed에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/15183).
- GitLab 18.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188613)하게 되었습니다. 모든 기능 플래그가 제거되었습니다.
- GitLab 18.0에서 GitLab Duo Core 추가 기능을 포함하도록 변경되었습니다.

{{< /history >}}

지원되는 IDE에서 `/include`을(를) 입력하고 파일을 선택하여 GitLab Duo Chat 대화에 리포지토리 파일을 추가합니다.

사전 요구 사항:

- 파일은 리포지토리의 일부여야 합니다.
- 파일은 텍스트 기반이어야 합니다. PDF 또는 이미지와 같은 이진 파일은 지원되지 않습니다.

이렇게 하려면 다음을 수행합니다.

1. IDE의 GitLab Duo Chat에서 `/include`을(를) 입력합니다.
1. 파일을 추가하려면 다음 중 하나를 수행할 수 있습니다:
   - 목록에서 파일을 선택합니다.
   - 파일 경로를 입력합니다.

예를 들어 전자 상거래 앱을 개발하는 경우 `cart_service.py` 및 `checkout_flow.js` 파일을 Chat의 컨텍스트에 추가하고 다음과 같이 물을 수 있습니다:

- `How does checkout_flow.js interact with cart_service.py? Generate a sequence diagram using Mermaid.`
- `Can you extend the checkout process by showing products related to the ones in the user's cart? I want to move the checkout logic to the backend before proceeding. Generate the Python backend code and change the frontend code to work with the new backend.`

> [!note]
> [Quick Chat](_index.md#in-an-editor-window)을(를) 사용하여 파일을 추가하거나 Chat 컨텍스트에 추가된 파일에 대한 질문을 할 수 없습니다.

## IDE에서 코드 리팩터링 {#refactor-code-in-the-ide}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기 - GitLab Duo Non-Agentic Chat: Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

GitLab Duo Chat에 선택한 코드를 리팩터링하도록 요청할 수 있습니다:

1. IDE에서 코드를 선택합니다.
1. GitLab Duo Chat에서 `/refactor`을(를) 입력합니다.

고려할 추가 지침을 포함할 수 있습니다. 예를 들어:

- 특정 코딩 패턴(예: `/refactor with ActiveRecord` 또는 `/refactor into a class providing static functions`)을 사용합니다.
- 특정 라이브러리(예: `/refactor using mysql`)를 사용합니다.
- 특정 함수/알고리즘(예: C++의 `/refactor into a stringstream with multiple lines`)을 사용합니다.
- 다른 프로그래밍 언어로 리팩터링(예: `/refactor to TypeScript`)합니다.
- 성능에 중점을 두고(예: `/refactor improving performance`) 있습니다.
- 잠재적 취약성(예: `/refactor avoiding memory leaks and exploits`)에 중점을 두고 있습니다.

`/refactor`은(는) [리포지토리 X-Ray](../project/repository/code_suggestions/repository_xray.md)를 사용하여 더 정확하고 컨텍스트 인식 제안을 제공합니다.

자세한 정보는 다음을 참조하세요.

- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo를 사용한 애플리케이션 현대화 (C++ to Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z).
  <!-- Video published on 2025-03-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [개요 보기](https://youtu.be/oxziu7_mWVk?si=fS2JUO-8doARS169)

## IDE에서 코드 수정 {#fix-code-in-the-ide}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기 - GitLab Duo Non-Agentic Chat: Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.3에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated용 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/429915).
- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

GitLab Duo Chat에 선택한 코드를 수정하도록 요청할 수 있습니다:

1. IDE에서 코드를 선택합니다.
1. GitLab Duo Chat에서 `/fix`을(를) 입력합니다.

고려할 추가 지침을 포함할 수 있습니다. 예를 들어:

- 문법 및 오타(예: `/fix grammar mistakes and typos`)에 중점을 두고 있습니다.
- 구체적인 알고리즘 또는 문제 설명(예: `/fix duplicate database inserts` 또는 `/fix race conditions`)에 중점을 두고 있습니다.
- 직접 표시되지 않는 잠재적 버그(예: `/fix potential bugs`)에 중점을 두고 있습니다.
- 코드 성능 문제(예: `/fix performance problems`)에 중점을 두고 있습니다.
- 코드가 컴파일되지 않을 때 빌드 수정(예: `/fix the build`)에 중점을 두고 있습니다.

`/fix`은(는) [리포지토리 X-Ray](../project/repository/code_suggestions/repository_xray.md)를 사용하여 더 정확하고 컨텍스트 인식 제안을 제공합니다.

## IDE에서 테스트 작성 {#write-tests-in-the-ide}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기 - GitLab Duo Non-Agentic Chat: Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

GitLab Duo Chat에 선택한 코드에 대한 테스트를 생성하도록 요청할 수 있습니다:

1. IDE에서 코드를 선택합니다.
1. GitLab Duo Chat에서 `/tests`을(를) 입력합니다.

고려할 추가 지침을 포함할 수 있습니다. 예를 들어:

- 특정 테스트 프레임워크(예: `/tests using the Boost.test framework` (C++) 또는 `/tests using Jest` (JavaScript))를 사용합니다.
- 극단적인 테스트 사례(예: `/tests focus on extreme cases, force regression testing`)에 중점을 두고 있습니다.
- 성능에 중점을 두고(예: `/tests focus on performance`) 있습니다.
- 회귀 및 잠재적 악용(예: `/tests focus on regressions and potential exploits`)에 중점을 두고 있습니다.

`/tests`은(는) [리포지토리 X-Ray](../project/repository/code_suggestions/repository_xray.md)를 사용하여 더 정확하고 컨텍스트 인식 제안을 제공합니다.

자세한 내용은 [VS Code에서 GitLab Duo Chat 사용](_index.md#use-gitlab-duo-chat-in-vs-code)을(를) 참조하세요.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 보기](https://www.youtube.com/watch?v=zWhwuixUkYU)

## CI/CD에 대해 질문하기 {#ask-about-cicd}

{{< details >}}

- 추가 기능: GitLab Duo Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- GitLab 17.2에서 [LLM을 Claude 2.1에서 Claude 3 Sonnet으로 업데이트했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149619).
- GitLab 17.2에서 [LLM을 Claude 3 Sonnet에서 Claude 3.5 Sonnet으로 업데이트했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157696).
- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 17.10에서 [LLM을 Claude 3.5 Sonnet에서 Claude 4.0 Sonnet으로 업데이트했습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/521034).

{{< /history >}}

GitLab Duo Chat에 CI/CD 구성을 생성하도록 요청할 수 있습니다:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

오류 메시지를 복사해서 붙여넣고 `Explain this CI/CD job error message, in the context of <language>:`을(를) 앞에 붙여 특정 작업 오류를 설명하도록 요청할 수도 있습니다:

- `Explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

또는 GitLab Duo Root Cause Analysis를 사용하여 [실패한 CI/CD 작업을 문제 해결](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)할 수 있습니다.

## 근본 원인 분석으로 실패한 CI/CD 작업 문제 해결 {#troubleshoot-failed-cicd-jobs-with-root-cause-analysis}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기: GitLab UI
- 기본 LLM: Anthropic [Claude Sonnet 4.0](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.3에서 [일반 공개되고 GitLab Duo Chat으로 옮겨졌습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/441681).
- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.
- GitLab 17.7에서 머지 리퀘스트용 실패한 작업 위젯 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174586).
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

GitLab Duo Root Cause Analysis를 GitLab Duo Chat에서 사용하여 CI/CD 작업 실패를 빠르게 식별하고 수정할 수 있습니다. 작업 로그의 마지막 100,000자를 분석하여 실패 원인을 파악하고 수정 예제를 제공합니다.

머지 리퀘스트의 **파이프라인** 탭이나 작업 로그에서 직접 이 기능에 액세스할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 보기](https://www.youtube.com/watch?v=MLjhVbMjFAY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

근본 원인 분석은 지원하지 않습니다:

- 트리거 작업
- 다운스트림 파이프라인

근본 원인 분석은 GitLab Duo 에이전트 플랫폼과 별개의 GitLab Duo Chat 환경입니다. GitLab Duo Chat이 인스턴스에 대해 비활성화된 경우, 에이전트 플랫폼을 사용할 수 있더라도 문제 해결 옵션이 나타나지 않습니다. 파이프라인을 자동으로 수정하려면 [Fix CI/CD Pipeline 플로우](../duo_agent_platform/flows/foundational_flows/fix_pipeline.md)를 참조하세요.

[epic 13872](https://gitlab.com/groups/gitlab-org/-/epics/13872)에서 이 기능에 대한 피드백을 제공하세요.

사전 요구 사항:

- CI/CD 작업을 볼 수 있는 권한이 있어야 합니다.

### 머지 리퀘스트에서 {#from-a-merge-request}

머지 리퀘스트에서 실패한 CI/CD 작업을 문제 해결하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 머지 리퀘스트로 이동합니다.
1. **파이프라인** 탭을 선택합니다.
1. 실패한 작업 위젯에서 다음 중 하나를 수행합니다:
   - 작업 ID를 선택하여 작업 로그로 이동합니다.
   - **문제 해결**을(를) 선택하여 실패를 직접 분석합니다.

### 작업 로그에서 {#from-the-job-log}

작업 로그에서 실패한 CI/CD 작업을 문제 해결하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **작업**을(를) 선택합니다.
1. 실패한 CI/CD 작업을 선택합니다.
1. 작업 로그 아래에서 다음 중 하나를 수행합니다:
   - **문제 해결**을(를) 선택합니다.
   - GitLab Duo Chat을 열고 `/troubleshoot`을(를) 입력합니다.

### 보안 구성 페이지에서 {#from-the-security-configuration-page}

보안 구성 페이지에서 실패한 스캐너 작업을 문제 해결하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **스캔 프로필** 섹션에서 실패 상태의 스캐너를 찾습니다.
1. 다음 옵션 중 하나를 완료하여 작업 세부 정보 서랍을 엽니다:
   - **마지막 스캔** 열 위로 마우스를 올려 작업 세부 정보 팝오버를 열고 **문제해결 실패**를 선택합니다.
   - 스캐너 옆에 있는 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **문제해결 실패**를 선택합니다.
1. 서랍 바닥글에서 **문제해결 실패** ({{< icon name="tanuki-ai" >}})를 선택합니다.

## 취약성 설명 {#explain-a-vulnerability}

{{< details >}}

- 티어:  Ultimate
- 추가 기능: GitLab Duo Enterprise, GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="편집기 및 모델 정보" >}}

- 편집기: GitLab UI
- 기본 LLM: Anthropic [Claude Sonnet 4.5](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4-5)
- Amazon Q용 LLM: Amazon Q Developer
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.

{{< /history >}}

SAST 취약성 보고서를 보고 있을 때 GitLab Duo Chat에 취약성을 설명하도록 요청할 수 있습니다.

자세한 내용은 [취약성 설명](../application_security/analyze/duo.md)을(를) 참조하세요.

## GitLab Duo Chat 슬래시 명령어 {#gitlab-duo-chat-slash-commands}

GitLab Duo Chat에는 슬래시(`/`)로 시작하는 범용, GitLab UI 및 IDE 명령어 목록이 있습니다.

명령어를 사용하여 특정 작업을 빠르게 완료합니다.

### 범용 {#universal}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: GitLab UI, Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

| 명령 | 목적                                                                                                                       |
|---------|-------------------------------------------------------------------------------------------------------------------------------|
| /new    | 새 대화를 시작하되 이전 대화는 채팅 기록에 유지합니다.      |
| /reset  | 채팅 창을 지우고 대화를 재설정합니다.                                       |
| /help   | GitLab Duo Chat의 작동 방식에 대해 자세히 알아봅니다. GitLab Duo 에이전트 Chat에서는 사용할 수 없습니다.                                                                    |

> [!note]
> GitLab.com의 GitLab 17.10 이상에서 [여러 대화](_index.md#have-multiple-conversations)가 있을 때 `/clear` 및 `/reset` 슬래시 명령어는 [`/new` 슬래시 명령어](#gitlab-ui)로 바뀝니다.

### GitLab UI {#gitlab-ui}

{{< details >}}

- 추가 기능: GitLab Duo Enterprise
- 편집기: GitLab UI

{{< /details >}}

{{< history >}}

- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.

{{< /history >}}

이 명령어는 동적이며 GitLab Duo Chat을 사용할 때 GitLab UI에서만 사용할 수 있습니다. GitLab Duo 에이전트 Chat에서는 사용할 수 없습니다.

| 명령                | 목적                                                                                                            | 영역 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ---- |
| /summarize_comments    | 현재 이슈의 모든 댓글 요약을 생성합니다.                                               | 이슈 |
| /troubleshoot          | [근본 원인 분석으로 실패한 CI/CD 작업 문제 해결](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis). | 작업 |
| /vulnerability_explain | [현재 취약성 설명](../application_security/analyze/duo.md).                               | 취약성 |

### IDE {#ide}

{{< details >}}

- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise

{{< /details >}}

{{< collapsible title="편집기 정보" >}}

- GitLab Duo Non-Agentic Chat: Web IDE, VS Code, JetBrains IDE, Visual Studio 및 Eclipse

{{< /collapsible >}}

{{< history >}}

- [GitLab 17.9에서 활성화되었습니다](https://gitlab.com/groups/gitlab-org/-/work_items/15227) [자체 호스팅된 모델 구성](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)은 물론 [기본 GitLab 외부 AI 공급업체 구성](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)에 대해서도.
- GitLab 18.0에서 GitLab Duo Core 애드온을 포함하도록 변경됨.

{{< /history >}}

이 명령어는 지원되는 IDE에서 GitLab Duo Chat을 사용할 때만 작동합니다:

| 명령   | 목적                                           |
|-----------|---------------------------------------------------|
| /tests    | [테스트 작성](#write-tests-in-the-ide)            |
| /explain  | [코드 설명](#explain-selected-code)            |
| /refactor | [코드 리팩터링](#refactor-code-in-the-ide)    |
| /fix      | [코드 수정](#fix-code-in-the-ide)              |
| /include  | [파일 컨텍스트 포함](#ask-about-specific-files-in-the-ide) <sup>1</sup> |

**각주**:

1. Web IDE에서 GitLab Duo Non-Agentic Chat을 사용할 때는 사용할 수 없습니다.
