---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Review 플로우
---

{{< details >}}

- 티어:  [Free](../../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic Claude Sonnet 5 Vertex
- GitLab 19.0 이전 버전용 LLM: [기본 LLM](../../../../gitlab_duo/model_selection.md#default-models)(비에이전틱 버전)인 GitLab Duo 코드 검토
- GitLab.com에서는 **에이전틱 코드 검토** 설정을 사용하여 [다른 모델을 선택](../../../model_selection.md#select-a-model-for-a-feature)할 수 있습니다.
- GitLab Self-Managed 및 GitLab Dedicated에서는 GitLab 버전에 맞는 설정을 사용하여 [다른 모델을 선택](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)할 수 있습니다.
- [자체 호스팅 모델이 포함된 GitLab Duo](../../../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645)에서 `duo_code_review_on_agent_platform` [기능 플래그](../../../../../administration/feature_flags/_index.md)의 [베타](../../../../../policy/development_stages_support.md)로 도입되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)하게 되었습니다. `duo_code_review_on_agent_platform` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209)되었습니다.
- GitLab 18.10부터 GitLab.com의 Free 티어에서 GitLab Credits를 사용하여 이용 가능합니다.
- LLM이 2026년 5월 20일 Claude Sonnet 4.6 Vertex로 [업데이트](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5555)되었습니다.
- LLM이 2026년 8월 6일 Claude Sonnet 5 Vertex로 [업데이트](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6422)되었습니다.

{{< /history >}}

> [!note]
> 추가 기능 및 그룹 설정에 따라 GitLab은 두 가지 코드 검토 기능 중 하나를 실행합니다.
>
> - Code Review 플로우: 에이전트 버전으로 GitLab Duo Agent Platform의 일부입니다.
> - GitLab Duo 코드 리뷰: 비에이전트 버전으로 GitLab Duo Enterprise 추가 기능이 있는 사용자만 사용할 수 있습니다.
>
> 이 페이지는 에이전트 버전을 설명합니다.
>
> 두 기능이 어떻게 비교되는지, GitLab Duo Enterprise 사용자를 위해 Code Review 플로우를 켜는 방법에 대한 자세한 내용은 [GitLab Duo를 사용하여 코드 검토](../../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)를 참조하세요.

Code Review 플로우는 에이전트 AI로 코드 검토를 간소화하는 데 도움이 됩니다.

이 플로우:

- 코드 변경 사항을 분석합니다.
- 리포지토리 구조 및 파일 간 종속성에 대한 향상된 문맥적 이해를 제공합니다.
- 실행 가능한 피드백이 포함된 상세한 검토 주석을 제공합니다.
- 프로젝트에 맞게 조정된 사용자 지정 검토 지침을 지원합니다.

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 전제 조건](../../../_index.md#prerequisites)을 충족해야 합니다.
- **기본 플로우 허용**과 **코드 리뷰**를 [최상위 그룹](../_index.md#turn-foundational-flows-on-or-off)에 대해 켭니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 여러 GitLab Duo 네임스페이스에 속한 경우 [기본 GitLab Duo 네임스페이스 설정](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)합니다.
- [자신의 러너 구성](../../execution/_index.md#configure-runners-to-execute-flows)을 수행하고 `gitlab--duo` 태그 및 Docker 이미지를 지원하는 실행기를 사용하거나, 프로젝트에 [GitLab 호스팅 러너](../../../../../ci/runners/hosted_runners/_index.md)를 켭니다. Code Review 플로우는 CI/CD 작업으로 실행되며 실행을 위해 러너가 필요합니다.

## 플로우 사용 {#use-the-flow}

Code Review 플로우는 GitLab UI 및 REST API를 통해 이용할 수 있습니다.

### GitLab UI에서 검토 요청 {#request-a-review-in-the-gitlab-ui}

{{< history >}}

- GitLab 19.2에서 GitLab Duo Agentic Chat 대화의 플로우 사용이 `agentic_foundational_flow_tool` [기능 플래그](../../../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20484)되었습니다. 기본적으로 활성화되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요.

GitLab UI에서 검토를 요청하려면:

1. 왼쪽 사이드바에서 **코드** > **병합 요청**를 선택하고 병합 요청을 찾습니다.
1. 다음 방법 중 하나를 사용하여 검토를 요청합니다.
   - `@GitLabDuo`을 검토자로 할당합니다.
   - 주석 상자에 빠른 작업 `/assign_reviewer @GitLabDuo`을 입력합니다.
   - 주석 상자에 `@GitLabDuo`을 언급하고 검토를 요청합니다.
   - GitLab Duo 사이드바에서 새로운 또는 기존 Agentic Chat 대화를 엽니다. Agentic Chat에 머지 리퀘스트를 검토하도록 요청하십시오.
1. 진행 상황을 모니터링하려면 왼쪽 사이드바에서 **AI** > **세션**을 선택합니다.

   Agentic Chat에 있는 경우 다음을 수행할 수도 있습니다.
   - Chat 대화에서 진행 상황을 확인합니다.
   - 대화에서 **에이전트 세션 보기**를 선택합니다.

### REST API를 통한 검토 요청 {#request-a-review-through-the-rest-api}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- REST API를 통한 코드 검토 트리거가 GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250117)되었습니다.

{{< /history >}}

REST API를 통해 검토를 요청하려면 다음 매개변수를 사용하여 [플로우를 트리거](../../../../../api/duo_agent_platform_flows.md#trigger-a-flow)합니다:

- `project_id`을(를) 머지 리퀘스트를 포함하는 프로젝트로 설정합니다.
- `goal`을(를) 검토할 머지 리퀘스트의 IID 또는 전체 URL로 설정합니다.
- `workflow_definition`을 `code_review/v1`로 설정합니다. 또는 `ai_catalog_item_consumer_id`을(를) Code Review 플로우의 [컨슈머 ID](../../../../../api/duo_agent_platform_flows.md#look-up-the-consumer-id)로 설정합니다.
- `start_workflow`을(를) `true`로 설정하여 검토를 즉시 시작합니다.

다음 예제는 머지 리퀘스트 `42`에 대한 코드 검토를 트리거합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "42",
    "workflow_definition": "code_review/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

## 리뷰에서 GitLab Duo와 상호 작용 {#interact-with-gitlab-duo-in-reviews}

검토 후 댓글 상호작용을 통해 GitLab Duo와 피드백을 논의할 수 있습니다. 상호작용은 Code Review 플로우와는 별개의 기능입니다.

자세한 내용은 [GitLab Duo와 상호작용](../../../../project/merge_requests/duo_in_merge_requests.md#interact-with-gitlab-duo)을 참조하세요.

## 문맥적 인식 {#contextual-awareness}

Code Review 플로우는 두 개의 스테이지에서 실행됩니다.

1. 사전 스캔: 플로우는 머지 리퀘스트 diff를 검사하고 이를 사용하여 프로젝트 리포지토리에서 가져올 관련 문맥을 식별합니다. 사전 스캔은 일반적으로 디렉토리 목록과 변경 사항에서 참조하는 테스트 및 종속성과 같은 관련 파일의 내용을 포함합니다. 가져오는 정확한 문맥은 diff 분석에 따라 달라집니다.
1. 검토: 플로우는 대규모 언어 모델에서 다음 데이터로 검토를 실행합니다. 검토 스테이지는 필요에 따라 추가 문맥을 가져올 수 없습니다.

   - 사전 스캔 단계의 결과입니다.
   - 머지 리퀘스트 제목입니다.
   - 머지 리퀘스트 설명입니다.
   - 머지 리퀘스트 diff입니다.
   - 파일의 원본 버전입니다.
   - 파일 이름입니다.
   - 사용자 지정 검토 지침입니다.

제외할 콘텐츠를 지정하려면 [GitLab Duo에서 문맥 제외](../../../context.md#exclude-context-from-gitlab-duo)를 참조하세요.

### 파일 및 문맥 제한 {#file-and-context-limits}

Code Review 플로우는 프롬프트를 작동 가능한 크기로 유지하기 위해 두 가지 제한을 적용합니다.

- 10,000줄보다 긴 파일의 경우 diff만 모델로 전송됩니다. 전체 파일 콘텐츠는 포함되지 않습니다.
- 사전 스캔에서 수집하는 총 문맥은 대략 1MiB로 제한됩니다. 제한을 초과하면 검토 스테이지가 실행되기 전에 문맥이 약 800KiB로 잘립니다.

이러한 제한은 플로우가 수집하는 데이터에 적용되며 [선택한 모델의](../../../model_selection.md) 문맥 창과는 별개입니다.

매우 큰 머지 리퀘스트의 경우 검토에서 잘린 문맥을 놓칠 수 있습니다. 위험을 줄이려면:

- 머지 리퀘스트를 더 작은 머지 리퀘스트로 분할합니다.
- [문맥 제외](../../../context.md#exclude-context-from-gitlab-duo)를 검토와 관련이 없는 파일에 대해 수행합니다.
- 그룹 소유자 또는 인스턴스 관리자에게 [GitLab.com](../../../model_selection.md#select-a-model-for-a-feature) 또는 [GitLab Self-Managed 및 GitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)에 대해 다른 모델을 선택하도록 요청하세요.

## 사용자 지정 코드 검토 지침 {#custom-code-review-instructions}

`mr-review-instructions.yaml` 파일을 사용하여 Code Review 플로우의 동작을 사용자 지정합니다.

리포지토리별 검토 지침으로 GitLab Duo를 안내할 수 있습니다.

- 특정 코드 품질 측면(예: 보안, 성능 및 유지 관리)에 집중합니다.
- 프로젝트에 고유한 코딩 표준 및 모범 사례를 시행합니다.
- 특정 파일 패턴을 맞춤형 검토 기준으로 대상 지정합니다.
- 특정 유형의 변경 사항에 대해 더 자세한 설명을 제공합니다.

Code Review 플로우는 `AGENTS.md`과 `SKILL.md` 파일을 참조하지 않습니다.

사용자 지정 지침을 구성하려면 [GitLab Duo에 대한 검토 지침 사용자 지정](../../../customize/review_instructions.md)을 참조하세요.

## 자동 검토 {#automatic-reviews}

{{< history >}}

- GitLab 18.0에서 프로젝트에 대한 자동 검토를 UI 설정으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/506537)했습니다.
- GitLab 18.4에서 그룹에 대한 자동 검토를 [베타](../../../../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)했으며 `cascading_auto_duo_code_review_settings` [기능 플래그](../../../../../administration/feature_flags/_index.md)가 있습니다. 기본적으로 비활성화되었습니다.
- GitLab 18.7에서 `cascading_auto_duo_code_review_settings` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240)되었습니다.
- GitLab 19.1에서 GitLab.com의 새로운 GitLab Duo 평가판에 대해 그룹 및 애플리케이션에 대한 자동 검토가 [기본적으로 설정](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822)됩니다.

{{< /history >}}

GitLab Duo의 자동 검토는 프로젝트 또는 그룹의 모든 머지 리퀘스트가 초기 검토를 받도록 합니다.

사용자가 머지 리퀘스트를 생성하면 GitLab Duo가 자동으로 검토합니다. 다음의 경우는 제외됩니다:

- 드래프트로 표시됩니다. GitLab Duo가 머지 리퀘스트를 검토하려면 이를 준비 상태로 표시합니다.
- 변경 사항이 없습니다. GitLab Duo가 머지 리퀘스트를 검토하려면 변경 사항을 추가합니다.
- 설정한 하나 이상의 제외 규칙과 일치합니다. GitLab Duo가 머지 리퀘스트를 검토하도록 하려면 수동으로 검토를 요청합니다.

GitLab 19.1 이상에서 GitLab.com의 새로운 GitLab Duo 평가판의 경우 그룹에 대한 자동 검토가 기본적으로 켜져 있습니다.

{{< tabs >}}

{{< tab title="프로젝트" >}}

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.

프로젝트에 대한 자동 검토를 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="그룹" >}}

사전 요구 사항:

- 그룹의 Owner 역할.

그룹에 대한 자동 검토를 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **머지 리퀘스트** 섹션을 확장합니다.
1. **GitLab Duo 코드 리뷰** 섹션에서 **GitLab Duo에서 자동 검토 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

설정은 그룹에서 프로젝트로 계단식으로 전달됩니다. 더 구체적인 설정이 더 광범위한 설정을 무시합니다.

{{< /tab >}}

{{< /tabs >}}

자동 검토를 활성화한 후 특정 머지 리퀘스트를 제외하는 규칙을 지정할 수 있습니다.

자동 검토에 대한 크레딧 사용이 어떻게 귀속되는지에 대한 정보는 [실행되는 코드 검토 기능 결정](../../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs)을 참조하세요.

### 프로젝트에 대한 머지 리퀘스트 제외 {#exclude-merge-requests-for-a-project}

{{< history >}}

- GitLab 19.2에서 `duo_code_review_automated_rules` [플래그](../../../../../administration/feature_flags/_index.md)의 [베타](../../../../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236)되었습니다. 기본적으로 활성화되었습니다.
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
> 이미 그룹에 대해 [사용자 지정 검토 지침](../../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group)을 저장하도록 프로젝트를 구성했다면 `mr-review-automated-rules.yaml`을(를) 같은 프로젝트에 저장합니다. 그룹에 대한 코드 검토를 커스터마이징할 프로젝트는 하나만 지정할 수 있으므로 GitLab이 자동으로 해당 프로젝트에서 제외 규칙도 확인합니다. 아래의 단계를 다시 따를 필요가 없습니다.

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

그룹 또는 하위 그룹의 경우:

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

Code Review 플로우로 작업할 때 문제가 발생할 수 있습니다.

이러한 문제를 해결하는 방법에 대한 자세한 내용은 [문제 해결](troubleshooting.md)을 참조하세요.

## 관련 항목 {#related-topics}

- [머지 리퀘스트에서의 GitLab Duo](../../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent Platform AI 모델](../../../model_selection.md)
- [GitLab Duo Enterprise 사용자를 위해 Code Review 플로우 켜기](../../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).
