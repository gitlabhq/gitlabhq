---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "OAuth 2.0、アクセスジョブトークンを使用してGitLab REST APIで認証します。"
title: REST API認証
---

ほとんどのAPIリクエストは認証を必要としますが、認証が提供されていない場合は公開データのみを返します。認証が不要な場合、各エンドポイントのドキュメントにその旨が明記されています。たとえば、[`/projects/:id`エンドポイント](../projects.md#get-a-single-project)は認証を必要としません。

GitLab REST APIでは、いくつかの方法で認証を行うことができます:

- [OAuth 2.0トークン](#oauth-20-tokens)
- [パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)
- [プロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)
- [グループアクセストークン](../../user/group/settings/group_access_tokens.md)
- [セッションCookie](#session-cookie)
- [GitLab CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)**（特定のエンドポイントのみ）**

プロジェクトアクセストークンは次の製品でサポートされています:

- GitLab Self-Managed: Free、Premium、Ultimate。
- GitLab.com: Premium、Ultimate。

管理者の場合、管理者または管理者のアプリケーションは、以下のいずれかを使用して、特定のユーザーとして認証できます:

- [代理トークン](#impersonation-tokens)
- [Sudo](#sudo)

認証情報が無効であるか、欠落している場合、GitLabはステータスコード`401`のエラーメッセージを返します:

```json
{
  "message": "401 Unauthorized"
}
```

{{< alert type="note" >}}

デプロイトークンは、GitLabパブリックAPIでは使用できません。詳細については、[デプロイトークン](../../user/project/deploy_tokens/_index.md)を参照してください。

{{< /alert >}}

## OAuth 2.0トークン {#oauth-20-tokens}

[OAuth 2.0トークン](../oauth2.md)を使用して、`access_token`パラメータまたは`Authorization`ヘッダーのいずれかでトークンを渡すことにより、APIで認証できます。

パラメータでOAuth 2.0トークンを使用する例:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

ヘッダーでOAuth 2.0トークンを使用する例:

```shell
curl --request GET \
  --header "Authorization: Bearer OAUTH-TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects"
```

詳細については、[OAuth 2.0プロバイダーとしてのGitLab](../oauth2.md)を参照してください。

{{< alert type="note" >}}

すべてのOAuthアクセストークンは、作成された後、2時間有効です。`refresh_token`パラメータを使用して、トークンを更新できます。更新トークンを使用して新しいアクセストークンをリクエストする方法については、[OAuth 2.0トークン](../oauth2.md)のドキュメントを参照してください。

{{< /alert >}}

## パーソナル/プロジェクト/グループアクセストークン {#personalprojectgroup-access-tokens}

アクセストークンを使用して、`private_token`パラメータまたは`PRIVATE-TOKEN`ヘッダーのいずれかでトークンを渡すことにより、APIで認証できます。

パラメータでパーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを使用する例:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects?private_token=<your_access_token>"
```

ヘッダーでパーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを使用する例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

OAuth準拠のヘッダーでパーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを使用することもできます:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

## ジョブトークン {#job-tokens}

ジョブトークンを使用して、`job_token`パラメータまたは`JOB-TOKEN`ヘッダーでトークンを渡すことにより、[特定のAPIエンドポイント](../../ci/jobs/ci_job_token.md)で認証できます。GitLab CI/CDジョブでトークンを渡すには、`CI_JOB_TOKEN`変数を使用します。

パラメータでジョブトークンを使用する例:

```shell
curl --request GET \
  --location --output artifacts.zip \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"
```

ヘッダーでジョブトークンを使用する例:

```shell
curl --request GET \
  --header "JOB-TOKEN:$CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects/1/releases"
```

## セッションCookie {#session-cookie}

メインのGitLabアプリケーションにサインインすると、`_gitlab_session` Cookieが設定されます。このCookieが存在する場合、APIはそれを使用して認証します。APIを使用して新しいセッションCookieを生成することはサポートされていません。

この認証方法の主なユーザーは、GitLab自体のWebフロントエンドです。Webフロントエンドは認証済みユーザーとしてAPIを使用して、アクセストークンを明示的に渡すことなく、プロジェクトのリストを取得できます。

## 代理トークン {#impersonation-tokens}

代理トークンは、[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)の一種です。代理トークンは管理者のみが作成でき、特定のユーザーとしてAPIで認証するために使用されます。

以下の代替手段として、代理トークンを使用します:

- ユーザーのパスワード、またはパーソナルアクセストークンの1つ。
- [Sudo](#sudo)機能。ユーザーや管理者のパスワードまたはトークンが不明な場合もあれば、時間の経過とともに変更される場合もあります。

詳細については、[ユーザートークンAPI](../user_tokens.md#create-an-impersonation-token)のドキュメントを参照してください。

代理トークンは、通常のパーソナルアクセストークンとまったく同じように使用され、`private_token`パラメータまたは`PRIVATE-TOKEN`ヘッダーのいずれかで渡すことができます。

### 代理を無効にする {#disable-impersonation}

デフォルトでは、代理は有効になっています。代理を無効にするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`ファイルを編集します:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. ファイルを保存してから、変更を有効にするためにGitLabを[再設定](../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`ファイルを編集します:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. ファイルを保存してから、変更を有効にするためにGitLabを[再起動](../../administration/restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

代理を再度有効にするには、この設定を削除して、GitLabを再設定するか（Linuxパッケージのインストール）、GitLabを再起動します（自己コンパイルのインストール）。

## Sudo {#sudo}

すべてのAPIリクエストは、`sudo`スコープを持つOAuthトークンまたはパーソナルアクセストークンでユーザーが管理者として認証されていることを条件として、その管理者が別のユーザーであるかのようにAPIリクエストを実行することをサポートしています。APIリクエストは、代理ユーザーの権限で実行されます。

[管理者](../../user/permissions.md)として、操作が実行されるユーザーのIDまたはユーザー名（大文字と小文字を区別しない）を使用して、クエリ文字列またはヘッダーのいずれかで`sudo`パラメータを渡します。ヘッダーとして渡す場合、ヘッダー名は`Sudo`である必要があります。

管理者権限のないアクセストークンが指定された場合、GitLabはステータスコード`403`のエラーメッセージを返します:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

`sudo`スコープのないアクセストークンが指定された場合、ステータスコード`403`のエラーメッセージが返されます:

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

sudoユーザーIDまたはユーザー名が見つからない場合は、ステータスコード`404`のエラーメッセージが返されます:

```json
{
  "message": "404 User with ID or username '123' Not Found"
}
```

有効なAPIリクエストと、ユーザー名を指定してsudoリクエストでcURLを使用するリクエストの例:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=username
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: username" \
  --url "https://gitlab.example.com/api/v4/projects"
```

有効なAPIリクエストと、IDを指定してsudoリクエストでcURLを使用するリクエストの例:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: 23" \
  --url "https://gitlab.example.com/api/v4/projects"
```
