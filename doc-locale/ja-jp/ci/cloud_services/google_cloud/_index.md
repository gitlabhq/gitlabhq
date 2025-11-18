---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GCPワークロードアイデンティティフェデレーションでOpenID Connectを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT_V2`は[GitLab 15.9で非推奨](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)となり、GitLab 17.0で削除される予定です。代わりに[IDトークン](../../secrets/id_token_authentication.md)を使用してください。

{{< /alert >}}

このチュートリアルでは、JSON Webトークン（JWT）トークンとワークロードアイデンティティフェデレーションを使用して、GitLab CI/CDジョブからGoogle Cloudへの認証を実演します。この設定では、シークレットを保存する必要なく、オンデマンドの有効期間の短い認証情報を生成します。

まず、GitLabとGoogle Cloud間のアイデンティティプロバイダーフェデレーション用にOpenID Connect（OIDC）を設定します。GitLabでOIDCを使用する方法の詳細については、[クラウドサービスへの接続](../_index.md)をお読みください。

このチュートリアルでは、Google CloudアカウントとGoogle Cloudプロジェクトがあることを前提としています。お使いのアカウントには、Google Cloudプロジェクトに対する少なくとも**workload identity pool Admin**（ワークロードアイデンティティプロバイダープール管理者）権限が必要です。

{{< alert type="note" >}}

このチュートリアルの代わりにTerraformモジュールとCI/CDテンプレートを使用する場合は、[OIDCでGoogle CloudとのGitLab CI/CDパイプラインの認証をどのように簡素化できるか](https://about.gitlab.com/blog/2023/06/28/introduction-of-oidc-modules-for-integration-between-google-cloud-and-gitlab-ci/)を参照してください。

{{< /alert >}}

このチュートリアルを完了するには、以下を行います:

1. [Google Cloudワークロードアイデンティティフェデレーションプールを作成します](#create-the-google-cloud-workload-identity-pool)。
1. [ワークロードIDアイデンティティプロバイダーを作成する](#create-a-workload-identity-provider)。
1. [サービスアカウント代理の権限を付与する](#grant-permissions-for-service-account-impersonation)。
1. [一時的な認証情報を取得する](#retrieve-a-temporary-credential)。

## Google Cloudワークロードアイデンティティフェデレーションプールを作成する {#create-the-google-cloud-workload-identity-pool}

次のオプションを使用して、[新しいGoogle Cloudワークロードアイデンティティフェデレーションプールを作成する](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider):

- **名前**: `GitLab`などの、ワークロードIDプールのわかりやすい名前。
- **プールID**: `gitlab`などの、ワークロードIDプールのGoogle Cloudプロジェクト内の一意のID。この値は、プールを参照するために使用され、URLに表示されます。
- **説明**: オプション。プールの説明。
- **Enabled Pool**（有効なプール）: このオプションが`true`であることを確認してください。

Google CloudプロジェクトごとにGitLabインスタンスごとに単一のプールを作成することをお勧めします。同じGitLabインスタンス上に複数のGitLabリポジトリとCI/CDジョブがある場合、同じプールに対して異なるアイデンティティプロバイダーを使用して認証できます。

## ワークロードIDアイデンティティプロバイダーを作成する {#create-a-workload-identity-provider}

次のオプションを使用して、前の手順で作成したワークロードIDプール内に[新しいGoogle Cloudワークロードアイデンティティフェデレーションアイデンティティプロバイダーを作成する](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider):

- **プロバイダータイプ**: OpenID Connect（OIDC）。
- **Provider name**（プロバイダー名）: `gitlab/gitlab`などの、ワークロードIDアイデンティティプロバイダーのわかりやすい名前。
- **プロバイダーID**: `gitlab-gitlab`などの、ワークロードIDアイデンティティプロバイダーのプール内の一意のID。この値は、アイデンティティプロバイダーを参照するために使用され、URLに表示されます。
- **Issuer (URL)**（発行者（URL））: `https://gitlab.com/`や`https://gitlab.example.com/`など、GitLabインスタンスのアドレス。
  - アドレスは`https://`プロトコルを使用する必要があります。
  - アドレスは末尾のスラッシュで終わる必要があります。
- **Audiences**（対象者）: `https://gitlab.com`や`https://gitlab.example.com`など、許可された対象者リストをご自身のGitLabインスタンスのアドレスに手動で設定します。
  - アドレスは`https://`プロトコルを使用する必要があります。
  - アドレスは末尾のスラッシュで終わらないようにする必要があります。
