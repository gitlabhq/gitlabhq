---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab CI/CD 작업 토큰](../ci/jobs/ci_job_token.md) 인증이 [GitLab 16.2에 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414549)되었습니다.

{{< /history >}}

이 API를 사용하여 GitLab 환경에 [코드 배포](../ci/environments/deployments.md)와 상호 작용합니다.

## 모든 프로젝트 배포 나열 {#list-all-project-deployments}

프로젝트의 모든 배포를 나열합니다.

```plaintext
GET /projects/:id/deployments
```

| 속성         | 유형           | 필수 | 설명                                                                                                     |
|-------------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`              | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `order_by`        | 문자열         | 아니요       | 배포를 `id`, `iid`, `created_at`, `updated_at`, `finished_at` 또는 `ref` 필드 중 하나로 정렬하여 반환합니다. 기본값은 `id`입니다.    |
| `sort`            | 문자열         | 아니요       | 배포를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `asc`입니다.                                            |
| `updated_after`   | 날짜/시간       | 아니요       | 지정된 날짜 이후에 업데이트된 배포를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `updated_before`  | 날짜/시간       | 아니요       | 지정된 날짜 이전에 업데이트된 배포를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `finished_after`  | 날짜/시간       | 아니요       | 지정된 날짜 이후에 완료된 배포를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `finished_before` | 날짜/시간       | 아니요       | 지정된 날짜 이전에 완료된 배포를 반환합니다. ISO 8601 형식(`2019-03-15T08:00:00Z`)으로 예상됩니다. |
| `environment`     | 문자열         | 아니요       | 배포를 필터링할 [환경의 이름](../ci/environments/_index.md)입니다.       |
| `status`          | 문자열         | 아니요       | 배포를 필터링할 상태입니다. `created`, `running`, `success`, `failed`, `canceled` 또는 `blocked` 중 하나입니다. |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

> [!note]
> `finished_before` 또는 `finished_after`을 사용할 때, `order_by`을 `finished_at`로 지정하고 `status`은 `success`이어야 합니다.

응답 예시:

```json
[
  {
    "created_at": "2016-08-11T07:36:40.222Z",
    "updated_at": "2016-08-11T07:38:12.414Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T09:36:01.000+02:00",
        "id": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "message": "Merge branch 'new-title' into 'main'\r\n\r\nUpdate README\r\n\r\n\r\n\r\nSee merge request !1",
        "short_id": "99d03678",
        "title": "Merge branch 'new-title' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T07:36:27.357Z",
      "finished_at": "2016-08-11T07:36:39.851Z",
      "id": 657,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "project": {
        "ci_job_token_scope_enabled": false
      },
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T02:12:10.222Z",
        "id": 36,
        "ref": "main",
        "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "status": "success",
        "updated_at": "2016-08-11T02:12:10.222Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/12"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 41,
    "iid": 1,
    "ref": "main",
    "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  },
  {
    "created_at": "2016-08-11T11:32:35.444Z",
    "updated_at": "2016-08-11T11:34:01.123Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T13:28:26.000+02:00",
        "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2",
        "short_id": "a91957a8",
        "title": "Merge branch 'rename-readme' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T11:32:24.456Z",
      "finished_at": "2016-08-11T11:32:35.145Z",
      "id": 664,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "project": {
        "ci_job_token_scope_enabled": false
      },
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T07:43:52.143Z",
        "id": 37,
        "ref": "main",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "status": "success",
        "updated_at": "2016-08-11T07:43:52.143Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/13"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 42,
    "iid": 2,
    "ref": "main",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  }
]
```

## 배포 검색 {#retrieve-a-deployment}

단일 배포를 검색합니다.

```plaintext
GET /projects/:id/deployments/:deployment_id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `deployment_id` | 정수 | 예      | 배포의 ID |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

응답 예시:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "updated_at": "2016-08-11T11:34:01.123Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": {
    "id": 664,
    "status": "success",
    "stage": "deploy",
    "name": "deploy",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "created_at": "2016-08-11T11:32:24.456Z",
    "started_at": null,
    "finished_at": "2016-08-11T11:32:35.145Z",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "commit": {
      "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "short_id": "a91957a8",
      "title": "Merge branch 'rename-readme' into 'main'\r",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "created_at": "2016-08-11T13:28:26.000+02:00",
      "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2"
    },
    "pipeline": {
      "created_at": "2016-08-11T07:43:52.143Z",
      "id": 42,
      "ref": "main",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "status": "success",
      "updated_at": "2016-08-11T07:43:52.143Z",
      "web_url": "http://gitlab.dev/root/project/pipelines/5"
    },
    "runner": null
  }
}
```

[여러 승인 규칙](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)이 구성되면, GitLab Premium 또는 Ultimate의 사용자가 만든 배포에는 `approval_summary` 속성이 포함됩니다:

```json
{
  "approval_summary": {
    "rules": [
      {
        "user_id": null,
        "group_id": 134,
        "access_level": null,
        "access_level_description": "qa-group",
        "required_approvals": 1,
        "deployment_approvals": []
      },
      {
        "user_id": null,
        "group_id": 135,
        "access_level": null,
        "access_level_description": "security-group",
        "required_approvals": 2,
        "deployment_approvals": [
          {
            "user": {
              "id": 100,
              "username": "security-user-1",
              "name": "security user-1",
              "state": "active",
              "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
              "web_url": "http://localhost:3000/security-user-1"
            },
            "status": "approved",
            "created_at": "2022-04-11T03:37:03.058Z",
            "comment": null
          }
        ]
      }
    ]
  }
  ...
}
```

## 배포 생성 {#create-a-deployment}

배포를 생성합니다.

```plaintext
POST /projects/:id/deployments
```

| 속성     | 유형           | 필수 | 설명                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다.|
| `environment` | 문자열         | 예      | 배포를 생성할 [환경의 이름](../ci/environments/_index.md)입니다.                        |
| `sha`         | 문자열         | 예      | 배포된 커밋의 SHA입니다.                                                                         |
| `ref`         | 문자열         | 예      | 배포된 브랜치 또는 태그의 이름입니다.                                                                 |
| `tag`         | 부울        | 예      | 배포된 ref가 태그인지(`true`) 아닌지(`false`)를 나타내는 부울입니다.                                |
| `status`      | 문자열         | 예      | 생성된 배포의 상태입니다. `running`, `success`, `failed` 또는 `canceled` 중 하나        |

```shell
curl --request "POST" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "environment=production&sha=a91957a858320c0e17f3a0eca7cfacbff50ea29a&ref=main&tag=false&status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

