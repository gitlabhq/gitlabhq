---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group release API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351703) in GitLab 14.10 [with a flag](../administration/feature_flags/_index.md) named `group_releases_finder_inoperator`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/355463) in GitLab 15.0. Feature flag `group_releases_finder_inoperator` removed.

{{< /history >}}

Use this API to interact with [projects releases](../user/project/releases/_index.md) in groups.

{{< alert type="note" >}}

To interact with project releases directly, see the [project release API](releases/_index.md).

{{< /alert >}}

## List all releases in a group

Lists all releases for projects in a specified group.

```plaintext
GET /groups/:id/releases
GET /groups/:id/releases?simple=true
```

Parameters:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `sort`    | string         | no       | The direction of the order. Possible values: `desc` or `asc`. |
| `simple`  | boolean        | no       | If `true`, only returns limited fields for each release. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>"
   --url "https://gitlab.example.com/api/v4/groups/5/releases"
```

Example response:

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
