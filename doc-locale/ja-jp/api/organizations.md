---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 組織API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

このAPIを使用して、GitLabの組織と連携します。詳細については、[組織](../user/organization/_index.md)を参照してください。

## 組織を作成する {#create-an-organization}

{{< history >}}

- GitLab 17.5で、`allow_organization_creation`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/470613)。デフォルトでは無効になっています。これは[実験的機能](../policy/development_stages_support.md)です。
- GitLab 18.4で[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/549062)。機能フラグ`allow_organization_creation`が統合され、`organization_switching`に名称変更されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

組織を作成します。

このエンドポイントは[実験的機能](../policy/development_stages_support.md)であり、予告なく変更または削除される可能性があります。

```plaintext
POST /organizations
```

パラメータは以下のとおりです:

| 属性     | 型   | 必須 | 説明                           |
|---------------|--------|----------|---------------------------------------|
| `name`        | 文字列 | はい      | 組織名          |
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
  "uuid": "0192f8c2-1a2b-7cde-89ab-0123456789ab",
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/o/new-org/-/overview",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```

## 組織を論理削除する {#soft-delete-an-organization}

{{< history >}}

- [GitLab](https://gitlab.com/gitlab-org/gitlab/-/issues/599345) 19.2で導入されました。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

組織を論理削除します。組織は空（グループやプロジェクトがない）であり、デフォルト組織であってはなりません。組織のオーナーと管理者のみが組織を論理削除できます。

このエンドポイントは[実験的機能](../policy/development_stages_support.md)であり、予告なく変更または削除される可能性があります。

```plaintext
DELETE /organizations/:id
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明                   |
|-----------|---------|----------|-------------------------------|
| `id`      | 整数 | はい      | 組織のID    |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/42"
```

成功した場合、`202 Accepted`を返します。
