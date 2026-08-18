---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: VS Code 확장 프로그램의 사용자 지정 쿼리
---

VS Code용 GitLab 확장 프로그램은 **GitLab** ({{< icon name="tanuki" >}}) 패널을 VS Code에 추가하며, 이를 사용하여 [프로젝트에서 작업](projects.md)할 수 있습니다.

기본적으로 패널의 **이슈와 머지 리퀘스트** 섹션에는 다음 검색 쿼리의 결과가 표시됩니다:

- 내게 할당된 이슈
- 내가 만든 이슈
- 내게 할당된 머지 리퀘스트
- 내가 만든 머지 리퀘스트
- 내가 검토 중인 머지 리퀘스트

사용자 지정 쿼리를 사용하여 이 섹션을 사용자 지정하고 중요한 정보를 표시합니다.

## 사용자 지정 쿼리 생성 {#create-a-custom-query}

사용자 지정 쿼리는 **GitLab** ({{< icon name="tanuki" >}}) 패널의 **이슈와 머지 리퀘스트** 아래에 표시된 기본 쿼리를 재정의합니다.

패널에 사용자 지정 쿼리를 사용하려면:

1. VS Code에서 **설정** 편집기를 엽니다:
   - macOS의 경우 <kbd>Command</kbd>+<kbd>,</kbd>를 누릅니다.
   - Windows 또는 Linux의 경우 <kbd>Control</kbd>+<kbd>,</kbd>를 누릅니다.
1. 오른쪽 위 모서리에서 **Open Settings (JSON)**를 선택하여 `settings.json` 파일을 편집하세요.
1. 파일에서 `gitlab.customQueries`을 정의합니다. 다음은 예입니다. 각 쿼리는 `gitlab.customQueries` JSON 배열의 항목이어야 합니다:

   ```json
   {
     "gitlab.customQueries": [
       {
         "name": "Issues assigned to me",
         "type": "issues",
         "scope": "assigned_to_me",
         "noItemText": "No issues assigned to you.",
         "state": "opened"
       }
     ]
   }
   ```

