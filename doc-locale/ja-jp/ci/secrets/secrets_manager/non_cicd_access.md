---
stage: Security Platform
group: Secrets Manager Application
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD以外のワークロードからのシークレットへのアクセス
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/594090)され、`secrets_manager_api_access`という名前の[フラグ](../../../administration/feature_flags/_index.md)が設定されています。デフォルトでは無効になっています。

{{< /history >}}

CI/CDジョブは、GitLab Runnerを通じて[GitLab Secrets Manager](_index.md)シークレットを読み取ります。他のワークロードは、[Secrets Manager API](../../../api/secrets_manager.md)を通じてシークレットを読み取ります。例としては、KubernetesアプリケーションやInfrastructure as Codeツールなどがあります。

読み取りはOpenBaoバックエンドに直接行われるため、シークレットの可用性はGitLabアプリケーションに依存しません。

## アクセストークンフロー {#access-token-flow}

1. クライアントは、パーソナルアクセストークン、サービスアカウントトークン、または`api`スコープを持つプロジェクトもしくはグループアクセストークンを使用してGitLabを認証します。
1. クライアントはシークレットマネージャーAPIを呼び出して、短期間有効なアクセストークンを発行します。レスポンスには、トークンとOpenBaoの接続詳細が含まれます。
1. クライアントはOpenBaoバックエンドにトークンを提示して、シークレットの値を読み取ります。

