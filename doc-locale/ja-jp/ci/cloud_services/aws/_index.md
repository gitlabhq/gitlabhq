---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AWSでOpenID Connectを設定して一時的な認証情報を取得する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT_V2`は[GitLab 15.9で非推奨](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)となり、GitLab 17.0で削除される予定です。代わりに[IDトークン](../../yaml/_index.md#id_tokens)を使用してください。

{{< /alert >}}

このチュートリアルでは、JSON Webトークン（JWT）を使用してGitLab CI/CDジョブからAWSの一時的な認証情報を取得する方法について説明します。シークレットを保存する必要はありません。そのためには、GitLabとAWS間のID連携用にOpenID Connect（OIDC）を設定する必要があります。OIDCを使用したGitLabの統合の背景と要件については、[クラウドサービスに接続する](../_index.md)を参照してください。

このチュートリアルを完了するには、以下を行います。

1. [Identity Providerを追加する](#add-the-identity-provider)
1. [ロールと信頼を設定する](#configure-a-role-and-trust)
1. [一時的な認証情報を取得する](#retrieve-temporary-credentials)

## Identity Providerを追加する {#add-the-identity-provider}

これらの[手順](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)に従って、AWSでGitLabをIAM OIDCプロバイダーとして作成します。

次の情報を含めます。

- **Provider URL**（プロバイダーのURL): `https://gitlab.com`や`http://gitlab.example.com`など、GitLabインスタンスのアドレス。このアドレスは、パブリックアクセスが可能である必要があります。パブリックアクセスできない場合は、[非公開のGitLabインスタンスを設定する](#configure-a-non-public-gitlab-instance)方法をご確認ください。
- **Audience**（オーディエンス）: `https://gitlab.com`や`http://gitlab.example.com`など、GitLabインスタンスのアドレス。
  - アドレスには、`https://`を含める必要があります。
  - 末尾にスラッシュを含めないでください。

## ロールと信頼を設定する {#configure-a-role-and-trust}

Identity Providerを作成したら、GitLabリソースへのアクセスを制限するための条件を使用して、[Web IDロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)を設定します。一時的な認証情報は、[AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)を使用して取得されるため、`Action`を[sts:AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)に設定します。

特定のグループ、プロジェクト、ブランチ、またはタグへの認証を制限するために、ロール用の[カスタム信頼ポリシー](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html)を作成できます。サポートされているフィルタリングタイプの完全なリストについては、[クラウドサービスに接続する](../_index.md#configure-a-conditional-role-with-oidc-claims)を参照してください。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/gitlab.example.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.example.com:sub": "project_path:mygroup/myproject:ref_type:branch:ref:main"
        }
      }
    }
  ]
}
```

ロールの作成後、AWSサービス（S3、EC2、Secrets Manager）への権限を定義するポリシーをアタッチします。

## 一時的な認証情報を取得する {#retrieve-temporary-credentials}

OIDCとロールを設定すると、GitLab CI/CDジョブは、[AWS Security Token Service（STS）](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)から一時的な認証情報を取得できます。

```yaml
assume role:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
  script:
    # this is split out for correct exit code handling
    - >
      aws_sts_output=$(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token ${GITLAB_OIDC_TOKEN}
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text)
    - export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" $aws_sts_output)
    - aws sts get-caller-identity
```

- `ROLE_ARN`: この[ステップ](#configure-a-role-and-trust)で定義されたロールARN。
- `GITLAB_OIDC_TOKEN`: OIDC [IDトークン](../../yaml/_index.md#id_tokens)。

## 動作例 {#working-examples}

- Terraformとサンプルスクリプトを使用してAWSでOIDCをプロビジョニングし、一時的な認証情報を取得する方法については、この[参照プロジェクト](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws)を参照してください。
- [GitLabとECSを使用したOIDCとマルチアカウントデプロイ](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs)。
- AWSパートナー（APN）ブログ: [Setting up OpenID Connect with GitLab CI/CD](https://aws.amazon.com/blogs/apn/setting-up-openid-connect-with-gitlab-ci-cd-to-provide-secure-access-to-environments-in-aws-accounts/)（GitLab CI/CDでOpenID Connectを設定する）。
- [GitLab at AWS re:Inforce 2023: Secure GitLab CD pipelines to AWS w/ OpenID and JWT](https://www.youtube.com/watch?v=xWQGADDVn8g)（GitLab at AWS re:Inforce 2023: OpenID連携、OIDC、JWTを使用したAWSへの安全なGitLab CDパイプライン）

## 非公開のGitLabインスタンスを設定する {#configure-a-non-public-gitlab-instance}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391928)されました。

{{< /history >}}

{{< alert type="warning" >}}

この回避策は高度な設定オプションであり、セキュリティ上の考慮事項を理解する必要があります。プライベートなGitLab Self-Managedインスタンスから公開されている場所（S3バケットなど）に、OpenID設定と公開キーを正しく同期するように注意する必要があります。S3バケットとその中のファイルが適切に保護されていることを確認することも必要です。S3バケットを適切に保護できない場合、このOpenID Connect IDに関連付けられているクラウドアカウントが乗っ取られる可能性があります。

{{< /alert >}}

GitLabインスタンスにパブリックアクセスできない場合、デフォルトではAWSでOpenID Connectを設定することはできません。回避策を使用して、特定の設定にパブリックアクセスできるようにし、インスタンスのOpenID Connect設定を有効にすることができます。

1. GitLabインスタンスの認証情報を、公開されている場所（S3ファイルなど）に保存します。

   - S3ファイルでインスタンスのOpenID設定をホスティングします。この設定は`/.well-known/openid-configuration`で利用できます（`http://gitlab.example.com/.well-known/openid-configuration`など）。公開されている場所を指すように設定ファイル内の`issuer:`と`jwks_uri:`の値を更新します。
   - S3ファイルでインスタンスURLの公開キーをホスティングします。キーは`/oauth/discovery/keys`で利用できます（`http://gitlab.example.com/oauth/discovery/keys`など）。

   次に例を示します。

   - OpenID設定ファイル: `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/.well-known/openid-configuration`。
   - JWKS（JSON Web Key Sets）: `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/oauth/discovery/keys`。
   - IDトークンの発行者クレーム`iss:`とOpenID設定の`issuer:`値: `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`

