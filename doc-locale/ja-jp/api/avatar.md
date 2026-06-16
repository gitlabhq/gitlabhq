---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アバターAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ユーザーのアバターを操作します。

## ユーザーアカウントのアバターを取得する {#retrieve-user-account-avatar}

指定された公開メールアドレスに関連付けられたユーザーアカウントの[アバター](../user/profile/_index.md#access-your-user-settings)のURLを取得します。このエンドポイントは認証を必要としません。

- 成功した場合、アバターのURLを返します。
- 指定されたメールアドレスに関連付けられたアカウントがない場合、外部のアバターサービスからの結果を返します。
- 公開表示レベルが制限されており、リクエストが認証されていない場合、`403 Forbidden`を返します。

```plaintext
GET /avatar?email=admin@example.com
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明 |
| --------- | ------- | -------- | ----------- |
| `email`   | 文字列  | はい      | アカウントの公開メールアドレス。 |
| `size`    | 整数 | いいえ       | 単一ピクセル寸法。`Gravatar`または設定された`Libravatar`サーバーでのアバター検索にのみ使用されます。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/avatar?email=admin@example.com&size=32"
```

レスポンス例: 

```json
{
  "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=64&d=identicon"
}
```

## 関連トピック {#related-topics}

- [自分のアバターをアップロード](users.md#upload-an-avatar-for-yourself)。
- [プロジェクトアバターをアップロード](projects.md#upload-a-project-avatar)。
