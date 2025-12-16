---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: トークン情報を公開するREST APIのドキュメント。
title: トークン情報API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

このAPIを使用すると、任意のトークンに関する詳細を取得し、それらを失効することができます。他のトークン情報を公開するAPIとは異なり、このAPIを使用すると、トークンの特定のタイプを知らなくても、詳細を取得したり、トークンを失効することができます。

## トークンのプレフィックス {#token-prefixes}

リクエストを行う場合、`personal`、`project`、または`group access`トークンは、`glpat`または現在の[カスタムプレフィックス](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)で始まる必要があります。トークンが以前のカスタムプレフィックスで始まる場合、操作は失敗します。以前のカスタムプレフィックスのサポートへの関心は、[issue 165663](https://gitlab.com/gitlab-org/gitlab/-/issues/165663)で追跡されます。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

## トークンに関する情報を取得します {#get-information-on-a-token}

{{< history >}}

- GitLab 17.5で`admin_agnostic_token_finder`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165157)されました。デフォルトでは無効になっています。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/490572)になりました。機能フラグ`admin_agnostic_token_finder`は削除されました。
- [フィードトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169821)されました（GitLab 17.6）。
- [OAuthアプリケーションシークレットが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172985)されました（GitLab 17.7）。
- [クラスターエージェントトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172932)されました（GitLab 17.7）。
- [Runner認証トークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173987)されました（GitLab 17.7）。
- [パイプライントリガートークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174030)されました（GitLab 17.7）。
- [CI/CDジョブトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175234)されました（GitLab 17.9）。
- [機能フラグクライアントトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177431)されました（GitLab 17.9）。
- [GitLabセッションクッキーが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178022)されました（GitLab 17.9）。
- [受信メールトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177077)されました（GitLab 17.9）。

{{< /history >}}

指定されたトークンの情報を取得します。このエンドポイントは、次のトークンをサポートしています:

- [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- [代理トークン](../rest/authentication.md#impersonation-tokens)
- [デプロイトークン](../../user/project/deploy_tokens/_index.md)
- [フィードトークン](../../security/tokens/_index.md#feed-token)
- [OAuthアプリケーションシークレット](../../integration/oauth_provider.md)
- [クラスターエージェントトークン](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [Runner認証トークン](../../security/tokens/_index.md#runner-authentication-tokens)
- [パイプライントリガートークン](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [CI/CDジョブトークン](../../security/tokens/_index.md#cicd-job-tokens)。
- [機能フラグクライアントトークン](../../operations/feature_flags.md#get-access-credentials)
- [GitLabセッションクッキー](../../user/profile/active_sessions.md)
- [受信メールトークン](../../security/tokens/_index.md#incoming-email-token)

```plaintext
POST /api/v4/admin/token
```

サポートされている属性は以下のとおりです:

| 属性    | 型    | 必須 | 説明                |
|--------------|---------|----------|----------------------------|
| `token`      | 文字列  | はい      | 識別する既存のトークン。`Personal`、`project`、または`group access`トークンは、`glpat`または現在の[カスタムプレフィックス](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)で始まる必要があります。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)とトークンに関する情報を返します。

次のステータスコードを返すことができます:

- `200 OK`: トークンに関する情報。
- `401 Unauthorized`: ユーザーは認証されていません。
- `403 Forbidden`: ユーザーは管理者ではありません。
- `404 Not Found`: トークンが見つかりませんでした。
- `422 Unprocessable`: トークンタイプはサポートされていません。

リクエスト例:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

レスポンス例:

```json
{
 "id": 1,
 "user_id": 70,
 "name": "project-access-token",
 "revoked": false,
 "expires_at": "2024-10-04",
 "created_at": "2024-09-04T07:19:18.652Z",
 "updated_at": "2024-09-04T07:19:18.652Z",
 "scopes": [
  "api",
  "read_api"
 ],
 "impersonation": false,
 "expire_notification_delivered": false,
 "last_used_at": null,
 "after_expiry_notification_delivered": false,
 "previous_personal_access_token_id": null,
 "advanced_scopes": null,
 "organization_id": 1
}
```

## トークンを失効させる {#revoke-a-token}

{{< history >}}

- [クラスターエージェントトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178211)されました（GitLab 17.9）。
- [Runner認証トークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179066)されました（GitLab 17.9）。
- [OAuthアプリケーションシークレットが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179035)されました（GitLab 17.9）。
- [受信メールトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180763)されました（GitLab 17.9）。
- [機能フラグクライアントトークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181096)されました（GitLab 17.9）。
- [パイプライントリガートークンが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181598)されました（GitLab 17.10、`token_api_expire_pipeline_triggers`という名前の[フラグ付き](../../administration/feature_flags/_index.md)）。デフォルトでは無効になっています。
- [GitLabセッションが追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184047)されました（GitLab 17.11）。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

トークンのタイプに基づいて、特定のトークンを失効、リセット、または削除します。このエンドポイントは、次のトークンタイプをサポートしています:

| トークンの種類                                                                                   | サポートされているアクション   |
|----------------------------------------------------------------------------------------------|--------------------|
| [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)                       | 失効             |
| [代理トークン](../../user/profile/personal_access_tokens.md)                         | 失効             |
| [プロジェクトアクセストークン](../../security/tokens/_index.md#project-access-tokens)               | 失効             |
| [グループアクセストークン](../../security/tokens/_index.md#group-access-tokens)                   | 失効             |
| [デプロイトークン](../../user/project/deploy_tokens/_index.md)                                   | 失効             |
| [クラスターエージェントトークン](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)          | 失効             |
| [パイプライントリガートークン](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)       | 失効             |
| [フィードトークン](../../security/tokens/_index.md#feed-token)                                    | リセット              |
| [Runner認証トークン](../../security/tokens/_index.md#runner-authentication-tokens) | リセット              |
| [OAuthアプリケーションシークレット](../../integration/oauth_provider.md)                             | リセット              |
| [受信メールトークン](../../security/tokens/_index.md#incoming-email-token)                | リセット              |
| [機能フラグクライアントトークン](../../operations/feature_flags.md#get-access-credentials)      | リセット              |
| [GitLabセッションクッキー](../../user/profile/active_sessions.md)                              | 削除             |

```plaintext
DELETE /api/v4/admin/token
```

サポートされている属性は以下のとおりです:

| 属性    | 型    | 必須 | 説明              |
|--------------|---------|----------|--------------------------|
| `token`      | 文字列  | はい      | 失効する既存のトークン。`Personal`、`project`、または`group access`トークンは、`glpat`または現在の[カスタムプレフィックス](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)で始まる必要があります。 |

成功した場合、コンテンツなしで[`204`](../rest/troubleshooting.md#status-codes)を返します。

次のステータスコードを返すことができます:

- `204 No content`: トークンは失効されました。
- `401 Unauthorized`: ユーザーは認証されていません。
- `403 Forbidden`: ユーザーは管理者ではありません。
- `404 Not Found`: トークンが見つかりませんでした。
- `422 Unprocessable`: トークンタイプはサポートされていません。

リクエスト例:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```
