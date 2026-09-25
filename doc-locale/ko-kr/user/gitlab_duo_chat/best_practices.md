---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Chat 모범 사례
---

GitLab Duo Chat에 질문할 때 다음 모범 사례를 적용하여 구체적인 예시와 구체적인 지도를 받으세요.

## 대화 나누기 {#have-a-conversation}

채팅을 검색 양식이 아닌 대화처럼 다루세요. 검색과 유사한 질문으로 시작한 다음, 범위를 좁히기 위해 관련 질문으로 후속 질문을 하세요. 앞뒤로 대화하며 컨텍스트를 구축하세요.

예를 들어 다음과 같이 질문할 수 있습니다:

```plaintext
c# start project best practices
```

그 다음으로 다음과 같이 후속 질문을 하세요:

```plaintext
Please show the project structure for the C# project.
```

GitLab Duo Agentic Chat을 사용하면 여러 프로젝트를 포함하는 대화를 나눌 수 있습니다.

```plaintext
Tell me the difference between project A and project B.
```

## 프롬프트 개선하기 {#refine-the-prompt}

더 나은 응답을 위해 미리 더 많은 컨텍스트를 제공하세요. 필요한 도움의 전체 범위를 생각해본 후 한 개의 프롬프트에 포함하세요.

```plaintext
How can I get started creating an empty C# console application in VS Code?
Please show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

또는 Agentic Chat을 사용하면:

```plaintext
Create an empty C# console application.
Show a .gitignore and .gitlab-ci.yml configuration with steps for C#,
and add security scanning for GitLab.
```

## 프롬프트 패턴 따르기 {#follow-prompt-patterns}

프롬프트를 문제 설명, 도움 요청, 그 다음 구체성 추가로 구조화하세요. 처음부터 모든 것을 물어봐야 한다고 느끼지 마세요.

```plaintext
I need to fulfill compliance requirements. How can I get started with Codeowners and approval rules?
```

그 다음으로 다음과 같이 질문하세요:

```plaintext
Please show an example for Codeowners with different teams: backend, frontend, release managers.
```

또는 Agentic Chat을 사용하면:

```plaintext
Create Codeowners with different teams: backend, frontend, release managers.

The group names are "backend-dev," "frontend-dev," and "release-man."
```

## 저컨텍스트 커뮤니케이션 사용하기 {#use-low-context-communication}

코드가 선택되었더라도 아무것도 보이지 않는 것처럼 컨텍스트를 제공하세요. 언어, 프레임워크, 요구 사항 같은 요소에 대해 구체적으로 말하세요.

```plaintext
When implementing a pure virtual function in an inherited C++ class,
should I use virtual function override, or just function override?
```

Agentic Chat을 사용할 때는 여러 소스에서 자동으로 검색하고 검색하며 정보를 결합하므로 이 컨텍스트가 덜 중요합니다. 그러나 Chat이 최대한 효율적으로 작동하도록 도우려면 여전히 명확해야 합니다.

## 반복하기 {#repeat-yourself}

예상치 못한 이상한 응답을 받으면 질문을 다시 표현해보세요. 더 많은 컨텍스트를 추가하세요.

```plaintext
How can I get started creating an C# application in VS Code?
```

그 다음으로 다음과 같이 후속 질문을 하세요:

```plaintext
How can I get started creating an empty C# console application in VS Code?
```

또는 Agentic Chat을 사용하면:

```plaintext
Create an empty C# console application in my test project.
```

## 인내심 유지하기 {#be-patient}

예/아니오 질문을 피하세요. 일반적으로 시작한 다음 필요에 따라 구체적인 내용을 제공하세요.

```plaintext
Explain labels in GitLab. Provide an example for efficient usage with issue boards.
```

## 필요할 때 초기화하기 {#reset-when-needed}

Chat이 잘못된 방향으로 고착되면 `/reset`을 사용하세요.

## 슬래시 명령어 프롬프트 개선하기 {#refine-slash-command-prompts}

기본 슬래시 명령어를 넘어서세요. 더 구체적인 제안과 함께 슬래시 명령어를 사용하세요.

```plaintext
/refactor into a multi-line written string. Show different approaches for all C++ standards.
```

또는:

```plaintext
/explain why this code has multiple vulnerabilities
```

슬래시 명령어는 여전히 Agentic Chat에 작동하지만, GitLab Duo Non-Agentic Chat만큼 중요하지 않습니다. Chat에 코드를 설명하거나 리팩터링하도록 요청할 수 있으며, 프로젝트 전체를 검색하고, 파일을 생성 및 편집하며, 여러 소스의 정보를 동시에 분석할 수 있습니다.

## 관련 항목 {#related-topics}

- GitLab Duo Chat 모범 사례 [블로그 게시물](https://about.gitlab.com/blog/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)
- [Chat 사용 방법 관련 동영상](https://www.youtube.com/playlist?list=PL05JrBw4t0Kp5uj_JgQiSvHw1jQu0mSVZ)
- [GitLab Duo Chat 학습 세션 요청](https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/476)
