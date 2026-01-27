---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AWS統合を使用して、Self-Managedインスタンス上のGitLab Duo with Amazon Qをセットアップおよび管理します。
title: GitLab Duo with Amazon Qをセットアップする
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo with Amazon Q
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [実験](../../policy/development_stages_support.md#experiment)として、GitLab 17.7で[フラグ付き](../../administration/feature_flags/_index.md)で導入されました。名前は`amazon_q_integration`です。デフォルトでは無効になっています。
- 機能フラグ`amazon_q_integration`は、GitLab 17.8で削除されました。
- GitLab 17.11で一般提供。

{{< /history >}}

> [!note] GitLab Duo with Amazon Qは、他のGitLab Duoアドオンと組み合わせることはできません。

GitLab Duo with Amazon Qのサブスクリプションを取得するには、アカウントエグゼクティブにお問い合わせください。

トライアルをリクエストするには、[このフォームにご記入ください](https://about.gitlab.com/partners/technology-partners/aws/#form)。

Self-Managedインスタンス上のGitLab Duo with Amazon Qをセットアップするには、次の手順を実行します。

## GitLab Duo with Amazon Qをセットアップする {#set-up-gitlab-duo-with-amazon-q}

GitLab Duo with Amazon Qをセットアップするには、以下を実行する必要があります:

- [前提条件を完了する](#prerequisites)
- [Amazon Q Developerコンソールでプロファイルを作成する](#create-a-profile-in-the-amazon-q-developer-console)
- [IDプロバイダーを作成する](#create-an-iam-identity-provider)
- [IAMロールを作成する](#create-an-iam-role)
- [ロールを編集する](#edit-the-role)
- [GitLabにARNを入力してAmazon Qを有効にする](#enter-the-arn-in-gitlab-and-enable-amazon-q)
- [管理者が顧客管理キーを使用できるようにする](#allow-administrators-to-use-customer-managed-keys)

### 前提条件 {#prerequisites}

- GitLab Self-Managedが必要です:
  - GitLab 17.11以降。
  - Amazon Qは、リクエストされたアクションを実行するときにGitLabインスタンスのREST APIを使用してデータを読み取りおよび書き込み、HTTPS URLにアクセスできる必要があります（[SSL証明書は自己署名でない必要があります](https://docs.gitlab.com/omnibus/settings/ssl/)）。
  - インスタンスは、インスタンスが使用するように構成されているポートでTCP/TLSを使用して、次のIPアドレスから発信されるAmazon Qサービスからの受信ネットワークアクセスを許可する必要があります。これは、[デフォルトでポート443](../../administration/package_information/defaults.md#ports)です。
    - `34.228.181.128`
    - `44.219.176.187`
    - `54.226.244.221`
  - GitLabと同期されたUltimateプランのサブスクリプション、およびGitLab Duo with Amazon Qアドオン。

### Amazon Q Developerコンソールでプロファイルを作成する {#create-a-profile-in-the-amazon-q-developer-console}

Amazon Q Developerプロファイルを作成します。

1. [Amazon Q Developerコンソール](https://us-east-1.console.aws.amazon.com/amazonq/developer/home#/gitlab)を開きます。
1. **Amazon Q Developer in GitLab**を選択します。
1. **Get Started**を選択します。
1. **プロファイル名**には、リージョンの一意なプロファイル名を入力します。たとえば`QDevProfile-us-east-1`などです。
1. オプション。**Profile description - optional**には、説明を入力します。
1. **Create**を選択します。

### IAMIDプロバイダーを作成する {#create-an-iam-identity-provider}

次に、IAMIDプロバイダーを作成します。

まず、GitLabからいくつかの値が必要です:

前提条件: 

- 管理者である必要があります。

1. GitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. ステップ1で、プロバイダーURLとオーディエンスをコピーします。次のステップで必要になります。

次に、AWS IDプロバイダーを作成します:

1. [AWS IAMコンソール](https://console.aws.amazon.com/iam)にサインインします。
1. **Access Management** > **Identity providers**を選択します。
1. **Add provider**を選択します。
1. **プロバイダータイプ**で、**OpenID Connect**を選択します。
1. **プロバイダーURL**には、GitLabの値を入力します。
1. **オーディエンス**には、GitLabの値を入力します。
1. **Add provider**を選択します。

### IAMロールを作成する {#create-an-iam-role}

次に、IAMIDプロバイダーを信頼し、Amazon QにアクセスできるIAMロールを作成する必要があります。

> [!note]IAMロールを設定した後、ロールに関連付けられているAWSアカウントを変更することはできません。

1. AWS IAMコンソールで、**Access Management** > **ロール** > **ロールを作成する**を選択します。
1. **Web identity**を選択します。
1. **Web identity**には、以前に入力したプロバイダーURLを選択します。
1. **オーディエンス**には、以前に入力したオーディエンス値を選択します。
1. **Next**を選択します。
1. **Add permissions**ページで:
   - 管理ポリシーを使用するには、**Permissions policies**で、`GitLabDuoWithAmazonQPermissionsPolicy`を検索して選択します。
   - インラインポリシーを作成するには、**Permissions policies**をスキップして**次へ**を選択します。ポリシーは後で作成します。
1. **Next**を選択します。
1. ロールに名前を付けます（例：`QDeveloperAccess`）。
1. 信頼ポリシーが正しいことを確認します。次のように表示されます:

   ```json
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Principal": {
                "Federated": "arn:aws:iam::<AWS_Account_ID>:oidc-provider/auth.token.gitlab.com/cc/oidc/<Instance_ID>"
            },
            "Condition": {
                "StringEquals": {
                    "auth.token.gitlab.com/cc/oidc/<Instance_ID>:aud": "gitlab-cc-<Instance_ID>"
                },

            }
         }
      ]
   }
   ```

1. **Create role**を選択します。

### インラインポリシーの作成（オプション） {#create-an-inline-policy-optional}

管理ポリシーを使用するのではなく、インラインポリシーを作成するには:

1. **権限** > **Add permissions** > **Create inline policy**を選択します。
1. **JSON**を選択し、エディタに以下を貼り付けます:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDuoUsagePermissions",
         "Effect": "Allow",
         "Action": [
           "q:SendEvent",
           "q:CreateAuthGrant",
           "q:UpdateAuthGrant",
           "q:GenerateCodeRecommendations",
           "q:SendMessage",
           "q:ListPlugins",
           "q:VerifyOAuthAppConnection"
         ],
         "Resource": "*"
       },
       {
         "Sid": "GitLabDuoManagementPermissions",
         "Effect": "Allow",
         "Action": [
           "q:CreateOAuthAppConnection",
           "q:DeleteOAuthAppConnection"
         ],
         "Resource": "*"
       },
       {
         "Sid": "GitLabDuoPluginPermissions",
         "Effect": "Allow",
         "Action": [
           "q:CreatePlugin",
           "q:DeletePlugin",
           "q:GetPlugin"
         ],
         "Resource": "arn:aws:qdeveloper:*:*:plugin/GitLabDuoWithAmazonQ/*"
       }
     ]
   }
   ```

1. **アクション** > **Optimize for readability**を選択して、AWS形式にし、JSONを解析します。
1. **Next**を選択します。
1. ポリシーに`gitlab-duo-amazon-q-policy`という名前を付けて、**ポリシーの作成**を選択します。

### ロールの編集 {#edit-the-role}

次に、ロールを編集します:

1. 作成したロールを見つけて選択します。
1. セッション時間を12時間に変更します。セッションが12時間以上に設定されていない場合、`AssumeRoleWithWebIdentity`はAIゲートウェイで失敗します。

   1. **Roles search**フィールドに、IAMロールの名前を入力し、ロール名を選択します。
   1. **サマリー**で、**編集**を選択してセッション時間を編集します。
   1. **Maximum session duration**ドロップダウンリストを選択し、**12 hours**を選択します。
   1. **変更を保存**を選択します。

1. ページにリストされているARNをコピーします。次のように表示されます:

   ```plaintext
   arn:aws:iam::123456789:role/QDeveloperAccess
   ```

### GitLabにARNを入力してAmazon Qを有効にする {#enter-the-arn-in-gitlab-and-enable-amazon-q}

次に、ARNをGitLabに入力し、どのグループとプロジェクトが機能にアクセスできるかを決定します。

前提条件: 

- GitLab管理者である必要があります。

GitLab Duo with Amazon Qの設定を完了するには:

1. GitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. **IAMロールのARN**で、ARNを貼り付けます。
1. どのグループとプロジェクトがGitLab Duo with Amazon Qを使用できるかを決定するには、オプションを選択します:
   - インスタンスに対してオンにするが、グループとプロジェクトでオフにできるようにするには、**デフォルトで有効にする**を選択します。
     - オプション。Amazon Qがマージリクエストで自動的にレビューできるように構成するには、**マージリクエストにあるコードをAmazon Qで自動的にレビューする**を選択します。
   - インスタンスに対してオフにするが、グループとプロジェクトでオンにできるようにするには、**デフォルトで無効にする**を選択します。
   - インスタンスに対してオフにし、グループまたはプロジェクトがオンにできないようにするには、**常にオフ**を選択します。

1. **変更を保存**を選択します。

保存すると、APIはAIゲートウェイに接続して、Amazon QでOAuthアプリケーションを作成します。

成功したことを確認するには:

- Amazon CloudWatchコンソールログで、`204`ステータスコードを確認します。詳細については、[Amazon CloudWatchとは](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)を参照してください。
- GitLabでは、`Amazon Q settings have been saved`と表示される通知が表示されます。
- GitLabで、左側のサイドバーで**アプリケーション**を選択します。Amazon Q OAuthアプリケーションが表示されます。

## 管理者が顧客管理キーを使用できるようにする {#allow-administrators-to-use-customer-managed-keys}

管理者の場合は、AWS Key Management Service（AWS KMS）のカスタマーマネージドキー（CMK）を使用して顧客データを暗号化できます。

KMSコンソールでキーポリシーを作成するときにCMKを使用する権限を付与するようにロールポリシーを更新します。

`kms:ViaService`条件キーは、指定されたAWSサービスからのリクエストに対してKMSキーの使用を制限します。さらに、特定のサービスからリクエストが送信された場合にKMSキーの使用権限を拒否するためにも使用されます。条件キーを使用すると、コンテンツを暗号化または復号化するためにCMKを使用できるユーザーを制限できます。

```json
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Sid": "Sid0",
         "Effect": "Allow",
         "Principal": {
            "AWS": "arn:aws:iam::<awsAccountId>:role/<rolename>"
         },
         "Action": [
            "kms:Decrypt",
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:GenerateDataKey",
            "kms:GenerateDataKeyWithoutPlaintext",
            "kms:ReEncryptFrom",
            "kms:ReEncryptTo"
         ],
         "Resource": "*",
         "Condition": {
            "StringEquals": {
                "kms:ViaService": [
                    "q.<region>.amazonaws.com"
                ]
            }
        }
      }
   ]
}
```

詳細については、[AWS KMS開発者ガイドの`kms:ViaService`](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service)を参照してください。

## -hosted AIゲートウェイを使用するようにGitLabを構成する {#configure-gitlab-to-use-aws-hosted-ai-gateway}

AWSでホストされているAIゲートウェイを使用するようにGitLabを構成できます。

1. [Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。たとえば、Linuxパッケージを使用するインストールの場合、次を実行します:

   ```shell
   sudo gitlab-rails console
   ```

1.現在割り当てられているサービスURLを表示するには、次を実行します:

   ```ruby
   Ai::Setting.instance.ai_gateway_url
   ```

1. サービスURLを更新するには、次を実行します:

   ```ruby
   Ai::Setting.instance.update!(ai_gateway_url: "https://cloud.gitlab.com/aws/ai")
   ```

## GitLab Duo with Amazon Qをオフにする {#turn-off-gitlab-duo-with-amazon-q}

インスタンス、グループ、またはプロジェクトのGitLab Duo with Amazon Qをオフにすることができます。

### インスタンスをオフにする {#turn-off-for-the-instance}

前提条件: 

- 管理者である必要があります。

インスタンスのGitLab Duo with Amazon Qをオフにするには:

1. GitLabにサインインします。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. **常にオフ**を選択します。
1. **変更を保存**を選択します。

### グループをオフにする {#turn-off-for-a-group}

前提条件: 

- グループのオーナーロールが必要です。

グループのGitLab Duo with Amazon Qをオフにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **Amazon Q**を展開します。
1. 次のオプションを選択します。
   - グループに対してオフにするが、他のグループまたはプロジェクトでオンにできるようにするには、**デフォルトで無効にする**を選択します。
   - グループに対してオフにし、他のグループまたはプロジェクトでオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

### プロジェクトをオフにする {#turn-off-for-a-project}

前提条件: 

- プロジェクトのオーナーロールを持っている必要があります。

プロジェクトのGitLab Duo with Amazon Qをオフにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **表示レベル、プロジェクトの機能、権限**を展開します。
1. **Amazon Q**で、切替をオフにします。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

GitLabからAmazon Qへの接続で問題が発生した場合は、GitLabインストールが[すべての前提条件](#prerequisites)を満たしていることを確認してください。

次の問題が発生する可能性もあります。

### GitLabインスタンスUUIDの不一致 {#gitlab-instance-uuid-mismatch}

Amazon Qの接続を解除するときに、`GitLab instance UUID mismatch`エラーが発生する可能性があります。通常、この問題は次の場合に発生します:

- GitLabインスタンスがバックアップから復元されました。
- GitLabインスタンスが新しいインフラストラクチャに移行されました。
- GitLabインスタンスUUIDが他の理由で変更されました。

UUIDの不一致が根本原因であることを確認するには、次の検証手順に進みます。

#### 検証 {#validate}

1. GitLabがホストされているEC2インスタンスにサインインします。
1. Railsコンソールにアクセスします。
1. 現在のUUIDを取得します：`Gitlab::CurrentSettings.current_application_settings.uuid`
1. JWTトークンを取得します:

   ```ruby
   token = CloudConnector::Tokens.get(unit_primitive: :agent_quick_actions, resource: :instance)
   JWT.decode(token, false, nil)
   ```

ステップ3の`sub`フィールドとステップ4の`gitlab_instance_uuid`の間にUUIDの不一致が存在する場合、問題は明らかです。

この問題を解決するには、次の手順を実行します。

1. すべてのアクティブなライセンスを削除します。
1. すべてのサブスクリプションアドオン購入を削除します:

   Railsコンソールを開き、次を実行します:

   ```ruby
   GitlabSubscriptions::AddOnPurchase.all.destroy_all
   ```

1. インスタンスUUIDリセットを実行します。Railsコンソールで、次を実行します:

   ```ruby
   ApplicationSetting.update!(uuid: SecureRandom.uuid)
   ```

1. アクティブなライセンスを適用します。
1. 1分ほど待って、ライセンスを同期します。このアクションにより、Cloud Connectorトークンが強制的に再生成されます。(このステップがないと、ヘッダーの不一致が発生します。)
1. 新しいUUIDでIdPとIAMロールを更新します。
1. 次のステップを選択します:
   - 新しいUUIDで既存のIdPとIAMロールを更新し、GitLab Duo with Amazon Qを引き続き使用して、既存の設定を引き続き使用します。
   - オフボード:
     1. GitLab Duo with Amazon Qからオフボードします。
     1. 必要に応じて、新しい接続をセットアップします。

完了すると、UUIDの不一致の問題が解決され、GitLab Duo with Amazon Qは新しい構成で適切に機能するはずです。
