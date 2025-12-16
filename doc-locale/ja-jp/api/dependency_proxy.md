---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存プロキシAPI
description: GitLab依存プロキシのREST APIのドキュメント。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## グループの依存プロキシをパージ {#purge-the-dependency-proxy-for-a-group}

グループのキャッシュされたマニフェストとblobの削除をスケジュールします。このエンドポイントには、グループのオーナーロールが必要です。

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
