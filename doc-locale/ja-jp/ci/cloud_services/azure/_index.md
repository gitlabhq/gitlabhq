---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AzureでOpenID Connectを設定して一時的な認証情報を取得する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT_V2`は[GitLab 15.9で非推奨](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)となり、GitLab 17.0で削除される予定です。代わりに[IDトークン](../../secrets/id_token_authentication.md)を使用してください。

{{< /alert >}}

このチュートリアルでは、シークレットを保存する必要なく、GitLab CI/CDジョブでJSON Webトークン（JWT）を使用してAzureから一時的な認証情報を取得する方法を説明します。

まず、GitLabとAzure間のアイデンティティフェデレーションのためにOpenID Connect（OIDC）を設定します。GitLabでのOIDCの使用に関する詳細は、[クラウドサービスへの接続](../_index.md)をお読みください。

前提要件: 

- `Owner`アクセスレベルを持つ既存のAzureサブスクリプションへのアクセス。
- 少なくとも`Application Developer`アクセスレベルを持つ、対応するAzure Activeディレクトリテナントへのアクセス。
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)のローカルインストール。または、[Azure Cloud Shell](https://portal.azure.com/#cloudshell/)ですべての以下の手順を実行できます。
- AzureがGitLab OIDCエンドポイントに接続する必要があるため、GitLabインスタンスはインターネット上でパブリックにアクセス可能である必要があります。
- GitLabプロジェクト。

このチュートリアルを完了するには、以下を行います:

1. [Azure ADアプリケーションとサービスプリンシパルを作成](#create-azure-ad-application-and-service-principal)。
1. [Azure ADフェデレーションID認証情報を作成](#create-azure-ad-federated-identity-credentials)。
1. [サービスプリンシパルの権限を付与](#grant-permissions-for-the-service-principal)。
1. [一時的な認証情報を取得する](#retrieve-a-temporary-credential)。

Azureアイデンティティフェデレーションに関する詳細は、[ワークロードIDフェデレーション](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)をご覧ください。

## Azure ADアプリケーションとサービスプリンシパルを作成 {#create-azure-ad-application-and-service-principal}

[Azure ADアプリケーション](https://learn.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az-ad-app-create)とサービスプリンシパルを作成するには:

1. Azure CLIで、ADアプリケーションを作成します:

   ```shell
   appId=$(az ad app create --display-name gitlab-oidc --query appId -otsv)
   ```

   GitLab CI/CDパイプラインを構成するために後で必要になるため、`appId`（アプリケーションクライアントID）出力を保存します。

1. 対応する[サービスプリンシパル](https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create)を作成します:

   ```shell
   az ad sp create --id $appId --query appId -otsv
   ```

Azure CLIの代わりに、[Azure Portalを使用してこれらのリソースを作成する](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)こともできます。

## Azure ADフェデレーションID認証情報を作成 {#create-azure-ad-federated-identity-credentials}

特定のブランチの以前のAzure ADアプリケーションのフェデレーションID認証情報を作成するには、`<mygroup>/<myproject>`を実行します:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": "project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>",
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

`issuer`、`subject`、または`audiences`の値に関連するイシューについては、[トラブルシューティング](#troubleshooting)の詳細を参照してください。

オプションで、Azure ADアプリケーションとAzure ADフェデレーションID認証情報をAzure Portalから確認できるようになりました:

1. [Azure Active Directory App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)ビューを開き、表示名`gitlab-oidc`を検索して、適切なアプリ登録を選択します。
1. 概要ページで、`Application (client) ID`、`Object ID`、および`Tenant ID`などの詳細を確認できます。
1. `Certificates & secrets`で、`Federated credentials`に移動して、Azure ADフェデレーションID認証情報を確認します。

### 任意のブランチまたはタグの認証情報を作成 {#create-credentials-for-any-branch-or-any-tag}

任意のブランチまたはタグの認証情報（ワイルドカードマッチング）を作成するには、[flexible federated identity credentials](https://learn.microsoft.com/entra/workload-id/workload-identities-flexible-federated-identity-credentials)を使用できます。

`<mygroup>/<myproject>`のすべてのブランチ:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:branch:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

すべてのタグについて、`<mygroup>/<myproject>`を使用します:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:tag:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

## サービスプリンシパルの権限を付与 {#grant-permissions-for-the-service-principal}

認証情報を作成したら、[`role assignment`](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create)を使用して、以前のサービスプリンシパルに権限を付与し、Azureリソースへのアクセスを取得できるようにします:

```shell
az role assignment create --assignee $appId --role Reader --scope /subscriptions/<subscription-id>
```

あなたのサブスクリプションIDは以下にあります:

- [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription)。
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription)。

前のコマンドは、サブスクリプション全体への読み取り専用権限を付与します。組織のコンテキストで最小特権の原則を適用する方法の詳細については、[Azure ADロールのベストプラクティス](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices)をお読みください。

## 一時的な認証情報を取得する {#retrieve-a-temporary-credential}

Azure ADアプリケーションとフェデレーションID認証情報を構成した後、CI/CDジョブは[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login)を使用して一時的な認証情報を取得できます:

```yaml
default:
  image: mcr.microsoft.com/azure-cli:latest

