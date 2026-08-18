---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 웹후크 API
description: "REST API를 사용하여 그룹의 웹후크를 설정하고 관리합니다."
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [그룹 웹후크](../user/project/integrations/webhooks.md#group-webhooks)를 관리합니다. 그룹 웹후크는 전체 인스턴스에 영향을 미치는 [시스템 후크](system_hooks.md) 와 단일 프로젝트로 제한되는 [프로젝트 웹후크](project_webhooks.md)와는 다릅니다.

전제 조건:

- 관리자이거나 그룹의 소유자 역할이 있어야 합니다.

## 모든 그룹 후크 나열 {#list-all-group-hooks}

지정된 그룹의 모든 그룹 후크를 나열합니다.

```plaintext
GET /groups/:id/hooks
```

지원되는 속성:

| 속성 | 유형            | 필수 | 설명 |
| --------- | --------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열  | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks"
```

응답 예시:

```json
[
  {
    "id": 1,
    "url": "http://example.com/hook",
    "name": "Test group hook",
    "description": "This is a test group hook.",
    "created_at": "2024-09-01T09:10:54.854Z",
    "push_events": true,
    "tag_push_events": false,
    "merge_requests_events": false,
    "repository_update_events": false,
    "enable_ssl_verification": true,
    "alert_status": "executable",
    "disabled_until": null,
    "url_variables": [],
    "push_events_branch_filter": null,
    "branch_filter_strategy": "all_branches",
    "group_id": 99,
    "issues_events": false,
    "confidential_issues_events": false,
    "note_events": false,
    "confidential_note_events": false,
    "pipeline_events": false,
    "wiki_page_events": false,
    "job_events": false,
    "deployment_events": false,
    "feature_flag_events": false,
    "releases_events": false,
    "milestone_events": false,
    "subgroup_events": false,
    "emoji_events": false,
    "resource_access_token_events": false,
    "member_events": false,
    "project_events": false,
    "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
    "custom_headers": [
      {
        "key": "Authorization"
      }
    ],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## 그룹 후크 검색 {#retrieve-a-group-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `token_present` 및 `signing_token_present` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325)되었습니다.

{{< /history >}}

지정된 그룹 후크를 검색합니다.

```plaintext
GET /groups/:id/hooks/:hook_id
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `hook_id` | 정수        | 예      | 그룹 후크의 ID입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

응답 예시:

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": false,
  "releases_events": true,
  "milestone_events": false,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ],
  "token_present": false,
  "signing_token_present": false
}
```

## 모든 그룹 후크 이벤트 나열 {#list-all-group-hook-events}

{{< history >}}

- GitLab 17.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048).

{{< /history >}}

지정된 그룹 후크의 지난 7일간의 모든 이벤트를 나열합니다.

```plaintext
GET /groups/:id/hooks/:hook_id/events
```

지원되는 속성:

| 속성  | 유형                 | 필수 | 설명 |
|----------- |--------------------- |--------- |------------ |
| `hook_id`  | 정수              | 예      | 프로젝트 웹후크의 ID입니다. |
| `id`       | 정수 또는 문자열    | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `page`     | 정수              | 아니요       | 검색할 페이지입니다. `1`로 기본값이 설정됩니다. |
| `per_page` | 정수              | 아니요       | 페이지당 반환할 레코드 수입니다. `20`로 기본값이 설정됩니다. |
| `status`   | 정수 또는 문자열    | 아니요       | 이벤트의 응답 상태 코드(예: `200` 또는 `500`)입니다. 상태 카테고리별로 검색할 수 있습니다:  `successful` (200-299), `client_failure` (400-499), `server_failure` (500-599). |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events"
```

응답 예시:

```json
[
  {
    "id": 1,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "a5461c4d-9c7f-4af9-add6-cddebe3c426f",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:17 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0906479999999874,
    "response_status": "200"
  },
  {
    "id": 2,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "1f0a54f0-0529-408d-a5b8-a2a98ff5f94a",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com:3000",
      "X-Gitlab-Event-UUID": "842d7c3e-3114-4396-8a95-66c084d53cb1",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:19 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0716120000000728,
    "response_status": "200"
  }
]
```

### 그룹 후크 이벤트 다시 보내기 {#resend-group-hook-event}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)되었습니다.

{{< /history >}}

특정 후크 이벤트를 다시 보냅니다.

이 엔드포인트는 각 후크 및 인증된 사용자에 대해 분당 5개 요청의 속도 제한이 있습니다. GitLab Self-Managed 및 GitLab Dedicated에서 이 제한을 비활성화하려면 관리자가 [기능 플래그](../administration/feature_flags/_index.md)를 `web_hook_event_resend_api_endpoint_rate_limit` 비활성화할 수 있습니다.

```plaintext
POST /groups/:id/hooks/:hook_id/events/:hook_event_id/resend
```

지원되는 속성:

| 속성       | 유형              | 필수 | 설명 |
|---------------- |------------------ |--------- |------------ |
| `hook_event_id` | 정수           | 예      | 후크 이벤트의 ID입니다. |
| `hook_id`       | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events/1/resend"
```

응답 예시:

```json
{
  "response_status": 200
}
```

## 그룹 후크 만들기 {#create-a-group-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `signing_token` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) 되었으며 [플래그](../administration/feature_flags/_index.md)라는 이름으로 `webhook_signing_token`입니다. 기본적으로 활성화됨.
- 기능 플래그 `webhook_signing_token`이(가) GitLab 19.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)되었습니다.

{{< /history >}}

지정된 그룹의 그룹 후크를 만듭니다.

```plaintext
POST /groups/:id/hooks
```

지원되는 속성:

| 속성                      | 유형              | 필수 | 설명 |
|------------------------------- |------------------ |--------- |------------ |
| `id`                           | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `url`                          | 문자열            | 예      | 훅 URL입니다. |
| `branch_filter_strategy`       | 문자열            | 아니요       | 푸시 이벤트를 브랜치별로 필터링합니다. 가능한 값은 `wildcard` (기본값), `regex`, `all_branches`입니다. |
| `confidential_issues_events`   | 부울           | 아니요       | 기밀 이슈 이벤트에서 후크를 트리거합니다. |
| `confidential_note_events`     | 부울           | 아니요       | 기밀 노트 이벤트에서 후크를 트리거합니다. |
| `custom_headers`               | 배열             | 아니요       | 후크에 대한 사용자 정의 헤더입니다. |
| `custom_webhook_template`      | 문자열            | 아니요       | 후크에 대한 사용자 정의 웹후크 템플릿입니다. |
| `deployment_events`            | 부울           | 아니요       | 배포 이벤트에서 후크를 트리거합니다. |
| `description`                  | 문자열            | 아니요       | 후크의 설명 (GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)됨)입니다. |
| `enable_ssl_verification`      | 부울           | 아니요       | 훅을 트리거할 때 SSL 검증을 수행합니다. |
| `feature_flag_events`          | 부울           | 아니요       | 기능 플래그 이벤트에서 후크를 트리거합니다. |
| `issues_events`                | 부울           | 아니요       | 이슈 이벤트에서 후크를 트리거합니다. |
| `job_events`                   | 부울           | 아니요       | 작업 이벤트에서 후크를 트리거합니다. |
| `member_events`                | 부울           | 아니요       | 멤버 이벤트에서 후크를 트리거합니다. |
| `merge_requests_events`        | 부울           | 아니요       | 머지 리퀘스트 이벤트에서 훅을 트리거합니다. |
| `milestone_events`             | 부울           | 아니요       | 마일스톤 이벤트에서 후크를 트리거합니다. |
| `name`                         | 문자열            | 아니요       | 후크의 이름 (GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)됨)입니다. |
| `note_events`                  | 부울           | 아니요       | 노트 이벤트에서 후크를 트리거합니다. |
| `pipeline_events`              | 부울           | 아니요       | 파이프라인 이벤트에서 후크를 트리거합니다. |
| `project_events`               | 부울           | 아니요       | 프로젝트 이벤트에서 후크를 트리거합니다. |
| `push_events`                  | 부울           | 아니요       | 푸시 이벤트에서 후크를 트리거합니다. |
| `push_events_branch_filter`    | 문자열            | 아니요       | 일치하는 브랜치에 대해서만 푸시 이벤트에서 훅을 트리거합니다. |
| `releases_events`              | 부울           | 아니요       | 릴리스 이벤트에서 후크를 트리거합니다. |
| `resource_access_token_events` | 부울           | 아니요       | 프로젝트 액세스 토큰 만료 이벤트에서 후크를 트리거합니다. |
| `signing_token`                | 문자열            | 아니요       | `webhook-signature` 헤더를 계산하는 데 사용되는 HMAC 서명 토큰입니다. `whsec_<base64>` 형식이어야 하며 32바이트 키를 인코딩합니다. 응답에서 반환되지 않습니다. |
| `subgroup_events`              | 부울           | 아니요       | 하위 그룹 이벤트에서 후크를 트리거합니다. |
| `tag_push_events`              | 부울           | 아니요       | 태그 푸시 이벤트에서 후크를 트리거합니다. |
| `token`                        | 문자열            | 아니요       | 수신한 페이로드를 검증하는 시크릿 토큰입니다. 응답에서 반환되지 않습니다. |
| `wiki_page_events`             | 부울           | 아니요       | 위키 페이지 이벤트에서 후크를 트리거합니다. |

