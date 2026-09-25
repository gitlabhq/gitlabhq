---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo 코드 검토 (비에이전트)
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](model_selection.md#default-models)
- [다른 모델 선택](model_selection.md#select-a-model-for-a-feature)하려면 **Non-Agentic Code Review** 설정을 사용합니다.
- [자체 호스팅 모델이 포함된 GitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/14825)되었으며 [실험](../../policy/development_stages_support.md#experiment) 단계에 있습니다. [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106)과 [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632)라는 두 기능 플래그의 뒤에 있으며, 기본적으로 비활성화되어 있습니다.
- [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) 및 [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632) 기능 플래그는 GitLab 17.10에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 기본적으로 활성화됩니다.
- GitLab 17.10에서 베타 버전으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/516234)되었습니다.
- GitLab 18.0에서 Premium 계층을 포함하도록 변경되었습니다.
- 기능 플래그 `ai_review_merge_request`은 GitLab 18.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639)되었습니다.
- 기능 플래그 `duo_code_review_chat`은 GitLab 18.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640)되었습니다.
- GitLab 18.1에서 일반적으로 사용 가능합니다.
- GitLab 18.3에서 GitLab Duo 자체 호스팅 모델에서 사용 가능하도록 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)되었습니다.
- GitLab 18.4에서 GitLab Duo 자체 호스팅 모델에서 일반적으로 사용 가능하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)되었습니다.

{{< /history >}}

> [!note]
> 추가 기능 및 그룹 설정에 따라 GitLab은 두 가지 코드 검토 기능 중 하나를 실행합니다.
>
> - Code Review 플로우: 에이전트 버전으로 GitLab Duo Agent Platform의 일부입니다.
> - GitLab Duo 코드 리뷰: 비에이전트 버전으로 GitLab Duo Enterprise 추가 기능이 있는 사용자만 사용할 수 있습니다.
>
> 이 페이지에서는 비에이전트 버전에 대해 설명합니다. [두 기능의 비교](../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)를 확인하세요.

GitLab Duo 코드 검토는 프로젝트에서 코드 검토를 간소화하는 데 도움이 됩니다.

## GitLab Duo 코드 검토 사용 {#use-gitlab-duo-code-review}

