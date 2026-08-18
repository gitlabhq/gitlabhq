---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: シークレットマネージャーAPI
description: GitLab Secrets Manager用の短期アクセストークンを発行するREST API。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/594090)され、`secrets_manager_api_access`という名前の[フラグ](../administration/feature_flags/_index.md)が設定されています。デフォルトでは無効になっています。

{{< /history >}}

このAPIを使用して、非CI/CDのワークロードから[GitLab Secrets Manager](../ci/secrets/secrets_manager/_index.md)のシークレットにアクセスします。

このAPIは、プロジェクトまたはグループ向けに短期間有効なJSON Webトークン（JWT）を生成します。クライアントはこのトークンをOpenBaoバックエンドに提示し、GitLab RunnerがCI/CDジョブ中にシークレットを読み取るのと同様に、シークレットを直接読み取ります。レスポンスには、クライアントが必要とするOpenBaoの接続詳細が含まれます。

このAPIは、パーソナルアクセストークン、プロジェクトまたはグループアクセストークン、あるいは`api`スコープを持つサービスアカウントのトークンで呼び出します。APIが返すトークンは、GitLabのアクセストークンではなく、別途生成される短期間有効なOpenBao JWTです。これは5分後に期限切れとなります。シークレットの値を読み取るには、そのシークレットに対する読み取り値の権限がプリンシパルに必要です。

返された接続詳細を使用してシークレットを読み取るには、[非CI/CDのワークロードからシークレットにアクセス](../ci/secrets/secrets_manager/non_cicd_access.md)を参照してください。

## プロジェクトのシークレットマネージャーアクセストークンを作成する {#create-a-secrets-manager-access-token-for-a-project}

プロジェクトのシークレットを読み取るためのアクセストークンを生成します。

```plaintext
POST /projects/:id/secrets_manager/access_token
```

サポートされている属性は以下のとおりです: 

| 属性 | タイプ              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secrets_manager/access_token"
```

レスポンス例: 

```json
{
  "expires_at": "2026-05-27T10:35:00Z",
  "provider": {
    "vault": {
      "server": "https://secrets.gitlab.com",
      "namespace": "org_5/group_42/project_99",
      "path": "secrets/kv",
      "version": "v2",
      "secrets_path": "explicit",
      "auth": {
        "jwt": {
          "path": "api_jwt/cel",
          "role": "all_api",
          "token": "<JWT>"
        }
      }
    }
  }
}
```

レスポンス属性:

| 属性 | タイプ | 説明 |
|-----------|------|-------------|
| `expires_at` | 文字列 | トークンの有効期限が切れるISO 8601タイムスタンプ。トークンは5分間有効です。 |
| `provider.vault.server` | 文字列 | 接続するOpenBaoサーバーのURL。GitLab.comでは、これは`https://secrets.gitlab.com`です。GitLab Self-Managedでは、インスタンス用に設定されたOpenBao URLです。 |
| `provider.vault.namespace` | 文字列 | プロジェクトのシークレットを保持するOpenBaoネームスペース。それを`X-Vault-Namespace`ヘッダーとして渡します。 |
| `provider.vault.path` | 文字列 | KVシークレットエンジンのマウントパス。 |
| `provider.vault.version` | 文字列 | KVシークレットエンジンのバージョン。 |
| `provider.vault.secrets_path` | 文字列 | シークレットが保存されているKVエンジンのベースパス。シークレット名の前に付加して、読み取りパスを構築します（`<path>/data/<secrets_path>/<secret_name>`）。 |
| `provider.vault.auth.jwt.path` | 文字列 | JWT認証メソッドのマウントパス。`auth/<path>/login`で認証します。 |
| `provider.vault.auth.jwt.role` | 文字列 | ログインに使用するJWT認証ロール。 |
| `provider.vault.auth.jwt.token` | 文字列 | クライアントがOpenBaoに提示する短期間有効なJWT。 |

## グループのシークレットマネージャーアクセストークンを作成する {#create-a-secrets-manager-access-token-for-a-group}

グループのシークレットを読み取るためのアクセストークンを生成します。

```plaintext
POST /groups/:id/secrets_manager/access_token
```

サポートされている属性は以下のとおりです: 

| 属性 | タイプ              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/secrets_manager/access_token"
```

レスポンス例: 

```json
{
  "expires_at": "2026-05-27T10:35:00Z",
  "provider": {
    "vault": {
      "server": "https://secrets.gitlab.com",
      "namespace": "org_5/group_42/group_99",
      "path": "secrets/kv",
      "version": "v2",
      "secrets_path": "explicit",
      "auth": {
        "jwt": {
          "path": "api_jwt/cel",
          "role": "all_api",
          "token": "<JWT>"
        }
      }
    }
  }
}
```

応答の属性は、[プロジェクトのシークレットマネージャーアクセストークンを作成する](#create-a-secrets-manager-access-token-for-a-project)の場合と同じですが、`provider.vault.namespace`はグループにスコープ指定されています。
