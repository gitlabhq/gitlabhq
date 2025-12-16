---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: CI/CDジョブトークンなど、CI/CD変数を使用してコンテナレジストリで認証する方法について説明します。
title: コンテナレジストリを使用して認証する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナレジストリを使用して認証するには、以下を使用できます:

- GitLabのユーザー名とパスワード（2FAが有効な場合は使用できません）
- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [デプロイトークン](../../project/deploy_tokens/_index.md)
- [プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)
- [グループアクセストークン](../../group/settings/group_access_tokens.md)
- [GitLab CLI](../../../editor_extensions/gitlab_cli/_index.md#use-the-cli-as-a-docker-credential-helper)。

トークンベースの認証方式に必要な最小限のスコープ:

- 読み取り（プル）アクセスの場合、`read_registry`である必要があります
- 書き込み（プッシュ）アクセスの場合、`write_registry`および`read_registry`である必要があります

{{< alert type="note" >}}

コンテナレジストリで認証する際には、管理者モードは適用されません。管理者モードが有効になっている管理者が、`admin_mode`スコープなしでパーソナルアクセストークンを作成した場合、管理者モードが有効になっていても、そのトークンは機能します。詳細については、[管理者モード](../../../administration/settings/sign_in_restrictions.md#admin-mode)を参照してください。

{{< /alert >}}

## ユーザー名とパスワードで認証する {#authenticate-with-username-and-password}

GitLabのユーザー名とパスワードを使用して、コンテナレジストリで認証できます:

```shell
docker login registry.example.com -u <username> -p <password>
```

セキュリティ上の理由から、`-p`の代わりに`--password-stdin`フラグを使用することをお勧めします:

```shell
echo "<password>" | docker login registry.example.com -u <username> --password-stdin
```

{{< alert type="warning" >}} 2要素認証（2FA）が有効になっている場合、ユーザー名とパスワードによる認証は使用できません。この場合、トークンベースの認証方法を使用する必要があります。{{< /alert >}}

## トークンで認証する {#authenticate-with-a-token}

トークンで認証するには、`docker login`コマンドを実行します:

```shell
TOKEN=<token>
echo "$TOKEN" | docker login registry.example.com -u <username> --password-stdin
```

認証後、クライアントは認証情報をキャッシュします。以降の操作では、指定された操作の実行だけが承認された、JWTトークンを返す認証リクエストを行います。トークンは引き続き有効です:

- GitLab Self-Managedでは[デフォルトで5分](../../../administration/packages/container_registry.md#increase-token-duration)
- GitLab.comでは[15分](../../gitlab_com/_index.md#container-registry)

## GitLab CI/CDを使用して認証する {#use-gitlab-cicd-to-authenticate}

CI/CDを使用してコンテナレジストリで認証する場合、以下を使用できます:

- `CI_REGISTRY_USER` CI/CD変数。

  この変数は、コンテナレジストリへの読み取り/書き込みアクセス権があるジョブごとのユーザーを保持します。そのパスワードも自動的に作成され、`CI_REGISTRY_PASSWORD`で使用できます。

  ```shell
  echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

- [CIジョブトークン](../../../ci/jobs/ci_job_token.md)。

  このトークンは、読み取り（プル）アクセスのみに使用できます。`read_registry`スコープがありますが、プッシュ操作に必要な`write_registry`スコープはありません。

  ```shell
  echo "$CI_JOB_TOKEN" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

  `gitlab-ci-token`スキームを使用することもできます:

  ```shell
  echo "$CI_JOB_TOKEN" | docker login $CI_REGISTRY -u gitlab-ci-token --password-stdin
  ```

- 最小スコープを持つ[GitLabデプロイトークン](../../project/deploy_tokens/_index.md#gitlab-deploy-token):
  - 読み取り（プル）アクセスの場合、`read_registry`。
  - 書き込み（プッシュ）アクセスの場合、`read_registry`および`write_registry`。

  ```shell
  echo "$CI_DEPLOY_PASSWORD" | docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin
  ```

- 最小スコープを持つパーソナルアクセストークン:
  - 読み取り（プル）アクセスの場合、`read_registry`。
  - 書き込み（プッシュ）アクセスの場合、`read_registry`および`write_registry`。

  ```shell
  echo "<access_token>" | docker login $CI_REGISTRY -u <username> --password-stdin
  ```

## トラブルシューティング {#troubleshooting}

### `docker login`コマンドが`access forbidden`で失敗する {#docker-login-command-fails-with-access-forbidden}

コンテナレジストリは、認証情報を検証するために、GitLab API URLをDockerクライアントに返します。Dockerクライアントは基本認証を使用するので、リクエストには`Authorization`ヘッダーが含まれています。レジストリ設定の`token_realm`で設定された`/jwt/auth`エンドポイントへのリクエストで`Authorization`ヘッダーが見つからない場合、`access forbidden`エラーメッセージが表示されます。

例: 

```plaintext
> docker login gitlab.example.com:4567

Username: user
Password:
Error response from daemon: Get "https://gitlab.company.com:4567/v2/": denied: access forbidden
```

このエラーを回避するには、`Authorization`ヘッダーがリクエストから削除されないようにしてください。たとえば、GitLabの前にあるプロキシが`/jwt/auth`エンドポイントにリダイレクトされている可能性があります。

Dockerクライアントでの認証情報の検証の詳細については、[コンテナレジストリアーキテクチャ](../../../administration/packages/container_registry.md#container-registry-architecture)を参照してください。

### 大きなイメージをプッシュしている場合の`unauthorized: authentication required` {#unauthorized-authentication-required-when-pushing-large-images}

大きなイメージをプッシュすると、次のような認証エラーが発生する可能性があります:

```shell
docker push gitlab.example.com/myproject/docs:latest
The push refers to a repository [gitlab.example.com/myproject/docs]
630816f32edb: Preparing
530d5553aec8: Preparing
...
4b0bab9ff599: Waiting
d1c800db26c7: Waiting
42755cf4ee95: Waiting
unauthorized: authentication required
```

このエラーは、イメージのプッシュが完了する前に認証トークンが期限切れになった場合に発生します。デフォルトでは、GitLab Self-Managedインスタンスのコンテナレジストリのトークンが期限切れになるのは5分後です。GitLab.comでのトークンの有効期限は15分です。
