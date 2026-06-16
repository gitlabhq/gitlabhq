---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アプリケーションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、次のインスタンス全体のOAuthアプリケーションを管理します:

- [GitLabを認証プロバイダーとして使用する](../integration/oauth_provider.md)。
- [ユーザーに代わってGitLabリソースへのアクセスを許可する](oauth2.md)。

> [!note]
> このAPIを使用して、グループアプリケーションまたは個々のユーザーアプリケーションを管理することはできません。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## アプリケーションを作成 {#create-an-application}

アプリケーションを作成します。

リクエストが成功した場合、`200`を返します。

```plaintext
POST /applications
```

サポートされている属性は以下のとおりです: 

| 属性      | 型    | 必須 | 説明                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | 文字列  | はい      | アプリケーションの名前。         |
| `redirect_uri` | 文字列  | はい      | アプリケーションのリダイレクトURI。 |
| `scopes`       | 文字列  | はい      | アプリケーションで利用可能なスコープ。複数のスコープをスペースで区切ります。 |
| `confidential` | ブール値 | いいえ       | `true`の場合、アプリケーションはクライアント認証情報（クライアントシークレットなど）を安全に保存できます。非機密アプリケーション（ネイティブモバイルアプリやシングルページアプリケーションなど）は、クライアント認証情報を公開する可能性があります。指定されていない場合、`true`がデフォルトです。 |

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
    "confidential": true,
    "scopes": ["api", "read_user", "email"]
}
```

## すべてのアプリケーションをリスト表示 {#list-all-applications}

すべてのアプリケーションをリスト表示します。

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
        "confidential": true,
        "scopes": ["api", "read_user"]
    }
]
```

> [!note]
> `secret`の値は、このAPIでは公開されません。

## アプリケーションを削除 {#delete-an-application}

指定されたアプリケーションを削除します。

リクエストが成功した場合、`204`を返します。

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

## アプリケーションシークレットを更新 {#renew-an-application-secret}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)されました。

{{< /history >}}

指定されたアプリケーションのシークレットを更新します。リクエストが成功した場合、`200`を返します。

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
    "confidential": true,
    "scopes": ["api", "read_user"]
}
```