アクセストークンは5分後に期限切れになります。OpenBaoはVault APIを実装しているため、任意の[HashiCorp Vault](https://developer.hashicorp.com/vault)互換クライアントでトークンを提示できます。

すべてのOpenBao接続詳細は発行応答から提供されるため、ネームスペース、マウント、または認証パスを自分で構築する必要はありません。

## 前提条件 {#prerequisites}

- プロジェクトまたはグループでシークレットマネージャーが有効になっています。
- パーソナルアクセストークン、プロジェクトまたはグループアクセストークン、または`api`スコープを持つサービスアカウントトークンを使用して認証します。
- 役割は少なくともレポーターです。
- シークレットの値を読み取るには、そのシークレットに対する読み取り値のアクセス許可が付与されます。レポーターの役割だけではシークレットの値を公開しません。

## シークレットを読み取る {#read-a-secret}

この例では、プロジェクトのアクセストークンを発行し、OpenBaoに認証した後、シークレットの値を読み取ります。

1. アクセストークンを発行します。認証に使用するトークンは、`api`スコープを持っている必要があります:

   ```shell
   RESPONSE=$(curl --silent --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/secrets_manager/access_token")
   ```

   レスポンスには、`provider.vault`オブジェクトと、`server`、`namespace`、`path`、`secrets_path`、および`auth.jwt`の詳細、さらに短期間有効な`token`が含まれています。

1. 返されたトークンを使用してOpenBaoに認証し、値を読み取ります:

   ```shell
   SERVER=$(echo "$RESPONSE" | jq --raw-output .provider.vault.server)
   NAMESPACE=$(echo "$RESPONSE" | jq --raw-output .provider.vault.namespace)
   MOUNT=$(echo "$RESPONSE" | jq --raw-output .provider.vault.path)
   SECRETS_PATH=$(echo "$RESPONSE" | jq --raw-output .provider.vault.secrets_path)
   AUTH_PATH=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.path)
   ROLE=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.role)
   JWT=$(echo "$RESPONSE" | jq --raw-output .provider.vault.auth.jwt.token)

   # Exchange the JWT for a short-lived OpenBao token.
   VAULT_TOKEN=$(curl --silent --request POST \
     --header "X-Vault-Namespace: $NAMESPACE" \
     --data "{\"role\":\"$ROLE\",\"jwt\":\"$JWT\"}" \
     "$SERVER/v1/auth/$AUTH_PATH/login" | jq --raw-output .auth.client_token)

   # Read the secret value.
   curl --silent \
     --header "X-Vault-Token: $VAULT_TOKEN" \
     --header "X-Vault-Namespace: $NAMESPACE" \
     "$SERVER/v1/$MOUNT/data/$SECRETS_PATH/<secret_name>"
   ```

GitLab.comでは、`server`が`https://secrets.gitlab.com`です。GitLab Self-Managedでは、`server`はインスタンス用に設定されたOpenBaoのURLです。

完全なリクエストとレスポンスの形式については、[Secrets Manager API](../../../api/secrets_manager.md)を参照してください。

## Vault CLIで使用する {#use-with-the-vault-cli}

OpenBaoはVault APIを実装しているため、レスポンスの値を[Vault CLI](https://developer.hashicorp.com/vault/docs/commands)で使用できます:

```shell
export VAULT_ADDR="<server>"
export VAULT_NAMESPACE="<namespace>"

# Exchange the minted JWT for an OpenBao token, then export it.
vault write "auth/<auth_jwt_path>/login" role=<role> jwt=<token>
export VAULT_TOKEN="<client_token>"

# Read the secret value.
vault kv get -mount=<path> "<secrets_path>/<secret_name>"
```

## External Secrets Operatorで使用する {#use-with-the-external-secrets-operator}

[External Secrets Operator](https://external-secrets.io)は、HashiCorp Vaultプロバイダーを介して、GitLabシークレットをKubernetes Secretsに同期します。クラスター内のワークロードは、新しいアクセストークンをKubernetesシークレットに保持し、オペレーターはそのトークンを読み取ってOpenBaoに認証します。

発行応答を`SecretStore`にマップし、各シークレットを`<secrets_path>/<secret_name>`で参照します:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: gitlab-secrets-manager
  namespace: my-app
spec:
  provider:
    vault:
      server: https://secrets.gitlab.com     # provider.vault.server
      path: secrets/kv                        # provider.vault.path
      version: v2
      namespace: org_5/group_42/project_99    # provider.vault.namespace
      auth:
        jwt:
          path: api_jwt/cel                   # provider.vault.auth.jwt.path
          role: all_api                       # provider.vault.auth.jwt.role
          secretRef:
            name: gitlab-access-token         # Kubernetes secret holding the minted token
            key: token
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: my-app
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: gitlab-secrets-manager
    kind: SecretStore
  target:
    name: synced-secret
  data:
    - secretKey: value
      remoteRef:
        key: explicit/<secret_name>           # <secrets_path>/<secret_name>
        property: value
```

アクセストークンは5分後に期限切れになるため、ワークロードは期限切れになる前に`gitlab-access-token` Kubernetesシークレットを更新する必要があります。

ネイティブなKubernetesインテグレーションは、[エピック20382](https://gitlab.com/groups/gitlab-org/-/epics/20382)で提案されています。

## Terraformで使用する {#use-with-terraform}

TerraformまたはOpenTofuの設定は、GitLabシークレットをデータソースとして読み取ることができます。Terraformはアクセストークン自体を発行できないため、[`external`データソース](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external)がシークレットマネージャーAPIを呼び出し、`provider.vault`接続詳細を返すスクリプトを実行します。[Vault](https://registry.terraform.io/providers/hashicorp/vault/latest/docs)プロバイダーは、発行されたJWTで認証し、シークレットを読み取ります。

このスクリプトはトークンを発行し、接続詳細をJSONとして出力します。これは`GITLAB_TOKEN`環境変数からGitLabトークンを読み取ります:

```shell
#!/usr/bin/env bash
# scripts/mint_token.sh
set -euo pipefail
eval "$(jq --raw-output '@sh "PROJECT_ID=\(.project_id)"')"

curl --silent --request POST \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --url "https://gitlab.example.com/api/v4/projects/${PROJECT_ID}/secrets_manager/access_token" \
  | jq '{
      server:       .provider.vault.server,
      namespace:    .provider.vault.namespace,
      mount:        .provider.vault.path,
      secrets_path: .provider.vault.secrets_path,
      auth_path:    .provider.vault.auth.jwt.path,
      role:         .provider.vault.auth.jwt.role,
      jwt:          .provider.vault.auth.jwt.token
    }'
```

`external`データソースからスクリプトを参照し、Vaultプロバイダーを設定してから、シークレットを読み取ります:

```hcl
data "external" "gitlab_secrets_token" {
  program = ["bash", "${path.module}/scripts/mint_token.sh"]

  query = {
    project_id = var.gitlab_project_id
  }
}

provider "vault" {
  address   = data.external.gitlab_secrets_token.result.server
  namespace = data.external.gitlab_secrets_token.result.namespace

  auth_login_jwt {
    mount = data.external.gitlab_secrets_token.result.auth_path
    role  = data.external.gitlab_secrets_token.result.role
    jwt   = data.external.gitlab_secrets_token.result.jwt
  }
}

data "vault_kv_secret_v2" "my_secret" {
  mount = data.external.gitlab_secrets_token.result.mount
  name  = "${data.external.gitlab_secrets_token.result.secrets_path}/<secret_name>"
}

output "secret_value" {
  value     = data.vault_kv_secret_v2.my_secret.data["value"]
  sensitive = true
}
```

発行されたトークンは5分間有効なため、`terraform apply`はその時間枠内で実行する必要があります。

ネイティブなGitLab Terraform Providerインテグレーションは、[エピック21177](https://gitlab.com/groups/gitlab-org/-/epics/21177)で提案されています。
