---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Developer 플로우
---

{{< details >}}

- 계층:  [무료](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [베타](../../../../policy/development_stages_support.md) 로 도입되었습니다. [플래그](../../../../administration/feature_flags/_index.md) 이름: `duo_workflow_in_ci` 기본적으로 사용 중지되어 있으나, 인스턴스 또는 사용자에 대해 활성화할 수 있습니다.
- `Issue to MR`에서 `Developer Flow`로 변경되었으며, GitLab 18.6에서 `duo_developer_button` 플래그를 사용합니다. 기본적으로 사용 중지되어 있으나, 인스턴스 또는 사용자에 대해 활성화할 수 있습니다. 기능 플래그 `duo_workflow`도 활성화해야 하지만, 기본적으로 활성화되어 있습니다.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다.
- 기능 플래그 `duo_workflow_in_ci`, `duo_developer_button`, `duo_workflow`은 GitLab 18.9에서 제거되었습니다.
- GitLab 18.10에서 GitLab.com의 무료 티어에서 GitLab Credits를 사용하여 사용 가능합니다.
- 언급 트리거는 GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)되었습니다.

{{< /history >}}

Developer 플로우는 이슈 및 머지 리퀘스트 전반에서 더 효율적으로 작업할 수 있도록 도와줍니다. Developer 플로우를 사용하여 다음을 수행할 수 있습니다:

- 이슈에서 초안 머지 리퀘스트를 생성합니다.
- 리뷰 피드백을 기반으로 기존 머지 리퀘스트에서 반복합니다.
- 구현 방식을 조사하고 의견을 토론에 게시합니다.
- 대규모 머지 리퀘스트를 더 작고 집중된 머지 리퀘스트로 분할합니다.
- 머지 충돌을 해결합니다.

