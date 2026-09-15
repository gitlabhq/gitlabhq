---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 병합 요청에 대한 관련 정보에 대해 AI 지원 기능을 사용합니다.
title: 병합 요청에 GitLab Duo
---

> [!disclaimer]

GitLab Duo는 병합 요청의 수명 주기 동안 상황에 맞는 관련 정보를 제공하도록 설계되었습니다.

## 코드 변경 사항을 요약하여 설명 생성 {#generate-a-description-by-summarizing-code-changes}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../../gitlab_duo/model_selection.md#default-models)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2에서 [실험적 기능](../../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10401)되었습니다.
- GitLab 16.10에서 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/429882)되었습니다.
- GitLab 17.6 이상에서 GitLab Duo 애드온을 요구하도록 변경되었습니다.
- LLM을 GitLab 17.10에서 Claude 3.7 Sonnet으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862)했습니다.
- GitLab 17.11에서 `add_ai_summary_for_new_mr` 기능 플래그는 [기본적으로 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108)되어 있습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.
- LLM을 GitLab 18.1에서 Claude 4.0 Sonnet으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193208)했습니다.

{{< /history >}}

병합 요청을 만들거나 편집할 때 GitLab Duo 병합 요청 요약을 사용하여 병합 요청 설명을 만듭니다.

1. [새 병합 요청을 만듭니다](creating_merge_requests.md).
1. **설명** 필드에서 설명을 삽입할 위치에 커서를 놓습니다.
1. 텍스트 영역 위의 도구 모음에서 **코드 변경 사항 요약**({{< icon name="tanuki-ai" >}})을 선택합니다.

   ![텍스트 영역 위의 도구 모음에 "코드 변경 사항 요약" 단추가 표시됩니다.](img/merge_request_ai_summary_v17_6.png)

