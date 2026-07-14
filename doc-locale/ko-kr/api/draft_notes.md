---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 드래프트 노트(미발행 댓글)에 대한 REST API 문서입니다.
title: 드래프트 노트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 드래프트 노트를 관리합니다. 이러한 노트는 머지 리퀘스트에 대한 보류 중인 미발행 댓글입니다. 드래프트 노트는 토론을 시작하거나 기존 토론에 회신으로 계속할 수 있습니다.

발행하기 전에 드래프트 노트는 작성자에게만 표시됩니다.

## 모든 머지 리퀘스트 임시 노트 나열 {#list-all-merge-request-draft-notes}

모든 머지 리퀘스트 임시 노트를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes"
```

## 임시 노트 검색 {#retrieve-a-draft-note}

머지 리퀘스트의 임시 노트를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `draft_note_id`     | 정수           | 예      | 임시 노트의 ID입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## 임시 노트 생성 {#create-a-draft-note}

머지 리퀘스트의 임시 노트를 생성합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| 속성                   | 유형              | 필수    | 설명           |
| ----------------------------| ----------------- | ----------- | --------------------- |
| `id`                        | 정수 또는 문자열 | 예         | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid`         | 정수           | 예         | 머지 리퀘스트의 IID입니다. |
| `note`                      | 문자열            | 예         | 노트의 내용입니다. |
| `commit_id`                 | 문자열            | 아니요          | 임시 노트와 연결할 커밋의 SHA입니다. |
| `in_reply_to_discussion_id` | 문자열            | 아니요          | 임시 노트가 회신하는 토론의 ID입니다. |
| `resolve_discussion`        | 부울           | 아니요          | 연결된 토론을 해결해야 합니다. |
| `position`                  | 해시              | 아니요          | diff 노트를 만들 때의 위치입니다. 생략하면 일반 토론 노트를 생성합니다. |
| `position[base_sha]`        | 문자열            | `position`이(가) 제공되는 경우 예 | 소스 브랜치의 기본 커밋 SHA입니다. |
| `position[head_sha]`        | 문자열            | `position`이(가) 제공되는 경우 예 | 이 머지 리퀘스트의 HEAD를 참조하는 SHA입니다. |
| `position[start_sha]`       | 문자열            | `position`이(가) 제공되는 경우 예 | 대상 브랜치의 커밋을 참조하는 SHA입니다. |
| `position[new_path]`        | 문자열            | 위치 유형이 `text`인 경우 예 | 변경 후 파일 경로입니다. |
| `position[old_path]`        | 문자열            | 위치 유형이 `text`인 경우 예 | 변경 전 파일 경로입니다. |
| `position[position_type]`   | 문자열            | `position`이(가) 제공되는 경우 예 | 위치 참조의 유형입니다. 허용되는 값: `text`, `image` 또는 `file`. `file` [GitLab 16.4에서 소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/423046). |
| `position[new_line]`        | 정수           | 아니요          | `text` diff 노트의 변경 후 줄 번호입니다. |
| `position[old_line]`        | 정수           | 아니요          | `text` diff 노트의 변경 전 줄 번호입니다. |
| `position[line_range]`      | 해시              | 아니요          | 여러 줄 diff 노트의 줄 범위입니다. |
| `position[width]`           | 정수           | 아니요          | `image` diff 노트의 이미지 너비입니다. |
| `position[height]`          | 정수           | 아니요          | `image` diff 노트의 이미지 높이입니다. |
| `position[x]`               | 부동소수점             | 아니요          | `image` diff 노트의 X 좌표입니다. |
| `position[y]`               | 부동소수점             | 아니요          | `image` diff 노트의 Y 좌표입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes?note=note"
```

## 임시 노트 업데이트 {#update-a-draft-note}

머지 리퀘스트의 임시 노트를 업데이트합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 속성                 | 유형              | 필수 | 설명 |
| ------------------------- | ----------------- | -------- | ----------- |
| `id`                      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `draft_note_id`           | 정수           | 예      | 임시 노트의 ID입니다. |
| `merge_request_iid`       | 정수           | 예      | 머지 리퀘스트의 IID입니다. |
| `note`                    | 문자열            | 아니요       | 노트의 내용입니다. |
| `position`                | 해시              | 아니요       | diff 노트를 만들 때의 위치입니다. |
| `position[base_sha]`      | 문자열            | `position`이(가) 제공되는 경우 예 | 소스 브랜치의 기본 커밋 SHA입니다. |
| `position[head_sha]`      | 문자열            | `position`이(가) 제공되는 경우 예 | 이 머지 리퀘스트의 HEAD를 참조하는 SHA입니다. |
| `position[start_sha]`     | 문자열            | `position`이(가) 제공되는 경우 예 | 대상 브랜치의 커밋을 참조하는 SHA입니다. |
| `position[new_path]`      | 문자열            | 위치 유형이 `text`인 경우 예 | 변경 후 파일 경로입니다. |
| `position[old_path]`      | 문자열            | 위치 유형이 `text`인 경우 예 | 변경 전 파일 경로입니다. |
| `position[position_type]` | 문자열            | `position`이(가) 제공되는 경우 예 | 위치 참조의 유형입니다. 허용되는 값: `text`, `image` 또는 `file`. `file` [GitLab 16.4에서 소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/423046). |
| `position[new_line]`      | 정수           | 아니요       | `text` diff 노트의 변경 후 줄 번호입니다. |
| `position[old_line]`      | 정수           | 아니요       | `text` diff 노트의 변경 전 줄 번호입니다. |
| `position[line_range]`    | 해시              | 아니요       | 여러 줄 diff 노트의 줄 범위입니다. |
| `position[width]`         | 정수           | 아니요       | `image` diff 노트의 이미지 너비입니다. |
| `position[height]`        | 정수           | 아니요       | `image` diff 노트의 이미지 높이입니다. |
| `position[x]`             | 부동소수점             | 아니요       | `image` diff 노트의 X 좌표입니다. |
| `position[y]`             | 부동소수점             | 아니요       | `image` diff 노트의 Y 좌표입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## 임시 노트 삭제 {#delete-a-draft-note}

머지 리퀘스트의 임시 노트를 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | 정수           | 예      | 임시 노트의 ID입니다. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## 임시 노트 게시 {#publish-a-draft-note}

머지 리퀘스트의 임시 노트를 게시합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id/publish
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | 정수           | 예      | 임시 노트의 ID입니다. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5/publish"
```

## 모든 보류 중인 임시 노트 게시 {#publish-all-pending-draft-notes}

사용자에게 속한 머지 리퀘스트의 모든 보류 중인 임시 노트를 게시합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes/bulk_publish
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/bulk_publish"
```
