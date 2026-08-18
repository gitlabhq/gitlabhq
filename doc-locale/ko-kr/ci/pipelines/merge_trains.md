---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지 트레인을 사용하여 머지 리퀘스트를 대기열에 넣고 GitLab CI/CD에서 브랜치 충돌을 방지합니다.
title: 머지 트레인
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본 브랜치로의 빈번한 머지가 있는 프로젝트에서는 서로 다른 머지 리퀘스트의 변경 사항이 서로 충돌할 수 있습니다. 머지 트레인을 사용하여 머지 리퀘스트를 대기열에 넣습니다. 각 머지 리퀘스트는 다른 이전 머지 리퀘스트와 비교되어 모두 함께 작동하는지 확인합니다.

다음에 대한 자세한 정보:

- 머지 트레인의 작동 방식에 대해서는 [머지 트레인 워크플로우](#merge-train-workflow)를 검토합니다.
- 머지 트레인을 사용하는 이유에 대해서는 [머지 트레인 시작이 DevOps의 효율성을 개선하는 방법](https://about.gitlab.com/blog/all-aboard-merge-trains/)을 읽습니다.

## 머지 트레인 워크플로우 {#merge-train-workflow}

머지할 대기 중인 머지 리퀘스트가 없고 [**머지** 또는 **자동 병합으로 설정**](#start-a-merge-train)을 선택하면 머지 트레인이 시작됩니다. GitLab은 변경 사항을 기본 브랜치에 머지할 수 있는지 검증하는 머지 트레인 파이프라인을 시작합니다. 이 첫 번째 파이프라인은 [머지된 결과 파이프라인](merged_results_pipelines.md)과 같으며, 소스 및 대상 브랜치의 변경 사항을 함께 결합하여 실행됩니다. 내부 머지된 결과 커밋의 작성자는 머지를 시작한 사용자입니다.

첫 번째 파이프라인이 완료된 후 즉시 머지되도록 두 번째 머지 리퀘스트를 대기열에 넣으려면 [**머지** 또는 **자동 병합으로 설정**](#add-a-merge-request-to-a-merge-train)을 선택하여 트레인에 추가합니다. 이 두 번째 머지 트레인 파이프라인은 _두_ 머지 리퀘스트의 변경 사항을 대상 브랜치와 함께 실행됩니다. 유사하게 세 번째 머지 리퀘스트를 추가하면 해당 파이프라인은 세 개의 머지 리퀘스트 모두의 변경 사항을 대상 브랜치와 병합하여 실행됩니다. 파이프라인은 모두 병렬로 실행됩니다.

각 머지 리퀘스트는 다음 조건을 충족한 후에만 대상 브랜치로 머지됩니다:

- 머지 리퀘스트의 파이프라인이 성공적으로 완료됩니다.
- 이전에 대기열에 있던 다른 모든 머지 리퀘스트가 머지됩니다.

머지 트레인 파이프라인이 실패하면 머지 리퀘스트는 머지되지 않습니다. GitLab은 해당 머지 리퀘스트를 머지 트레인에서 제거하고 이후 대기열에 있던 모든 머지 리퀘스트에 대해 새로운 파이프라인을 시작합니다.

예를 들어:

세 개의 머지 리퀘스트(`A`, `B`, `C`)가 순서대로 머지 트레인에 추가되어 병렬로 실행되는 3개의 머지된 결과 파이프라인을 생성합니다:

1. 첫 번째 파이프라인은 `A`의 변경 사항을 대상 브랜치와 함께 실행합니다.
1. 두 번째 파이프라인은 `A`과 `B`의 변경 사항을 대상 브랜치와 함께 실행합니다.
1. 세 번째 파이프라인은 `A`, `B`, `C`의 변경 사항을 대상 브랜치와 함께 실행합니다.

`B`의 파이프라인이 실패하면:

- 첫 번째 파이프라인(`A`)은 계속 실행됩니다.
- `B`은 트레인에서 제거됩니다.
- `C`의 파이프라인이 [취소되고](#automatic-pipeline-cancellation), `A`과 `C`의 변경 사항을 대상 브랜치와 함께 실행하는 새 파이프라인이 시작됩니다(`B` 변경 사항 제외).

`A`이 성공적으로 완료되면 대상 브랜치로 머지되고, `C`은 계속 실행됩니다. 트레인에 추가된 새로운 머지 리퀘스트는 이제 대상 브랜치에 있는 `A` 변경 사항과 머지 트레인의 `C` 변경 사항을 포함합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [머지 트레인의 병렬 실행이 기본 브랜치를 깨지는 것을 방지하는 방법](https://www.youtube.com/watch?v=D4qCqXgZkHQ)에 대한 데모를 보려면 이 비디오를 시청하세요.

### 자동 파이프라인 취소 {#automatic-pipeline-cancellation}

GitLab CI/CD는 중복된 파이프라인을 감지하고 리소스를 절약하기 위해 취소합니다.

중복된 머지 트레인 파이프라인은 다음과 같은 경우 발생합니다:

- 머지 트레인의 머지 리퀘스트 중 하나에서 파이프라인이 실패합니다.
- [머지 트레인을 건너뛰고 즉시 머지합니다](#skip-the-merge-train-and-merge-immediately).
- [머지 트레인에서 머지 리퀘스트를 제거합니다](#remove-a-merge-request-from-a-merge-train).

이 경우 GitLab은 트레인의 일부 또는 모든 머지 리퀘스트에 대해 새로운 머지 트레인 파이프라인을 생성해야 합니다. 이전 파이프라인은 머지 트레인의 이전 결합된 변경 사항과 비교되었으며, 더 이상 유효하지 않으므로 이러한 이전 파이프라인이 취소됩니다.

## 머지 트레인 활성화 {#enable-merge-trains}

전제 조건:

- Maintainer 역할이 있어야 합니다.
- 리포지토리는 GitLab 리포지토리여야 하며 [외부 리포지토리](../ci_cd_for_external_repos/_index.md)가 아니어야 합니다.
- 파이프라인은 [머지 리퀘스트 파이프라인을 사용하도록 구성](merge_request_pipelines.md#prerequisites)되어야 합니다. 그렇지 않으면 머지 리퀘스트가 미해결 상태에서 동결되거나 파이프라인이 드롭될 수 있습니다.
- [머지된 결과 파이프라인이 활성화](merged_results_pipelines.md#enable-merged-results-pipelines)되어 있어야 합니다.

머지 트레인을 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 옵션** 섹션에서 **머지된 결과 파이프라인 활성화**가 활성화되어 있는지 확인하고 **머지 트레인 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 머지 트레인 시작 {#start-a-merge-train}

전제 조건:

- 대상 브랜치에 머지하거나 푸시할 수 있는 [권한](../../user/permissions.md)이 있어야 합니다.

머지 트레인을 시작하려면:

1. 머지 리퀘스트로 이동합니다.
1. 다음 중 하나를 선택합니다:
   - 파이프라인이 실행되지 않을 때 **머지**를 선택합니다.
   - 파이프라인이 실행 중일 때 [**자동 병합으로 설정**](../../user/project/merge_requests/auto_merge.md)을 선택합니다.

머지 리퀘스트의 머지 트레인 상태는 파이프라인 위젯 아래에 `A new merge train has started and this merge request is the first of the queue. View merge train details.`과 같은 메시지와 함께 표시됩니다. 링크를 선택하여 머지 트레인을 볼 수 있습니다.

이제 다른 머지 리퀘스트를 트레인에 추가할 수 있습니다.

## 머지 트레인 보기 {#view-a-merge-train}

{{< history >}}

- 머지 트레인 시각화는 GitLab 17.3에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/13705)되었습니다.

{{< /history >}}

머지 트레인을 보고 대기열에 있는 머지 리퀘스트의 순서 및 상태에 대해 더 잘 이해할 수 있습니다. 머지 트레인 세부 정보 페이지는 대기열의 활성 머지 리퀘스트와 트레인의 일부였던 머지된 머지 리퀘스트를 표시합니다.

머지 리퀘스트 목록에서 머지 트레인 세부 정보에 액세스하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택합니다.
1. 머지 리퀘스트 목록 위에서 **머지 트레인**을 선택합니다.
1. 선택 사항. 대상 브랜치별로 머지 트레인을 필터링합니다.

다음에서 **머지 트레인 세부 정보 보기**를 선택하여 이 보기에 액세스할 수도 있습니다:

- 머지 트레인에 추가된 머지 리퀘스트의 파이프라인 위젯 및 시스템 노트입니다.
- 머지 트레인 파이프라인의 파이프라인 세부 정보 페이지입니다.

머지 트레인 세부 정보 보기에서 머지 리퀘스트 옆의 ({{< icon name="close" >}})를 선택하여 제거할 수도 있습니다.

## 머지 트레인에 머지 리퀘스트 추가 {#add-a-merge-request-to-a-merge-train}

{{< history >}}

- 머지 트레인용 자동 머지는 GitLab 17.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10874)되었으며 [플래그](../../administration/feature_flags/_index.md) `merge_when_checks_pass_merge_train`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- 머지 트레인용 자동 머지는 GitLab 17.2에서 GitLab.com에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/470667)되었습니다.
- 머지 트레인용 자동 머지는 GitLab 17.4에서 기본적으로 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/470667)되었습니다.
- 머지 트레인용 자동 머지는 GitLab 17.7에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174357)합니다. 기능 플래그 `merge_when_checks_pass_merge_train`이 제거되었습니다.

{{< /history >}}

전제 조건:

- 대상 브랜치에 머지하거나 푸시할 수 있는 [권한](../../user/permissions.md)이 있어야 합니다.

머지 리퀘스트를 머지 트레인에 추가하려면:

1. 머지 리퀘스트를 방문합니다.
1. 다음 중 하나를 선택합니다:
   - 파이프라인이 실행되지 않을 때 **머지**를 선택합니다.
   - 파이프라인이 실행 중일 때 [**자동 병합으로 설정**](../../user/project/merge_requests/auto_merge.md)을 선택합니다.

머지 리퀨스트의 머지 트레인 상태는 파이프라인 위젯 아래에 `This merge request is 2 of 3 in queue.`과 같은 메시지와 함께 표시됩니다.

각 머지 트레인은 [병렬로 실행되는 파이프라인의 최대 수](#merge-train-parallel-pipeline-limit)를 실행할 수 있습니다. 기본 제한은 20입니다. 제한보다 많은 머지 리퀘스트를 머지 트레인에 추가하면 파이프라인이 완료될 때까지 추가 머지 리퀘스트가 대기열에 들어갑니다. 대기열에 있는 머지 리퀘스트 수는 무제한입니다.

## 머지 트레인에서 머지 리퀘스트 제거 {#remove-a-merge-request-from-a-merge-train}

머지 트레인에서 머지 리퀘스트를 제거할 때:

- 제거된 머지 리퀘스트 이후 대기열에 있던 모든 머지 리퀘스트의 파이프라인이 다시 시작됩니다.
- 중복된 파이프라인은 [취소](#automatic-pipeline-cancellation)됩니다.

나중에 머지 리퀨스트를 머지 트레인에 다시 추가할 수 있습니다.

머지 트레인에서 머지 리퀘스트를 제거하려면:

- 머지 리퀘스트에서 **자동 머지 취소**를 선택합니다.
- [머지 트레인 세부 정보](#view-a-merge-train)에서 머지 리퀘스트 옆의 {{< icon name="close" >}}를 선택합니다.

## 머지 트레인을 건너뛰고 즉시 머지 {#skip-the-merge-train-and-merge-immediately}

긴급하게 머지해야 하는 중요한 패치와 같은 높은 우선순위의 머지 리퀘스트가 있는 경우 **즉시 머지**를 선택할 수 있습니다.

> [!warning]
> 즉시 머지하면 많은 CI/CD 리소스를 사용할 수 있습니다. 이 옵션은 중요한 상황에서만 사용합니다.

머지 리퀘스트를 즉시 머지할 때:

- 머지 리퀘스트의 커밋이 머지 트레인의 상태를 무시하고 머지됩니다.
- 트레인의 다른 모든 머지 리퀘스트의 머지 트레인 파이프라인이 [취소](#automatic-pipeline-cancellation)됩니다.
- 새로운 머지 트레인이 시작되고 원래 머지 트레인의 모든 머지 리퀘스트가 이 새로운 머지 트레인에 추가되며 각각에 대해 새로운 머지 트레인 파이프라인이 생성됩니다. 이러한 새로운 머지 트레인 파이프라인은 이제 즉시 머지된 머지 리퀨스트가 추가한 커밋을 포함합니다.

> [!note]
> **merge immediately** 옵션은 프로젝트가 [fast-forward](../../user/project/merge_requests/methods/_index.md#fast-forward-merge) 머지 방법을 사용하고 소스 브랜치가 대상 브랜치 뒤에 있는 경우 사용하지 못할 수 있습니다. 자세한 내용은 [이슈 434070](https://gitlab.com/gitlab-org/gitlab/-/issues/434070)을 참조합니다.

### 머지 트레인 파이프라인을 다시 시작하지 않고 즉시 머지 {#merge-immediately-without-restarting-merge-train-pipelines}

{{< details >}}

- 상태: 실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414505)되었으며 [플래그](../../administration/feature_flags/_index.md) `merge_trains_skip_train`로 명명되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.10에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/422111)되었으며 [실험 기능](../../policy/development_stages_support.md)입니다.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서는 기본적으로 이 기능을 사용할 수 있습니다. 기능을 숨기려면 관리자가 [기능 플래그를 비활성화](../../administration/feature_flags/_index.md)할 수 있으며 `merge_trains_skip_train`로 명명되었습니다. GitLab.com 및 GitLab Dedicated에서는 이 기능을 사용할 수 있습니다.

실행 중인 머지 트레인을 완전히 다시 시작하지 않고 머지 리퀨스트를 머지할 수 있습니다. 이 기능을 사용하면 파이프라인을 안전하게 건너뛸 수 있는 변경 사항(예: 사소한 문서 업데이트)을 빠르게 머지할 수 있습니다.

fast-forward 또는 semi-linear 머지 방법으로는 머지 트레인을 건너뛸 수 없습니다. 자세한 내용은 [이슈 429009](https://gitlab.com/gitlab-org/gitlab/-/issues/429009)를 참조합니다.

머지 트레인 건너뛰기는 실험 기능입니다. 향후 릴리스에서 변경되거나 완전히 제거될 수 있습니다.

> [!warning]
> 이 기능을 사용하면 보안 또는 버그 수정을 빠르게 머지할 수 있지만, 트레인을 건너뛴 머지 리퀘스트의 변경 사항은 트레인의 다른 머지 리퀘스트와 비교하여 검증되지 않습니다. 이러한 다른 머지 트레인 파이프라인이 성공적으로 완료되고 머지되면 결합된 변경 사항이 호환되지 않을 위험이 있습니다. 대상 브랜치는 새로운 장애를 해결하기 위해 추가 작업이 필요할 수 있습니다.

전제 조건:

- Maintainer 역할이 있어야 합니다.
- [머지 트레인이 활성화](#enable-merge-trains)되어 있어야 합니다.

파이프라인을 다시 시작하지 않고 트레인 건너뛰기를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 옵션** 섹션에서 **머지된 결과 파이프라인 활성화** 및 **머지 트레인 활성화** 옵션이 활성화되어 있는지 확인합니다.
1. **Merge immediately without restarting the merge train**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

머지 트레인을 건너뛰어 머지 리퀨스트를 머지하려면 [머지 리퀘스트 머지 API 엔드포인트](../../api/merge_requests.md#merge-a-merge-request)를 사용하여 특성 `skip_merge_train`을 `true`로 설정하여 머지합니다.

머지 리퀨스트가 머지되고 기존 머지 트레인 파이프라인이 취소되거나 다시 시작되지 않습니다.

### 머지 트레인 병렬 파이프라인 제한 {#merge-train-parallel-pipeline-limit}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/374188)되었습니다.

{{< /history >}}

기본적으로 각 [머지 트레인](../../ci/pipelines/merge_trains.md)은 최대 20개의 파이프라인을 병렬로 실행할 수 있습니다. 이 제한에 도달하면 파이프라인 슬롯을 사용할 수 있을 때까지 추가 머지 리퀘스트가 대기열에 올라갑니다.

프로젝트의 이 제한을 수정하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 옵션** 섹션에서 **Maximum parallel pipelines per merge train**에 값을 설정합니다. 최소값은 `1`입니다. `1`의 값은 머지 리퀘스트를 병렬 처리 없이 순차적으로 처리합니다.
1. **변경사항 저장**을 선택합니다.

프로젝트 제한은 [인스턴스 제한](../../administration/cicd/limits.md#merge-train-parallel-pipeline-limit)을 초과할 수 없습니다.

[프로젝트 API](../../api/projects.md) 또는 [GraphQL API](../../api/graphql/reference/_index.md#projectcicdsetting)를 사용할 수도 있습니다.

## 문제 해결 {#troubleshooting}

### 머지 트레인에서 제거된 머지 리퀘스트 {#merge-request-dropped-from-the-merge-train}

머지 트레인 파이프라인이 실행되는 동안 머지 리퀨스트가 머지 불가능해지면 머지 트레인이 머지 리퀨스트를 자동으로 삭제합니다. 일반적인 원인은 다음과 같습니다:

- 머지 리퀨스트를 [초안](../../user/project/merge_requests/drafts.md)으로 변경합니다.
- 머지 충돌입니다.
- [모든 스레드를 해결해야 함](../../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)이 활성화된 상태에서 해결되지 않은 새로운 대화 스레드입니다.

시스템 노트에서 머지 리퀨스트가 머지 트레인에서 제거된 이유를 찾을 수 있습니다. **활동** 섹션의 **개요** 탭에서 `User removed this merge request from the merge train because ...`과 같은 메시지를 확인합니다.

### 자동 머지를 사용할 수 없음 {#cannot-use-auto-merge}

머지 트레인이 활성화된 경우 [자동 머지](../../user/project/merge_requests/auto_merge.md)(이전에 **파이프라인 성공시 머지**)를 사용하여 머지 트레인을 건너뛸 수 없습니다. 자세한 내용은 [이슈 12267](https://gitlab.com/gitlab-org/gitlab/-/issues/12267)을 참조합니다.

### 머지 트레인 파이프라인을 다시 시도할 수 없음 {#cannot-retry-merge-train-pipeline}

머지 트레인 파이프라인이 실패하면 머지 리퀨스트는 트레인에서 삭제되고 실패 후 파이프라인을 다시 시도할 수 없습니다. 머지 트레인 파이프라인은 머지 리퀨스트의 변경 사항과 이미 트레인에 있는 다른 머지 리퀨스트의 변경 사항의 머지된 결과에서 실행됩니다. 머지 리퀨스트가 트레인에서 삭제되면 머지된 결과가 만료되고 파이프라인을 다시 시도할 수 없습니다.

다음을 수행할 수 있습니다.

- [머지 리퀨스트를 트레인에 다시 추가](#add-a-merge-request-to-a-merge-train)하면 새로운 파이프라인이 트리거됩니다.
- 간헐적으로 실패하면 작업에 [`retry`](../yaml/_index.md#retry) 키워드를 추가합니다. 재시도 후 성공하면 머지 리퀨스트는 머지 트레인에서 제거되지 않습니다.

### 머지 트레인에 머지 리퀨스트를 추가할 수 없음 {#cannot-add-a-merge-request-to-the-merge-train}

[**파이프라인이 성공해야 함**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이 활성화되어 있지만 최신 파이프라인이 실패한 경우:

- **자동 병합으로 설정** 또는 **머지** 옵션을 사용할 수 없습니다.
- 머지 리퀨스트에는 `The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.`가 표시됩니다.

머지 리퀨스트를 머지 트레인에 다시 추가하기 전에 다음을 시도할 수 있습니다:

- 실패한 작업을 다시 시도합니다. 성공하고 다른 작업이 실패하지 않으면 파이프라인이 성공으로 표시됩니다.
- 전체 파이프라인을 다시 실행합니다. **파이프라인** 탭에서 **파이프라인 실행**을 선택합니다.
- 문제를 해결하는 새로운 커밋을 푸시하면 새로운 파이프라인도 트리거됩니다.

자세한 내용은 [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/35135)를 참조합니다.