설명이 커서가 있던 위치에 삽입됩니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 시청](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

[이슈 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236)에서 이 기능에 대한 피드백을 제공합니다.

데이터 사용: 소스 브랜치의 헤드와 대상 브랜치 간의 변경 사항 diff가 대규모 언어 모델로 전송됩니다.

## GitLab Duo를 사용하여 코드 검토 {#use-gitlab-duo-to-review-your-code}

GitLab Duo는 잠재적 오류에 대해 병합 요청을 검토하고 표준에 정렬에 대한 피드백을 제공할 수 있습니다.

GitLab Duo에 검토를 요청하면 추가 기능에 따라 두 가지 코드 검토 기능 중 하나가 자동으로 실행됩니다. 그룹의 소유자 역할을 가진 사용자는 모든 사용자에 대해 실행할 기능을 구성할 수 있습니다.

| 세부 정보              | [Code 검토 플로우](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md) | [GitLab Duo 코드 검토](../../gitlab_duo/code_review.md) |
|---------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------|
| 검토자            | `@GitLabDuo`                                                                         | `@GitLabDuo`                                              |
| 형식                | 에이전트 방식                                                                              | 비에이전트 방식                                               |
| 필수 추가 기능     | 없음. GitLab Credits를 사용합니다.                                                           | GitLab Duo Enterprise                                     |
| 상황 인식   | 리포지토리 구조 및 교차 파일 종속성에 대한 향상된 이해           | 병합 요청 및 그 안의 파일 diff에 초점을 맞춤 |
| 분석            | 다중 단계 에이전트 추론                                                         | 단일 패스                                               |
| 세션 만들기    | {{< yes >}}                                                                          | {{< no >}}                                                |
| 자동 검토   | {{< yes >}}                                                                          | {{< yes >}}                                               |
| 사용자 지정 안내 | {{< yes >}}                                                                          | {{< yes >}}                                               |
| 사용자 지정 댓글     | {{< yes >}}                                                                          | {{< yes >}}                                               |

### 실행할 검토 기능 결정 {#determine-which-review-feature-runs}

기본적으로 GitLab이 실행하는 코드 검토 기능은 검토를 시작하는 사용자에 따라 다릅니다.

| 검토 트리거                          | 검토를 시작하는 사용자                      |
|-----------------------------------------|--------------------------------------|
| 검토가 수동으로 요청됨               | 검토를 요청한 사용자입니다.    |
| 병합 요청 만듦(초안 아님)     | 병합 요청 작성자입니다.            |
| 초안 병합 요청이 준비 완료로 표시됨     | 병합 요청 작성자입니다.            |

검토를 시작하는 사용자에게 GitLab Duo Enterprise 사용자가 있으면 GitLab Duo 코드 검토가 실행됩니다. 그렇지 않으면 Code Review 플로우가 실행됩니다. 두 기능 모두 같은 프로젝트에서 실행될 수 있습니다.

그룹의 소유자 역할을 가진 사용자는 사용자 유형에 관계없이 [Code Review 플로우를 사용하도록 모든 검토를 구성](#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats)할 수 있습니다. Code Review 플로우가 실행되면 크레딧 사용이 검토를 시작한 사용자에게 귀속됩니다.

어떤 기능이 검토를 실행하는지 확인하려면 병합 요청의 작업 피드를 확인하세요. Code Review 플로우는 실행 시 검토 세션을 시작합니다. 검토 세션이 표시되지 않으면 GitLab Duo 코드 검토가 검토를 실행합니다.

![GitLab Duo에서 시작한 검토 세션을 보여주는 병합 요청 작업 피드입니다.](img/gitlab_duo_code_review_flow_session_v18_10.png)

검토가 완료된 후 [프로젝트의 세션](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project)에서 Code Review 플로우 세션을 찾을 수도 있습니다.

#### GitLab Duo Enterprise 사용자에 대해 Code Review 플로우 활성화 {#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats}

{{< history >}}

- GitLab 19.2에서 `duo_code_review_dap_routing_consent_enabled` [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240432)되었습니다. 기본적으로 사용으로 설정되어 있습니다.
- GitLab 19.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/602689)되었습니다. `duo_code_review_dap_routing_consent_enabled` 기능 플래그가 제거되었습니다.

{{< /history >}}

GitLab Duo Enterprise 사용자가 GitLab Credits를 사용하는 기능을 사용하지 못하도록 하기 위해 이들이 시작하는 모든 코드 검토는 기본적으로 GitLab Duo 코드 검토를 사용합니다. 이 동작은 소유자 역할을 가진 사용자가 그룹에 대해 Code Review 플로우를 활성화하는 경우에도 발생합니다.

이 기본값을 변경하고 사용자 유형에 관계없이 모든 코드 검토를 Code Review 플로우를 사용하도록 구성할 수 있습니다.

GitLab Duo Enterprise 사용자를 위한 기본 코드 검토 기능을 재정의하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

사전 요구 사항:

- 최상위 그룹의 소유자 역할입니다.
- 최상위 그룹에 대해 [Code 검토 플로우](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md#prerequisites)가 활성화 및 구성되어 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **플로우 실행** > **파운데이셔널 플로우 허용**에서 **Code Review 플로우** 확인란을 지운 후 다시 선택합니다.
1. 확인 대화 상자에서 **코드 검토 플로우 사용**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed and GitLab Dedicated" >}}

사전 요구 사항:

- 그룹에 대한 유지 관리자 또는 소유자 역할입니다.
- 인스턴스에 대해 [Code 검토 플로우](../../duo_agent_platform/flows/foundational_flows/code_review/_index.md#prerequisites)가 활성화 및 구성되어 있습니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **플로우 실행**에서 **코드 검토 플로우** 확인란을 지우고 **변경 사항 저장**을 선택합니다.
1. **GitLab Duo 기능**을 다시 확장하고 **플로우 실행** 아래에서 **코드 검토 플로우** 확인란을 선택합니다.
1. 확인 대화 상자에서 **코드 검토 플로우 사용**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

Code Review 플로우가 이제 그룹의 모든 코드 검토에 대해 실행되고 GitLab Credits를 사용합니다. 모든 검토를 GitLab Duo 코드 검토로 다시 전환하려면 Code Review 플로우를 끕니다.

## GitLab Duo를 사용하여 토론 해결 {#resolve-a-discussion-with-gitlab-duo}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.2에서 `resolve_discussion_with_duo` [기능 플래그](../../../administration/feature_flags/_index.md)의 [베타](../../../policy/development_stages_support.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/600990)되었습니다. 기본적으로 사용으로 설정되어 있습니다.
- GitLab 19.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/603482)되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요.

GitLab Duo를 사용하여 병합 요청의 검토 토론을 해결합니다.

GitLab Duo에 토론을 해결하도록 요청하면 검토 댓글과 주변 코드를 읽고 소스 브랜치에서 요청된 변경을 수행한 후 변경을 커밋하고 푸시합니다. 그런 다음 GitLab Duo는 변경 요약으로 토론에 회신하고 스레드를 해결합니다.

이 기능은 [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)에서 개발자 플로우를 사용합니다.

사전 요구 사항:

- 프로젝트에 대한 개발자, 유지 관리자 또는 소유자 역할이 있어야 합니다.
- [GitLab Duo Agent Platform의 필수 조건](../../duo_agent_platform/_index.md#prerequisites)입니다.
- **기본 플로우 허용** 및 **개발자**가 [최상위 그룹에 대해](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) 활성화되어 있습니다.
- [서비스 계정을 허용하도록 푸시 규칙 구성](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account)됨.
- [자신이 구성한 러너](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows) 또는 [GitLab에서 호스팅하는 러너](../../../ci/runners/hosted_runners/_index.md)가 프로젝트에 대해 활성화되어 있습니다.

GitLab Duo를 사용하여 토론을 해결하려면 다음을 수행합니다.

1. 병합 요청에서 해결되지 않은 토론으로 이동합니다.
1. **스레드 해결** 옆에서 **추가 해결 옵션**({{< icon name="chevron-down" >}})을 선택합니다.
1. **GitLab Duo와 함께 해결**을 선택합니다.

GitLab Duo는 [프로젝트의 세션](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project)에서 추적할 수 있는 세션을 시작합니다.

## 코드 검토 요약 {#summarize-a-code-review}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../../gitlab_duo/model_selection.md#default-models)
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0에서 [실험적 기능](../../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10466)되었습니다.
- GitLab 17.10에서 `summarize_my_code_review` 기능 플래그가 [기본적으로 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448)되었습니다.
- LLM을 GitLab 17.11에서 Claude 3.7 Sonnet으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873)했습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.
- LLM을 GitLab 18.1에서 Claude 4.0 Sonnet으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193685)했습니다.

{{< /history >}}

병합 요청의 검토를 완료했고 [검토를 제출](reviews/_index.md#submit-a-review)할 준비가 되었으면 GitLab Duo 코드 검토 요약을 사용하여 댓글 요약을 생성합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **병합 요청**를 선택하고 검토할 병합 요청을 찾습니다.
1. 검토를 제출할 준비가 되었으면 **검토 완료**를 선택합니다.
1. **요약 추가**를 선택합니다.

요약이 설명 상자에 표시됩니다. 검토를 제출하기 전에 요약을 편집하고 개선할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 시청](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

[이슈 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991)에서 이 실험 기능에 대한 피드백을 제공합니다.

데이터 사용: 이 기능을 사용하면 다음 데이터가 대규모 언어 모델로 전송됩니다.

- 초안 댓글의 텍스트

## 병합 커밋 메시지 생성 {#generate-a-merge-commit-message}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon Q용 LLM: Amazon Q 개발자
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2에서 `generate_commit_message_flag` [기능 플래그](../../../administration/feature_flags/_index.md)의 [실험적 기능](../../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10453)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 17.2에서 `generate_commit_message_flag` 기능 플래그가 [기본적으로 사용으로 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339)되었습니다.
- GitLab 17.7에서 `generate_commit_message_flag` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262)되었습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.
- LLM을 GitLab 18.1에서 Claude 4.0 Sonnet으로 [업데이트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793)했습니다.
- GitLab 18.3에서 Amazon Q 지원으로 변경되었습니다.

{{< /history >}}

병합 요청을 병합할 준비를 할 때 GitLab Duo 병합 커밋 메시지 생성을 사용하여 제안된 병합 커밋 메시지를 편집합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **병합 요청**를 선택하고 병합 요청을 찾습니다.
1. 병합 위젯에서 **커밋 메시지 수정** 확인란을 선택합니다.
1. **커밋 메시지 생성**을 선택합니다.
1. 제공된 커밋 메시지를 검토하고 **삽입**을 선택하여 커밋에 추가합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 시청](https://www.youtube.com/watch?v=fUHPNT4uByQ)

데이터 사용: 이 기능을 사용하면 다음 데이터가 대규모 언어 모델로 전송됩니다.

- 파일의 내용
- 파일명

## 관련 항목 {#related-topics}

- [GitLab Duo 가용성 제어](../../gitlab_duo/turn_on_off.md)
- [모든 GitLab Duo 기능](../../gitlab_duo/_index.md)
- [GitLab Duo를 사용하여 병합 충돌 해결](conflicts.md#resolve-conflicts-with-gitlab-duo)

## 문제 해결 {#troubleshooting}

병합 요청에서 GitLab Duo를 사용할 때 다음 문제가 발생할 수 있습니다.

### 응답을 받지 못함 {#response-not-received}

`@GitLabDuo`을 언급하거나 회신하여 GitLab Duo에 검토를 요청했는데 응답을 받지 못한 경우 적절한 GitLab Duo 추가 기능이 없을 수 있습니다.

GitLab Duo 추가 기능을 확인하려면 그룹 소유자에게 그룹의 [GitLab Duo 사용자 할당](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)을 확인하도록 요청하세요.

GitLab Duo 추가 기능을 변경하려면 관리자에게 문의하십시오.

### GitLab Duo를 검토자로 할당할 수 없음 {#unable-to-assign-gitlab-duo-to-review}

GitLab Duo를 검토자로 할당할 수 없는 경우 적절한 GitLab Duo 추가 기능이 없을 수 있습니다.

GitLab Duo 추가 기능을 확인하려면 그룹 소유자에게 그룹의 [GitLab Duo 사용자 할당](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users)을 확인하도록 요청하세요.

GitLab Duo 추가 기능을 변경하려면 관리자에게 문의하십시오.

### 오류: `GitLab Duo Code Review was not automatically added...` {#error-gitlab-duo-code-review-was-not-automatically-added}

GitLab Duo에서 자동 검토를 활성화한 상태로 병합 요청을 만들려고 하면 다음 오류 메시지가 표시될 수 있습니다.

```plaintext
GitLab Duo Code Review was not automatically added because your account requires
GitLab Duo Enterprise. Contact your administrator to upgrade your account.
```

관리자에게 [GitLab Duo Enterprise 사용자 구매](../../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo)하고 할당하도록 요청하십시오.
