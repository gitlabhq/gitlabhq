---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 REST API를 통한 머지 리퀘스트 컨텍스트 커밋에 대한 설명서입니다.
title: 머지 리퀘스트 컨텍스트 커밋 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 리퀘스트가 이전 머지 리퀘스트를 기반으로 한다면, 머지 리퀘스트에서 [컨텍스트를 위해 이전에 병합된 커밋 포함](../user/project/merge_requests/commits.md#show-commits-from-previous-merge-requests)이 필요할 수 있습니다. 이 API를 사용하여 더 많은 컨텍스트를 위해 머지 리퀘스트에 커밋을 추가할 수 있습니다.

## 머지 리퀘스트의 컨텍스트 커밋 목록 {#list-context-commits-for-a-merge-request}

단일 머지 리퀘스트의 컨텍스트 커밋을 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

매개변수:

| 속성           | 유형    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 정수 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수 | 예 | 머지 리퀘스트의 내부 ID입니다. |

```json
[
    {
        "id": "4a24d82dbca5c11c61556f3b35ca472b7463187e",
        "short_id": "4a24d82d",
        "created_at": "2017-04-11T10:08:59.000Z",
        "parent_ids": null,
        "title": "Update README.md to include `Usage in testing and development`",
        "message": "Update README.md to include `Usage in testing and development`",
        "author_name": "Example \"Sample\" User",
        "author_email": "user@example.com",
        "authored_date": "2017-04-11T10:08:59.000Z",
        "committer_name": "Example \"Sample\" User",
        "committer_email": "user@example.com",
        "committed_date": "2017-04-11T10:08:59.000Z"
    }
]
```

## 머지 리퀘스트의 컨텍스트 커밋 생성 {#create-context-commits-for-a-merge-request}

단일 머지 리퀘스트의 컨텍스트 커밋을 생성합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/context_commits
```

매개변수:

| 속성           | 유형    | 필수 | 설명 |
|---------------------|---------|----------|-------------|
| `id`                | 정수 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `merge_request_iid` | 정수 | 예 | 머지 리퀘스트의 내부 ID입니다. |
| `commits`           | 문자열 배열 | 예 | 컨텍스트 커밋의 SHA입니다. |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"commits": ["51856a574ac3302a95f82483d6c7396b1e0783cb"]}' \
  --url "https://gitlab.example.com/api/v4/projects/15/merge_requests/12/context_commits"
```

응답 예시:

```json
[
    {
        "id": "51856a574ac3302a95f82483d6c7396b1e0783cb",
        "short_id": "51856a57",
        "created_at": "2014-02-27T10:05:10.000+02:00",
        "parent_ids": [
            "57a82e2180507c9e12880c0747f0ea65ad489515"
        ],
        "title": "Commit title",
        "message": "Commit message",
        "author_name": "Example User",
        "author_email": "user@example.com",
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Example User",
        "committer_email": "user@example.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "trailers": {},
        "web_url": "https://gitlab.example.com/project/path/-/commit/b782f6c553653ab4e16469ff34bf3a81638ac304"
    }
]
```

## 머지 리퀘스트에서 컨텍스트 커밋 삭제 {#delete-context-commits-from-a-merge-request}

단일 머지 리퀘스트에서 컨텍스트 커밋을 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

매개변수:

| 속성           | 유형         | 필수 | 설명  |
|---------------------|--------------|----------|--------------|
| `commits`           | 문자열 배열 | 예 | 컨텍스트 커밋의 SHA입니다. |
| `id`                | 정수      | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수      | 예 | 머지 리퀘스트의 내부 ID입니다. |