요청 예시:

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks" \
  --data '{"url": "https://example.com/hook", "name": "My Hook", "description": "Hook description"}'
```

응답 예시:

```json
{
  "id": 42,
  "url": "https://example.com/hook",
  "name": "My Hook",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "token_present": false,
  "signing_token_present": false
}
```

## 그룹 후크 업데이트 {#update-a-group-hook}

{{< history >}}

- `name` 및 `description` 속성이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)되었습니다.
- `signing_token` 속성이 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) 되었으며 [플래그](../administration/feature_flags/_index.md)라는 이름으로 `webhook_signing_token`입니다. 기본적으로 활성화됨.
- 기능 플래그 `webhook_signing_token`이(가) GitLab 19.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)되었습니다.

{{< /history >}}

지정된 그룹의 그룹 후크를 업데이트합니다.

```plaintext
PUT /groups/:id/hooks/:hook_id
```

지원되는 속성:

| 속성                                   | 유형              | 필수 | 설명 |
|-------------------------------------------- |------------------ |--------- |------------ |
| `hook_id`                                   | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`                                        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `url`                                       | 문자열            | 예      | 훅 URL입니다. |
| `branch_filter_strategy`                    | 문자열            | 아니요       | 푸시 이벤트를 브랜치별로 필터링합니다. 가능한 값은 `wildcard` (기본값), `regex`, `all_branches`입니다. |
| `confidential_issues_events`                | 부울           | 아니요       | 기밀 이슈 이벤트에서 후크를 트리거합니다. |
| `confidential_note_events`                  | 부울           | 아니요       | 기밀 노트 이벤트에서 후크를 트리거합니다. |
| `custom_headers`                            | 배열             | 아니요       | 후크에 대한 사용자 정의 헤더입니다. |
| `custom_webhook_template`                   | 문자열            | 아니요       | 후크에 대한 사용자 정의 웹후크 템플릿입니다. |
| `deployment_events`                         | 부울           | 아니요       | 배포 이벤트에서 후크를 트리거합니다. |
| `description`                               | 문자열            | 아니요       | 훅의 설명입니다. |
| `enable_ssl_verification`                   | 부울           | 아니요       | 훅을 트리거할 때 SSL 검증을 수행합니다. |
| `feature_flag_events`                       | 부울           | 아니요       | 기능 플래그 이벤트에서 후크를 트리거합니다. |
| `issues_events`                             | 부울           | 아니요       | 이슈 이벤트에서 후크를 트리거합니다. |
| `job_events`                                | 부울           | 아니요       | 작업 이벤트에서 후크를 트리거합니다. |
| `member_events`                             | 부울           | 아니요       | 멤버 이벤트에서 후크를 트리거합니다. |
| `merge_requests_events`                     | 부울           | 아니요       | 머지 리퀘스트 이벤트에서 훅을 트리거합니다. |
| `milestone_events`                          | 부울           | 아니요       | 마일스톤 이벤트에서 후크를 트리거합니다. |
| `name`                                      | 문자열            | 아니요       | 훅의 이름입니다. |
| `note_events`                               | 부울           | 아니요       | 노트 이벤트에서 후크를 트리거합니다. |
| `pipeline_events`                           | 부울           | 아니요       | 파이프라인 이벤트에서 후크를 트리거합니다. |
| `project_events`                            | 부울           | 아니요       | 프로젝트 이벤트에서 후크를 트리거합니다. |
| `push_events`                               | 부울           | 아니요       | 푸시 이벤트에서 후크를 트리거합니다. |
| `push_events_branch_filter`                 | 문자열            | 아니요       | 일치하는 브랜치에 대해서만 푸시 이벤트에서 훅을 트리거합니다. |
| `releases_events`                           | 부울           | 아니요       | 릴리스 이벤트에서 후크를 트리거합니다. |
| `resource_access_token_events`              | 부울           | 아니요       | 프로젝트 액세스 토큰 만료 이벤트에서 후크를 트리거합니다. |
| `service_access_tokens_expiration_enforced` | 부울           | 아니요       | 서비스 계정 액세스 토큰에 만료 날짜가 있어야 합니다. |
| `signing_token`                             | 문자열            | 아니요       | `webhook-signature` 헤더를 계산하는 데 사용되는 HMAC 서명 토큰입니다. `whsec_<base64>` 형식이어야 하며 32바이트 키를 인코딩합니다. 응답에서 반환되지 않습니다. |
| `subgroup_events`                           | 부울           | 아니요       | 하위 그룹 이벤트에서 후크를 트리거합니다. |
| `tag_push_events`                           | 부울           | 아니요       | 태그 푸시 이벤트에서 후크를 트리거합니다. |
| `token`                                     | 문자열            | 아니요       | 수신한 페이로드를 검증하는 시크릿 토큰입니다. 응답에서 반환되지 않습니다. 웹후크 URL을 변경하면 비밀 토큰이 재설정되고 유지되지 않습니다. |
| `wiki_page_events`                          | 부울           | 아니요       | 위키 페이지 이벤트에서 후크를 트리거합니다. |

