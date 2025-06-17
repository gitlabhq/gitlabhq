---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 一時的な認証情報を取得するために、AWS で OpenID Connect をConfigureします
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

`CI_JOB_JWT_V2` は[GitLab 15.9 で非推奨](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)となり、GitLab 17.0 で削除される予定です。代わりに[ID トークン](../../yaml/_index.md#id_tokens)を使用してください。

{{< /alert >}}

このチュートリアルでは、シークレットを保存しなくても、JSON Web トークン（JWT）を使用して GitLab CI/CD ジョブから AWS から一時的な認証情報を取得する方法について説明します。これを行うには、GitLab と AWS 間の ID フェデレーション用に OpenID Connect（OIDC）をConfigureする必要があります。OIDC を使用した GitLab の統合の背景と要件については、[クラウドサービスへの接続](../_index.md)を参照してください。

このチュートリアルを完了するには:

1. [identity providerを追加](#add-the-identity-provider)
1. [ロールと信頼をConfigure](#configure-a-role-and-trust)
1. [一時的な認証情報を取得](#retrieve-temporary-credentials)

## identity providerを追加

これらの[手順](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)に従って、AWS で GitLab を IAM OIDC プロバイダーとして作成します。

次の情報を含めます:

- **プロバイダーの URL**:`https://gitlab.com` や `http://gitlab.example.com` などの GitLab インスタンスのアドレス。このアドレスは、パブリックにアクセスできる必要があります。
- **オーディエンス**:`https://gitlab.com` や `http://gitlab.example.com` などの GitLab インスタンスのアドレス。
  - アドレスには、`https://` を含める必要があります。
  - 末尾にスラッシュを含めないでください。

## ロールと信頼をConfigure

Identity Providerを作成したら、GitLab リソースへのアクセスを制限するための条件を使用して、[ウェブIDロール](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)をConfigureします。一時的な認証情報は[AWS Security トークンサービス](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)を使用して取得されるため、`Action` を [sts:AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html) に設定します。

ロールの[カスタム信頼ポリシー](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html)を作成して、特定のグループ、プロジェクト、ブランチ、またはtagへの認証を制限できます。サポートされているフィルタリングタイプの完全なリストについては、[クラウドサービスへの接続](../_index.md#configure-a-conditional-role-with-oidc-claims)を参照してください。

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

ロールの作成後、AWS サービス（S3、EC2、シークレットマネージャー）への権限を定義するポリシーを添付します。

## 一時的な認証情報を取得

OIDC とロールをConfigureすると、GitLab CI/CD ジョブは[AWS Security トークンサービス（STS）](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)から一時的な認証情報を取得できます。

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

- `ROLE_ARN`:この[ステップ](#configure-a-role-and-trust)で定義されたロール ARN。
- `GITLAB_OIDC_TOKEN`:OIDC [ID トークン](../../yaml/_index.md#id_tokens)。

## 動作例

- Terraform を使用して AWS で OIDC をプロビジョニングし、一時的な認証情報を取得するためのサンプルスクリプトについては、この[参照プロジェクト](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws)を参照してください。
- [GitLab と ECS を使用した OIDC およびマルチアカウントデプロイ](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs)。
- AWS パートナー（APN）ブログ:[GitLab CI/CD で OpenID Connect を設定](https://aws.amazon.com/blogs/apn/setting-up-openid-connect-with-gitlab-ci-cd-to-provide-secure-access-to-environments-in-aws-accounts/)。
- [AWS re:Inforce 2023 での GitLab:OpenID と JWT](https://www.youtube.com/watch?v=xWQGADDVn8g) で AWS へのSecureな GitLab CD パイプライン。

## トラブルシューティング

### エラー: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

このエラーが表示された場合:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

複数の理由で発生する可能性があります:

- クラウド管理者が、GitLab で OIDC を使用するようにプロジェクトをConfigureしていません。
- ロールは、ブランチまたはtagで実行できないように制限されています。[条件付きロールのConfigure](../_index.md)を参照してください。
- ワイルドカード条件を使用する場合、`StringLike` の代わりに `StringEquals` が使用されます。[関連するイシュー](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934)を参照してください。

### `Could not connect to openid configuration of provider` エラー

AWS IAM に Identity Providerを追加した後、次のエラーが表示されることがあります:

```plaintext
Your request has a problem. Please see the following details.
  - Could not connect to openid configuration of provider: `https://gitlab.example.com`
```

このエラーは、OIDC Identity Providerの発行者が、順序が正しくない証明書チェーンを提示するか、重複または追加の証明書が含まれている場合に発生します。

GitLab インスタンスの証明書チェーンを検証します。チェーンは、ドメインまたは発行者の URL で始まり、次いで中間証明書、最後にルート証明書で終わる必要があります。このコマンドを使用して証明書チェーンをレビューし、`gitlab.example.com` を GitLab ホスト名に置き換えます:

```shell
echo | /opt/gitlab/embedded/bin/openssl s_client -connect gitlab.example.com:443
```

### `Couldn't retrieve verification key from your identity provider` エラー

次のようなエラーが表示される場合があります:

- `An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Couldn't retrieve verification key from your identity provider, please reference AssumeRoleWithWebIdentity documentation for requirements`

このエラーの原因として考えられるのは:

- Identity Provider（IdP）の `.well_known` URL と `jwks_uri` がパブリックインターネットからアクセスできない。
- カスタムファイアウォールがリクエストをブロックしている。
- IdP から AWS STS エンドポイントに到達する APIリクエストで、5 秒を超えるレイテンシーが発生している。
- STS が、IdP の `.well_known` URL または `jwks_uri` に過剰なリクエストを送信している。

[このエラーに関する AWS ナレッジセンターのドキュメント](https://repost.aws/knowledge-center/iam-sts-invalididentitytoken)に記載されているように、`.well_known` URL と `jwks_uri` を解決できるように、GitLab インスタンスがパブリックにアクセスできる必要があります。たとえば、GitLab インスタンスがオフライン環境にある場合など、これが不可能な場合は、[イシュー #391928](https://gitlab.com/gitlab-org/gitlab/-/issues/391928)に従って、回避策とより恒久的な解決策が検討されています。
