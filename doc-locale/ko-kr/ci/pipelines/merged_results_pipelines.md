---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지된 결과 파이프라인을 사용하여 소스 브랜치와 대상 브랜치 코드를 병합하기 전에 함께 테스트합니다.
title: 머지된 결과 파이프라인
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지된 결과 파이프라인은 소스 브랜치와 대상 브랜치 코드를 결합한 임시 머지 커밋을 테스트합니다. 이 커밋은 어느 브랜치에도 존재하지 않지만 파이프라인 상세 정보에서 확인할 수 있습니다.

이 접근 방식은 최신 대상 브랜치의 코드와 변경 사항이 제대로 작동하는지 확인하고, 머지하기 전에 통합 문제를 감지하며, 다양한 파일의 변경 사항이 함께 작동하는지 확인하는 데 도움이 됩니다.

머지된 결과 파이프라인은 대상 브랜치의 변경 사항이 소스 브랜치의 변경 사항과 충돌할 때 실행할 수 없습니다. 이러한 경우에 GitLab은 표준 머지 리퀘스트 파이프라인을 대신 실행합니다.

## 머지된 결과 파이프라인 활성화 {#enable-merged-results-pipelines}

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.
- 사용자의 `.gitlab-ci.yml` 파일은 [머지 리퀘스트 파이프라인](merge_request_pipelines.md#prerequisites)에 맞게 구성되어야 합니다.
- 프로젝트는 GitLab에 호스팅되어야 합니다(GitHub 또는 Bitbucket 같은 외부 리포지토리가 아님).

프로젝트에서 머지된 결과 파이프라인을 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **머지 리퀘스트**를 선택합니다.
1. **머지 옵션**에서 **머지된 결과 파이프라인 활성화**를 선택합니다.
1. **변경사항 저장**을 선택합니다.

> [!warning]
> `.gitlab-ci.yml` 파일에서 머지 리퀘스트 파이프라인을 구성하지 않고 이 설정을 활성화하면 머지 리퀘스트가 미해결 상태에서 멈추거나 파이프라인이 삭제될 수 있습니다.

## 문제 해결 {#troubleshooting}

머지된 결과 파이프라인으로 작업할 때 다음 문제가 발생할 수 있습니다.

### 작업 또는 파이프라인이 `rules:changes:compare_to`에서 예상치 못하게 실행됩니다 {#jobs-or-pipelines-run-unexpectedly-with-ruleschangescompare_to}

`rules:changes:compare_to`을 머지 리퀘스트 파이프라인과 함께 사용할 때 작업 또는 파이프라인이 예상치 못하게 실행될 수 있습니다.

이 문제는 머지된 결과 파이프라인이 비교 기준으로 임시 머지 커밋을 사용하기 때문에 발생합니다. 이 커밋은 머지 리퀘스트 브랜치와 대상 브랜치의 변경 사항을 포함하며, 규칙이 예상치 못하게 트리거될 수 있습니다.

예를 들어, 머지 리퀘스트가 `src/feature.js`을 추가하고 대상 브랜치가 `src/utils.js`를 포함하는 경우, 임시 머지 커밋은 두 파일을 모두 포함합니다. `rules:changes:compare_to: main`이 포함된 규칙은 기능 파일만이 아닌 모든 변경 사항을 감지하며, 변경 사항에만 실행되어야 하는 작업을 트리거할 수 있습니다.

이 이슈를 해결하려면:

- 기본 비교 동작을 사용하려면 `compare_to` 매개변수를 제거합니다.
- 변경 규칙에서 더 구체적인 파일 경로 패턴을 사용합니다.
- `rules:changes`을 `compare_to` 없이 사용하는 것을 고려하세요.

### 성공한 머지된 결과 파이프라인이 실패한 브랜치 파이프라인 재정의 {#successful-merged-results-pipeline-overrides-a-failed-branch-pipeline}

[**파이프라인이 성공해야 함** 설정](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이 활성화되면 실패한 브랜치 파이프라인이 무시되는 상황이 발생할 수 있습니다.

이 문제는 파이프라인 논리 우선순위 지정으로 인해 발생합니다. 개선 사항 지원은 [이슈 385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841)에서 제안됩니다.
