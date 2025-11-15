---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicatedの暗号化は、保存時データと転送時データをAWSテクノロジーで保護し、独自の暗号化キー（BYOK）を持ち込むことをサポートします。
title: GitLab Dedicatedの暗号化
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedは、AWSが提供する堅牢なセキュリティインフラストラクチャにより、データを保護するための安全な暗号化機能を提供します。データは、保存時と転送時の両方で暗号化されています。

## 暗号化された保存時データ {#encrypted-data-at-rest}

GitLab Dedicatedは、AWS AES-256（256ビットキーによる高度暗号化標準）を使用して、保存されているすべてのデータを暗号化します。この暗号化は、GitLab Dedicatedで使用されるすべてのAWSストレージサービスに適用されます。

| サービス | 暗号化の方法 |
|-------------|-------------------|
| Amazon S3（SSE-S3） | オブジェクトごとに独自のキーで暗号化され、そのキーがAWS管理のルートキーによって暗号化される、オブジェクトごとの暗号化を使用します。 |
| Amazon EBS | AWS Key Management Service（AWS KMS）によって生成されたデータ暗号化（DEK）を使用して、ボリュームレベルの暗号化を使用します。 |
| Amazon RDS（PostgreSQL） | AWS KMSによって生成されたDEKを使用して、ストレージレベルの暗号化を使用します。 |
| AWS KMS | ハードウェアセキュリティモジュール（HSM）を使用して保護し、AWS管理のキー階層で暗号化キーを管理します。 |

すべてのサービスは、AES-256暗号化標準を使用します。このエンベロープ暗号化システムでは、次のようになります:

1. データは、データ暗号化キー（DEK）を使用して暗号化されます。
1. DEK自体は、AWS KMSキーを使用して暗号化されます。
1. 暗号化されたDEKは、暗号化されたデータとともに保存されます。
1. AWS KMSキーはAWS Key Management Serviceに残っており、暗号化されていない形式で公開されることはありません。
1. すべての暗号化キーは、ハードウェアセキュリティモジュール（HSM）によって保護されています。

このエンベロープ暗号化プロセスは、AWS KMSが各暗号化操作に固有のDEKを導出することで機能します。DEKはデータを直接暗号化し、DEK自体はAWS KMSキーによって暗号化され、データの周りに安全なエンベロープを作成します。

### 暗号化キーのソース {#encryption-key-sources}

AWS KMS暗号化キーは、次のいずれかのソースから取得できます:

- [AWS管理キー](#aws-managed-keys)（デフォルト）: GitLabとAWSは、キーの生成と管理のすべての側面を処理します。
- [Bring your own key（BYOK）](#bring-your-own-key-byok): 独自のAWS KMSキーを提供および管理します。

すべてのキー生成は、専用ハードウェアを使用してAWS KMSで行われ、すべてのストレージサービスでの暗号化に対する高いセキュリティ標準を保証します。

次の表は、これらのオプション間の機能的な違いをまとめたものです:

| 暗号化キーソース | AWS管理キー                                                                            | Bring your own key（BYOK） |
|-----------------------|---------------------------------------------------------------------------------------------|---------------------------|
| **Key generation**（キーの生成）    | BYOKが提供されていない場合は、自動的に生成されます。                                               | 独自のAWS KMSキーを作成します。 |
| **Ownership**（所有権）         | AWSがお客様に代わって管理します。                                                                 | 自分でキーを所有および管理します。 |
| **Access control**（アクセス制御）    | キーを使用するAWSサービスのみが、復号化してアクセスできます。直接アクセスすることはできません。 | AWSアカウントのIAMポリシーを通じてアクセスを制御します。 |
| **セットアップ**             | セットアップは不要です。                                                                          | オンボーディングの前にセットアップする必要があります。後でイネーブルメントすることはできません。 |

### AWS管理キー {#aws-managed-keys}

独自のキーを持ち込まない場合、AWSはデフォルトで暗号化にAWS管理のAWS KMSキーを使用します。これらのキーは、各サービスに対してAWSによって自動的に作成および管理されます。

AWS KMSは、Identity and Access Management（IAM）を使用して、AWS管理キーへのアクセスを管理します。このアーキテクチャにより、すべてのキー操作がHSMベースのセキュリティ制御を通じて管理されるため、AWSの担当者でさえ、暗号化キーにアクセスしたり、データを直接復号化したりすることはできません。

AWS管理のAWS KMSキーに直接アクセスすることはできません。インスタンスで使用する特定のAWSサービスのみが、お客様に代わって管理するリソースに対する暗号化または復号化操作をリクエストできます。

キーへのアクセスを必要とするAWSサービス（S3、EBS、RDS）のみがそれらを使用できます。AWS KMSキーは内部HSMベースのメカニズムによって保護されているため、AWSの担当者はキーマテリアルに直接アクセスできません。

詳細については、[AWS管理キー](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk)に関するAmazonドキュメントを参照してください。

### Bring your own key（BYOK） {#bring-your-own-key-byok}

BYOKを使用すると、独自のAWS KMSキーを使用して、保存時にGitLab Dedicatedデータを暗号化できます。これにより、独自のAWS KMS暗号化キーの制御を維持できます。AWSアカウントを通じてアクセス設定を管理します。

{{< alert type="note" >}}

BYOKは、インスタンスのオンボーディング中にイネーブルメントする必要があります。いったんイネーブルメントすると、無効にすることはできません。

オンボーディング中にBYOKをイネーブルメントしなかった場合、データはAWS管理キーで保存時に暗号化されたままになりますが、独自のキーを使用することはできません。

{{< /alert >}}

キーローテーション要件により、GitLab DedicatedはAWS管理のキーマテリアル（[AWS_KMS](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#key-origin)originタイプ）のみをサポートします。

GitLab Dedicatedでは、KMSキーをいくつかの方法で使用できます:

- すべてのリージョンにわたるすべてのサービスに対して1つのKMSキー: 複数のGeoインスタンスがある各リージョンにレプリカがある、単一のマルチリージョンキーを使用します。
- 各リージョン内のすべてのサービスに対して1つのKMSキー: 複数のGeoインスタンスがある各リージョンに個別のキーを使用します。
- リージョンごとのサービス別KMSキー: 各リージョン内で、さまざまなサービス（バックアップ、EBS、RDS、S3、高度な検索）に異なるキーを使用します。
  - キーは、各サービスに固有である必要はありません。
  - 選択的なイネーブルメントはサポートされていません。

#### BYOKのAWS KMSキーを作成する {#create-aws-kms-keys-for-byok}

AWSコンソールを使用して、KMSキーを作成します。

前提要件: 

- GitLab AWSアカウントIDをGitLab Dedicatedアカウントチームから受け取っている必要があります。
- GitLab Dedicatedテナントインスタンスはまだ作成されていない必要があります。

BYOKのAWS KMSキーを作成するには:

1. AWSコンソールにサインインし、KMSサービスに移動します。
1. キーを作成するGeoインスタンスのAWSリージョンを選択します。
1. **Create key**（キーを作成）を選択します。
1. **Configure key**（キーの構成）セクション:
   1. **Key type**（キータイプ）で、**Symmetrical**（対称）を選択します。
   1. **Key usage**（キーの使用方法）で、**Encrypt and decrypt**（暗号化と復号化）を選択します。
   1. **Advanced options**（詳細オプション）:
      1. **Key material origin**（キーマテリアルのオリジン）で、**KMS**（KMS）を選択します。
      1. **Regionality**（地域）で、**Multi-Region key**（マルチリージョンキー）を選択します。
1. キーのエイリアス、説明、およびタグの値を入力します。
1. キーの管理者を選択します。
1. オプション。キーの管理者がキーを削除できるようにするか、削除できないようにします。
1. **Define key usage permissions**（キーの使用許可の定義）ページで、**Other AWS accounts**（他のAWSアカウント）の下にあるGitLab AWSアカウントを追加します。
1. KMSキーポリシーをレビューします。アカウントIDとユーザー名が入力された、以下の例と同様に見えるはずです。

```json
{
    "Version": "2012-10-17",
    "Id": "byok-key-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:user/<CUSTOMER-USER>"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:UpdatePrimaryRegion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 追加のGeoインスタンスのレプリカキーを作成する {#create-replica-keys-for-additional-geo-instances}

異なるリージョンの複数のGeoインスタンス間で同じKMSキーを使用する場合は、[レプリカキー](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-replicate.html)を作成します。

レプリカキーを作成するには:

1. AWS Key Management Service（AWS KMS）コンソールで、以前に作成したキーに移動します。
1. **Regionality**（地域）タブを選択します。
1. **Related multi-Region keys**（関連するマルチリージョンキー）セクションで、**Create new replica keys**（新しいレプリカキーの作成）を選択します。
1. 追加のGeoインスタンスがある1つ以上のAWSリージョンを選択します。
1. オリジンのエイリアスを保持するか、レプリカキーに別のエイリアスを入力します。
1. オプション。説明を入力し、タグを追加します。
1. レプリカキーを管理できるIAMユーザーとロールを選択します。
1. オプション。**Allow key administrators to delete this key**（このキーを削除するためのキーの管理者を許可する）チェックボックスをオンまたはオフにします。
1. **次へ**を選択します。
1. **Define key usage permissions**（キーの使用許可の定義）ページで、GitLab AWSアカウントが**Other AWS accounts**（他のAWSアカウント）の下にリストされていることを確認します。
1. **次へ**を選択して、ポリシーを確認します。
1. **次へ**を選択し、設定をレビューして、**Finish**（完了）を選択します。

KMSキーの作成と管理の詳細については、[AWS KMSドキュメント](https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html)を参照してください。

#### インスタンスのBYOKをイネーブルメントする {#enable-byok-for-your-instance}

BYOKをイネーブルメントするには:

1. 作成したすべてのキーのARNを収集します。これには、それぞれのリージョンにあるレプリカキーが含まれます。
1. GitLab Dedicatedテナントがプロビジョニングされる前に、これらのARNが[オンボーディング](create_instance/_index.md)中にスイッチボードに入力されていることを確認してください。
1. AWS KMSキーが、[オンボーディング](create_instance/_index.md)中にスイッチボードで指定された、目的のプライマリ、セカンダリ、およびバックアップリージョンにレプリケートされていることを確認してください。

## 転送中に暗号化されたデータ {#encrypted-data-in-transit}

GitLab Dedicatedは、強力なサイファースイートを備えたTLS（トランスポートレイヤーセキュリティ）を使用して、ネットワーク経由で移動するすべてのデータを暗号化します。この暗号化は、GitLab Dedicatedサービスで使用されるすべてのネットワーク通信に適用されます。

| サービス | 暗号化の方法 |
|---------|-------------------|
| ウェブアプリケーション | TLS 1.2/1.3を使用して、クライアントとサーバー間の通信を暗号化します。 |
| Amazon S3 | TLS 1.2/1.3を使用して、HTTPSアクセスを暗号化します。 |
| Amazon EBS | TLSを使用して、AWSデータセンター間のデータレプリケーションを暗号化します。 |
| Amazon RDS（PostgreSQL） | SSL/TLS（最小TLS 1.2）を使用して、データベース接続を暗号化します。 |
| AWS KMS | TLSを使用して、APIリクエストを暗号化します。 |

{{< alert type="note" >}}

転送中のデータの暗号化は、GitLab Dedicatedコンポーネントによって生成および管理されるキーを使用してTLSで実行され、BYOKではカバーされません。

{{< /alert >}}

### カスタムTLS証明書 {#custom-tls-certificates}

カスタムTLS証明書を構成して、暗号化された通信に組織の証明書を使用できます。

カスタム証明書の構成の詳細については、[カスタム証明書](configure_instance/network_security.md#custom-certificate-authority)を参照してください。