1. （オプション）[OpenID Configuration Endpoint Validator](https://www.oauth2.dev/tools/openid-configuration-validator)などのOpenID設定バリデーターを使用して、公開されているOpenID設定を検証します。
1. IDトークンのカスタム発行者クレームを設定します。デフォルトでは、GitLab IDトークンの発行者クレーム`iss:`は、GitLabインスタンスのアドレスに設定されています（`http://gitlab.example.com`など）。

1. 発行者URLを更新します。

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   1. `/etc/gitlab/gitlab.rb`を編集します。

      ```ruby
      gitlab_rails['ci_id_tokens_issuer_url'] = 'public_url_with_openid_configuration_and_keys'
      ```

   1. ファイルを保存して、[GitLabを再設定](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

   {{< /tab >}}

   {{< tab title="Helmチャート（Kubernetes）" >}}

   1. Helmの値をエクスポートします。

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`を編集します。

      ```yaml
      global:
        appConfig:
          ciIdTokens:
            issuerUrl: 'public_url_with_openid_configuration_and_keys'
      ```

   1. ファイルを保存して、新しい値を適用します。

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   1. `docker-compose.yml`を編集します。

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['ci_id_tokens_issuer_url'] = 'public_url_with_openid_configuration_and_keys'
      ```

   1. ファイルを保存して、GitLabを再起動します。

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   1. `/home/git/gitlab/config/gitlab.yml`を編集します。

      ```yaml
       production: &base
         ci_id_tokens:
           issuer_url: 'public_url_with_openid_configuration_and_keys'
      ```

   1. ファイルを保存して、[GitLabを再設定](../../../administration/restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

   {{< /tab >}}

   {{< /tabs >}}

1. [`ci:validate_id_token_configuration` Rakeタスク](../../../administration/raketasks/tokens/_index.md#validate-custom-issuer-url-configuration-for-cicd-id-tokens)を実行して、CI/CD IDトークンの設定を検証します。

## トラブルシューティング {#troubleshooting}

### エラー: `Not authorized to perform sts:AssumeRoleWithWebIdentity` {#error-not-authorized-to-perform-stsassumerolewithwebidentity}

このエラーが表示された場合:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

このエラーは、次のような複数の理由で発生する可能性があります。

- クラウド管理者が、GitLabでOIDCを使用するようにプロジェクトを設定していない。
- ロールが、ブランチまたはタグでの実行を制限されている。[条件付きロールを設定する](../_index.md)を参照してください。
- ワイルドカード条件を使用する際に、`StringLike`の代わりに`StringEquals`が使用されている。[関連イシュー](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934)を参照してください。

### エラー: `Could not connect to openid configuration of provider` {#could-not-connect-to-openid-configuration-of-provider-error}

AWS IAMにIdentity Providerを追加した後、次のエラーが表示されることがあります。

```plaintext
Your request has a problem. Please see the following details.
  - Could not connect to openid configuration of provider: `https://gitlab.example.com`
```

このエラーは、OIDC Identity Providerの発行者が順序の間違った証明書チェーンを提示するか、重複や追加の証明書が含まれている場合に発生します。

GitLabインスタンスの証明書チェーンを検証します。チェーンは、ドメインまたは発行者のURLで始まり、中間証明書が続き、最後にルート証明書で終わる必要があります。このコマンドを使用して証明書チェーンを確認し、`gitlab.example.com`をGitLabホスト名に置き換えます。

```shell
echo | /opt/gitlab/embedded/bin/openssl s_client -connect gitlab.example.com:443
```

### エラー: `Couldn't retrieve verification key from your identity provider` {#couldnt-retrieve-verification-key-from-your-identity-provider-error}

次のようなエラーが表示される場合があります。

- `An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Couldn't retrieve verification key from your identity provider, please reference AssumeRoleWithWebIdentity documentation for requirements`

このエラーについては次のような原因が考えられます。

- パブリックインターネットからIdentity Provider（IdP）の`.well_known` URLと`jwks_uri`にアクセスできない。
- カスタムファイアウォールがリクエストをブロックしている。
- IdPからAWS STSエンドポイントに到達するAPIリクエストで、5秒を超えるレイテンシーが発生している。
- STSが、IdPの`.well_known` URLまたは`jwks_uri`に過剰なリクエストを送信している。

[このエラーに関するAWSナレッジセンターのドキュメント](https://repost.aws/knowledge-center/iam-sts-invalididentitytoken)に記載されているように、GitLabインスタンスをパブリックアクセス可能にして、`.well_known` URLと`jwks_uri`を解決できるようにする必要があります。パブリックアクセスできない場合（GitLabインスタンスがオフライン環境にある場合など）は、[非公開のGitLabインスタンスを設定する](#configure-a-non-public-gitlab-instance)方法をご確認ください。