응답 예시:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

GitLab Premium 또는 Ultimate의 사용자가 만든 배포에는 `approvals` 및 `pending_approval_count` 속성이 포함됩니다:

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [],
  ...
}
```

## 배포 업데이트 {#update-a-deployment}

배포를 업데이트합니다.

```plaintext
PUT /projects/:id/deployments/:deployment_id
```

| 속성        | 유형           | 필수 | 설명         |
|------------------|----------------|----------|---------------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `deployment_id`  | 정수        | 예      | 업데이트할 배포의 ID입니다. |
| `status`         | 문자열         | 예      | 배포의 새로운 상태입니다. `running`, `success`, `failed` 또는 `canceled` 중 하나입니다.                         |

```shell
curl --request "PUT" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42"
```

응답 예시:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

GitLab Premium 또는 Ultimate의 사용자가 만든 배포에는 `approvals` 및 `pending_approval_count` 속성이 포함됩니다:

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [
    {
      "user": {
        "id": 49,
        "username": "project_6_bot",
        "name": "****",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e83ac685f68ea07553ad3054c738c709?s=80&d=identicon",
        "web_url": "http://localhost:3000/project_6_bot"
      },
      "status": "approved",
      "created_at": "2022-02-24T20:22:30.097Z",
      "comment": "Looks good to me"
    }
  ],
  ...
}
```

## 배포 삭제 {#delete-a-deployment}

현재 환경의 마지막 배포가 아니거나 `running` 상태인 지정된 배포를 삭제합니다.

```plaintext
DELETE /projects/:id/deployments/:deployment_id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `deployment_id` | 정수 | 예      | 배포의 ID |

```shell
curl --request "DELETE" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

응답 예시:

```json
{ "message": "204 Deployment destroyed" }
```

```json
{ "message": "403 Forbidden" }
```

```json
{ "message": "400 Cannot destroy running deployment" }
```

```json
{ "message": "400 Deployment currently deployed to environment" }
```

## 배포와 연결된 모든 머지 리퀘스트 나열 {#list-all-merge-requests-associated-with-a-deployment}

> [!note]
> 모든 배포를 머지 리퀘스트와 연결할 수 있는 것은 아닙니다. [환경에 배포된 머지 리퀘스트 추적](../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment)을 참조하여 자세한 정보를 확인하세요.

주어진 배포로 제공된 모든 머지 리퀘스트를 나열합니다.

```plaintext
GET /projects/:id/deployments/:deployment_id/merge_requests
```

[머지 리퀘스트 API](merge_requests.md#list-merge-requests)와 동일한 매개변수를 지원하며 동일한 형식으로 응답을 반환합니다:

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42/merge_requests"
```

## 배포 승인 또는 거부 {#approve-or-reject-a-deployment}

배포를 승인하거나 거부합니다.

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/343864) 되었으며 [플래그](../administration/feature_flags/_index.md) `deployment_approvals`로 명명되었습니다. 기본적으로 비활성화됨.
- GitLab 14.8에서 [기능 플래그 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/347342)되었습니다.

{{< /history >}}

[배포 승인](../ci/environments/deployment_approvals.md)을 참조하여 이 기능에 대한 자세한 정보를 확인하세요.

```plaintext
POST /projects/:id/deployments/:deployment_id/approval
```

| 속성       | 유형           | 필수 | 설명                                                                                                     |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `deployment_id` | 정수        | 예      | 배포의 ID입니다.                                                                                       |
| `status`        | 문자열         | 예      | 승인의 상태(`approved` 또는 `rejected` 중 하나)입니다.                                                   |
| `comment`       | 문자열         | 아니요       | 승인과 함께 포함할 의견                                                                               |
| `represented_as`| 문자열         | 아니요       | 사용자가 [여러 승인 규칙](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)에 속할 때 승인에 사용할 사용자/그룹/역할의 이름입니다. |

```shell
curl --request "POST" \
  --data "status=approved&comment=Looks good to me&represented_as=security" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1/approval"
```

응답 예시:

```json
{
  "user": {
    "id": 100,
    "username": "security-user-1",
    "name": "security user-1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
    "web_url": "http://localhost:3000/security-user-1"
  },
  "status": "approved",
  "created_at": "2022-02-24T20:22:30.097Z",
  "comment":"Looks good to me"
}
```