## 필수 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform의 사전 요구사항](../../_index.md#prerequisites)을 충족합니다.
- **기본 플로우 허용** 및 **개발자** [최상위 그룹의](_index.md#turn-foundational-flows-on-or-off)를 활성화합니다.
- 프로젝트에 대한 개발자, 유지관리자 또는 소유자 역할이 있습니다.
- [서비스 계정을 허용하도록 푸시 규칙 구성](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account)
- [자신의 러너 구성](../execution.md#configure-runners) 또는 프로젝트에 대해 [GitLab 호스팅 러너](../../../../ci/runners/hosted_runners/_index.md)를 활성화합니다.

## 프로젝트 설정 {#set-up-your-project}

Developer 플로우가 더 나은 결과를 생성하도록 하려면, 다음 선택 사항 설정으로 프로젝트를 구성해야 합니다:

- `AGENTS.md` 파일 추가:  테스트 명령, 린팅 규칙, 커밋 형식 및 코딩 패턴 같은 프로젝트 규칙을 문서화합니다. Developer 플로우는 리포지토리에서 작업할 때 이 파일을 컨텍스트로 사용합니다. 자세한 내용은 [AGENTS.md 사용자 지정 파일](../../customize/agents_md.md)을 참조하세요.
- 실행 환경 구성:  프로젝트에 특정 도구(예: Go, Python 또는 Node.js)가 필요한 경우, `agent-config.yml` 파일로 에이전트 환경을 구성합니다. 적절히 구성된 환경에서 Developer 플로우는 테스트를 실행하고 커밋하기 전에 자체 변경 사항을 확인할 수 있습니다. 자세한 내용은 [플로우 실행 구성](../execution.md)을 참조하세요.

## 플로우 사용 {#use-the-flow}

전제 조건:

- 이벤트 유형 **언급** 및 **할당**은 Developer 플로우의 트리거에서 [구성](../../triggers/_index.md)됩니다.

### 토론에서 Duo Developer 언급 {#mention-duo-developer-in-a-discussion}

의견을 Developer 플로우의 실행 가능한 작업으로 전환하려면, 토론에서 `@duo-developer-<namespace>`으로 언급합니다. `<namespace>`을 GitLab 네임스페이스 경로로 바꿉니다(예: `gitlab-org`).

이슈 또는 머지 리퀘스트 콘텐츠 및 제공하는 컨텍스트의 양에 따라, 플로우는 다음 작업을 실행할 수 있습니다:

- 코드 변경
- 머지 리퀘스트 및 이슈 생성
- 구현 방식을 조사하고 결과를 보고하거나 그에 따라 업데이트합니다

예를 들어:

```plaintext
@duo-developer-<namespace> research approaches for implementing pagination
on the /users endpoint, then create a draft MR with the most
promising approach.
```

Developer 플로우는 해당 세션에 대한 링크로 응답합니다.

또는 진행 상황을 모니터링하려면 왼쪽 사이드바에서 **AI** > **세션**을 선택합니다.

### 이슈에서 머지 리퀘스트 생성 {#generate-a-merge-request-from-an-issue}

이슈에서 머지 리퀘스트를 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **계획** > **작업 항목**을 선택한 다음, **유형** = **이슈**로 필터링합니다.
1. 머지 리퀘스트를 생성할 이슈를 선택합니다.
1. 이슈에서 머지 리퀘스트를 생성하려면, 다음 중 하나를 수행합니다:
   - 이슈에 Duo Developer 서비스 계정을 할당합니다:
     1. 오른쪽 사이드바의 **담당자** 섹션에서 **편집**을 선택합니다.
     1. `duo developer`을 입력하고 검색 결과에서 선택합니다.
   - 이슈 헤더 아래에서 **GitLab Duo를 사용하여 머지 리퀘스트 생성**을 선택합니다.
1. 선택사항. 플로우의 진행 상황을 모니터링하려면, 왼쪽 사이드바에서 **AI** > **세션**을 선택합니다.
1. 세션이 완료되면, 이슈의 **활동** 섹션의 링크에서 머지 리퀘스트를 검토합니다.

## 모범 사례 {#best-practices}

### 명확한 컨텍스트 제공 {#provide-clear-context}

Developer 플로우는 사용자가 알려주거나 이슈, 머지 리퀘스트 또는 토론 스레드의 컨텍스트에서 사용 가능한 내용만 알 수 있습니다. 인간 협력자를 돕는 것과 동일한 관행이 여기에 적용됩니다:

- 관련 파일 또는 토론에 대한 링크가 있는 명확한 문제 설명을 작성하세요.
- "완료"가 어떤 모습인지 정의하는 수용 기준을 포함합니다.
- 알려진 경우 정확한 파일 경로를 지정합니다.
- 일관성을 유지하기 위해 기존 패턴의 코드 예제를 포함합니다.

### 토론에서 Duo Developer를 언급할 때 명시적 {#be-explicit-when-mentioning-duo-developer-in-discussions}

토론에서 Duo Developer를 언급할 때, 정확히 어떤 작업을 수행하고 싶은지 알려줍니다. 예를 들어:

- "`/api/users` 엔드포인트에 대한 페이지 매김을 구현하는 초안 머지 리퀘스트를 생성합니다."
- "이 머지 리퀘스트의 리뷰 피드백을 처리합니다."
- "로깅 변경 사항을 별도의 머지 리퀘스트로 분할합니다."
- "이 서비스를 gRPC로 마이그레이션하기 위한 방식을 조사하고 여기에 내 결과를 게시합니다."
- "이 머지 리퀘스트에 머지 충돌이 있습니다. 해결해 주세요."

명시적 지침이 없으면 플로우는 자체 방식을 선택하며, 이는 기대와 일치하지 않을 수 있습니다.

### 작업 집중 유지 {#keep-tasks-focused}

복잡한 작업을 더 작고, 집중된, 행동 지향적인 요청으로 분해합니다. 대규모 개방형 작업은 반복 제한에 도달할 가능성이 더 높습니다.

## 예제 {#examples}

### 머지 리퀘스트를 생성하기 위한 이슈 {#issue-for-generating-a-merge-request}

이 예제는 Developer 플로우가 머지 리퀘스트를 생성하는 데 사용할 수 있는 잘 만들어진 이슈를 보여줍니다.

```plaintext
## Description
The users endpoint currently returns all users at once,
which will cause performance issues as the user base grows.
Implement cursor-based pagination for the `/api/users` endpoint
to handle large datasets efficiently.

## Implementation plan
Add pagination to GET /users API endpoint.
Include pagination metadata in /users API response (per_page, page).
Add query parameters for per page size limit (default 5, max 20).

#### Files to modify
- `src/api/users.py` - Add pagination parameters and logic.
- `src/models/user.py` - Add pagination query method.
- `tests/api/test_users_api.py` - Add pagination tests.

## Acceptance criteria
- Accepts page and per_page query parameters (default: page=5, per_page=10).
- Limits per_page to a maximum of 20 users.
- Maintains existing response format for user objects in data array.
```

### 머지 리퀘스트 리뷰 피드백에 대해 반복 {#iterate-on-merge-request-review-feedback}

머지 리퀘스트를 검토한 후 Developer 플로우를 언급하여 피드백을 처리할 수 있습니다. 예를 들어, 특정 라인의 리뷰 의견에서:

```plaintext
@duo-developer-<namespace> move this validation logic into the `BaseService` class
in `app/services/base_service.rb` instead of duplicating it here.
```

전체 리뷰를 제출한 다음 Developer 플로우를 언급하여 모든 열린 스레드를 처리할 수도 있습니다:

```plaintext
@duo-developer-<namespace> please address the review feedback on this MR.
```

### 머지 리퀘스트 분할 {#split-a-merge-request}

머지 리퀘스트가 너무 커진 경우, Developer 플로우에 해당 부분을 별도의 머지 리퀘스트로 추출하도록 요청할 수 있습니다:

```plaintext
@duo-developer-<namespace> the logging changes in this MR are out of scope.
Split them into a separate MR.
```

### 구현 방식 조사 {#research-an-implementation-approach}

Developer 플로우에 문제를 조사하고 변경을 수행하기 전에 보고하도록 요청할 수 있습니다:

```plaintext
@duo-developer-<namespace> research whether the `PUT /api/users` endpoint also needs
rate limiting like we added to the `POST /api/users` endpoint.
Post your findings here.
```