요청 예시:

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1" \
  --data '{"url": "https://example.com/hook", "name": "New hook name", "description": "Changed hook description"}'
```

응답 예시:

```json
{
  "id": 1,
  "url": "https://example.com/hook",
  "name": "New hook name",
  "description": "Changed hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ],
  "token_present": false,
  "signing_token_present": false
}
```

## 그룹 후크 삭제 {#delete-a-group-hook}

지정된 그룹 후크를 삭제합니다. 이것은 멱등 메서드이며 여러 번 호출할 수 있습니다. 후크를 사용할 수 있거나 없습니다.

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

성공 시 메시지가 반환되지 않습니다.

## 그룹 후크 테스트 트리거 {#trigger-a-test-group-hook}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)됨.
- 특수 속도 제한이 GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486) 되었으며 [플래그 포함](../administration/feature_flags/_index.md) `web_hook_test_api_endpoint_rate_limit`입니다. 기본적으로 활성화됨.

{{< /history >}}

지정된 그룹에 대한 테스트 후크를 트리거합니다.

이 엔드포인트는 각 그룹 및 인증된 사용자에 대해 분당 5개 요청의 속도 제한이 있습니다. GitLab Self-Managed 및 GitLab Dedicated에서 이 제한을 비활성화하려면 관리자가 [기능 플래그](../administration/feature_flags/_index.md)를 `web_hook_test_api_endpoint_rate_limit` 비활성화할 수 있습니다.

```plaintext
POST /groups/:id/hooks/:hook_id/test/:trigger
```

| 속성 | 유형              | 필수 | 설명 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `trigger` | 문자열            | 예      | `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `milestone_events`, `emoji_events` 또는 `resource_access_token_events` 중 하나입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/test/push_events"
```

응답 예시:

```json
{"message":"201 Created"}
```

## 사용자 정의 헤더 업데이트 {#update-a-custom-header}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)됨.

{{< /history >}}

지정된 그룹 후크의 사용자 정의 헤더를 업데이트합니다.

```plaintext
PUT /groups/:id/hooks/:hook_id/custom_headers/:key
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`     | 문자열            | 예      | 사용자 정의 헤더의 키입니다. |
| `value`   | 문자열            | 예      | 사용자 정의 헤더의 값입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key?value='header_value'"
```