머지 리퀘스트를 검토할 준비가 되면 GitLab Duo 코드 검토를 사용하여 초기 검토를 수행합니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **병합 요청**를 선택하고 병합 요청을 찾습니다.
1. 댓글 상자에서 빠른 작업 `/assign_reviewer @GitLabDuo`을 입력하거나 GitLab Duo를 검토자로 할당합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 보기](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

이 기능에 대해 [이슈 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 피드백을 제공하세요.

### 문맥적 인식 {#contextual-awareness}

GitLab Duo 코드 검토를 사용하면 다음 데이터가 대규모 언어 모델로 전송됩니다:

- 머지 리퀘스트 제목
- 머지 리퀘스트 설명
- 변경 사항이 적용되기 전의 파일 내용 (컨텍스트용)
- 머지 리퀘스트 차이
- 파일명
- 사용자 지정 설명

제외할 컨텐츠를 지정하려면 [코드 검토에서 컨텍스트 제외](context.md#exclude-context-from-code-review)를 참조하세요.

#### 대규모 머지 리퀘스트의 동작 {#behavior-on-large-merge-requests}

GitLab Duo 코드 검토는 머지 리퀘스트 차이와 변경된 파일의 원본 내용을 모델로 전송합니다. 결합된 프롬프트는 [선택한 모델의](model_selection.md) 컨텍스트 윈도우에 따릅니다.

대규모 머지 리퀘스트의 경우 GitLab Duo 코드 검토는 성공적인 검토 가능성을 높이기 위해 폴백을 사용합니다:

1. 초기 요청에는 머지 리퀘스트 차이와 원본 파일 내용이 포함됩니다.
1. 해당 요청이 실패하면 GitLab Duo 코드 검토는 원본 파일 내용 없이 자동으로 재시도합니다.
1. 재시도도 실패하면 GitLab Duo 코드 검토는 일반적인 오류 메시지를 반환합니다.

파일 내용 없이 재시도하면 프롬프트 크기가 줄어들지만 변경 사항을 검토할 때 모델의 컨텍스트도 줄어듭니다. 댓글은 원본 파일 내용을 포함하는 검토보다 덜 구체적일 수 있습니다.

GitLab Duo 코드 검토의 AI Gateway 요청 타임아웃은 120초입니다. 이 기간에 완료되지 않은 검토도 일반적인 오류로 표시됩니다.

대규모 머지 리퀘스트에서 실패한 검토의 위험을 줄이려면:

- 대규모 머지 리퀘스트를 더 작은 것으로 분할합니다.
- [문맥 제외](context.md#exclude-context-from-code-review)를 검토와 관련이 없는 파일에 대해 수행합니다.
- 그룹 소유자 또는 인스턴스 관리자에게 **Non-Agentic Code Review** 설정을 사용하여 다른 모델을 선택하도록 요청합니다. [GitLab.com](model_selection.md#select-a-model-for-a-feature) 또는 [GitLab Self-Managed 및 GitLab Dedicated](../../administration/gitlab_duo/model_selection.md#select-a-model-for-the-instance)를 참조하세요.

## 리뷰에서 GitLab Duo와 상호 작용 {#interact-with-gitlab-duo-in-reviews}

머지 리퀘스트에서 GitLab Duo와 상호작용하려면 댓글에서 `@GitLabDuo`을 언급할 수 있습니다. 검토 댓글에 대해 후속 질문을 하거나 머지 리퀘스트의 모든 토론 스레드에서 질문을 할 수 있습니다.

GitLab Duo와의 상호작용은 머지 리퀘스트를 개선하기 위해 제안과 피드백을 개선하는 데 도움이 될 수 있습니다.

GitLab Duo에 제공된 피드백은 다른 머지 리퀘스트의 나중 검토에 영향을 주지 않습니다. [이슈 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116)을 참조하여 이 기능을 추가하는 기능 요청이 있습니다.

## 사용자 지정 코드 검토 지침 {#custom-code-review-instructions}

프로젝트에서 일관되고 구체적인 코드 검토 표준을 보장하기 위해 사용자 지정 MR 검토 지침을 생성할 수 있습니다.

자세한 내용은 [GitLab Duo에 대한 검토 지침 커스터마이징](customize_duo/review_instructions.md)을 참조하세요.

## 자동 검토 {#automatic-reviews}

{{< history >}}

- GitLab 18.0에서 프로젝트 자동 검토가 UI 설정으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)되었습니다.
- GitLab 18.4에서 그룹 및 인스턴스에 대한 자동 검토가 [베타](../../policy/development_stages_support.md#beta) [기능 플래그](../../administration/feature_flags/_index.md) `cascading_auto_duo_code_review_settings`로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 18.7에서 `cascading_auto_duo_code_review_settings` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)되었습니다.

{{< /history >}}

GitLab Duo의 자동 검토는 프로젝트, 그룹 또는 인스턴스의 모든 머지 리퀘스트가 초기 검토를 받도록 보장합니다.

사용자가 머지 리퀘스트를 생성할 때 GitLab Duo는 다음을 제외한 경우 자동으로 검토합니다:

- 드래프트로 표시됩니다. GitLab Duo가 머지 리퀘스트를 검토하려면 이를 준비 상태로 표시합니다.
- 변경 사항이 없습니다. GitLab Duo가 머지 리퀘스트를 검토하려면 변경 사항을 추가합니다.
- 설정한 하나 이상의 제외 규칙과 일치합니다. GitLab Duo가 머지 리퀘스트를 검토하도록 하려면 검토를 수동으로 요청합니다.

{{< tabs >}}

{{< tab title="프로젝트" >}}

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.

프로젝트에 대한 자동 검토를 활성화합니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="그룹" >}}

사전 요구 사항:

- 그룹의 Owner 역할.

그룹에 대한 자동 검토를 활성화합니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **머지 리퀘스트** 섹션을 확장합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

설정은 그룹에서 프로젝트로 계단식으로 적용됩니다. 더 구체적인 설정이 더 광범위한 설정을 무시합니다.

{{< /tab >}}

{{< tab title="인스턴스" >}}

사전 요구 사항:

- 관리자 액세스

인스턴스에 대한 자동 검토를 활성화합니다:

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

설정은 인스턴스에서 그룹, 프로젝트 순으로 계단식으로 적용됩니다. 더 구체적인 설정이 더 광범위한 설정을 무시합니다.

{{< /tab >}}

{{< /tabs >}}

자동 검토를 활성화한 후 특정 머지 리퀘스트를 제외하는 규칙을 지정할 수 있습니다.

### 프로젝트에 대한 머지 리퀘스트 제외 {#exclude-merge-requests-for-a-project}

{{< history >}}

- GitLab 19.2에서 `duo_code_review_automated_rules` [플래그](../../administration/feature_flags/_index.md)의 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236)되었습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 19.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245852)되었습니다. `duo_code_review_automated_rules` 기능 플래그가 제거되었습니다.

{{< /history >}}

프로젝트에 대해 자동 검토가 켜져 있으면 GitLab Duo는 적격 머지 리퀘스트를 모두 검토합니다. 특정 머지 리퀘스트를 제외하려면 `.gitlab/duo/mr-review-automated-rules.yaml` 파일에 제외 규칙을 정의합니다.

제외 규칙은 자동 검토만 방지합니다. 제외된 머지 리퀘스트에 대해 수동으로 검토를 요청할 수 있습니다.

제외 규칙을 정의하려면:

1. 리포지토리의 루트에 `.gitlab/duo` 디렉터리가 없으면 생성합니다.
1. `.gitlab/duo` 디렉터리에서 `mr-review-automated-rules.yaml` 파일을 생성합니다.
1. 다음 형식을 사용하여 제외 규칙을 추가합니다.

   ```yaml
   exclude:
     target_branches:
       - <pattern>
     source_branches:
       - <pattern>
     authors:
       - <pattern>
   ```

   각 키는 선택적입니다. GitLab Duo는 머지 리퀘스트가 모든 카테고리의 모든 패턴과 일치할 때 자동 검토를 건너뜁니다.

   - `target_branches`: 머지 리퀘스트의 대상 브랜치 이름과 일치합니다.
   - `source_branches`: 머지 리퀘스트의 소스 브랜치 이름과 일치합니다.
   - `authors`: 머지 리퀘스트 작성자의 사용자 이름과 일치합니다.

   패턴은 와일드카드(glob) 일치를 지원합니다. 예를 들어, `dependabot/*`은 `dependabot/`로 시작하는 모든 소스 브랜치와 일치합니다.

   예를 들어, 릴리스 브랜치를 대상으로 하거나 봇 계정이 생성한 머지 리퀘스트에 대한 자동 검토를 건너뛰려면:

   ```yaml
   exclude:
     target_branches:
       - "release/*"
     authors:
       - "*-bot"
   ```

1. 파일을 리포지토리의 기본 브랜치에 커밋합니다.

GitLab Duo는 리포지토리의 기본 브랜치에서 제외 규칙을 읽습니다. GitLab Duo는 다른 브랜치에 규칙을 적용하지 않습니다.

### 그룹에 대해 머지 리퀘스트 제외 {#exclude-merge-requests-for-a-group}

그룹 및 해당 하위 그룹의 모든 프로젝트에 대한 제외 규칙을 정의하려면 템플릿으로 사용할 프로젝트를 지정하십시오. 템플릿 프로젝트는 `.gitlab/duo/mr-review-automated-rules.yaml` 파일을 포함해야 합니다.

GitLab Duo는 그룹 템플릿 프로젝트의 제외 규칙과 개별 프로젝트에 정의된 규칙을 결합합니다. 같은 카테고리가 두 수준 모두에서 정의된 경우 프로젝트의 규칙이 우선합니다. 그룹 및 해당 하위 그룹이 각각 템플릿 프로젝트를 설정할 때 GitLab Duo는 모든 수준의 규칙을 결합합니다.

> [!note]
> 그룹에 대해 [사용자 지정 검토 지침](customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group)을 저장하도록 프로젝트를 이미 구성한 경우 `mr-review-automated-rules.yaml`를 동일한 프로젝트에 저장합니다. 그룹의 코드 검토를 커스터마이징하기 위해 단일 프로젝트만 지정할 수 있으므로 GitLab은 자동으로 해당 프로젝트의 제외 규칙도 확인합니다. 아래 단계를 다시 수행할 필요가 없습니다.

사전 요구 사항:

- 그룹의 Owner 역할.
- 그룹의 프로젝트에 설정할 제외 규칙이 포함되어 있습니다.

그룹에 대한 제외 규칙을 구성하려면:

{{< tabs >}}

{{< tab title="GitLab.com" >}}

최상위 그룹의 경우:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 기능** > **코드 리뷰 커스터마이징** 아래에서 `.gitlab/duo/mr-review-automated-rules.yaml` 파일을 포함하는 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

그룹 또는 서브그룹의 경우:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **코드 리뷰 커스터마이징** 아래에서 `.gitlab/duo/mr-review-automated-rules.yaml` 파일을 포함하는 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed and GitLab Dedicated" >}}

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **코드 리뷰 커스터마이징** 아래에서 `.gitlab/duo/mr-review-automated-rules.yaml` 파일을 포함하는 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

### 대규모 머지 리퀘스트에서 검토 실패 {#review-fails-on-a-large-merge-request}

GitLab Duo 코드 검토는 많은 대규모 변경 파일이 있는 머지 리퀘스트에 검토를 게시하지 못할 수 있습니다. 일반적인 원인은 다음과 같습니다.

- 차이와 원본 파일 내용의 결합 크기가 모델의 컨텍스트 윈도우를 초과합니다.
- AI Gateway 요청에 120초 이상 소요됩니다.

재시도 및 타임아웃 동작에 대한 자세한 내용은 [대규모 머지 리퀘스트의 동작](#behavior-on-large-merge-requests)을 참조하세요.

실패를 해결하려면:

- 머지 리퀘스트를 더 작은 머지 리퀘스트로 분할합니다.
- [문맥 제외](context.md#exclude-context-from-code-review)를 검토와 관련이 없는 파일에 대해 수행합니다.
- 그룹 소유자 또는 인스턴스 관리자에게 **Non-Agentic Code Review** 설정을 사용하여 다른 모델을 선택하도록 요청합니다. [GitLab.com](model_selection.md#select-a-model-for-a-feature) 또는 [GitLab Self-Managed 및 GitLab Dedicated](../../administration/gitlab_duo/model_selection.md#select-a-model-for-the-instance)를 참조하세요.

자세한 내용은 [이슈 596794](https://gitlab.com/gitlab-org/gitlab/-/work_items/596794)를 참조하세요.

## 관련 항목 {#related-topics}

- [병합 요청에 GitLab Duo](../project/merge_requests/duo_in_merge_requests.md)
- [GitLab Duo Enterprise 사용자를 위해 Code Review 플로우 켜기](../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).
