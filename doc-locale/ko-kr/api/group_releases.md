---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 릴리스 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/351703) 되었으며, [플래그](../administration/feature_flags/_index.md)의 이름은 `group_releases_finder_inoperator`입니다. 기본적으로 비활성화됨.
- GitLab 15.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/355463)합니다. 기능 플래그 `group_releases_finder_inoperator` 제거됨.

{{< /history >}}

이 API를 사용하여 그룹의 [프로젝트 릴리스](../user/project/releases/_index.md)와 상호작용합니다.

> [!note]
> 프로젝트 릴리스와 직접 상호작용하려면 [프로젝트 릴리스 API](releases/_index.md)를 참조하세요.

## 그룹의 모든 릴리스 나열 {#list-all-releases-in-a-group}

지정된 그룹의 프로젝트에 대한 모든 릴리스를 나열합니다.

```plaintext
GET /groups/:id/releases
GET /groups/:id/releases?simple=true
```

매개 변수:

| 특성 | 유형           | 필수 | 설명 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `sort`    | 문자열         | 아니오       | 정렬 순서의 방향입니다. 가능한 값: `desc` 또는 `asc`입니다. |
| `simple`  | 부울        | 아니오       | `true`인 경우 각 릴리스에 대해 제한된 필드만 반환합니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>"
   --url "https://gitlab.example.com/api/v4/groups/5/releases"
```

응답 예시:

```json
[
  {
    "name": "standard release",
    "tag_name": "releasetag",
    "description": "",
    "created_at": "2022-01-10T15:23:15.529Z",
    "released_at": "2022-01-10T15:23:15.529Z",
    "author": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.com/root"
    },
    "commit": {
      "id": "e8cbb845ae5a53a2fef2938cf63cf82efc10d993",
      "short_id": "e8cbb845",
      "created_at": "2022-01-10T15:20:29.000+00:00",
      "parent_ids": [],
      "title": "Update test",
      "message": "Update test",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "authored_date": "2022-01-10T15:20:29.000+00:00",
      "committer_name": "Administrator",
      "committer_email": "admin@example.com",
      "committed_date": "2022-01-10T15:20:29.000+00:00",
      "trailers": {},
      "web_url": "https://gitlab.com/groups/gitlab-org/-/commit/e8cbb845ae5a53a2fef2938cf63cf82efc10d993"
    },
    "upcoming_release": false,
    "commit_path": "/testgroup/test/-/commit/e8cbb845ae5a53a2fef2938cf63cf82efc10d993",
    "tag_path": "/testgroup/test/-/tags/testtag"
  }
]
```
