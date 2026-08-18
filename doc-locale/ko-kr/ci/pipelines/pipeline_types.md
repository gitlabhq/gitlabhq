---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인의 유형
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트에서 실행할 수 있는 여러 파이프라인 유형에는 다음과 같은 것이 있습니다:

- 브랜치 파이프라인
- 태그 파이프라인
- 머지 리퀘스트 파이프라인
- 병합 결과 파이프라인
- 머지 트레인
- 워크로드 파이프라인(GitLab Duo Agent Platform만 해당)

이러한 모든 파이프라인 유형은 머지 리퀘스트의 **파이프라인** 탭에 표시됩니다.

## 브랜치 파이프라인 {#branch-pipeline}

브랜치에 변경 사항을 커밋할 때마다 파이프라인을 실행할 수 있습니다.

이 유형의 파이프라인을 *브랜치 파이프라인*이라고 합니다. 파이프라인 목록에서 `branch` 레이블을 표시합니다.

이 파이프라인은 기본적으로 실행됩니다. 구성이 필요하지 않습니다.

브랜치 파이프라인:

- 브랜치에 새 커밋을 푸시할 때 실행됩니다.
- [미리 정의된 일부 변수](../variables/predefined_variables.md)에 액세스할 수 있습니다.
- [보호된 변수](../variables/_index.md#protect-a-cicd-variable)와 [보호되는 러너](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)에 액세스할 수 있습니다. 단, 브랜치가 [보호된 브랜치](../../user/project/repository/branches/protected.md)일 때만 가능합니다.

## 태그 파이프라인 {#tag-pipeline}

새 [태그](../../user/project/repository/tags/_index.md)를 생성하거나 푸시할 때마다 파이프라인을 실행할 수 있습니다.

이 유형의 파이프라인을 *태그 파이프라인*이라고 합니다. 파이프라인 목록에서 `tag` 레이블을 표시합니다.

이 파이프라인은 기본적으로 실행됩니다. 구성이 필요하지 않습니다.

태그 파이프라인:

- 리포지토리에 새 태그를 생성하거나 푸시할 때 실행됩니다.
- [미리 정의된 일부 변수](../variables/predefined_variables.md)에 액세스할 수 있습니다.
- 태그가 [보호된 태그](../../user/project/protected_tags.md)일 때 [보호된 변수](../variables/_index.md#protect-a-cicd-variable) 및 [보호되는 러너](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)에 액세스할 수 있습니다.

## 머지 리퀘스트 파이프라인 {#merge-request-pipeline}

브랜치 파이프라인 대신 머지 리퀘스트의 소스 브랜치에 변경 사항을 할 때마다 실행되도록 파이프라인을 구성할 수 있습니다.

이 유형의 파이프라인을 *머지 리퀘스트 파이프라인*이라고 합니다. 파이프라인 목록에서 `merge request` 레이블을 표시합니다.

머지 리퀘스트 파이프라인은 기본적으로 실행되지 않습니다. `.gitlab-ci.yml` 파일에서 작업을 구성하여 머지 리퀘스트 파이프라인으로 실행해야 합니다.

자세한 내용은 [머지 리퀘스트 파이프라인](merge_request_pipelines.md)을 참조하세요.

## 병합 결과 파이프라인 {#merged-results-pipeline}

*병합 결과 파이프라인*은 소스 브랜치와 대상 브랜치가 함께 병합된 결과에서 실행됩니다. 이는 머지 리퀘스트 파이프라인의 유형입니다.

이 파이프라인은 기본적으로 실행되지 않습니다. `.gitlab-ci.yml` 파일에서 작업을 구성하여 머지 리퀘스트 파이프라인으로 실행하고 병합 결과 파이프라인을 활성화해야 합니다.

이 파이프라인은 파이프라인 목록에서 `merged results` 레이블을 표시합니다.

자세한 내용은 [병합 결과 파이프라인](merged_results_pipelines.md)을 참조하세요.

## 머지 트레인 {#merge-trains}

기본 브랜치로의 병합이 자주 이루어지는 프로젝트에서는 서로 다른 머지 리퀘스트의 변경 사항이 충돌할 수 있습니다. *머지 트레인*을 사용하여 머지 리퀘스트를 큐에 넣습니다. 각 머지 리퀘스트는 다른 이전 머지 리퀘스트와 비교되어 모두 함께 작동하는지 확인합니다.

머지 트레인은 병합 결과 파이프라인과 다릅니다. 병합 결과 파이프라인은 변경 사항이 기본 브랜치의 콘텐츠와 작동하는지 확인하지만 다른 사용자가 동시에 병합 중인 콘텐츠는 확인하지 않습니다.

이 파이프라인은 기본적으로 실행되지 않습니다. `.gitlab-ci.yml` 파일에서 작업을 구성하여 머지 리퀘스트 파이프라인으로 실행하고, 병합 결과 파이프라인을 활성화하고, 머지 트레인을 활성화해야 합니다.

이 파이프라인은 파이프라인 목록에서 `merge train` 레이블을 표시합니다.

자세한 내용은 [머지 트레인](merge_trains.md)을 참조하세요.

## 워크로드 파이프라인 {#workload-pipeline}

워크로드 파이프라인은 GitLab Duo Agent Platform 워크로드의 실행 환경입니다.

워크로드 파이프라인:

- 다음 명명 규칙을 따르는 임시 Git 참조에서 실행됩니다: `refs/workloads/<identifier>`.
- 파이프라인 목록에서 `duo_workflow` 소스를 포함합니다.
- 워크로드 참조는 파이프라인 작업이 완료되거나 실패할 때 자동으로 제거됩니다.

워크로드 파이프라인으로의 링크는 에이전트 또는 플랫폼 세션에서 사용할 수 있습니다.