variables:
  AZURE_CLIENT_ID: "<client-id>"
  AZURE_TENANT_ID: "<tenant-id>"

auth:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN
    - az account show
```

CI/CD変数は次のとおりです:

- `AZURE_CLIENT_ID`: 以前に保存した[アプリケーションクライアントID](#create-azure-ad-application-and-service-principal)。
- `AZURE_TENANT_ID`: Azure Active Directory。[Azure CLIまたはAzure Portalを使用して見つける](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant)ことができます。
- `GITLAB_OIDC_TOKEN`: OIDC [IDトークン](../../secrets/id_token_authentication.md)。

## トラブルシューティング {#troubleshooting}

### エラー: `No matching federated identity record found` {#error-no-matching-federated-identity-record-found}

エラー`ERROR: AADSTS70021: No matching federated identity record found for presented assertion.`が表示された場合は、以下を確認する必要があります:

- Azure ADフェデレーションID認証情報で定義された`Issuer`（たとえば、`https://gitlab.com`または独自のGitLab URL）。
- Azure ADフェデレーションID認証情報で定義された`Subject identifier`（たとえば、`project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>`）。
  - `gitlab-group/gitlab-project`プロジェクトと`main`ブランチの場合、`project_path:gitlab-group/gitlab-project:ref_type:branch:ref:main`になります。
  - `mygroup`と`myproject`の正しい値は、GitLabプロジェクトへのアクセス時にURLを確認するか、プロジェクトの概要ページの右上隅で**コード**を選択することで取得できます。
- Azure ADフェデレーションID認証情報で定義された`Audience`（たとえば、`https://gitlab.com`または独自のGitLab URL）。

Azure Portalから、これらの設定と、`AZURE_CLIENT_ID`および`AZURE_TENANT_ID` CI/CD変数を確認できます:

1. [Azure Active Directory App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)ビューを開き、表示名`gitlab-oidc`を検索して、適切なアプリ登録を選択します。
1. 概要ページで、`Application (client) ID`、`Object ID`、および`Tenant ID`などの詳細を確認できます。
1. `Certificates & secrets`で、`Federated credentials`に移動して、Azure ADフェデレーションID認証情報を確認します。

詳細については、[クラウドサービスへの接続](../_index.md)を確認してください。

### `Request to External OIDC endpoint failed`メッセージ {#request-to-external-oidc-endpoint-failed-message}

エラー`ERROR: AADSTS501661: Request to External OIDC endpoint failed.`が表示された場合は、GitLabインスタンスがインターネットからパブリックにアクセス可能であることを確認する必要があります。

Azureは、OIDCで認証するために、次のGitLabエンドポイントにアクセスできる必要があります:

- `GET /.well-known/openid-configuration`
- `GET /oauth/discovery/keys`

ファイアウォールを更新してもこのエラーが引き続き発生する場合は、[Redisキャッシュをクリア](../../../administration/raketasks/maintenance.md#clear-redis-cache)して、もう一度お試しください。

### `No matching federated identity record found for presented assertion audience`メッセージ {#no-matching-federated-identity-record-found-for-presented-assertion-audience-message}

エラー`ERROR: AADSTS700212: No matching federated identity record found for presented assertion audience 'https://gitlab.com'`が表示された場合は、CI/CDジョブが正しい`aud`値を使用していることを確認する必要があります。

`aud`値は、[フェデレーションID認証情報を作成](#create-azure-ad-federated-identity-credentials)するために使用されるオーディエンスと一致する必要があります。
