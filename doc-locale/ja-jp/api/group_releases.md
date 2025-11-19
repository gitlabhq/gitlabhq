---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グルーリリースAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.10で`group_releases_finder_inoperator`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/351703)されました。デフォルトでは無効になっています。
- GitLab 15.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/355463)になりました。機能フラグ`group_releases_finder_inoperator`は削除されました。

{{< /history >}}

このAPIを使用して、グループ内の[projectsリリース](../user/project/releases/_index.md)を操作します。

{{< alert type="note" >}}

プロジェクトリリースを直接操作するには、[projectリリースAPI](releases/_index.md)を参照してください。

{{< /alert >}}

## グループ内のすべてのリリースをリストします {#list-all-releases-in-a-group}

指定されたグループ内のプロジェクトのすべてのリリースをリストします。

```plaintext
GET /groups/:id/releases
GET /groups/:id/releases?simple=true
```

パラメータは以下のとおりです:

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `sort`    | 文字列         | いいえ       | 並び替えの方向。使用可能な値: `desc`または`asc`。 |
| `simple`  | ブール値        | いいえ       | `true`の場合、各リリースについて制限されたフィールドのみを返します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>"
   --url "https://gitlab.example.com/api/v4/groups/5/releases"
```

レスポンス例:

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
