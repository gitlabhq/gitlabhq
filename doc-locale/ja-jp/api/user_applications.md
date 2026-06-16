---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーアプリケーションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、以下のユーザーレベルOAuthアプリケーションを管理します:

- [GitLabを認証プロバイダーとして使用する](../integration/oauth_provider.md)。
- [ユーザーに代わってGitLabリソースへのアクセスを許可する](oauth2.md)。

> [!note]
> インスタンス全体のアプリケーションを管理するには、[Applications API](applications.md)を使用してください。

前提条件: 

- 管理者アクセス権、またはアプリケーションを所有する認証済みユーザーとしてアクセス。

## アプリケーションを作成する {#create-an-application}

認証済みユーザー用に新しいOAuthアプリケーションを作成します。

リクエストが成功すると`201`を返します。

```plaintext
POST /user/applications
```

サポートされている属性は以下のとおりです: 

| 属性      | 型    | 必須 | 説明                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | 文字列  | はい      | アプリケーションの名前。         |
| `redirect_uri` | 文字列  | はい      | アプリケーションのリダイレクトURI。 |
| `scopes`       | 文字列  | はい      | アプリケーションで利用可能なスコープ。複数のスコープはスペースで区切ります。 |
| `confidential` | ブール値 | いいえ       | `true`の場合、アプリケーションはクライアントシークレットなどのクライアント認証情報を安全に保存できます。機密性のないアプリケーション（ネイティブモバイルアプリやSPAなど）は、クライアント認証情報を公開する可能性があります。指定しない場合、`true`がデフォルトになります。 |

リクエスト例: 

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/user/applications"
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

## すべてのアプリケーションを一覧表示する {#list-all-applications}

認証済みユーザーが所有するすべてのアプリケーションを一覧表示します。

```plaintext
GET /user/applications
```

リクエスト例: 

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications"
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

## 特定のアプリケーションを取得する {#retrieve-a-specific-application}

認証済みユーザーが所有する特定のアプリケーションの詳細を取得します。

リクエストが成功すると`200`を返します。

```plaintext
GET /user/applications/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 整数 | はい      | アプリケーションのID。`application_id`とは異なります。 |

リクエスト例: 

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

レスポンス例: 

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## アプリケーションを更新する {#update-an-application}

認証済みユーザーが所有する既存のアプリケーションを更新します。

リクエストが成功すると`200`を返します。

```plaintext
PUT /user/applications/:id
```

サポートされている属性は以下のとおりです: 

| 属性      | 型    | 必須 | 説明                      |
|:---------------|:--------|:---------|:---------------------------------|
| `id`           | 整数 | はい      | アプリケーションのID。`application_id`とは異なります。 |
| `name`         | 文字列  | いいえ       | アプリケーションの名前。         |
| `scopes`       | 文字列  | いいえ       | アプリケーションで利用可能なスコープ。複数のスコープはスペースで区切ります。 |

リクエスト例: 

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=UpdatedApplication" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

レスポンス例: 

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "UpdatedApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## アプリケーションを削除する {#delete-an-application}

認証済みユーザーが所有する指定されたアプリケーションを削除します。

リクエストが成功すると`204`を返します。

```plaintext
DELETE /user/applications/:id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | 整数 | はい      | アプリケーションのID。`application_id`とは異なります。 |

リクエスト例: 

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```
