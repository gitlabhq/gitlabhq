---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AWSインテグレーションを使用して、Self-ManagedインスタンスでGitLab Duo with Amazon Qを設定および管理します。
title: GitLab Duo with Amazon Qを設定する
---

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo with Amazon Q
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.7で`amazon_q_integration`という[フラグ](../../administration/feature_flags/_index.md)とともに[実験](../../policy/development_stages_support.md#experiment)として導入されました。デフォルトでは無効になっています。
- 機能フラグ`amazon_q_integration`は、GitLab 17.8で削除されました。
- 一般提供は、GitLab 17.11で一般提供となりました。

{{< /history >}}

{{< alert type="note" >}}

GitLab Duo with Amazon Qは、他のGitLab Duoアドオンと組み合わせることはできません。

{{< /alert >}}

GitLab Duo with Amazon Qのサブスクリプションを取得するには、アカウントエグゼクティブにお問い合わせください。

トライアルをリクエストするには、[このフォームに記入してください](https://about.gitlab.com/partners/technology-partners/aws/#form)。

Self-Managedインスタンス上のGitLab Duo with Amazon Qを設定するには、次の手順を実行します。

## GitLab Duo with Amazon Qをセットアップする {#set-up-gitlab-duo-with-amazon-q}

GitLab Duo with Amazon Qを設定するには、以下を行う必要があります:

- [前提条件を満たす](#prerequisites)
- [Amazon Q Developerコンソールでプロファイルを作成する](#create-a-profile-in-the-amazon-q-developer-console)
- [Identity Providerを作成する](#create-an-iam-identity-provider)
- [IAMロール](#create-an-iam-role)を作成する
- [ロールを編集する](#edit-the-role)
- [GitLabでARNを入力してAmazon Qを有効にする](#enter-the-arn-in-gitlab-and-enable-amazon-q)
- [管理者が顧客管理キーを使用できるようにする](#allow-administrators-to-use-customer-managed-keys)

### 前提要件 {#prerequisites}

- GitLab Self-Managedインスタンスが必要です:
  - GitLab 17.11以降。
  - Amazon Qは、リクエストされたアクションを実行する際に、GitLabインスタンスのREST APIを使用してデータを読み取りおよび書き込みを行い、HTTPS URLにアクセスできる必要があります（[SSL証明書は自己署名でない必要があります](https://docs.gitlab.com/omnibus/settings/ssl/)）。
  - インスタンスは、インスタンスが使用するように設定されているポートでTCP/TLSを使用して、次のIPアドレスから発信されるAmazon Qサービスからの受信ネットワークアクセスを許可する必要があります。これは[デフォルトでポート443](../../administration/package_information/defaults.md#ports)です。
    - `34.228.181.128`
    - `44.219.176.187`
    - `54.226.244.221`
  - GitLabと同期されたUltimateサブスクリプションと、GitLab Duo with Amazon Qアドオンが必要です。

### Amazon Q Developerコンソールでプロファイルを作成する {#create-a-profile-in-the-amazon-q-developer-console}

Amazon Q Developerプロファイルを作成します。

1. [Amazon Q Developerコンソール](https://us-east-1.console.aws.amazon.com/amazonq/developer/home#/gitlab)を開きます。
1. **Amazon Q Developer in GitLab**（GitLabのAmazon Q Developer）を選択します。
1. **Get Started**（開始）を選択します。
1. **プロファイル名**に、リージョンの一意のプロファイル名を入力します。たとえば`QDevProfile-us-east-1`などです。
1. オプション。**Profile description - optional**（プロファイルの説明（オプション））に、説明を入力します。
1. **作成**を選択します。

### IAM Identity Providerを作成する {#create-an-iam-identity-provider}

次に、IAM Identity Providerを作成します。

まず、GitLabからいくつかの値が必要です:

前提要件: 

- 管理者である必要があります。

1. GitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. 手順1で、プロバイダーURLとオーディエンスをコピーします。これらは次の手順で必要になります。

次に、AWS Identity Providerを作成します:

1. [AWS IAMコンソール](https://console.aws.amazon.com/iam)にサインインします。
1. **Access Management** > **Identity providers**を選択します。
1. **Add provider**（プロバイダーの追加）を選択します。
1. **プロバイダータイプ**で、**OpenID Connect**を選択します。
1. **プロバイダーURL**に、GitLabからの値を入力します。
1. **オーディエンス**に、GitLabからの値を入力します。
1. **Add provider**（プロバイダーの追加）を選択します。

### IAMロールを作成する {#create-an-iam-role}

次に、IAM Identity Providerを信頼し、Amazon QにアクセスできるIAMロールを作成する必要があります。

{{< alert type="note" >}}

IAMロールを設定した後、ロールに関連付けられているAWSアカウントを変更することはできません。

{{< /alert >}}

1. AWS IAMコンソールで、**Access Management** > **ロール** > **ロールを作成する**を選択します。
1. **Web identity**（ウェブアイデンティティ）を選択します。
1. **Web identity**（ウェブアイデンティティ）で、以前に入力したプロバイダーURLを選択します。
1. **オーディエンス**で、以前に入力したオーディエンス値を選択します。
1. **次へ**を選択します。
1. **Add permissions**（権限の追加）ページで、以下を実行します:
   - 管理されたポリシーを使用するには、**Permissions policies**（許可ポリシー）で検索して`GitLabDuoWithAmazonQPermissionsPolicy`を選択します。
   - インラインポリシーを作成するには、**Permissions policies**（許可ポリシー）をスキップして、**次へ**を選択します。ポリシーは後で作成します。
1. **次へ**を選択します。
1. たとえば、`QDeveloperAccess`のようにロールに名前を付けます。
1. 信頼ポリシーが正しいことを確認してください。次のようになります:

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

1. **ロールを作成する**を選択します。

### インラインポリシーを作成する（オプション） {#create-an-inline-policy-optional}

管理されたポリシーを使用するのではなく、インラインポリシーを作成するには、次の手順を実行します:

1. **権限** > **Add permissions**（権限の追加） > **Create inline policy**（インラインポリシーの作成）を選択します。
1. **JSON**を選択し、エディターに以下を貼り付けます:

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

1. **アクション** > **Optimize for readability**（可読性のために最適化）を選択して、AWS形式を作成し、JSONを解析します。
1. **次へ**を選択します。
1. ポリシーに`gitlab-duo-amazon-q-policy`という名前を付けて、**ポリシーの作成**を選択します。

### ロールを編集する {#edit-the-role}

次に、ロールを編集します:

1. 作成したロールを見つけて選択します。
1. セッション時間を12時間に変更します。セッションが12時間以上に設定されていない場合、`AssumeRoleWithWebIdentity`はAIゲートウェイで失敗します。

   1. **Roles search**（ロールの検索）フィールドに、IAMロールの名前を入力し、ロール名を選択します。
   1. **サマリー**で、**編集**を選択して、セッション時間を編集します。
   1. **Maximum session duration**（最大セッション時間）ドロップダウンリストを選択し、**12 hours**（12時間）を選択します。
   1. **変更を保存**を選択します。

1. ページに表示されているARNをコピーします。次のようになります:

   ```plaintext
   arn:aws:iam::123456789:role/QDeveloperAccess
   ```

### GitLabでARNを入力してAmazon Qを有効にする {#enter-the-arn-in-gitlab-and-enable-amazon-q}

次に、ARNをGitLabに入力し、どのグループとプロジェクトが機能にアクセスできるかを決定します。

前提要件: 

- GitLab管理者である必要があります。

GitLab Duo with Amazon Qの設定を完了するには、以下を実行します:

1. GitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. **IAMロールのARN**で、ARNを貼り付けます。
1. どのグループとプロジェクトがGitLab Duo with Amazon Qを使用できるかを決定するには、オプションを選択します:
   - インスタンスに対してオンにし、グループとプロジェクトでオフにできるようにするには、**デフォルトで有効にする**を選択します。
     - オプション。Amazon Qがマージリクエストでコードを自動的にレビューするように設定するには、**マージリクエストにあるコードをAmazon Qで自動的にレビューする**を選択します。
   - インスタンスに対してオフに設定しても、グループやプロジェクトでオンにできるようにするには、**デフォルトで無効にする**を選択します。
   - インスタンスに対してオフにし、グループやプロジェクトでオンにできないようにするには、**常にオフ**を選択します。

1. **変更を保存**を選択します。

変更を保存すると、APIがAIゲートウェイに接続し、Amazon QでOAuthアプリケーションを作成します。

成功したことを確認するには、次のようにします:

- Amazon CloudWatchコンソールのログで、`204`ステータスコードを確認します。詳しくは、[Amazon CloudWatchとは](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)をご覧ください。
- GitLabで、`Amazon Q settings have been saved`という通知が表示されます。
- GitLabの左側のサイドバーで、**アプリケーション**を選択します。Amazon Q OAuthアプリケーションが表示されます。

## 管理者が顧客管理キーを使用できるようにする {#allow-administrators-to-use-customer-managed-keys}

管理者の場合は、AWS Key Management Service（AWS KMS）のカスタマーマネージドキー（CMK）を使用して顧客データを暗号化できます。

KMSコンソールで設定されたロールにキーポリシーを作成するときに、CMKを使用する権限を付与するようにロールポリシーを更新します。

`kms:ViaService`条件キーは、指定されたAWSサービスからのリクエストに対するKMSキーの使用を制限します。さらに、特定のサービスからのリクエストの場合にKMSキーの使用を許可しないために使用されます。条件キーを使用すると、CMKを使用してコンテンツを暗号化されたり、復号化したりできるユーザーを制限できます。

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

詳しくは、[AWS KMS開発者ガイドの`kms:ViaService`](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service)をご覧ください。

## GitLab Duo with Amazon Qをオフにする {#turn-off-gitlab-duo-with-amazon-q}

インスタンス、グループ、またはプロジェクトのGitLab Duo with Amazon Qをオフにすることができます。

### インスタンスに対してオフにする {#turn-off-for-the-instance}

前提要件: 

- 管理者である必要があります。

インスタンスのGitLab Duo with Amazon Qをオフにするには、次のようにします:

1. GitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duo with Amazon Q**を展開します。
1. **設定の表示**を選択します。
1. **常にオフ**を選択します。
1. **変更を保存**を選択します。

### グループに対してオフにする {#turn-off-for-a-group}

前提要件: 

- グループのオーナーロールが必要です。

グループのGitLab Duo with Amazon Qをオフにするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **Amazon Q**を展開します。
1. 次のオプションを選択します:
   - グループに対してオフに設定しても、他のグループやプロジェクトでオンにできるようにするには、**デフォルトで無効にする**を選択します。
   - グループに対してオフにし、他のグループやプロジェクトでオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

### プロジェクトに対してオフにする {#turn-off-for-a-project}

前提要件: 

- プロジェクトのオーナーロールを持っている必要があります。

プロジェクトのGitLab Duo with Amazon Qをオフにするには、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **Amazon Q**で、トグルをオフにします。
1. **変更を保存**を選択します。

## トラブルシューティング {#troubleshooting}

GitLabをAmazon Qに接続する際に問題が発生した場合は、GitLabインストールが[すべての前提条件](#prerequisites)を満たしていることを確認してください。

次の問題が発生する可能性もあります。

### GitLabインスタンスUUIDの不一致 {#gitlab-instance-uuid-mismatch}

Amazon Qの接続を解除すると、`GitLab instance UUID mismatch`エラーが発生する可能性があります。通常、この問題は次の場合に発生します:

- GitLabインスタンスがバックアップから復元されました。
- GitLabインスタンスが新しいインフラストラクチャに移行されました。
- GitLabインスタンスのUUIDが他の理由で変更されました。

不一致のUUIDが根本原因であることを確認するには、次の検証手順に進みます。

#### 検証 {#validate}

1. GitLabがホストされているEC2インスタンスにサインインします。
1. Railsコンソールにアクセスします。
1. 現在のUUIDを取得する`Gitlab::CurrentSettings.current_application_settings.uuid`
1. JWTトークンを取得します:

   ```ruby
   token = CloudConnector::Tokens.get(unit_primitive: :agent_quick_actions, resource: :instance)
   JWT.decode(token, false, nil)
   ```

手順3の`sub`フィールドと手順4の`gitlab_instance_uuid`の間にUUIDの不一致が存在する場合、問題は明らかです。

この問題を解決するには、次の手順を実行します。

1. すべてのアクティブなライセンスを削除します。
1. すべてのサブスクリプションアドオンの購入を削除します:

   Railsコンソールを開き、以下を実行します:

   ```ruby
   GitlabSubscriptions::AddOnPurchase.all.destroy_all
   ```

1. インスタンスのUUIDリセットを実行します。Railsコンソールで、以下を実行します:

   ```ruby
   ApplicationSetting.update!(uuid: SecureRandom.uuid)
   ```

1. アクティブなライセンスを適用します。
1. 1分ほど待ってから、ライセンスを同期します。このアクションにより、Cloud Connectorトークンが強制的に再生成されます。（この手順を実行しないと、ヘッダーの不一致が発生します。）
1. 新しいUUIDでIdPとIAMロールを更新します。
1. 次のステップを選択します:
   - 新しいUUIDで既存のIdPとIAMロールを更新し、GitLab Duo with Amazon Qの使用を続行して、既存のセットアップを引き続き使用します。
   - オフボード:
     1. GitLab Duo with Amazon Qからオフボードします。
     1. 必要に応じて、新しい接続を設定します。

完了すると、UUIDの不一致の問題が解決され、GitLab Duo with Amazon Qが新しい設定で正しく機能するはずです。
