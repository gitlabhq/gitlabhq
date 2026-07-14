---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHub 가져오기 모니터링
description: "Prometheus 메트릭을 사용하여 GitLab 셀프 관리형 인스턴스로의 GitHub 가져오기를 모니터링합니다."
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitHub 가져오기 도구는 다양한 Prometheus 메트릭을 노출하며, 이를 사용하여 가져오기 도구의 상태와 진행 상황을 모니터링할 수 있습니다.

## 가져오기 소요 시간 {#import-duration-times}

| 이름                                     | 유형      |
|------------------------------------------|-----------|
| `github_importer_total_duration_seconds` | 히스토그램 |

이 메트릭은 가져온 모든 프로젝트에 대해 프로젝트 생성부터 가져오기 프로세스 완료까지의 소요 시간(초)을 추적합니다. 프로젝트의 이름은 `project` 레이블에 `namespace/name` 형식으로 저장됩니다(예: `gitlab-org/gitlab`).

## 가져온 프로젝트 수 {#number-of-imported-projects}

| 이름                                | 유형    |
|-------------------------------------|---------|
| `github_importer_imported_projects` | 카운터 |

이 메트릭은 시간 경과에 따라 가져온 프로젝트의 총 수를 추적합니다. 이 메트릭은 모든 레이블을 노출하지 않습니다.

## GitHub API 호출 수 {#number-of-github-api-calls}

| 이름                            | 유형    |
|---------------------------------|---------|
| `github_importer_request_count` | 카운터 |

이 메트릭은 모든 프로젝트에 대해 시간 경과에 따라 수행된 GitHub API 호출의 총 수를 추적합니다. 이 메트릭은 모든 레이블을 노출하지 않습니다.

## 속도 제한 오류 {#rate-limit-errors}

| 이름                              | 유형    |
|-----------------------------------|---------|
| `github_importer_rate_limit_hits` | 카운터 |

이 메트릭은 모든 프로젝트에 대해 GitHub 속도 제한에 도달한 횟수를 추적합니다. 이 메트릭은 모든 레이블을 노출하지 않습니다.

## 가져온 이슈 수 {#number-of-imported-issues}

| 이름                              | 유형    |
|-----------------------------------|---------|
| `github_importer_imported_issues` | 카운터 |

이 메트릭은 모든 프로젝트에서 가져온 이슈의 수를 추적합니다.

프로젝트의 이름은 `project` 레이블에 `namespace/name` 형식으로 저장됩니다(예: `gitlab-org/gitlab`).

## 가져온 병합 요청 수 {#number-of-imported-pull-requests}

| 이름                                     | 유형    |
|------------------------------------------|---------|
| `github_importer_imported_pull_requests` | 카운터 |

이 메트릭은 모든 프로젝트에서 가져온 병합 요청의 수를 추적합니다.

프로젝트의 이름은 `project` 레이블에 `namespace/name` 형식으로 저장됩니다(예: `gitlab-org/gitlab`).

## 가져온 댓글 수 {#number-of-imported-comments}

| 이름                             | 유형    |
|----------------------------------|---------|
| `github_importer_imported_notes` | 카운터 |

이 메트릭은 모든 프로젝트에서 가져온 댓글의 수를 추적합니다.

프로젝트의 이름은 `project` 레이블에 `namespace/name` 형식으로 저장됩니다(예: `gitlab-org/gitlab`).

## 가져온 병합 요청 검토 댓글 수 {#number-of-imported-pull-request-review-comments}

| 이름                                  | 유형    |
|---------------------------------------|---------|
| `github_importer_imported_diff_notes` | 카운터 |

이 메트릭은 모든 프로젝트에서 가져온 댓글의 수를 추적합니다.

프로젝트의 이름은 `project` 레이블에 `namespace/name` 형식으로 저장됩니다(예: `gitlab-org/gitlab`).

## 가져온 리포지토리 수 {#number-of-imported-repositories}

| 이름                                    | 유형    |
|-----------------------------------------|---------|
| `github_importer_imported_repositories` | 카운터 |

이 메트릭은 모든 프로젝트에서 가져온 리포지토리의 수를 추적합니다. 이 메트릭은 모든 레이블을 노출하지 않습니다.