1. 선택 사항. 기본 쿼리를 유지하려면 확장 프로그램의 `default` 배열에서 쿼리를 복사하여 [`desktop.package.json` 파일](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/8e4350232154fe5bf0ef8a6c0765b2eac0496dc7/desktop.package.json#L955-998)에서 복사한 후 `gitlab.customQueries` 배열에 추가 사용자 지정 쿼리로 추가합니다.
1. 변경 사항을 저장합니다.

### 모든 쿼리에 지원되는 매개 변수 {#supported-parameters-for-all-queries}

이러한 매개 변수는 모든 쿼리 유형에 적용됩니다:

| 매개 변수    | 필수    | 기본값           | 정의 |
|--------------|-------------|-------------------|------------|
| `name`       | {{< yes >}} | 없음              | **GitLab** 패널에 표시할 레이블을 지정합니다. |
| `noItemText` | {{< no >}}  | `No items found.` | 쿼리가 0개 항목을 반환할 경우 표시할 텍스트를 지정합니다. |
| `type`       | {{< no >}}  | `merge_requests`  | 반환할 항목 유형을 지정합니다. 가능한 값: `issues`, `merge_requests`, `epics`, `snippets`, `vulnerabilities`. 스니펫은 [다른 필터를 지원하지 않습니다](../../api/project_snippets.md). 에픽은 GitLab Premium 및 Ultimate에서만 사용 가능합니다. |

### 이슈, 에픽, 머지 리퀘스트 쿼리에 지원되는 매개 변수 {#supported-parameters-for-issue-epic-and-merge-request-queries}

이러한 모든 매개 변수는 선택 사항입니다.

| 매개 변수          | 기본값        | 정의 |
|--------------------|----------------|------------|
| `assignee`         | 없음           | 지정된 사용자 이름에 할당된 항목을 반환합니다. `None`은 할당되지 않은 GitLab 항목을 반환합니다. `Any`은 담당자가 있는 GitLab 항목을 반환합니다. 에픽 및 취약성에는 사용할 수 없습니다. |
| `author`           | 없음           | 지정된 사용자 이름으로 만든 항목을 반환합니다. |
| `confidential`     | 없음           | 기밀 또는 공개 이슈를 반환합니다. 이슈에만 사용할 수 있습니다. |
| `createdAfter`     | 없음           | 지정된 날짜 이후에 만든 항목을 반환합니다. |
| `createdBefore`    | 없음           | 지정된 날짜 이전에 만든 항목을 반환합니다. |
| `draft`            | `no`           | 초안 상태로 필터링한 머지 리퀘스트를 반환합니다. `yes`는 [초안 상태](../../user/project/merge_requests/drafts.md)의 머지 리퀘스트만 반환하고, `no`은 초안 상태가 아닌 머지 리퀘스트만 반환합니다. 머지 리퀘스트에만 사용할 수 있습니다. |
| `excludeAssignee`  | 없음           | 지정된 사용자 이름에 할당되지 않은 항목을 반환합니다. 이슈에만 사용할 수 있습니다. 현재 사용자에게는 `<current_user>`로 설정합니다. |
| `excludeAuthor`    | 없음           | 지정된 사용자 이름으로 만들지 않은 항목을 반환합니다. 이슈에만 사용할 수 있습니다. 현재 사용자에게는 `<current_user>`로 설정합니다. |
| `excludeLabels`    | `[]`           | 지정된 배열의 레이블 중 어느 것도 없는 항목을 반환합니다. 이슈에만 사용할 수 있습니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `excludeMilestone` | 없음           | 지정된 마일스톤 제목을 제외하는 항목을 반환합니다. 이슈에만 사용할 수 있습니다. |
| `excludeSearch`    | 없음           | 제목이나 설명에 검색 키가 없는 항목을 반환합니다. 이슈에만 작동합니다. |
| `labels`           | `[]`           | 지정된 배열의 모든 레이블을 가진 항목을 반환합니다. `None`은 레이블이 없는 항목을 반환합니다. `Any`은 하나 이상의 레이블을 가진 항목을 반환합니다. 미리 정의된 이름은 대소문자를 구분하지 않습니다. |
| `maxResults`       | 20             | 이 개수까지의 결과를 반환합니다. |
| `milestone`        | 없음           | 지정된 마일스톤 제목과 일치하는 항목을 반환합니다. `None`은 마일스톤이 없는 모든 항목을 반환합니다. `Any`은 할당된 마일스톤이 있는 모든 항목을 반환합니다. 에픽 및 취약성에는 사용할 수 없습니다. |
| `orderBy`          | `created_at`   | 선택한 값으로 정렬된 항목을 반환합니다. 가능한 값: `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. 일부 값은 이슈에만 해당하고 일부는 머지 리퀘스트에만 해당합니다. 자세한 내용은 [머지 리퀘스트 목록](../../api/merge_requests.md#list-merge-requests)을 참조하세요. |
| `reviewer`         | 없음           | 검토자로 지정된 사용자 이름이 있는 머지 리퀘스트를 반환합니다. 현재 사용자에게는 `<current_user>`로 설정합니다. `None`은 검토자 없는 항목을 반환합니다. `Any`은 검토자가 있는 항목을 반환합니다. |
| `scope`            | `all`          | 지정된 범위의 항목을 반환합니다. 에픽에는 적용되지 않습니다. 가능한 값: `assigned_to_me`, `created_by_me`, `all`. |
| `search`           | 없음           | 제목 및 설명에서 지정된 검색어가 있는 항목을 반환합니다. |
| `searchIn`         | `all`          | `excludeSearch` 속성이 지정된 값으로 범위가 지정된 결과를 반환합니다. 가능한 값: `all`, `title`, `description`. 이슈에만 작동합니다. |
| `sort`             | `desc`         | 오름차순 또는 내림차순으로 정렬된 이슈를 반환합니다. 가능한 값: `asc`, `desc`. |
| `state`            | `opened`       | 모든 이슈를 반환하거나 특정 상태와 일치하는 이슈만 반환합니다. 가능한 값: `all`, `opened`, `closed`. |
| `updatedAfter`     | 없음           | 지정된 날짜 이후에 업데이트된 항목을 반환합니다. |
| `updatedBefore`    | 없음           | 지정된 날짜 이전에 업데이트된 항목을 반환합니다. |

### 취약성 보고서 쿼리에 지원되는 매개 변수 {#supported-parameters-for-vulnerability-report-queries}

취약성 보고서는 다른 항목 유형과 [공통 쿼리 매개 변수](../../api/vulnerability_findings.md)를 공유하지 않습니다. 이 테이블에 나열된 각 매개 변수는 취약성 보고서에만 작동하며 모든 매개 변수는 선택 사항입니다:

| 매개 변수          | 기본값        | 정의 |
|--------------------|----------------|------------|
| `confidenceLevels` | `all`          | 지정된 신뢰도 수준이 있는 취약성을 반환합니다. 가능한 값: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, `confirmed`. |
| `reportTypes`      | 없음           | 지정된 보고서 유형이 있는 취약성을 반환합니다. 가능한 값: `sast`, `dast`, `dependency_scanning`, `container_scanning`. |
| `scope`            | `dismissed`    | 지정된 범위의 취약성을 반환합니다. 가능한 값: `all`, `dismissed`. 자세한 내용은 [취약성 검색 API](../../api/vulnerability_findings.md)를 참조하세요. |
| `severityLevels`   | `all`          | 지정된 심각도 수준이 있는 취약성을 반환합니다. 가능한 값: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, `critical`. |
