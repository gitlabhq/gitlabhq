---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIアプリケーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、インスタンス全体のOAuthアプリケーションを管理します:

- [認証プロバイダーとしてGitLabを使用する](../integration/oauth_provider.md)。
- [ユーザーに代わってGitLabリソースへのアクセスを許可する](oauth2.md)。

{{< alert type="note" >}}

このAPIを使用して、グループアプリケーションまたは個々のユーザーアプリケーションを管理することはできません。

{{< /alert >}}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

## アプリケーションを作成する {#create-an-application}

JSONペイロードをリクエストすることで、アプリケーションを作成します。

リクエストが成功すると、`200`を返します。

```plaintext
POST /applications
```

サポートされている属性は以下のとおりです:

| 属性      | 型    | 必須 | 説明                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | 文字列  | はい      | アプリケーションの名前。         |
| `redirect_uri` | 文字列  | はい      | アプリケーションのリダイレクトURI。 |
| `scopes`       | 文字列  | はい      | アプリケーションで使用できるスコープ。複数のスコープをスペースで区切ります。 |
| `confidential` | ブール値 | いいえ       | `true`の場合、アプリケーションは、クライアントの認証情報 (クライアントシークレットなど) を安全に保存できます。機密性の低いアプリケーション (ネイティブモバイルアプリやシングルページアプリなど) は、クライアントの認証情報を公開する可能性があります。指定されていない場合、`true`がデフォルトになります。 |

リクエスト例:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/applications"
```

レスポンス例:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## すべてのアプリケーションをリストする {#list-all-applications}

登録されているすべてのアプリケーションをリストします。

```plaintext
GET /applications
```

リクエスト例:

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications"
```

レスポンス例:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true
    }
]
```

{{< alert type="note" >}}

`secret`の値は、このAPIでは公開されていません。

{{< /alert >}}

## アプリケーションを削除する {#delete-an-application}

登録済みのアプリケーションを削除します。

リクエストが成功すると、`204`を返します。

```plaintext
DELETE /applications/:id
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 整数 | はい      | アプリケーションのID（`application_id`ではありません）。 |

リクエスト例:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id"
```

## アプリケーションのシークレットを更新する {#renew-an-application-secret}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)されました。

{{< /history >}}

アプリケーションのシークレットを更新します。リクエストが成功すると、`200`を返します。

```plaintext
POST /applications/:id/renew-secret
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 整数 | はい      | アプリケーションのID（`application_id`ではありません）。 |

リクエスト例:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id/renew-secret"
```

レスポンス例:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```
