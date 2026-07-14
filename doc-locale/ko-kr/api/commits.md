---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 Git 커밋에 대한 REST API 문서입니다.
title: 커밋 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Git 커밋](../user/project/repository/commits/_index.md)을 관리합니다.

## 응답 {#responses}

이 API의 응답에서 일부 날짜 필드는 중복된 정보이거나 중복된 것처럼 보일 수 있습니다:

- `created_at` 필드는 다른 GitLab API와의 일관성을 위해서만 존재합니다. 항상 `committed_date` 필드와 동일합니다.
- `committed_date` 및 `authored_date` 필드는 다른 소스에서 생성되므로 동일하지 않을 수 있습니다.

### 페이지 매김 응답 헤더 {#pagination-response-headers}

성능상의 이유로 GitLab은 커밋 API 응답에서 다음 헤더를 반환하지 않습니다:

- `x-total`
- `x-total-pages`

자세한 내용은 [문제 389582](https://gitlab.com/gitlab-org/gitlab/-/issues/389582)를 참고하세요.

## 리포지토리 커밋 나열 {#list-repository-commits}

{{< history >}}

- `follow` [GitLab 18.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225733).

{{< /history >}}

프로젝트에서 커밋 목록을 가져옵니다.

```plaintext
GET /projects/:id/repository/commits
```

| 속성      | 유형           | 필수 | 설명 |
|----------------|----------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `all`          | 부울        | 아니요       | 리포지토리의 모든 커밋을 검색합니다. `true`인 경우 `ref_name` 매개변수는 무시됩니다. |
| `author`       | 문자열         | 아니요       | 커밋 작성자로 커밋을 검색합니다. |
| `first_parent` | 부울        | 아니요       | `true`인 경우 머지 충돌을 볼 때만 첫 번째 상위 커밋을 따릅니다. |
| `follow`       | 부울        | 아니요       | `true`인 경우 `path`로 필터링할 때 파일 이름 바꾸기를 따르고 파일 이름이 바뀐 경우에도 파일에 대한 커밋을 반환합니다. `false`인 경우 파일이 현재 경로에 존재하는 커밋만 반환합니다. `path`가 단일 파일을 지정할 때만 사용됩니다. `true`로 기본 설정됩니다. |
| `order`        | 문자열         | 아니요       | 커밋을 순서대로 나열합니다. 가능한 값: `default`, [`topo`](https://git-scm.com/docs/git-log#Documentation/git-log.txt---topo-order). `default`로 기본 설정되며, 커밋은 역순 시간순으로 표시됩니다. |
| `path`         | 문자열         | 아니요       | 파일 경로입니다. |
| `ref_name`     | 문자열         | 아니요       | 리포지토리 브랜치, 태그 또는 개정 범위의 이름이거나 주어지지 않은 경우 기본 브랜치. |
| `since`        | 문자열         | 아니요       | 이 날짜 이후 또는 이 날짜에 커밋만 ISO 8601 형식 `YYYY-MM-DDTHH:MM:SSZ`로 반환됩니다. |
| `trailers`     | 부울        | 아니요       | `true`인 경우 모든 커밋에 대해 [Git 예고편](https://git-scm.com/docs/git-interpret-trailers)을 구문 분석하고 포함합니다. |
| `until`        | 문자열         | 아니요       | 이 날짜 이전 또는 이 날짜의 커밋만 ISO 8601 형식 `YYYY-MM-DDTHH:MM:SSZ`로 반환됩니다. |
| `with_stats`   | 부울        | 아니요       | `true`인 경우 각 커밋에 대한 통계를 검색합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성           | 유형   | 설명 |
|---------------------|--------|-------------|
| `author_email`      | 문자열 | 커밋 작성자의 이메일 주소입니다. |
| `author_name`       | 문자열 | 커밋 작성자의 이름입니다. |
| `authored_date`     | 문자열 | 커밋이 작성된 날짜입니다. |
| `committed_date`    | 문자열 | 커밋이 커밋된 날짜입니다. |
| `committer_email`   | 문자열 | 커밋 커미터의 이메일 주소입니다. |
| `committer_name`    | 문자열 | 커밋 커미터의 이름입니다. |
| `created_at`        | 문자열 | 커밋이 생성된 날짜(`committed_date`과 동일). |
| `extended_trailers` | 객체 | 모든 값이 포함된 확장 Git 예고편입니다. |
| `id`                | 문자열 | 커밋의 SHA입니다. |
| `message`           | 문자열 | 전체 커밋 메시지입니다. |
| `parent_ids`        | 배열  | 상위 커밋 SHA 배열입니다. |
| `short_id`          | 문자열 | 커밋의 짧은 SHA입니다. |
| `title`             | 문자열 | 커밋 메시지의 제목입니다. |
| `trailers`          | 객체 | 커밋 메시지에서 구문 분석된 Git 예고편입니다. |
| `web_url`           | 문자열 | 커밋의 웹 URL입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits"
```

응답 예시:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2021-09-20T11:50:22.001+00:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2021-09-20T11:50:22.001+00:00",
    "created_at": "2021-09-20T11:50:22.001+00:00",
    "message": "Replace sanitize with escape once",
    "parent_ids": [
      "6104942438c14ec7bd21c6cd5bd995272b3faff6"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {},
    "extended_trailers": {}
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "user@example.com",
    "committer_name": "ExampleName",
    "committer_email": "user@example.com",
    "created_at": "2021-09-20T09:06:12.201+00:00",
    "message": "Sanitize for network graph\nCc: John Doe <johndoe@gitlab.com>\nCc: Jane Doe <janedoe@gitlab.com>",
    "parent_ids": [
      "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {
      "Cc": "Jane Doe <janedoe@gitlab.com>"
    },
    "extended_trailers": {
      "Cc": [
        "John Doe <johndoe@gitlab.com>",
        "Jane Doe <janedoe@gitlab.com>"
      ]
    }
  }
]
```

## 커밋 생성 {#create-a-commit}

{{< history >}}

- `allow_empty` [GitLab 18.8에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211520).
- 요청 크기 및 속도 제한이 GitLab 18.7에 도입되었습니다.

{{< /history >}}

JSON 페이로드를 게시하여 커밋을 생성합니다.

```plaintext
POST /projects/:id/repository/commits
```

> [!note]
> 이 끝점은 [요청 크기 및 속도 제한](../administration/instance_limits.md#commits-and-files-api-limits)의 대상입니다. 기본 300 MB 제한보다 큰 요청은 거부됩니다. 20 MB보다 큰 요청은 30초마다 3개 요청으로 속도 제한됩니다.

| 속성        | 유형              | 필수 | 설명 |
|------------------|-------------------|----------|-------------|
| `branch`         | 문자열            | 예      | 커밋할 브랜치의 이름입니다. 새 브랜치를 생성하려면 `start_branch` 또는 `start_sha` 중 하나를 제공하고 선택적으로 `start_project`을 제공합니다. |
| `commit_message` | 문자열            | 예      | 커밋 메시지. |
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `actions[]`      | 배열             | 아니요       | 배치로 커밋할 작업 해시 배열입니다. 다음 표에서 어떤 속성을 사용할 수 있는지 확인하세요. |
| `allow_empty`    | 부울           | 아니요       | `true`인 경우 빈 커밋을 생성합니다. 기본값은 `false`입니다. |
| `author_email`   | 문자열            | 아니요       | 커밋 작성자의 이메일 주소를 지정합니다. |
| `author_name`    | 문자열            | 아니요       | 커밋 작성자의 이름을 지정합니다. |
| `force`          | 부울           | 아니요       | `true`인 경우 `branch`을 `start_branch` 또는 `start_sha`을 기반으로 한 새 커밋으로 덮어쓰고 브랜치의 기존 커밋 기록을 대체합니다. 기본값은 `false`입니다. <sup>1</sup> |
| `start_branch`   | 문자열            | 아니요       | 새 커밋의 상위로 사용할 브랜치의 이름입니다. 제공되지 않고 `start_sha`도 제공되지 않으면 `branch`의 값으로 기본 설정됩니다. `start_sha`과 상호 배타적입니다. <sup>1</sup> |
| `start_project`  | 정수 또는 문자열 | 아니요       | `start_branch` 또는 `start_sha`의 소스로 사용할 프로젝트 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). `id`의 값으로 기본 설정됩니다. |
| `start_sha`      | 문자열            | 아니요       | 새 커밋의 상위로 사용할 커밋의 SHA입니다. 전체 40자 SHA여야 합니다. `start_branch`과 상호 배타적입니다. <sup>1</sup> |
| `stats`          | 부울           | 아니요       | 커밋 통계를 포함합니다. 기본값은 `true`입니다. |

**각주**:

1. `force`이 `true`인 경우 다른 상위 커밋을 지정하려면 `start_branch` 또는 `start_sha`를 제공합니다. 둘 다 제공되지 않으면 `start_branch`는 `branch`의 값으로 기본 설정되고, 새로운 커밋은 현재 브랜치 팁을 기반으로 합니다. 이 경우 결과가 일반 커밋과 같으므로 `force`은 효과가 없습니다.

> [!note]
> 많은 작업이 있는 대규모 요청은 크기 제한의 대상일 수 있습니다. 자세한 내용은 [커밋 API 제한](../administration/instance_limits.md#commits-and-files-api-limits)을 참고하세요.

| `actions[]` 속성 | 유형    | 필수 | 설명 |
|-----------------------|---------|----------|-------------|
| `action`              | 문자열  | 예      | 수행할 작업: `create`, `delete`, `move`, `update` 또는 `chmod`. |
| `file_path`           | 문자열  | 예      | 파일의 전체 경로입니다. 예: `lib/class.rb`. |
| `content`             | 문자열  | 아니요       | `delete`, `chmod` 및 `move` 제외한 모든 항목에 필수인 파일 콘텐츠. `content`를 지정하지 않는 이동 작업은 기존 파일 콘텐츠를 유지하고 `content`의 다른 값은 파일 콘텐츠를 덮어씁니다. |
| `encoding`            | 문자열  | 아니요       | `text` 또는 `base64`. `text`이 기본값입니다. |
| `execute_filemode`    | 부울 | 아니요       | `true`인 경우 파일에서 실행 플래그를 활성화합니다. `false`인 경우 비활성화합니다. `chmod` 작업에만 고려됩니다. |
| `last_commit_id`      | 문자열  | 아니요       | 마지막 알려진 파일 커밋 ID입니다. 업데이트, 이동 및 삭제 작업에서만 고려됩니다. |
| `previous_path`       | 문자열  | 아니요       | 옮겨지는 파일의 원래 전체 경로입니다. 예를 들어 `lib/class1.rb`입니다. `move` 작업에만 고려됩니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성         | 유형   | 설명 |
|-------------------|--------|-------------|
| `author_email`    | 문자열 | 커밋 작성자의 이메일 주소입니다. |
| `author_name`     | 문자열 | 커밋 작성자의 이름입니다. |
| `authored_date`   | 문자열 | 커밋이 작성된 날짜입니다. |
| `committed_date`  | 문자열 | 커밋이 커밋된 날짜입니다. |
| `committer_email` | 문자열 | 커밋 커미터의 이메일 주소입니다. |
| `committer_name`  | 문자열 | 커밋 커미터의 이름입니다. |
| `created_at`      | 문자열 | 커밋이 생성된 날짜입니다. |
| `id`              | 문자열 | 생성된 커밋의 SHA입니다. |
| `message`         | 문자열 | 전체 커밋 메시지입니다. |
| `parent_ids`      | 배열  | 상위 커밋 SHA 배열입니다. |
| `short_id`        | 문자열 | 생성된 커밋의 짧은 SHA입니다. |
| `stats`           | 객체 | 커밋에 대한 통계(추가, 삭제, 총계). |
| `status`          | 문자열 | 커밋의 상태입니다. |
| `title`           | 문자열 | 커밋 메시지의 제목입니다. |
| `web_url`         | 문자열 | 커밋의 웹 URL입니다. |

```shell
PAYLOAD=$(cat << 'JSON'
{
  "branch": "main",
  "commit_message": "some commit message",
  "actions": [
    {
      "action": "create",
      "file_path": "foo/bar",
      "content": "some content"
    },
    {
      "action": "delete",
      "file_path": "foo/bar2"
    },
    {
      "action": "move",
      "file_path": "foo/bar3",
      "previous_path": "foo/bar4",
      "content": "some content"
    },
    {
      "action": "update",
      "file_path": "foo/bar5",
      "content": "new content"
    },
    {
      "action": "chmod",
      "file_path": "foo/bar5",
      "execute_filemode": true
    }
  ]
}
JSON
)
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data "$PAYLOAD" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

응답 예시:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "some commit message",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "created_at": "2016-09-20T09:26:24.000-07:00",
  "message": "some commit message",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2016-09-20T09:26:24.000-07:00",
  "authored_date": "2016-09-20T09:26:24.000-07:00",
  "stats": {
    "additions": 2,
    "deletions": 2,
    "total": 4
  },
  "status": null,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
}
```

GitLab은 [양식 인코딩](rest/_index.md#array-and-hash-types)을 지원합니다. 다음은 양식 인코딩을 사용하는 커밋 API의 예입니다:

```shell
curl --request POST \
     --form "branch=main" \
     --form "commit_message=some commit message" \
     --form "start_branch=main" \
     --form "actions[][action]=create" \
     --form "actions[][file_path]=foo/bar" \
     --form "actions[][content]=</path/to/local.file" \
     --form "actions[][action]=delete" \
     --form "actions[][file_path]=foo/bar2" \
     --form "actions[][action]=move" \
     --form "actions[][file_path]=foo/bar3" \
     --form "actions[][previous_path]=foo/bar4" \
     --form "actions[][content]=</path/to/local1.file" \
     --form "actions[][action]=update" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][content]=</path/to/local2.file" \
     --form "actions[][action]=chmod" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][execute_filemode]=true" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

## 커밋 검색 {#retrieve-a-commit}

커밋 해시 또는 브랜치 또는 태그의 이름으로 식별되는 특정 커밋을 검색합니다.

```plaintext
GET /projects/:id/repository/commits/:sha
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 커밋 해시 또는 리포지토리 브랜치 또는 태그의 이름입니다. |
| `stats`   | 부울        | 아니요       | 커밋 통계를 포함합니다. 기본값은 `true`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성         | 유형   | 설명 |
|-------------------|--------|-------------|
| `author_email`    | 문자열 | 커밋 작성자의 이메일 주소입니다. |
| `author_name`     | 문자열 | 커밋 작성자의 이름입니다. |
| `authored_date`   | 문자열 | 커밋이 작성된 날짜입니다. |
| `committed_date`  | 문자열 | 커밋이 커밋된 날짜입니다. |
| `committer_email` | 문자열 | 커밋 커미터의 이메일 주소입니다. |
| `committer_name`  | 문자열 | 커밋 커미터의 이름입니다. |
| `created_at`      | 문자열 | 커밋이 생성된 날짜입니다. |
| `id`              | 문자열 | 커밋의 SHA입니다. |
| `last_pipeline`   | 객체 | 이 커밋의 마지막 파이프라인에 대한 정보입니다. |
| `message`         | 문자열 | 전체 커밋 메시지입니다. |
| `parent_ids`      | 배열  | 상위 커밋 SHA 배열입니다. |
| `short_id`        | 문자열 | 커밋의 짧은 SHA입니다. |
| `stats`           | 객체 | 커밋에 대한 통계(추가, 삭제, 총계). |
| `status`          | 문자열 | 커밋의 상태입니다. |
| `title`           | 문자열 | 커밋 메시지의 제목입니다. |
| `web_url`         | 문자열 | 커밋의 웹 URL입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main"
```

응답 예시:

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "user@example.com",
  "committer_name": "Dmitriy",
  "committer_email": "user@example.com",
  "created_at": "2021-09-20T09:06:12.300+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2021-09-20T09:06:12.300+03:00",
  "authored_date": "2021-09-20T09:06:12.420+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "last_pipeline": {
    "id": 8,
    "ref": "main",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0",
    "status": "created"
  },
  "stats": {
    "additions": 15,
    "deletions": 10,
    "total": 25
  },
  "status": "running",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
}
```

## 커밋이 푸시되는 모든 참조 나열 {#list-all-references-a-commit-is-pushed-to}

커밋이 푸시되는 모든 참조(브랜치 또는 태그)를 나열합니다. 페이지 매김 매개변수 `page` 및 `per_page`를 사용하여 참조 목록을 제한할 수 있습니다.

```plaintext
GET /projects/:id/repository/commits/:sha/refs
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 커밋 해시입니다. |
| `type`    | 문자열         | 아니요       | 커밋의 범위입니다. 가능한 값 `branch`, `tag`, `all`. 기본값은 `all`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `name`    | 문자열 | 브랜치 또는 태그의 이름입니다. |
| `type`    | 문자열 | 참조의 유형(`branch` 또는 `tag`). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/refs?type=all"
```

응답 예시:

```json
[
  {
    "type": "branch",
    "name": "'test'"
  },
  {
    "type": "branch",
    "name": "add-balsamiq-file"
  },
  {
    "type": "branch",
    "name": "wip"
  },
  {
    "type": "tag",
    "name": "v1.1.0"
  }
]
```

## 커밋 시퀀스 가져오기 {#get-commit-sequence}

{{< history >}}

- [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438151).

{{< /history >}}

주어진 커밋의 상위 링크를 따라 프로젝트에서 커밋의 시퀀스 번호를 가져옵니다.

이 API는 주어진 커밋 SHA에 대해 본질적으로 `git rev-list --count` 명령과 동일한 기능을 제공합니다.

```plaintext
GET /projects/:id/repository/commits/:sha/sequence
```

매개변수:

| 속성      | 유형           | 필수 | 설명 |
|----------------|----------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`          | 문자열         | 예      | 커밋 해시입니다. |
| `first_parent` | 부울        | 아니요       | `true`인 경우 머지 충돌을 볼 때만 첫 번째 상위 커밋을 따릅니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
| --------- | ---- | ----------- |
| `count` | 정수 | 커밋의 시퀀스 번호입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/sequence"
```

응답 예시:

```json
{
  "count": 632
}
```

## 커밋 체리 픽 {#cherry-pick-a-commit}

주어진 브랜치에 커밋을 체리 픽합니다.

```plaintext
POST /projects/:id/repository/commits/:sha/cherry_pick
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `branch`  | 문자열         | 예      | 브랜치의 이름입니다. |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 커밋 해시입니다. |
| `dry_run` | 부울        | 아니요       | `true`인 경우 변경 사항을 커밋하지 않습니다. 기본값은 `false`입니다. |
| `message` | 문자열         | 아니요       | 새 커밋에 사용할 사용자 지정 커밋 메시지입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성         | 유형   | 설명 |
|-------------------|--------|-------------|
| `author_email`    | 문자열 | 원본 커밋 작성자의 이메일 주소입니다. |
| `author_name`     | 문자열 | 원본 커밋 작성자의 이름입니다. |
| `authored_date`   | 문자열 | 원본 커밋이 작성된 날짜입니다. |
| `committed_date`  | 문자열 | 체리 픽된 커밋이 커밋된 날짜입니다. |
| `committer_email` | 문자열 | 체리 픽 커미터의 이메일 주소입니다. |
| `committer_name`  | 문자열 | 체리 픽 커미터의 이름입니다. |
| `created_at`      | 문자열 | 체리 픽된 커밋이 생성된 날짜입니다. |
| `id`              | 문자열 | 체리 픽된 커밋의 SHA입니다. |
| `message`         | 문자열 | 전체 커밋 메시지입니다. |
| `parent_ids`      | 배열  | 상위 커밋 SHA 배열입니다. |
| `short_id`        | 문자열 | 체리 픽된 커밋의 짧은 SHA입니다. |
| `title`           | 문자열 | 커밋 메시지의 제목입니다. |
| `web_url`         | 문자열 | 체리 픽된 커밋의 웹 URL입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/cherry_pick"
```

응답 예시:

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2016-12-12T20:10:39.000+01:00",
  "created_at": "2016-12-12T20:10:39.000+01:00",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2016-12-12T20:10:39.000+01:00",
  "title": "Feature added",
  "message": "Feature added\n\nSigned-off-by: Example User <user@example.com>\n",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

체리 픽 실패 시 응답은 실패 이유에 대한 컨텍스트를 제공합니다:

```json
{
  "message": "Sorry, we cannot cherry-pick this commit automatically. This commit may already have been cherry-picked, or a more recent commit may have updated some of its content.",
  "error_code": "empty"
}
```

이 경우 변경 집합이 비어 있어 커밋이 대상 브랜치에 이미 존재함을 나타낼 가능성이 높기 때문에 체리 픽이 실패했습니다. 다른 가능한 오류 코드는 `conflict`이며, 머지 충돌이 있었음을 나타냅니다.

`dry_run`이 활성화되면 서버가 체리 픽을 적용하려고 시도하지만 _실제로 결과 변경 사항을 커밋하지는 않습니다_. 체리 픽이 깔끔하게 적용되면 API는 `200 OK`으로 응답합니다:

```json
{
  "dry_run": "success"
}
```

실패 시 드라이 런 없이 실패와 동일한 오류가 표시됩니다.

## 커밋 되돌리기 {#revert-a-commit}

주어진 브랜치에서 커밋을 되돌립니다.

```plaintext
POST /projects/:id/repository/commits/:sha/revert
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `branch`  | 문자열         | 예      | 대상 브랜치 이름입니다. |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 되돌릴 커밋 SHA입니다. |
| `dry_run` | 부울        | 아니요       | `true`인 경우 변경 사항을 커밋하지 않습니다. 기본값은 `false`입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성         | 유형   | 설명 |
|-------------------|--------|-------------|
| `author_email`    | 문자열 | 되돌리기 커밋 작성자의 이메일 주소입니다. |
| `author_name`     | 문자열 | 되돌리기 커밋 작성자의 이름입니다. |
| `authored_date`   | 문자열 | 되돌리기 커밋이 작성된 날짜입니다. |
| `committed_date`  | 문자열 | 되돌리기 커밋이 커밋된 날짜입니다. |
| `committer_email` | 문자열 | 되돌리기 커밋 커미터의 이메일 주소입니다. |
| `committer_name`  | 문자열 | 되돌리기 커밋 커미터의 이름입니다. |
| `created_at`      | 문자열 | 되돌리기 커밋이 생성된 날짜입니다. |
| `id`              | 문자열 | 되돌리기 커밋의 SHA입니다. |
| `message`         | 문자열 | 전체 되돌리기 커밋 메시지입니다. |
| `parent_ids`      | 배열  | 상위 커밋 SHA 배열입니다. |
| `short_id`        | 문자열 | 되돌리기 커밋의 짧은 SHA입니다. |
| `title`           | 문자열 | 되돌리기 커밋 메시지의 제목입니다. |
| `web_url`         | 문자열 | 되돌리기 커밋의 웹 URL입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/a738f717824ff53aebad8b090c1b79a14f2bd9e8/revert"
```

응답 예시:

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "title": "Revert \"Feature added\"",
  "created_at": "2018-11-08T15:55:26.000Z",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "message": "Revert \"Feature added\"\n\nThis reverts commit a738f717824ff53aebad8b090c1b79a14f2bd9e8",
  "author_name": "Administrator",
  "author_email": "admin@example.com",
  "authored_date": "2018-11-08T15:55:26.000Z",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2018-11-08T15:55:26.000Z",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

되돌리기 실패 시 응답은 실패 이유에 대한 컨텍스트를 제공합니다:

```json
{
  "message": "Sorry, we cannot revert this commit automatically. This commit may already have been reverted, or a more recent commit may have updated some of its content.",
  "error_code": "conflict"
}
```

이 경우 시도된 되돌리기가 머지 충돌을 생성했기 때문에 되돌리기가 실패했습니다. 다른 가능한 오류 코드는 `empty`이며, 변경 집합이 비어 있음을 나타내며, 이는 변경 사항이 이미 되돌려진 것 때문일 가능성이 높습니다.

`dry_run`이 활성화되면 서버가 되돌리기를 적용하려고 시도하지만 _실제로 결과 변경 사항을 커밋하지는 않습니다_. 되돌리기가 깔끔하게 적용되면 API는 `200 OK`으로 응답합니다:

```json
{
  "dry_run": "success"
}
```

실패 시 드라이 런 없이 실패와 동일한 오류가 표시됩니다.

## 커밋 차이 검색 {#retrieve-commit-diff}

{{< history >}}

- `collapsed` 및 `too_large` 응답 속성은 [GitLab 18.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633).

{{< /history >}}

프로젝트에서 커밋의 차이를 검색합니다.

```plaintext
GET /projects/:id/repository/commits/:sha/diff
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 커밋 해시 또는 리포지토리 브랜치 또는 태그의 이름입니다. |
| `unidiff` | 부울        | 아니요       | `true`인 경우 [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) 형식으로 차이를 표시합니다. 기본값은 `false`입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610). |

> [!note]
> 이 끝점은 [차이 제한](../administration/diff_limits.md)의 대상입니다. 커밋이 구성된 최대 파일 수를 초과하면 페이지 매김이 중지되고 제한을 초과하는 추가 파일이 반환되지 않습니다. GitLab.com 특정 제한의 경우 [차이 표시 제한](../user/gitlab_com/_index.md#diff-display-limits)을 참고하세요.

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성      | 유형    | 설명 |
|----------------|---------|-------------|
| `a_mode`       | 문자열  | 파일의 이전 파일 모드입니다. |
| `b_mode`       | 문자열  | 파일의 새 파일 모드입니다. |
| `collapsed`    | 부울 | 파일 차이는 제외되지만 요청 시 가져올 수 있습니다. |
| `deleted_file` | 부울 | 파일이 제거되었습니다. |
| `diff`         | 문자열  | 파일에 대한 변경 사항의 차이 표현입니다. |
| `new_file`     | 부울 | 파일이 추가되었습니다. |
| `new_path`     | 문자열  | 파일의 새 경로입니다. |
| `old_path`     | 문자열  | 파일의 이전 경로입니다. |
| `renamed_file` | 부울 | 파일이 이름이 바뀌었습니다. |
| `too_large`    | 부울 | 파일 차이는 제외되어 검색할 수 없습니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/diff"
```

응답 예시:

```json
[
  {
    "diff": "@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
    "collapsed": false,
    "too_large": false,
    "new_path": "doc/update/5.4-to-6.0.md",
    "old_path": "doc/update/5.4-to-6.0.md",
    "a_mode": null,
    "b_mode": "100644",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }
]
```

## 모든 커밋 주석 나열 {#list-all-commit-comments}

프로젝트에서 커밋의 모든 주석을 나열합니다.

```plaintext
GET /projects/:id/repository/commits/:sha/comments
```

매개변수:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열         | 예      | 커밋 해시 또는 리포지토리 브랜치 또는 태그의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성 | 유형   | 설명 |
|-----------|--------|-------------|
| `author`  | 객체 | 주석 작성자에 대한 정보입니다. |
| `note`    | 문자열 | 주석 텍스트입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/comments"
```

응답 예시:

```json
[
  {
    "note": "this code is really nice",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@local.host",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  }
]
```

## 커밋에 주석 게시 {#post-comment-to-commit}

커밋에 주석을 생성합니다.

특정 파일의 특정 줄에 주석을 게시하려면 전체 커밋 SHA, `path`, `line`, `line_type`을 지정해야 하며 `new`여야 합니다.

다음 경우 중 하나 이상이 유효한 경우 주석이 마지막 커밋 끝에 추가됩니다:

- `sha`이 대신 브랜치 또는 태그이고 `line` 또는 `path`이 유효하지 않음
- `line` 번호가 유효하지 않음(존재하지 않음)
- `path`이 유효하지 않음(존재하지 않음)

이전 경우 중 하나에서 `line`, `line_type` 및 `path`의 응답이 `null`로 설정됩니다.

머지 리퀘스트에 주석을 달기 위한 다른 접근 방식은 노트 API에서 [머지 리퀘스트 주석 생성](notes.md#create-a-merge-request-note) 을 참고하고, 논의 API에서 [머지 리퀘스트 차이의 새 스레드 생성](discussions.md#create-a-new-thread-in-the-merge-request-diff)을 참고하세요.

```plaintext
POST /projects/:id/repository/commits/:sha/comments
```

| 속성   | 유형           | 필수 | 설명 |
|-------------|----------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `note`      | 문자열         | 예      | 주석의 텍스트입니다. |
| `sha`       | 문자열         | 예      | 커밋 SHA 또는 리포지토리 브랜치 또는 태그의 이름입니다. |
| `line`      | 정수        | 아니요       | 주석을 배치할 줄 번호입니다. |
| `line_type` | 문자열         | 아니요       | 줄 유형입니다. `new` 또는 `old`을 인수로 사용합니다. |
| `path`      | 문자열         | 아니요       | 리포지토리 상대 경로입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성    | 유형    | 설명 |
|--------------|---------|-------------|
| `author`     | 객체  | 주석 작성자에 대한 정보입니다. |
| `created_at` | 문자열  | 주석이 생성된 날짜입니다. |
| `line_type`  | 문자열  | 주석이 있는 줄의 유형입니다. |
| `line`       | 정수 | 주석이 배치된 줄 번호입니다. |
| `note`       | 문자열  | 주석 텍스트입니다. |
| `path`       | 문자열  | 리포지토리 상대 경로입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Nice picture\!" \
  --form "path=README.md" \
  --form "line=11" \
  --form "line_type=new" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments"
```

응답 예시:

```json
{
  "author": {
    "web_url": "https://gitlab.example.com/janedoe",
    "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
    "username": "janedoe",
    "state": "active",
    "name": "Jane Doe",
    "id": 28
  },
  "created_at": "2016-01-19T09:44:55.600Z",
  "line_type": "new",
  "path": "README.md",
  "line": 11,
  "note": "Nice picture!"
}
```

## 모든 커밋 논의 나열 {#list-all-commit-discussions}

프로젝트에서 커밋의 모든 논의를 나열합니다.

```plaintext
GET /projects/:id/repository/commits/:sha/discussions
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열 | 예 | 커밋 해시 또는 리포지토리 브랜치 또는 태그의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성         | 유형    | 설명 |
|-------------------|---------|-------------|
| `id`              | 문자열  | 논의의 ID입니다. |
| `individual_note` | 부울 | `true`인 경우 논의는 개별 노트입니다. |
| `notes`           | 배열   | 논의의 노트 배열입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/4604744a1c64de00ff62e1e8a6766919923d2b41/discussions"
```

응답 예시:

```json
[
  {
    "id": "4604744a1c64de00ff62e1e8a6766919923d2b41",
    "individual_note": true,
    "notes": [
      {
        "id": 334686748,
        "type": null,
        "body": "Nice piece of code!",
        "attachment": null,
        "author": {
          "id": 28,
          "name": "Jane Doe",
          "username": "janedoe",
          "web_url": "https://gitlab.example.com/janedoe",
          "state": "active",
          "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
        },
        "created_at": "2020-04-30T18:48:11.432Z",
        "updated_at": "2020-04-30T18:48:11.432Z",
        "system": false,
        "noteable_id": null,
        "noteable_type": "Commit",
        "resolvable": false,
        "confidential": null,
        "noteable_iid": null,
        "commands_changes": {}
      }
    ]
  }
]
```

## 커밋 상태 {#commit-status}

GitLab과 함께 사용할 커밋 상태 API입니다.

### 커밋 상태 나열 {#list-commit-statuses}

{{< history >}}

- `pipeline_id`, `order_by` 및 `sort` 필드는 [GitLab 17.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176142).

{{< /history >}}

프로젝트에서 커밋의 상태를 나열합니다. 페이지 매김 매개변수 `page` 및 `per_page`를 사용하여 참조 목록을 제한할 수 있습니다.

```plaintext
GET /projects/:id/repository/commits/:sha/statuses
```

| 속성     | 유형              | 필수 | 설명 |
|---------------|-------------------|----------|-------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths). |
| `sha`         | 문자열            | 예      | 커밋의 해시입니다. |
| `all`         | 부울           | 아니요       | `true`인 경우 최신 상태만 포함하는 대신 모든 상태를 포함합니다. 기본값은 `false`입니다. |
| `name`        | 문자열            | 아니요       | [작업 이름](../ci/yaml/_index.md#job-keywords)으로 상태를 필터링합니다. 예를 들어, `bundler:audit`입니다. |
| `order_by`    | 문자열            | 아니요       | 상태를 정렬하기 위한 값입니다. 유효한 값은 `id` 및 `pipeline_id`입니다. 기본값은 `id`입니다. |
| `pipeline_id` | 정수           | 아니요       | 파이프라인 ID로 상태를 필터링합니다. 예를 들어, `1234`입니다. |
| `ref`         | 문자열            | 아니요       | 브랜치 또는 태그의 이름입니다. 기본값은 기본 브랜치입니다. |
| `sort`        | 문자열            | 아니요       | 상태를 오름차순 또는 내림차순으로 정렬합니다. 유효한 값은 `asc` 및 `desc`입니다. 기본값은 `asc`입니다. |
| `stage`       | 문자열            | 아니요       | [스테이지](../ci/yaml/_index.md#stages)로 상태를 필터링합니다. 예를 들어, `test`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성       | 유형    | 설명 |
|-----------------|---------|-------------|
| `allow_failure` | 부울 | `true`인 경우 상태가 실패를 허용합니다. |
| `author`        | 객체  | 상태 작성자에 대한 정보입니다. |
| `created_at`    | 문자열  | 상태가 생성된 날짜입니다. |
| `description`   | 문자열  | 상태의 설명입니다. |
| `finished_at`   | 문자열  | 상태가 완료된 날짜입니다. |
| `id`            | 정수 | 상태의 ID입니다. |
| `name`          | 문자열  | 상태의 이름입니다. |
| `ref`           | 문자열  | 커밋의 참조(브랜치 또는 태그). |
| `sha`           | 문자열  | 커밋의 SHA입니다. |
| `started_at`    | 문자열  | 상태가 시작된 날짜입니다. |
| `status`        | 문자열  | 커밋의 상태입니다. |
| `target_url`    | 문자열  | 상태와 관련된 대상 URL입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/statuses"
```

응답 예시:

```json
[
  ...
  {
    "status": "pending",
    "created_at": "2016-01-19T08:40:25.934Z",
    "started_at": null,
    "name": "bundler:audit",
    "allow_failure": true,
    "author": {
      "username": "janedoe",
      "state": "active",
      "web_url": "https://gitlab.example.com/janedoe",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "id": 28,
      "name": "Jane Doe"
    },
    "description": null,
    "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
    "target_url": "https://gitlab.example.com/janedoe/gitlab-foss/builds/91",
    "finished_at": null,
    "id": 91,
    "ref": "main"
  },
  {
    "started_at": null,
    "name": "test",
    "allow_failure": false,
    "status": "pending",
    "created_at": "2016-01-19T08:40:25.832Z",
    "target_url": "https://gitlab.example.com/janedoe/gitlab-foss/builds/90",
    "id": 90,
    "finished_at": null,
    "ref": "main",
    "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
    "author": {
      "id": 28,
      "name": "Jane Doe",
      "username": "janedoe",
      "web_url": "https://gitlab.example.com/janedoe",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
    },
    "description": null
  }
  ...
]
```

### 커밋 파이프라인 상태 설정 {#set-commit-pipeline-status}

`external` 스테이지의 작업으로 표현되는 커밋의 상태를 추가하거나 업데이트합니다. 커밋이 머지 리퀘스트와 관련된 경우 머지 리퀘스트의 소스 브랜치에서 커밋을 대상으로 합니다.

커밋 상태를 설정할 때:

- 기존 파이프라인을 먼저 검색하여 작업을 추가합니다.
- 적절한 파이프라인이 없으면 `CI_PIPELINE_SOURCE: external`으로 새 파이프라인이 생성됩니다.

자세한 내용은 [외부 커밋 상태](../ci/ci_cd_for_external_repos/external_commit_statuses.md)를 참고하세요.

> [!note]
> 동일한 커밋에 중복 파이프라인이 있으면 어떤 파이프라인이 외부 상태를 수신하는지 모호할 수 있습니다. 파이프라인을 구성하여 [중복 방지](../ci/jobs/job_rules.md#avoid-duplicate-pipelines)합니다.

파이프라인이 이미 있고 [단일 파이프라인의 최대 작업 수 제한](../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline)을 초과하는 경우:

- `pipeline_id`이 지정된 경우 `422` 오류가 반환됩니다: `The number of jobs has exceeded the limit`.
- 그렇지 않으면 새 파이프라인이 생성됩니다.

SHA/ref 조합에 대해 업데이트가 이미 진행 중이면 `409` 오류가 반환됩니다. 이 오류를 처리하려면 요청을 다시 시도하세요.

```plaintext
POST /projects/:id/statuses/:sha
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`               | 문자열            | 예      | 커밋 SHA입니다. |
| `state`             | 문자열            | 예      | 상태의 상태입니다. 다음 중 하나일 수 있습니다: `pending`, `running`, `success`, `failed`, `canceled`, `skipped`. |
| `coverage`          | 부동소수점             | 아니요       | 전체 코드 범위입니다. |
| `description`       | 문자열            | 아니요       | 상태의 짧은 설명입니다. 255자 이하여야 합니다. |
| `name` 또는 `context` | 문자열            | 아니요       | 다른 시스템의 상태와 이 상태를 구분하기 위한 레이블입니다. 기본값은 `default`입니다. |
| `pipeline_id`       | 정수           | 아니요       | 상태를 설정할 파이프라인의 ID입니다. 동일한 SHA에 여러 파이프라인이 있는 경우에 사용합니다. |
| `ref`               | 문자열            | 아니요       | 상태가 참조하는 `ref`(브랜치 또는 태그). 255자 이하여야 합니다. |
| `target_url`        | 문자열            | 아니요       | 이 상태와 연결할 대상 URL입니다. 255자 이하여야 합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성       | 유형    | 설명 |
|-----------------|---------|-------------|
| `allow_failure` | 부울 | `true`인 경우 상태가 실패를 허용합니다. |
| `author`        | 객체  | 상태 작성자에 대한 정보입니다. |
| `coverage`      | 부동소수점   | 코드 범위 백분율입니다. |
| `created_at`    | 문자열  | 상태가 생성된 날짜입니다. |
| `description`   | 문자열  | 상태의 설명입니다. |
| `finished_at`   | 문자열  | 상태가 완료된 날짜입니다. |
| `id`            | 정수 | 상태의 ID입니다. |
| `name`          | 문자열  | 상태의 이름입니다. |
| `ref`           | 문자열  | 커밋의 참조(브랜치 또는 태그). |
| `sha`           | 문자열  | 커밋의 SHA입니다. |
| `started_at`    | 문자열  | 상태가 시작된 날짜입니다. |
| `status`        | 문자열  | 커밋의 상태입니다. |
| `target_url`    | 문자열  | 상태와 관련된 대상 URL입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8?state=success"
```

응답 예시:

```json
{
  "author": {
    "web_url": "https://gitlab.example.com/janedoe",
    "name": "Jane Doe",
    "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
    "username": "janedoe",
    "state": "active",
    "id": 28
  },
  "name": "default",
  "sha": "18f3e63d05582537db6d183d9d557be09e1f90c8",
  "status": "success",
  "coverage": 100.0,
  "description": null,
  "id": 93,
  "target_url": null,
  "ref": null,
  "started_at": null,
  "created_at": "2016-01-19T09:05:50.355Z",
  "allow_failure": false,
  "finished_at": "2016-01-19T09:05:50.365Z"
}
```

## 커밋과 관련된 머지 리퀘스트 나열 {#list-merge-requests-associated-with-a-commit}

{{< history >}}

- `state` 속성은 [GitLab 18.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191169).

{{< /history >}}

특정 커밋을 원래 도입한 머지 리퀘스트에 대한 정보를 반환합니다.

```plaintext
GET /projects/:id/repository/commits/:sha/merge_requests
```

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열            | 예      | 커밋 SHA입니다. |
| `state`   | 문자열            | 아니요       | 지정된 상태로 머지 리퀘스트를 반환합니다: `opened`, `closed`, `locked` 또는 `merged`. 이 매개변수를 생략하면 상태와 관계없이 모든 머지 리퀘스트를 가져옵니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성                      | 유형    | 설명 |
|--------------------------------|---------|-------------|
| `assignee`                     | 객체  | 머지 리퀘스트 담당자에 대한 정보입니다. |
| `author`                       | 객체  | 머지 리퀘스트 작성자에 대한 정보입니다. |
| `created_at`                   | 문자열  | 머지 리퀘스트가 생성된 날짜입니다. |
| `description`                  | 문자열  | 머지 리퀘스트의 설명입니다. |
| `discussion_locked`            | 부울 | `true`인 경우 논의가 잠깁니다. |
| `downvotes`                    | 정수 | 부정 투표 수입니다. |
| `draft`                        | 부울 | `true`인 경우 머지 리퀘스트는 초안입니다. |
| `force_remove_source_branch`   | 부울 | `true`인 경우 소스 브랜치 제거를 강제합니다. |
| `id`                           | 정수 | 머지 리퀘스트의 ID입니다. |
| `iid`                          | 정수 | 머지 리퀘스트의 내부 ID입니다. |
| `labels`                       | 배열   | 머지 리퀘스트와 관련된 레이블. |
| `merge_commit_sha`             | 문자열  | 머지 커밋의 SHA입니다. |
| `merge_status`                 | 문자열  | 머지 리퀘스트의 머지 상태입니다. |
| `merge_when_pipeline_succeeds` | 부울 | `true`인 경우 파이프라인이 성공하면 머지합니다. |
| `milestone`                    | 객체  | 머지 리퀘스트와 관련된 마일스톤. |
| `project_id`                   | 정수 | 프로젝트의 ID입니다. |
| `sha`                          | 문자열  | 머지 리퀘스트의 SHA입니다. |
| `should_remove_source_branch`  | 부울 | `true`인 경우 머지 후 소스 브랜치를 제거합니다. |
| `source_branch`                | 문자열  | 머지 리퀘스트의 소스 브랜치. |
| `source_project_id`            | 정수 | 소스 프로젝트의 ID입니다. |
| `squash_commit_sha`            | 문자열  | 스쿼시 커밋의 SHA입니다. |
| `state`                        | 문자열  | 머지 리퀘스트의 상태입니다. |
| `target_branch`                | 문자열  | 머지 리퀘스트의 대상 브랜치. |
| `target_project_id`            | 정수 | 대상 프로젝트의 ID입니다. |
| `time_stats`                   | 객체  | 시간 추적 통계입니다. |
| `title`                        | 문자열  | 머지 리퀘스트의 제목입니다. |
| `updated_at`                   | 문자열  | 머지 리퀘스트가 마지막으로 업데이트된 날짜입니다. |
| `upvotes`                      | 정수 | 찬성 투표 수입니다. |
| `user_notes_count`             | 정수 | 사용자 노트 수입니다. |
| `web_url`                      | 문자열  | 머지 리퀘스트의 웹 URL입니다. |
| `work_in_progress`             | 부울 | `true`인 경우 머지 리퀘스트는 작업 진행 중으로 설정됩니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/af5b13261899fb2c0db30abdd0af8b07cb44fdc5/merge_requests?state=opened"
```

응답 예시:

```json
[
  {
    "id": 45,
    "iid": 1,
    "project_id": 35,
    "title": "Add new file",
    "description": "",
    "state": "opened",
    "created_at": "2018-03-26T17:26:30.916Z",
    "updated_at": "2018-03-26T17:26:30.916Z",
    "target_branch": "main",
    "source_branch": "test-branch",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "web_url": "https://gitlab.example.com/janedoe",
      "name": "Jane Doe",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username": "janedoe",
      "state": "active",
      "id": 28
    },
    "assignee": null,
    "source_project_id": 35,
    "target_project_id": 35,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "af5b13261899fb2c0db30abdd0af8b07cb44fdc5",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/root/test-project/merge_requests/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## 커밋 서명 검색 {#retrieve-commit-signature}

서명된 경우 [커밋의 서명](../user/project/repository/signed_commits/_index.md)을 검색합니다. 서명되지 않은 커밋의 경우 404 응답이 반환됩니다.

```plaintext
GET /projects/:id/repository/commits/:sha/signature
```

매개변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths). |
| `sha`     | 문자열            | 예      | 커밋 해시 또는 리포지토리 브랜치 또는 태그의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 반환합니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `commit_source`         | 문자열  | 커밋의 소스입니다. |
| `gpg_key_id`            | 정수 | GPG 키의 ID입니다(PGP 서명의 경우). |
| `gpg_key_primary_keyid` | 문자열  | GPG 키의 기본 키 ID입니다. |
| `gpg_key_subkey_id`     | 문자열  | GPG 키의 부분 키 ID입니다. |
| `gpg_key_user_email`    | 문자열  | GPG 키와 연결된 이메일 주소입니다. |
| `gpg_key_user_name`     | 문자열  | GPG 키와 연결된 사용자 이름입니다. |
| `key`                   | 객체  | SSH 키 정보(SSH 서명의 경우)입니다. |
| `signature_type`        | 문자열  | 서명의 유형(`PGP`, `SSH`, 또는 `X509`). |
| `verification_status`   | 문자열  | 서명의 검증 상태입니다. |
| `x509_certificate`      | 객체  | X.509 인증서 정보(X.509 서명용). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits/da738facbc19eb2fc2cef57c49be0e6038570352/signature"
```

커밋이 GPG로 서명된 경우의 응답 예:

```json
{
  "signature_type": "PGP",
  "verification_status": "verified",
  "gpg_key_id": 1,
  "gpg_key_primary_keyid": "8254AAB3FBD54AC9",
  "gpg_key_user_name": "John Doe",
  "gpg_key_user_email": "johndoe@example.com",
  "gpg_key_subkey_id": null,
  "commit_source": "gitaly"
}
```

커밋이 SSH로 서명된 경우의 응답 예:

```json
{
  "signature_type": "SSH",
  "verification_status": "verified",
  "key": {
    "id": 11,
    "title": "Key",
    "created_at": "2023-05-08T09:12:38.503Z",
    "expires_at": "2024-05-07T00:00:00.000Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZzYDq6DhLp3aX84DGIV3F6Vf+Ae4yCTTz7RnqMJOlR MyKey)",
    "usage_type": "auth_and_signing"
  },
  "commit_source": "gitaly"
}
```

커밋이 X.509로 서명된 경우의 응답 예:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  },
  "commit_source": "gitaly"
}
```

커밋이 서명되지 않은 경우의 응답 예:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
