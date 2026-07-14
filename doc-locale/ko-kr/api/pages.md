---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pages API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab Pages를 [관리](../administration/pages/_index.md) 하고 [사용](../user/project/pages/_index.md)합니다.

GitLab Pages 기능을 활성화해야 이 엔드포인트를 사용할 수 있습니다.

## Pages 게시 취소 {#unpublish-pages}

{{< history >}}

- GitLab 17.9에서 최소 필수 역할을 관리자 액세스에서 Maintainer 역할로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/498658)했습니다.

{{< /history >}}

지정된 프로젝트에서 Pages를 게시 취소하고 제거합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
DELETE /projects/:id/pages
```

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

## 프로젝트의 Pages 설정 검색 {#retrieve-pages-settings-for-a-project}

{{< history >}}

- GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/436932)되었습니다.

{{< /history >}}

지정된 프로젝트의 Pages 설정을 검색합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
GET /projects/:id/pages
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                 | 유형       | 설명                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | 문자열     | 이 프로젝트의 Pages에 액세스하기 위한 URL입니다.                                                                                            |
| `is_unique_domain_enabled`                | 부울    | [고유 도메인](../user/project/pages/introduction.md)이 활성화된 경우입니다.                                                        |
| `force_https`                             | 부울    | `true` 프로젝트가 HTTPS를 강제하도록 설정된 경우입니다.                                                                                      |
| `deployments[]`                           | 배열      | 현재 활성 배포 목록입니다.                                                                                          |
| `primary_domain`                          | 문자열     | 모든 Pages 요청을 리디렉션할 기본 도메인입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)되었습니다. |

| `deployments[]` 속성                 | 유형       | 설명                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | 날짜       | 배포가 생성된 날짜입니다.                                                                                                  |
| `url`                                     | 문자열     | 이 배포의 URL입니다.                                                                                                      |
| `path_prefix`                             | 문자열     | [병렬 배포](../user/project/pages/_index.md#parallel-deployments)를 사용할 때 이 배포의 경로 접두사입니다. |
| `root_directory`                          | 문자열     | 루트 디렉터리입니다.                                                                                                               |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/2/pages"
```

응답 예시:

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```

## 프로젝트의 Pages 설정 업데이트 {#update-pages-settings-for-a-project}

{{< history >}}

- [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147227).
- GitLab 17.9에서 최소 필수 역할을 관리자 액세스에서 Maintainer 역할로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/498658)했습니다.

{{< /history >}}

지정된 프로젝트의 Pages 설정을 업데이트합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

```plaintext
PATCH /projects/:id/pages
```

지원되는 속성:

| 속성                       | 유형           | 필수 | 설명                                                                                                         |
| --------------------------------| -------------- | -------- | --------------------------------------------------------------------------------------------------------------------|
| `id`                            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                                 |
| `pages_unique_domain_enabled`   | 부울        | 아니요       | 고유 도메인 사용 여부                                                                                        |
| `pages_https_only`              | 부울        | 아니요       | HTTPS 강제 여부                                                                                              |
| `pages_primary_domain`          | 문자열         | 아니요       | 기존 할당된 도메인에서 기본 도메인을 설정하여 모든 Pages 요청을 리디렉션합니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)되었습니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                 | 유형       | 설명                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | 문자열     | 이 프로젝트의 Pages에 액세스하기 위한 URL입니다.                                                                                            |
| `is_unique_domain_enabled`                | 부울    | [고유 도메인](../user/project/pages/introduction.md)이 활성화된 경우입니다.                                                        |
| `force_https`                             | 부울    | `true` 프로젝트가 HTTPS를 강제하도록 설정된 경우입니다.                                                                                      |
| `deployments[]`                           | 배열      | 현재 활성 배포 목록입니다.                                                                                          |
| `primary_domain`                          | 문자열     | 모든 Pages 요청을 리디렉션할 기본 도메인입니다. GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/481334)되었습니다. |

| `deployments[]` 속성                 | 유형       | 설명                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | 날짜       | 배포가 생성된 날짜입니다.                                                                                                  |
| `url`                                     | 문자열     | 이 배포의 URL입니다.                                                                                                      |
| `path_prefix`                             | 문자열     | [병렬 배포](../user/project/pages/_index.md#parallel-deployments)를 사용할 때 이 배포의 경로 접두사입니다. |
| `root_directory`                          | 문자열     | 루트 디렉터리입니다.                                                                                                               |

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/pages" \
  --form 'pages_unique_domain_enabled=true' \
  --form 'pages_https_only=true' \
  --form 'pages_primary_domain=https://custom.example.com'
```

응답 예시:

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ],
  "primary_domain": null
}
```
