---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 組織API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

このAPIを使用してGitLabの組織を操作します。詳細については、[organization](../user/organization/_index.md)を参照してください。

## 組織を作成 {#create-an-organization}

{{< history >}}

- GitLab 17.5で、`allow_organization_creation`という[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470613)されました。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。
- GitLab 18.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/549062)されました。機能フラグ`allow_organization_creation`が統合され、`organization_switching`に名前が変更されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

新しい組織を作成します。

このエンドポイントは[実験的機能](../policy/development_stages_support.md)であり、予告なく変更または削除される可能性があります。

```plaintext
POST /organizations
```

パラメータは以下のとおりです:

| 属性     | 型   | 必須 | 説明                           |
|---------------|--------|----------|---------------------------------------|
| `name`        | 文字列 | はい      | 組織の名前          |
| `path`        | 文字列 | はい      | 組織のパス          |
| `description` | 文字列 | いいえ       | 組織の説明   |
| `avatar`      | ファイル   | いいえ       | 組織のアバター画像 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "name=New Organization" \
--form "path=new-org" \
--form "description=A new organization" \
--form "avatar=@/path/to/avatar.png" \
"https://gitlab.example.com/api/v4/organizations"
```

レスポンス例:

```json
{
  "id": 42,
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/-/organizations/new-org",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```
