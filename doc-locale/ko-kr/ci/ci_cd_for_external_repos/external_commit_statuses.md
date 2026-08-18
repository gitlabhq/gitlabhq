---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 커밋 상태
description: 외부 CI/CD 시스템이 커밋 상태를 사용하여 GitLab 파이프라인과 통합되는 방법입니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

외부 커밋 상태는 Jenkins, CircleCI 또는 사용자 지정 배포 도구와 같은 외부 CI/CD 시스템이 GitLab 파이프라인과 통합되도록 허용합니다. 외부 시스템은 커밋 상태를 GitLab으로 다시 게시하고, 상태 결과는 머지 리퀘스트 파이프라인과 커밋 보기에서 CI/CD 작업과 함께 나타납니다.

외부 시스템이 [Commits API](../../api/commits.md#set-commit-pipeline-status)를 사용하여 커밋 상태를 게시하면, GitLab은 이러한 상태를 기존 파이프라인에 추가하거나 이들을 포함할 새 파이프라인을 생성하여 처리합니다.

## 파이프라인 선택 {#pipeline-selection}

외부 시스템에서 커밋 상태를 게시할 때 찾기 또는 생성 방식을 사용합니다:

1. GitLab은 주어진 커밋 SHA 및 ref에 대해 가장 최근의 `non-archived` CI 파이프라인을 검색합니다. `pipeline_id` 매개 변수를 포함하여 파이프라인을 직접 검색할 수도 있습니다.
1. GitLab이 적합한 파이프라인을 찾으면, 새로운 작업 상태를 해당 파이프라인에 추가합니다. 기존 파이프라인에 추가된 작업의 경우, `CI_PIPELINE_SOURCE`은 파이프라인 소스와 일치합니다(예: `push` 또는 `merge_request_event`).
1. 적합한 파이프라인이 없으면, GitLab은 작업을 포함할 새 파이프라인을 생성합니다. 새 파이프라인의 경우, `CI_PIPELINE_SOURCE`은 `external`입니다.

외부 작업 상태는 파이프라인의 `external` 스테이지에 나타나며, 다른 GitLab CI/CD 스테이지와 분리됩니다.

> [!warning]
> 중복 파이프라인이 같은 커밋에 대해 존재하면, 외부 상태 배치가 모호해집니다. GitLab은 `newest_first`을 사용하여 최신 파이프라인을 선택하지만, 동시 파이프라인 생성의 경우, 외부 상태가 예상치 못한 파이프라인에 나타나거나 머지 리퀘스트 파이프라인 보기에서 보이지 않을 수 있습니다.
>
> [workflow rules](../yaml/workflow.md)를 구성하여 중복 파이프라인을 방지하거나 `pipeline_id`로 파이프라인을 직접 대상으로 지정합니다.

## 작업 업데이트 및 재시도 {#job-updates-and-retries}

외부 시스템에서 커밋 상태를 게시할 때:

- 같은 `name` `user` 및 `sha`을 가진 `running` 또는 `pending` 작업이 대상 파이프라인에 이미 존재하면, GitLab은 해당 상태를 업데이트합니다.
  - 다른 사용자가 같은 `name`을 가진 작업을 업데이트하면, 작업이 재시도됩니다. 이는 새 작업을 생성하고 현재 파이프라인에서 이전 작업을 숨깁니다.
- 같은 `name`을 가지지만 다른 `status`을 가진 `running` 또는 `pending` 상태가 아닌 작업을 재시도할 수 있습니다(예: 작업이 `failed`으로 표시된 경우 `success`를 전송합니다). 이는 새 작업을 생성하고 현재 파이프라인에서 이전 작업을 숨깁니다.
- 다양한 외부 서비스는 고유한 작업 `name`을 사용하여 같은 SHA 및 파이프라인에 작업을 추가할 수 있습니다.

SHA/ref 조합에 대해 업데이트가 이미 진행 중이면, `409` 오류가 반환됩니다. 이 오류를 처리하기 위해 요청을 재시도합니다.

## 문제 해결 {#troubleshooting}

### 외부 상태가 머지 리퀘스트 파이프라인에서 보이지 않음 {#external-statuses-not-visible-in-merge-requests}

외부 CI 상태가 머지 리퀘스트 파이프라인에 나타나지 않으면:

1. 같은 커밋에 대해 머지 리퀘스트 파이프라인과 브랜치 파이프라인이 모두 실행 중인지 확인합니다.
1. [workflow rules](../yaml/workflow.md)가 중복 파이프라인을 방지하는지 확인합니다.
1. 외부 시스템이 올바른 ref로 게시하고 있는지 확인합니다.
1. 커밋이 머지 리퀘스트와 연결되어 있으면, API 호출이 머지 리퀘스트의 소스 브랜치에서 커밋을 대상으로 하도록 합니다.

자세한 내용은 [avoid duplicate pipelines](../jobs/job_rules.md#avoid-duplicate-pipelines)를 참조합니다.