- **Provider attributes mapping**（プロバイダー属性マッピング）: 次のマッピングを作成します。`attribute.X`はGoogleトークン内のクレームとして含める属性の名前で、`assertion.X`は[GitLab claim](../_index.md#id-token-authentication-for-cloud-services)から抽出する値です:

  | 属性（Google上） | アサーション（GitLabから） |
  | --- | --- |
  | `google.subject` | `assertion.sub` |
  | `attribute.X` | `assertion.X` |

  Common Expression言語（CEL）を使用して、[複雑な属性をビルドする](https://cloud.google.com/iam/docs/workload-identity-federation#mapping)こともできます。

  権限の付与に使用するすべての属性をマップする必要があります。たとえば、次の手順でユーザーのメールアドレスに基づいて権限をマップする場合は、`attribute.user_email`を`assertion.user_email`にマップする必要があります。

{{< alert type="warning" >}}

GitLab.comでホストされているプロジェクトの場合、GCPでは、[GitLabグループによって発行されたトークンのみにアクセスを制限する](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2)必要があります。

{{< /alert >}}

## サービスアカウント代理の権限を付与する {#grant-permissions-for-service-account-impersonation}

ワークロードIDプールとワークロードIDアイデンティティプロバイダーを作成すると、Google Cloudへの認証が定義されます。この時点で、GitLab CI/CDジョブからGoogle Cloudへの認証が可能です。ただし、Google Cloud（認可）に対する権限はありません。

Google Cloudに対するGitLab CI/CDジョブの権限を付与するには、次の手順を実行する必要があります:

1. [Google Cloudサービスアカウントを作成する](https://cloud.google.com/iam/docs/service-accounts-create)。任意の名前とIDを使用できます。
1. Google Cloudリソース上のサービスアカウントに[IAM権限を付与する](https://cloud.google.com/iam/docs/granting-changing-revoking-access)。これらの権限は、ユースケースによって大きく異なります。一般に、このサービスアカウントに、GitLab CI/CDジョブで使用できるようにするGoogle Cloudプロジェクトとリソースに対する権限を付与します。たとえば、GitLab CI/CDジョブでファイルをGoogle Cloud Storageバケットにアップロードする必要がある場合は、このサービスアカウントにGoogle Cloud Storageバケットに対する`roles/storage.objectCreator`ロールを付与します。
1. [外部アイデンティティプロバイダーにそのサービスアカウントを代理する権限を付与する](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#impersonate)。この手順により、サービスアカウント代理を介して、GitLab CI/CDジョブがGoogle Cloudへの認可を有効にできます。この手順では、サービスアカウント自体に対するIAM権限が付与され、そのサービスアカウントとして機能する外部アイデンティティプロバイダーに権限が付与されます。外部アイデンティティプロバイダーは、`principalSet://`プロトコルを使用して表現されます。

前の手順と同様に、この手順は目的の設定に大きく依存します。たとえば、GitLab CI/CDジョブがユーザー名`chris`のGitLabユーザーによって開始された場合、GitLab CI/CDジョブが`my-service-account`という名前のサービスアカウントを代理できるようにするには、`my-service-account`の外部アイデンティティプロバイダーに`roles/iam.workloadIdentityUser` IAMロールを付与します。外部アイデンティティプロバイダーは、次の形式を取ります:

```plaintext
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.user_login/chris
```

ここで、`PROJECT_NUMBER`はGoogle Cloudプロジェクト番号、`POOL_ID`は最初のセクションで作成されたワークロードIDプールのID（名前ではない）です。

この設定では、前のセクションのアサーションからマップされた属性として`user_login`を追加したことも前提としています。

## 一時的な認証情報を取得する {#retrieve-a-temporary-credential}

OpenID Connectとロールを設定すると、GitLab CI/CDジョブは、[Google Cloud Security Token Service（STS）](https://cloud.google.com/iam/docs/reference/sts/rest)から一時的な認証情報を取得できます。

`id_tokens`をCI/CDジョブに追加します:

```yaml
job:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
```

IDトークンを使用して、一時的な認証情報を取得します:

```shell
PAYLOAD="$(cat <<EOF
{
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "grantType": "urn:ietf:params:oauth:grant-type:token-exchange",
  "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token",
  "scope": "https://www.googleapis.com/auth/cloud-platform",
  "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt",
  "subjectToken": "${GITLAB_OIDC_TOKEN}"
}
EOF
)"
```

```shell
FEDERATED_TOKEN="$(curl --fail "https://sts.googleapis.com/v1/token" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data "${PAYLOAD}" \
  | jq -r '.access_token'
)"
```

各設定項目の意味は次のとおりです:

- `PROJECT_NUMBER`はGoogle Cloudプロジェクト番号（名前ではない）です。
- `POOL_ID`は、最初のセクションで作成されたワークロードIDプールのIDです。
- `PROVIDER_ID`は、2番目のセクションで作成されたワークロードIDアイデンティティプロバイダーのIDです。
- `GITLAB_OIDC_TOKEN`はOpenID Connect [IDトークン](../../secrets/id_token_authentication.md)です。

次に、結果として得られたフェデレーショントークンを使用して、前のセクションで作成したサービスアカウントを代理できます:

```shell
ACCESS_TOKEN="$(curl --fail "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SERVICE_ACCOUNT_EMAIL:generateAccessToken" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer FEDERATED_TOKEN" \
  --data '{"scope": ["https://www.googleapis.com/auth/cloud-platform"]}' \
  | jq -r '.accessToken'
)"
```

各設定項目の意味は次のとおりです:

- `SERVICE_ACCOUNT_EMAIL`は、前のセクションで作成された代理するサービスアカウントの完全なメールアドレスです。
- `FEDERATED_TOKEN`は、前の手順で取得したフェデレーショントークンです。

結果はGoogle Cloud OAuth 2.0アクセストークンになり、ベアラトークンとして使用すると、ほとんどのGoogle Cloud APIとサービスへの認証に使用できます。この値を環境変数`CLOUDSDK_AUTH_ACCESS_TOKEN`を設定して、`gcloud` CLIに渡すこともできます。

## 動作例 {#working-example}

Terraformを使用してGCPでOpenID Connectをプロビジョニングし、一時的な認証情報を取得するサンプルスクリプトについては、この[参照プロジェクト](https://gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp)を確認してください。

## トラブルシューティング {#troubleshooting}

- `curl`応答をデバッグする場合は、最新バージョンのcURLをインストールします。`-f`の代わりに`--fail-with-body`を使用してください。このコマンドは本文全体を出力します。これには役立つエラーメッセージが含まれている場合があります。

- 詳細については、[ワークロードIDフェデレーションの問題を解決する](https://cloud.google.com/iam/docs/troubleshooting-workload-identity-federation)を参照してください。
