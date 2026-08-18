---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 검색 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [GitLab 전체에서 검색](../user/search/_index.md)합니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

[기본 검색](../user/search/_index.md#available-scopes)에 사용할 수 있는 일부 범위가 있습니다. [고급 검색](../user/search/advanced_search.md#available-scopes) 또는 [정확한 코드 검색](../user/search/exact_code_search.md#available-scopes) 을 사용할 수 있는 경우, [전역 검색](#search-an-instance) , [그룹 검색](#search-a-group) , [프로젝트 검색](#search-a-project) 작업에 추가 범위를 사용할 수 있습니다.

대신 기본 검색을 사용하려면 [검색 유형 지정](../user/search/_index.md#specify-a-search-type)을 참조하세요.

검색 API는 [오프셋 기반 페이지네이션](rest/_index.md#offset-based-pagination)을 지원합니다.

## 인스턴스 검색 {#search-an-instance}

[용어](../user/search/advanced_search.md#syntax)를 전체 GitLab 인스턴스에서 검색합니다. 응답은 요청된 범위에 따라 달라집니다.

```plaintext
GET /search
```

| 속성          | 유형             | 필수 | 설명                                                                                                                                                                                                    |
|--------------------|------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`            | 문자열           | 예      | 검색할 범위입니다. `projects`, `issues`, `work_items`, `merge_requests`, `milestones`, `snippet_titles`, `users`이 포함됩니다. 추가 범위는 `wiki_blobs`, `commits`, `blobs`, `notes`입니다.               |
| `search`           | 문자열           | 예      | 검색 용어입니다.                                                                                                                                                                                               |
| `search_type`      | 문자열           | 아니요       | 사용할 검색 유형입니다. `basic`, `advanced`, `zoekt`이 포함됩니다.                                                                                                                                       |
| `confidential`     | 부울          | 아니요       | 기밀성별로 필터링합니다. `issues` 및 `work_items` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                                  |
| `exclude_forks`      | 부울          | 아니요       | 검색에서 포크된 프로젝트를 제외합니다. 정확한 코드 검색에 사용할 수 있습니다. 설정하지 않으면 포크가 제외됩니다. GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281).          |
| `regex`              | 부울          | 아니요       | 정규식을 사용하여 코드를 검색합니다. 정확한 코드 검색에 사용할 수 있습니다. 설정하지 않으면 정규식을 사용합니다. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686). |
| `fields`             | 문자열 배열 | 아니요       | 검색하려는 필드의 배열입니다. 허용되는 값은 `title`만 해당합니다. `issues` 및 `merge_requests` 범위만 지원합니다. Premium 및 Ultimate만 해당합니다.                                                            |
| `include_archived`   | 부울          | 아니요       | 검색에 보관된 프로젝트를 포함합니다. 기본값은 `false`입니다. GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281).                                                           |
| `num_context_lines`  | 정수          | 아니요       | 결과에서 각 일치 항목 주변에 포함할 컨텍스트 라인의 수입니다. 고급 및 정확한 코드 검색에서만 사용할 수 있습니다. GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217). |
| `state`              | 문자열           | 아니요       | 상태별로 필터링합니다. `issues`, `work_items`, `merge_requests` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                      |
| `type`               | 문자열 배열 | 아니요       | 유형별로 작업 항목을 필터링합니다. `work_items` 범위에만 적용됩니다. 사용 가능한 유형: `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | 문자열           | 아니요       | 허용되는 값은 `created_at`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                              |
| `sort`               | 문자열           | 아니요       | 허용되는 값은 `asc` 또는 `desc`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                           |

### 범위: `projects` {#scope-projects}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=projects&search=flight"
```

응답 예시:

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### 범위: `issues` {#scope-issues}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=issues&search=file"
```

응답 예시:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. GitLab EE API를 준수하기 위해 단일 크기 배열 `assignees`로 표시됩니다.

### 범위: `work_items` {#scope-work_items}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=migrate"
```

응답 예시:

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

`type` 매개변수를 사용하여 작업 항목을 유형별로 필터링할 수 있습니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### 범위: `merge_requests` {#scope-merge_requests}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=merge_requests&search=file"
```

응답 예시:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### 범위: `milestones` {#scope-milestones}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=milestones&search=release"
```

응답 예시:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### 범위: `snippet_titles` {#scope-snippet_titles}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=snippet_titles&search=sample"
```

응답 예시:

```json
[
  {
    "id": 50,
    "title": "Sample file",
    "file_name": "file.rb",
    "description": "Simple ruby file",
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "updated_at": "2018-02-06T12:49:29.104Z",
    "created_at": "2017-11-28T08:20:18.071Z",
    "project_id": 9,
    "web_url": "http://localhost:3000/root/jira-test/snippets/50"
  }
]
```

### 범위: `users` {#scope-users}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=users&search=doe"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### 범위: `wiki_blobs` {#scope-wiki_blobs}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위를 사용하여 위키를 검색합니다.

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=wiki_blobs&search=bye"
```

응답 예시:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": null
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요.

### 범위: `commits` {#scope-commits}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=commits&search=bye"
```

응답 예시:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### 범위: `blobs` {#scope-blobs}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위를 사용하여 코드를 검색합니다.

이 범위는 [고급 검색](../user/search/advanced_search.md#use-advanced-search) 또는 [정확한 코드 검색](../user/search/exact_code_search.md#use-exact-code-search)을 사용할 수 있을 때만 사용할 수 있습니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=blobs&search=installation"
```

응답 예시:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요. Elasticsearch 구문은 정확한 코드 검색에서 제대로 작동하지 않을 수 있습니다. 정확한 코드 검색을 위해 Elasticsearch 와일드카드 쿼리를 정규식으로 바꿉니다. 자세한 내용은 [이슈 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)을 참조하세요.

### 범위: `notes` {#scope-notes}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=notes&search=maxime"
```

응답 예시:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## 그룹 검색 {#search-a-group}

지정된 그룹에서 [용어](../user/search/_index.md)를 검색합니다.

사용자가 그룹의 멤버가 아니고 그룹이 비공개인 경우, 해당 그룹에 대한 `GET` 요청은 `404 Not Found` 상태 코드를 반환합니다.

```plaintext
GET /groups/:id/search
```

| 속성          | 유형              | 필수 | 설명                                                                                                                                                                                                    |
|--------------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`               | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.                                                                                                                                    |
| `scope`            | 문자열            | 예      | 검색할 범위입니다. `projects`, `issues`, `work_items`, `merge_requests`, `milestones`, `users`이 포함됩니다. 추가 범위는 `wiki_blobs`, `commits`, `blobs`, `notes`입니다.                                 |
| `search`           | 문자열            | 예      | 검색 용어입니다.                                                                                                                                                                                               |
| `search_type`      | 문자열            | 아니요       | 사용할 검색 유형입니다. `basic`, `advanced`, `zoekt`이 포함됩니다.                                                                                                                                       |
| `confidential`     | 부울           | 아니요       | 기밀성별로 필터링합니다. `issues` 및 `work_items` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                                  |
| `exclude_forks`      | 부울           | 아니요       | 검색에서 포크된 프로젝트를 제외합니다. 정확한 코드 검색에 사용할 수 있습니다. 설정하지 않으면 포크가 제외됩니다. GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281).          |
| `regex`              | 부울           | 아니요       | 정규식을 사용하여 코드를 검색합니다. 정확한 코드 검색에 사용할 수 있습니다. 설정하지 않으면 정규식을 사용합니다. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686). |
| `fields`             | 문자열 배열  | 아니요       | 검색하려는 필드의 배열입니다. 허용되는 값은 `title`만 해당합니다. `issues` 및 `merge_requests` 범위만 지원합니다. Premium 및 Ultimate만 해당합니다.                                                            |
| `include_archived`   | 부울           | 아니요       | 검색에 보관된 프로젝트를 포함합니다. 기본값은 `false`입니다. GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281).                                                           |
| `num_context_lines`  | 정수           | 아니요       | 결과에서 각 일치 항목 주변에 포함할 컨텍스트 라인의 수입니다. 고급 및 정확한 코드 검색에서만 사용할 수 있습니다. GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217). |
| `state`              | 문자열            | 아니요       | 상태별로 필터링합니다. `issues`, `work_items`, `merge_requests` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                      |
| `type`               | 문자열 배열  | 아니요       | 유형별로 작업 항목을 필터링합니다. `work_items` 범위에만 적용됩니다. 사용 가능한 유형: `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | 문자열            | 아니요       | 허용되는 값은 `created_at`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                              |
| `sort`               | 문자열            | 아니요       | 허용되는 값은 `asc` 또는 `desc`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                           |

응답은 요청된 범위에 따라 달라집니다.

### 범위: `projects` {#scope-projects-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=projects&search=flight"
```

응답 예시:

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### 범위: `issues` {#scope-issues-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=issues&search=file"
```

응답 예시:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. 이제 단일 크기의 `assignees` 배열입니다.

### 범위: `work_items` {#scope-work_items-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=migrate"
```

응답 예시:

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

`type` 매개변수를 사용하여 작업 항목을 유형별로 필터링할 수 있습니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### 범위: `merge_requests` {#scope-merge_requests-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=merge_requests&search=file"
```

응답 예시:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### 범위: `milestones` {#scope-milestones-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=milestones&search=release"
```

응답 예시:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### 범위: `users` {#scope-users-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=users&search=doe"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### 범위: `wiki_blobs` {#scope-wiki_blobs-1}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위를 사용하여 위키를 검색합니다.

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=wiki_blobs&search=bye"
```

응답 예시:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요.

### 범위: `commits` {#scope-commits-1}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=commits&search=bye"
```

응답 예시:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### 범위: `blobs` {#scope-blobs-1}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위를 사용하여 코드를 검색합니다.

이 범위는 [고급 검색](../user/search/advanced_search.md#use-advanced-search) 또는 [정확한 코드 검색](../user/search/exact_code_search.md#use-exact-code-search)을 사용할 수 있을 때만 사용할 수 있습니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=blobs&search=installation"
```

응답 예시:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요. Elasticsearch 구문은 정확한 코드 검색에서 제대로 작동하지 않을 수 있습니다. 정확한 코드 검색을 위해 Elasticsearch 와일드카드 쿼리를 정규식으로 바꿉니다. 자세한 내용은 [이슈 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)을 참조하세요.

### 범위: `notes` {#scope-notes-1}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

이 범위는 [고급 검색을 사용할 수 있을 때](../user/search/advanced_search.md#use-advanced-search)만 사용할 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=notes&search=maxime"
```

응답 예시:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## 프로젝트 검색 {#search-a-project}

지정된 프로젝트에서 [용어](../user/search/_index.md)를 검색합니다.

사용자가 프로젝트의 멤버가 아니고 프로젝트가 비공개인 경우, 해당 프로젝트에 대한 `GET` 요청 결과는 `404` 상태 코드입니다.

```plaintext
GET /projects/:id/search
```

| 속성      | 유형              | 필수 | 설명                                                                                                                                                                                                    |
|----------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.                                                                                                                                  |
| `scope`              | 문자열            | 예      | 검색할 범위입니다. `issues`, `work_items`, `merge_requests`, `milestones`, `users`이 포함됩니다. 추가 범위는 `wiki_blobs`, `commits`, `blobs`, `notes`입니다.                                             |
| `search`             | 문자열            | 예      | 검색 용어입니다.                                                                                                                                                                                               |
| `search_type`        | 문자열            | 아니요       | 사용할 검색 유형입니다. `basic`, `advanced`, `zoekt`이 포함됩니다.                                                                                                                                       |
| `confidential`       | 부울           | 아니요       | 기밀성별로 필터링합니다. `issues` 및 `work_items` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                                  |
| `regex`              | 부울           | 아니요       | 정규식을 사용하여 코드를 검색합니다. 정확한 코드 검색에 사용할 수 있습니다. 설정하지 않으면 정규식을 사용합니다. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686). |
| `fields`             | 문자열 배열  | 아니요       | 검색하려는 필드의 배열입니다. 허용되는 값은 `title`만 해당합니다. `issues` 및 `merge_requests` 범위만 지원합니다. Premium 및 Ultimate만 해당합니다.                                                            |
| `num_context_lines`  | 정수           | 아니요       | 결과에서 각 일치 항목 주변에 포함할 컨텍스트 라인의 수입니다. 고급 및 정확한 코드 검색에서만 사용할 수 있습니다. GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217). |
| `ref`                | 문자열            | 아니요       | 검색할 리포지토리 브랜치 또는 태그의 이름입니다. 프로젝트의 기본 브랜치가 기본적으로 사용됩니다. 범위 `blobs`, `commits`, `wiki_blobs`에만 적용됩니다.                                         |
| `state`              | 문자열            | 아니요       | 상태별로 필터링합니다. `issues`, `work_items`, `merge_requests` 범위를 지원합니다. 다른 범위는 무시됩니다.                                                                                                                      |
| `type`               | 문자열 배열  | 아니요       | 유형별로 작업 항목을 필터링합니다. `work_items` 범위에만 적용됩니다. 사용 가능한 유형: `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | 문자열            | 아니요       | 허용되는 값은 `created_at`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                              |
| `sort`               | 문자열            | 아니요       | 허용되는 값은 `asc` 또는 `desc`만 해당합니다. 설정하지 않으면 결과가 기본 검색의 경우 `created_at`를 기준으로 내림차순으로 정렬되거나, 고급 검색의 경우 가장 관련성이 높은 문서를 기준으로 정렬됩니다.                           |

응답은 요청된 범위에 따라 달라집니다.

### 범위: `issues` {#scope-issues-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=issues&search=file"
```

응답 예시:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. 이제 단일 크기의 `assignees` 배열입니다.

### 범위: `work_items` {#scope-work_items-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=migrate"
```

응답 예시:

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

`type` 매개변수를 사용하여 작업 항목을 유형별로 필터링할 수 있습니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### 범위: `merge_requests` {#scope-merge_requests-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=merge_requests&search=file"
```

응답 예시:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### 범위: `milestones` {#scope-milestones-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=milestones&search=release"
```

응답 예시:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### 범위: `users` {#scope-users-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=users&search=doe"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### 범위: `wiki_blobs` {#scope-wiki_blobs-2}

이 범위를 사용하여 위키를 검색합니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

위키 블롭 검색은 파일명과 콘텐츠 모두에서 수행됩니다. 검색 결과:

- 파일명에서 찾은 항목이 콘텐츠에서 찾은 결과보다 먼저 표시됩니다.
- 검색 문자열이 파일명과 콘텐츠 모두에서 발견되거나 콘텐츠에 여러 번 나타날 수 있으므로 동일한 블롭에 대해 여러 일치 항목이 포함될 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=wiki_blobs&search=bye"
```

응답 예시:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요.

### 범위: `commits` {#scope-commits-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=commits&search=bye"
```

응답 예시:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### 범위: `blobs` {#scope-blobs-2}

이 범위를 사용하여 코드를 검색합니다.

이 범위에 사용할 수 있는 필터:

- `filename`
- `path`
- `extension`

필터를 사용하려면 쿼리에 포함합니다(예: `a query filename:some_name*`).

와일드카드(`*`)를 글로브 일치에 사용할 수 있습니다.

블롭 검색은 파일명과 콘텐츠 모두에서 수행됩니다. 검색 결과:

- 파일명에서 찾은 항목이 콘텐츠에서 찾은 결과보다 먼저 표시됩니다.
- 검색 문자열이 파일명과 콘텐츠 모두에서 발견되거나 콘텐츠에 여러 번 나타날 수 있으므로 동일한 블롭에 대해 여러 일치 항목이 포함될 수 있습니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=blobs&search=keyword%20filename:*.py"
```

응답 예시:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`는 `path`을 지원하는 것으로 더 이상 사용되지 않습니다. 둘 다 리포지토리 내 파일의 전체 경로를 반환하지만, 앞으로 `filename`는 전체 경로가 아닌 파일명만 표시할 수 있습니다. 자세한 내용은 [이슈 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)을 참조하세요. Elasticsearch 구문은 정확한 코드 검색에서 제대로 작동하지 않을 수 있습니다. 정확한 코드 검색을 위해 Elasticsearch 와일드카드 쿼리를 정규식으로 바꿉니다. 자세한 내용은 [이슈 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)을 참조하세요.

### 범위: `notes` {#scope-notes-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=notes&search=maxime"
```

응답 예시:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```
