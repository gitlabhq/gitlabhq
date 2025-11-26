---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バージョンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

バージョンAPIの代わりに、[Metadata API](metadata.md)を使用することをお勧めします。追加情報が含まれており、GraphQLメタデータエンドポイントと連携しています。バージョンAPIは、Metadata APIのミラーです。

{{< /alert >}}

GitLabインスタンスのバージョン情報を取得する。認証済みユーザーに対して`200 OK`で応答します。

```plaintext
GET /version
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/version"

```

## レスポンスの例 {#example-responses}

応答については、[Metadata API](metadata.md)を参照してください。
