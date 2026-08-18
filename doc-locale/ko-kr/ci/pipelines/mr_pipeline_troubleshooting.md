---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 머지 리퀘스트 파이프라인 문제 해결
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 리퀘스트 파이프라인으로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

## 브랜치에 푸시할 때 두 개의 작업 파이프라인 {#two-pipelines-when-pushing-to-a-branch}

머지 리퀘스트에서 중복된 파이프라인을 가져오면 파이프라인이 동시에 브랜치와 머지 리퀘스트 모두에 대해 실행되도록 구성되었을 수 있습니다. 작업 파이프라인 구성을 조정하여 [중복 파이프라인 방지](../jobs/job_rules.md#avoid-duplicate-pipelines)합니다.

`workflow:rules`을 추가하여 [브랜치 파이프라인에서 머지 리퀘스트 파이프라인으로 전환](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)할 수 있습니다. 브랜치에서 머지 리퀘스트를 열면 파이프라인이 머지 리퀘스트 파이프라인으로 전환됩니다.

## 잘못된 CI/CD 구성 파일을 푸시할 때 두 개의 작업 파이프라인 {#two-pipelines-when-pushing-an-invalid-cicd-configuration-file}

머지 리퀘스트의 브랜치에 잘못된 CI/CD 구성을 푸시하면 파이프라인 탭에 실패한 두 개의 파이프라인이 표시됩니다. 하나의 파이프라인은 실패한 브랜치 파이프라인이고 다른 하나는 실패한 머지 리퀘스트 파이프라인입니다.

구성 문법이 수정되면 더 이상 실패한 파이프라인이 나타나지 않아야 합니다. 구성 문제를 찾고 수정하려면 다음을 사용할 수 있습니다:

- [작업 파이프라인 편집기](../pipeline_editor/_index.md)입니다.
- [CI 린트 도구](../yaml/lint.md)입니다.

## 머지 리퀘스트의 파이프라인이 실패로 표시되지만 최신 파이프라인이 성공함 {#the-merge-requests-pipeline-is-marked-as-failed-but-the-latest-pipeline-succeeded}

단일 머지 리퀘스트의 **파이프라인** 탭에 브랜치 파이프라인과 머지 리퀘스트 파이프라인을 모두 가질 수 있습니다. 이는 [구성에 따라](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines) 또는 [실수로](#two-pipelines-when-pushing-to-a-branch) 발생할 수 있습니다.

작업 프로젝트에 [**파이프라인이 성공해야 함**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이 활성화되어 있고 두 파이프라인 유형이 모두 있으면 브랜치 파이프라인이 아닌 머지 리퀘스트 파이프라인이 확인됩니다.

따라서 **branch pipeline** 결과와 무관하게 **merge request pipeline**이 실패하면 MR 파이프라인 결과가 실패로 표시됩니다.

하지만:

- 이러한 조건은 적용되지 않습니다.
- 경합 조건이 머지 리퀘스트를 차단하거나 통과시키는 데 사용되는 파이프라인 결과를 결정합니다.

이 버그는 [이슈 384927](https://gitlab.com/gitlab-org/gitlab/-/issues/384927)에서 추적됩니다.

## `An error occurred while trying to run a new pipeline for this merge request.` {#an-error-occurred-while-trying-to-run-a-new-pipeline-for-this-merge-request}

머지 리퀘스트에서 **파이프라인 실행**을 선택하지만 프로젝트에 더 이상 머지 리퀘스트 파이프라인이 활성화되어 있지 않으면 이 오류가 발생할 수 있습니다.

이 오류 메시지의 가능한 이유는 다음과 같습니다:

- 프로젝트에 머지 리퀘스트 파이프라인이 활성화되어 있지 않고 **파이프라인** 탭에 나열된 파이프라인이 없으며 **Run pipelines**을 선택합니다.
- 프로젝트는 이전에 머지 리퀘스트 파이프라인이 활성화되어 있었지만 구성이 제거되었습니다. 예를 들어:

  1. 프로젝트에 머지 리퀘스트를 생성할 때 `.gitlab-ci.yml` 구성 파일에서 머지 리퀘스트 파이프라인이 활성화되어 있습니다.
  1. **파이프라인 실행** 옵션이 머지 리퀘스트의 **파이프라인** 탭에서 사용 가능하며 이 시점에서 **파이프라인 실행**을 선택하면 오류가 발생할 가능성이 낮습니다.
  1. 프로젝트의 `.gitlab-ci.yml` 파일이 머지 리퀘스트 파이프라인 구성을 제거하도록 변경되었습니다.
  1. 브랜치가 리베이스되어 업데이트된 구성이 머지 리퀘스트로 가져와집니다.
  1. 이제 작업 파이프라인 구성은 더 이상 머지 리퀘스트 파이프라인을 지원하지 않지만 **파이프라인 실행**을 선택하여 머지 리퀘스트 파이프라인을 실행합니다.

**파이프라인 실행**이 사용 가능하지만 프로젝트에 머지 리퀘스트 파이프라인이 활성화되어 있지 않으면 이 옵션을 사용하지 마세요. 작업 커밋을 푸시하거나 브랜치를 리베이스하여 새로운 브랜치 파이프라인을 트리거할 수 있습니다.

## `Merge blocked: pipeline must succeed. Push a new commit that fixes the failure` 메시지 {#merge-blocked-pipeline-must-succeed-push-a-new-commit-that-fixes-the-failure-message}

이 메시지는 머지 리퀘스트 파이프라인, [병합 결과 파이프라인](merged_results_pipelines.md), 또는 [머지 트레인 파이프라인](merge_trains.md)이 실패했거나 취소된 경우 표시됩니다. 이는 브랜치 파이프라인이 실패할 때 발생하지 않습니다.

머지 리퀘스트 파이프라인 또는 병합 결과 파이프라인이 취소되었거나 실패한 경우 다음을 수행할 수 있습니다:

- 머지 리퀘스트의 작업 파이프라인 탭에서 **파이프라인 실행**을 선택하여 전체 파이프라인을 다시 실행합니다.
- [실패한 작업만 다시 시도](_index.md#view-pipelines)합니다. 전체 파이프라인을 다시 실행하면 이는 필요하지 않습니다.
- 실패를 수정하기 위해 새로운 작업 커밋을 푸시합니다.

머지 트레인 파이프라인이 실패한 경우 다음을 수행할 수 있습니다:

- 실패를 확인하고 [`/merge` 빠른 작업](../../user/project/quick_actions.md#merge)을 사용하여 머지 리퀘스트를 트레인에 즉시 추가할 수 있는지 확인합니다.
- 머지 리퀘스트의 작업 파이프라인 탭에서 **파이프라인 실행**을 선택하여 전체 파이프라인을 다시 실행한 다음 머지 리퀘스트를 트레인에 다시 추가합니다.
- 실패를 수정하기 위해 작업 커밋을 푸시한 다음 머지 리퀘스트를 트레인에 다시 추가합니다.

머지 트레인 파이프라인이 실패 없이 머지되기 전에 취소된 경우 다음을 수행할 수 있습니다:

- 트레인에 다시 추가합니다.