성공 시 메시지가 반환되지 않습니다.

## 사용자 지정 헤더 삭제 {#delete-a-custom-header}

{{< history >}}

- [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)됨.

{{< /history >}}

사용자 정의 헤더를 삭제합니다.

```plaintext
DELETE /groups/:id/hooks/:hook_id/custom_headers/:key
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`     | 문자열            | 예      | 사용자 정의 헤더의 키입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key"
```

성공 시 메시지가 반환되지 않습니다.

## URL 변수 업데이트 {#update-a-url-variable}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310)되었습니다.

{{< /history >}}

지정된 그룹 후크의 URL 변수를 업데이트합니다.

```plaintext
PUT /groups/:id/hooks/:hook_id/url_variables/:key
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`     | 문자열            | 예      | URL 변수의 키입니다. |
| `value`   | 문자열            | 예      | URL 변수의 값입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key?value='my_key_value'"
```

성공 시 메시지가 반환되지 않습니다.

## URL 변수 삭제 {#delete-a-url-variable}

지정된 그룹 후크의 URL 변수를 삭제합니다.

```plaintext
DELETE /groups/:id/hooks/:hook_id/url_variables/:key
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 정수           | 예      | 그룹 후크의 ID입니다. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `key`     | 문자열            | 예      | URL 변수의 키입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key"
```

성공 시 메시지가 반환되지 않습니다.
