---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オブジェクトストレージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、さまざまな種類のデータを保持するためにオブジェクトストレージサービスの使用をサポートしています。NFSよりも推奨され、オブジェクトストレージは通常、パフォーマンス、信頼性、スケーラビリティがはるかに高いため、一般的に大規模なセットアップに適しています。

オブジェクトストレージを設定するには、次の2つのオプションがあります。

- （推奨）[すべてのオブジェクトタイプに対して単一のストレージ接続を設定する](#configure-a-single-storage-connection-for-all-object-types-consolidated-form): サポートされているすべてのオブジェクトタイプで単一の認証情報を共有します。これは、統合形式と呼ばれます。
- [オブジェクトタイプごとに個別のストレージ接続を設定する](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form): オブジェクトごとに、個別のオブジェクトストレージの接続と設定を定義します。これは、ストレージ固有形式と呼ばれます。

  すでにストレージ固有形式を使用している場合は、[統合形式への移行方法](#transition-to-consolidated-form)を参照してください。

データをローカルに保存している場合は、[オブジェクトストレージへの移行方法](#migrate-to-object-storage)を参照してください。

## サポート対象のオブジェクトストレージプロバイダー

GitLabはFogライブラリと緊密に統合されているため、GitLabで使用できる[プロバイダー](https://fog.github.io/about/provider_documentation.html)を確認できます。

具体的には、GitLabは複数のオブジェクトストレージプロバイダー上で、ベンダーおよび顧客によってテストされています。

- [Amazon S3](https://aws.amazon.com/s3/)（[オブジェクトロック](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)はサポートされていません。詳細については、[イシュー335775](https://gitlab.com/gitlab-org/gitlab/-/issues/335775)を参照してください）
- [Google Cloud Storage](https://cloud.google.com/storage)
- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces)（S3互換）
- [Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm)
- [Open Stack Swift](https://docs.openstack.org/swift/latest/s3_compat.html)（S3互換モード）
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)
- [MinIO](https://min.io/)（S3互換）
- さまざまなストレージベンダーが提供するオンプレミスハードウェアおよびアプライアンス。正式なリストは確定していません。

## すべてのオブジェクトタイプに対して単一のストレージ接続を設定する（統合形式）

CIアーティファクト、LFSファイル、アップロード添付ファイルなど、ほとんどのオブジェクトタイプは、複数のバケットを持つオブジェクトストレージに対して単一の認証情報を指定することで保存できます。

{{< alert type="note" >}}

GitLab Helmチャートを使用している場合は、[統合形式の設定方法](https://docs.gitlab.com/charts/charts/globals.html#consolidated-object-storage)を参照してください。

{{< /alert >}}

統合形式を使用してオブジェクトストレージを設定すると、次のような利点があります。

- オブジェクトタイプ間で接続の詳細を共有するため、GitLabの設定を簡素化できる。
- [暗号化されたS3バケット](#encrypted-s3-buckets)を使用できる。
- [適切な`Content-MD5`ヘッダーを付加して、ファイルをS3にアップロードできる](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222)。

統合形式を使用する場合、[直接アップロード](../development/uploads/_index.md#direct-upload)が自動的に有効になります。そのため、次のプロバイダーのみを使用できます。

- [Amazon S3互換プロバイダー](#amazon-s3)
- [Google Cloud Storage](#google-cloud-storage-gcs)
- [Azure Blob Storage](#azure-blob-storage)

統合形式の設定は、バックアップまたはMattermostには使用できません。バックアップについては、[サーバー側の暗号化](backup_restore/backup_gitlab.md#s3-encrypted-buckets)を個別に設定できます。サポート対象のオブジェクトストレージタイプについては、[こちらの完全な一覧表](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)を参照してください。

統合形式を有効にすると、すべてのオブジェクトタイプに対してオブジェクトストレージが有効になります。すべてのバケットが指定されていない場合、次のようなエラーが表示されることがあります。

```plaintext
Object storage for <object type> must have a bucket specified
```

特定のオブジェクトタイプにローカルストレージを使用したい場合は、[特定の機能に対してオブジェクトストレージを無効にできます](#disable-object-storage-for-specific-features)。

### 共通パラメーターを設定する

統合形式では、`object_store`セクションで共通のパラメーターセットを定義します。

| 設定           | 説明                       |
|-------------------|-----------------------------------|
| `enabled`         | オブジェクトストレージを有効または無効にします。 |
| `proxy_download`  | `true`に設定すると、[提供されるすべてのファイルに対してプロキシ処理を有効](#proxy-download)にします。このオプションを使用すると、GitLabがすべてのデータをプロキシ処理する代わりに、クライアントがリモートストレージから直接ダウンロードできるようになるため、エグレストラフィックを削減できます。 |
| `connection`      | さまざまな[接続オプション](#configure-the-connection-settings)（以降のセクションで説明します）。 |
| `storage_options` | [サーバー側の暗号化](#server-side-encryption-headers)など、新しいオブジェクトを保存する際に使用するオプション。 |
| `objects`         | [オブジェクト固有の設定](#configure-the-parameters-of-each-object)。 |

例については、[統合形式とAmazon S3の使用方法](#full-example-using-the-consolidated-form-and-amazon-s3)を参照してください。

### 各オブジェクトのパラメーターを設定する

各オブジェクトタイプについて、少なくとも保存先のバケット名を定義する必要があります。

次の表に、使用できる有効な`objects`を示します。

| タイプ               | 説明 |
|--------------------|-------------|
| `artifacts`        | [CI/CDジョブアーティファクト](cicd/job_artifacts.md) |
| `external_diffs`   | [マージリクエストの差分](merge_request_diffs.md) |
| `uploads`          | [ユーザーアップロード](uploads.md) |
| `lfs`              | [Git Large File Storageオブジェクト](lfs/_index.md) |
| `packages`         | [プロジェクトパッケージ（例: PyPI、Maven、NuGet）](packages/_index.md) |
| `dependency_proxy` | [依存プロキシ](packages/dependency_proxy.md) |
| `terraform_state`  | [Terraformステートファイル](terraform_state.md) |
| `pages`            | [Pages](pages/_index.md) |
| `ci_secure_files`  | [セキュアファイル](cicd/secure_files.md) |

各オブジェクトタイプ内で、3つのパラメーターを定義できます。

| 設定          | 必須？              | 説明                         |
|------------------|------------------------|-------------------------------------|
| `bucket`         | {{< icon name="check-circle" >}} はい* | オブジェクトタイプのバケット名。`enabled`が`false`に設定されている場合は必須ではありません。 |
| `enabled`        | {{< icon name="dotted-circle" >}} いいえ | [共通パラメーター](#configure-the-common-parameters)をオーバーライドします。     |
| `proxy_download` | {{< icon name="dotted-circle" >}} いいえ | [共通パラメーター](#configure-the-common-parameters)をオーバーライドします。     |

例については、[統合形式とAmazon S3の使用方法](#full-example-using-the-consolidated-form-and-amazon-s3)を参照してください。

#### 特定の機能に対してオブジェクトストレージを無効にする

上記のとおり、`enabled`フラグを`false`に設定することで、特定のオブジェクトタイプに対してオブジェクトストレージを無効にできます。たとえば、CIアーティファクトのオブジェクトストレージを無効にするには、次の手順に従います。

```ruby
gitlab_rails['object_store']['objects']['artifacts']['enabled'] = false
```

機能が完全に無効になっている場合、バケットは必要ありません。たとえば、次の設定によりCIアーティファクトを無効にした場合、バケットは不要です。

```ruby
gitlab_rails['artifacts_enabled'] = false
```

## オブジェクトタイプごとに個別のストレージ接続を設定する（ストレージ固有形式）

ストレージ固有形式では、オブジェクトごとに個別のオブジェクトストレージの接続と設定を定義します。ただし、統合形式でサポートされていないストレージタイプを除き、[統合形式を使用](#transition-to-consolidated-form)することが推奨されます。GitLab Helmチャートを使用する場合は、チャートが[オブジェクトストレージの統合形式](https://docs.gitlab.com/charts/charts/globals.html#consolidated-object-storage)をどのように扱うのかを参照してください。

統合形式以外では、[暗号化されたS3バケット](#encrypted-s3-buckets)の使用はサポートされていません。使用すると、[ETagの不一致エラー](#etag-mismatch)が発生する可能性があります。

{{< alert type="note" >}}

ストレージ固有形式では共有フォルダーを必要としないため、[直接アップロードがデフォルトになる可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/27331)。

{{< /alert >}}

統合形式でサポートされていないストレージタイプについては、次のガイドを参照してください。

| オブジェクトストレージタイプ | 統合形式でサポートされているか？ |
|---------------------|------------------------------------------|
| [バックアップ](backup_restore/backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) | {{< icon name="dotted-circle" >}} いいえ |
| [コンテナレジストリ](packages/container_registry.md#use-object-storage)（オプション機能） | {{< icon name="dotted-circle" >}} いいえ |
| [Mattermost](https://docs.mattermost.com/configure/file-storage-configuration-settings.html)| {{< icon name="dotted-circle" >}} いいえ |
| [自動スケールRunnerのキャッシュ](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)（パフォーマンスを向上させるためのオプション） | {{< icon name="dotted-circle" >}} いいえ |
| [セキュアファイル](cicd/secure_files.md#using-object-storage) | {{< icon name="check-circle" >}} はい |
| [ジョブアーティファクト](cicd/job_artifacts.md#using-object-storage)（アーカイブされたジョブログを含む） | {{< icon name="check-circle" >}} はい |
| [LFSオブジェクト](lfs/_index.md#storing-lfs-objects-in-remote-object-storage) | {{< icon name="check-circle" >}} はい |
| [アップロード](uploads.md#using-object-storage) | {{< icon name="check-circle" >}} はい |
| [マージリクエストの差分](merge_request_diffs.md#using-object-storage) | {{< icon name="check-circle" >}} はい |
| [パッケージ](packages/_index.md#use-object-storage)（オプション機能） | {{< icon name="check-circle" >}} はい |
| [依存プロキシ](packages/dependency_proxy.md#using-object-storage)（オプション機能） | {{< icon name="check-circle" >}} はい |
| [Terraformステートファイル](terraform_state.md#using-object-storage) | {{< icon name="check-circle" >}} はい |
| [Pagesコンテンツ](pages/_index.md#object-storage-settings) | {{< icon name="check-circle" >}} はい |

## 接続を設定する

統合形式とストレージ固有形式の両方で、接続を設定する必要があります。次のセクションでは、`connection`設定で使用できるパラメーターについて説明します。

### Amazon S3

接続設定は、[fog-aws](https://github.com/fog/fog-aws)によって提供されるものと一致します。

| 設定                                     | 説明                        | デフォルト |
|---------------------------------------------|------------------------------------|---------|
| `provider`                                  | 互換性のあるホストの場合、常に`AWS`になります。 | `AWS` |
| `aws_access_key_id`                         | AWS認証情報、または互換性のある設定。    | |
| `aws_secret_access_key`                     | AWS認証情報、または互換性のある設定。    | |
| `aws_signature_version`                     | 使用するAWS署名バージョン。`2`または`4`が有効なオプションです。Digital Ocean Spacesやその他のプロバイダーでは、`2`が必要な場合があります。 | `4` |
| `enable_signature_v4_streaming`             | [AWS v4署名](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html)でHTTPチャンク転送を有効にする場合は`true`に設定します。Oracle Cloud S3では、これを`false`にする必要があります。GitLab 17.4で、デフォルトが`true`から`false`に変更されました。  | `false` |
| `region`                                    | AWSリージョン。                        | |
| `host`                                      | 非推奨: 代わりに`endpoint`を使用してください。AWS以外を使用する場合のS3互換ホスト。例: `localhost`、`storage.example.com`。HTTPSおよびポート443が前提となります。 | `s3.amazonaws.com` |
| `endpoint`                                  | [MinIO](https://min.io)などのS3互換サービスを設定する際に使用できます。`http://127.0.0.1:9000`などのURLを指定します。これは、`host`よりも優先されます。統合形式では必ず`endpoint`を使用してください。 | （オプション） |
| `path_style`                                | `true`に設定すると、`bucket_name.host/object`ではなく、`host/bucket_name/object`形式のパスを使用します。[MinIO](https://min.io)を使用する場合は`true`に設定します。AWS S3の場合は`false`のままにします。 | `false` |
| `use_iam_profile`                           | アクセスキーの代わりにIAMプロファイルを使用する場合は`true`に設定します。 | `false` |
| `aws_credentials_refresh_threshold_seconds` | IAMで一時的な認証情報を使用する場合、[自動更新のしきい値](https://github.com/fog/fog-aws#controlling-credential-refresh-time-with-iam-authentication)（秒）を設定します。 | `15` |

#### Amazonインスタンスプロファイルを使用する

オブジェクトストレージ設定でAWSアクセスキーとシークレットキーを指定する代わりに、Amazon Identity Access and Management（IAM）ロールを使用して[Amazonインスタンスプロファイル](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html)を設定するようにGitLabを設定できます。これを使用すると、GitLabはS3バケットにアクセスするたびに一時的な認証情報をフェッチするため、設定に値をハードコーディングする必要はありません。

前提要件:

- GitLabが[インスタンスメタデータエンドポイント](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html)に接続できる必要があります。
- GitLabが[インターネットプロキシを使用するように設定されている](https://docs.gitlab.com/omnibus/settings/environment-variables.html)場合、エンドポイントのIPアドレスを`no_proxy`リストに追加する必要があります。

インスタンスプロファイルを設定するには、次の手順に従います。

1. 必要な権限を持つIAMロールを作成します。`test-bucket`という名前のS3バケットのロールの例を次に示します。

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::test-bucket/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket"
               ],
               "Resource": "arn:aws:s3:::test-bucket"
           }
       ]
   }
   ```

1. GitLabインスタンスをホストしているEC2インスタンスに、[このロールをアタッチ](https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile)します。
1. GitLab設定オプション`use_iam_profile`を`true`に設定します。

#### 暗号化されたS3バケット

インスタンスプロファイルまたは統合形式のいずれかで設定している場合、GitLab Workhorseは、[SSE-S3またはSSE-KMS暗号化がデフォルトで有効になっている](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html)S3バケットに対して、ファイルを適切にアップロードします。AWS KMSキーとSSE-C暗号化は、[すべてのリクエストで暗号化キーを送信する必要があるため、サポートされていません](https://gitlab.com/gitlab-org/gitlab/-/issues/226006)。

#### サーバー側の暗号化ヘッダー

暗号化を有効にする最も簡単な方法はS3バケットでデフォルトの暗号化を設定することですが、[暗号化されたオブジェクトのみがアップロードされるようにバケットポリシーを設定する](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects)こともできます。そのためには、`storage_options`設定セクションで適切な暗号化ヘッダーを送信するようにGitLabを設定する必要があります。

| 設定                             | 説明                              |
|-------------------------------------|------------------------------------------|
| `server_side_encryption`            | 暗号化モード（`AES256`または`aws:kms`）。 |
| `server_side_encryption_kms_key_id` | Amazonリソース名。これが必要になるのは`server_side_encryption`で`aws:kms`を使用する場合のみです。[KMS暗号化の使用に関するAmazonのドキュメントを](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)参照してください。 |

デフォルトの暗号化の場合と同様に、これらのオプションは、Workhorse S3クライアントが有効になっている場合にのみ機能します。次の2つの条件のいずれかを満たす必要があります。

- 接続設定で`use_iam_profile`が`true`に設定されている。
- 統合形式が使用されている。

Workhorse S3クライアントを有効にせずにサーバー側の暗号化ヘッダーを使用すると、[ETagの不一致エラー](#etag-mismatch)が発生します。

### Oracle Cloud S3

Oracle Cloud S3では、次の設定を必ず使用してください。

| 設定                         | 値   |
|---------------------------------|---------|
| `enable_signature_v4_streaming` | `false` |
| `path_style`                    | `true`  |

`enable_signature_v4_streaming`が`true`に設定されている場合、`production.log`に次のエラーが記録されることがあります。

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

### Google Cloud Storage（GCS）

GCSの有効な接続パラメーターを次に示します。

| 設定                      | 説明       | 例 |
|------------------------------|-------------------|---------|
| `provider`                   | プロバイダー名。    | `Google` |
| `google_project`             | GCPプロジェクト名。 | `gcp-project-12345` |
| `google_json_key_location`   | JSONキーパス。    | `/path/to/gcp-project-12345-abcde.json` |
| `google_json_key_string`     | JSONキー文字列。  | `{ "type": "service_account", "project_id": "example-project-382839", ... }` |
| `google_application_default` | [Google Cloudのアプリケーションのデフォルト認証情報](https://cloud.google.com/docs/authentication#adc)を使用してサービスアカウントの認証情報を特定する場合は、`true`に設定します。 | |

GitLabは、まず`google_json_key_location`、次に`google_json_key_string`、最後に`google_application_default`の順に値を読み取ります。これらのうち、値を持つ最初の設定を使用します。

サービスアカウントには、バケットにアクセスするための権限が必要です。詳細については、[Cloud Storageの認証に関するドキュメント](https://cloud.google.com/storage/docs/authentication)を参照してください。

#### Google Cloudのアプリケーションのデフォルト認証情報

[Google Cloudのアプリケーションのデフォルト認証情報（ADC）](https://cloud.google.com/docs/authentication/application-default-credentials)を使用するのは、通常、GitLabでデフォルトのサービスアカウントまたは[ワークロードアイデンティティフェデレーション](https://cloud.google.com/iam/docs/workload-identity-federation)を使用する場合です。`google_application_default`を`true`に設定し、`google_json_key_location`と`google_json_key_string`を省略します。

ADCを使用する場合は、次の点を確認してください。

- 使用するサービスアカウントに[`iam.serviceAccounts.signBlob`権限](https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob)が付与されていること。通常、この権限はサービスアカウントに`Service Account Token Creator`ロールを付与することで設定します。
- Google Compute仮想マシンを使用している場合は、[Google Cloud APIにアクセスするための適切なアクセススコープ](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes)が設定されていること。マシンに適切なスコープが設定されていない場合、エラーログに次のように記録されることがあります。

  ```markdown
  Google::Apis::ClientError (insufficientPermissions: Request had insufficient authentication scopes.)
  ```

{{< alert type="note" >}}

[顧客管理の暗号化キー](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys)でバケットの暗号化を使用するには、[統合形式](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用します。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_json_key_location' => '<FILENAME>'
   }
   ```

   ADCを使用する場合は、代わりに`google_application_default`を使用します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_application_default' => true
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`object_storage.yaml`ファイルに記述し、[Kubernetesシークレット](https://docs.gitlab.com/charts/charts/globals.html#connection)として使用します。

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_json_key_location: '<FILENAME>'
   ```

   ADCを使用する場合は、代わりに`google_application_default`を使用します。

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_application_default: true
   ```

1. Kubernetesシークレットを作成します。

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'Google',
             'google_project' => '<GOOGLE PROJECT>',
             'google_json_key_location' => '<FILENAME>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   ADCを使用する場合は、代わりに`google_application_default`を使用します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<GOOGLE PROJECT>',
     'google_application_default' => true
   }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< /tabs >}}

### Azure Blob Storage

Azureではblobのコレクションを表す用語として`container`を使用していますが、GitLabではこの用語を`bucket`に統一しています。必ず、`bucket`設定でAzureコンテナ名を指定してください。

Azure Blob Storageは、単一の認証情報セットで複数のコンテナにアクセスするため、[統合形式](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)でのみ使用できます。[ストレージ固有形式](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form)はサポートされていません。詳細については、[統合形式への移行方法](#transition-to-consolidated-form)を参照してください。

Azureの有効な接続パラメーターを次に示します。詳細については、[Azure Blob Storageのドキュメント](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction)を参照してください。

| 設定                      | 説明    | 例   |
|------------------------------|----------------|-----------|
| `provider`                   | プロバイダー名。 | `AzureRM` |
| `azure_storage_account_name` | ストレージへのアクセスに使用するAzure Blob Storageアカウントの名前。 | `azuretest` |
| `azure_storage_access_key`   | コンテナへのアクセスに使用するストレージアカウントのアクセスキー。これは通常、base64でエンコードされた512ビットの暗号化キーであり、シークレットとして扱われます。これは、[Azureワークロードアイデンティティまたはマネージドアイデンティティ](#azure-workload-and-managed-identities)を使用する場合は省略可能です。 | `czV2OHkvQj9FKEgrTWJRZVRoV21ZcTN0Nnc5eiRDJkYpSkBOY1JmVWpYbjJy\nNHU3eCFBJUQqRy1LYVBkU2dWaw==\n` |
| `azure_storage_domain`       | Azure Blob Storage APIへの接続に使用するドメイン名（オプション）。デフォルトは`blob.core.windows.net`です。Azure China、Azure Germany、Azure US Government、またはその他のカスタムAzureドメインを使用している場合は、これを設定します。 | `blob.core.windows.net` |

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [ワークロードアイデンティティ](#azure-workload-and-managed-identities)を使用している場合は、`azure_storage_access_key`を省略します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`object_storage.yaml`ファイルに記述し、[Kubernetesシークレット](https://docs.gitlab.com/charts/charts/globals.html#connection)として使用します。

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_access_key: <YOUR_AZURE_STORAGE_ACCOUNT_KEY>
   azure_storage_domain: blob.core.windows.net
   ```

   [ワークロードアイデンティティまたはマネージドアイデンティティ](#azure-workload-and-managed-identities)を使用している場合は、`azure_storage_access_key`を省略します。

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_domain: blob.core.windows.net
   ```

1. Kubernetesシークレットを作成します。

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AzureRM',
             'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
             'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
             'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

    [マネージドアイデンティティ](#azure-workload-and-managed-identities)を使用している場合は、`azure_storage_access_key`を省略します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

自己コンパイルインストールの場合、WorkhorseにもAzure認証情報を設定する必要があります。Linuxパッケージインストールの場合、Workhorseの設定は以前の設定が引き継がれるため、この作業は不要です。

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AzureRM
         azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
         azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

1. `/home/git/gitlab-workhorse/config.toml`を編集し、次の行を追加または修正します。

     ```toml
     [object_storage]
       provider = "AzureRM"

     [object_storage.azurerm]
       azure_storage_account_name = "<AZURE STORAGE ACCOUNT NAME>"
       azure_storage_access_key = "<AZURE STORAGE ACCESS KEY>"
     ```

   カスタムのAzureストレージドメインを使用している場合、Workhorseの設定で`azure_storage_domain`を設定する必要は**ありません**。この情報は、GitLab RailsとWorkhorse間のAPIコールでやり取りされます。

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### Azureワークロードアイデンティティとマネージドアイデンティティ

{{< history >}}

- [GitLab 17.9で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/242245)

{{< /history >}}

[Azureワークロードアイデンティティ](https://azure.github.io/azure-workload-identity/docs/)または[マネージドアイデンティティ](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/)を使用する場合は、設定から`azure_storage_access_key`を省略します。`azure_storage_access_key`が空の場合、GitLabは次の処理を試みます。

1. [ワークロードアイデンティティ](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview)を使用して一時的な認証情報を取得します。`AZURE_TENANT_ID`、`AZURE_CLIENT_ID`、`AZURE_FEDERATED_TOKEN_FILE`を環境変数に設定しておく必要があります。
1. ワークロードアイデンティティが利用できない場合は、[Azureインスタンスメタデータサービス](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token)に対して認証情報をリクエストします。
1. [ユーザー委任キー](https://learn.microsoft.com/en-us/rest/api/storageservices/get-user-delegation-key)を取得します。
1. そのキーを使用して、ストレージアカウントのblobにアクセスするためのSASトークンを生成します。

対象のアイデンティティに`Storage Blob Data Contributor`ロールが割り当てられていることを確認します。

### Storj Gateway（SJ）

{{< alert type="note" >}}

Storj Gatewayは、マルチスレッドコピーを[サポートしていません](https://github.com/storj/gateway-st/blob/4b74c3b92c63b5de7409378b0d1ebd029db9337d/docs/s3-compatibility.md)（表の`UploadPartCopy`を参照してください）。実装が[計画](https://github.com/storj/roadmap/issues/40)されていますが、完了するまで[マルチスレッドコピーを無効にする](#multi-threaded-copying)必要があります。

{{< /alert >}}

[Storjネットワーク](https://www.storj.io/)は、S3互換のAPIゲートウェイを提供します。次の設定例を使用してください。

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://gateway.storjshare.io',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 2,
  'enable_signature_v4_streaming' => false
}
```

署名バージョンは`2`である必要があります。v4を使用すると、HTTP 411 Length Required（長さ情報が必要）エラーが発生します。詳細については、[イシュー4419](https://gitlab.com/gitlab-org/gitlab/-/issues/4419)を参照してください。

### Hitachi Vantara HCP

{{< alert type="note" >}}

HCPへの接続時に、次のエラーが返される場合があります。`SignatureDoesNotMatch - The request signature we calculated does not match the signature you provided. Check your HCP Secret Access key and signing method.`このような場合、ネームスペースではなくテナントのURLに`endpoint`を設定し、バケットパスを`<namespace_name>/<bucket_name>`の形式で設定していることを確認してください。

{{< /alert >}}

[HCP](https://docs.hitachivantara.com/r/en-us/content-platform-for-cloud-scale/2.6.x/mk-hcpcs008/getting-started/introducing-hcp-for-cloud-scale/support-for-the-amazon-s3-api)は、S3互換のAPIを提供しています。次の設定例を使用してください。

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://<tenant_endpoint>',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 4,
  'enable_signature_v4_streaming' => false
}

# Example of <namespace_name/bucket_name> formatting
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<namespace_name>/<bucket_name>'
```

## 統合形式とAmazon S3を使用した完全な設定例

次の例では、AWS S3を使用して、サポートされているすべてのサービスに対してオブジェクトストレージを有効にします。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します。

   ```ruby
   # Consolidated object storage configuration
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['proxy_download'] = false
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
     'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
   }
   # OPTIONAL: The following lines are only needed if server side encryption is required
   gitlab_rails['object_store']['storage_options'] = {
     'server_side_encryption' => '<AES256 or aws:kms>',
     'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [AWS IAMプロファイル](#use-amazon-instance-profiles)を使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略します。次に例を示します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. 次の内容を`object_storage.yaml`ファイルに記述し、[Kubernetesシークレット](https://docs.gitlab.com/charts/charts/globals.html#connection)として使用します。

   ```yaml
   provider: AWS
   region: us-east-1
   aws_access_key_id: <AWS_ACCESS_KEY_ID>
   aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
   ```

   [AWS IAMプロファイル](#use-amazon-instance-profiles)を使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略します。次に例を示します。

   ```yaml
   provider: AWS
   region: us-east-1
   use_iam_profile: true
   ```

1. Kubernetesシークレットを作成します。

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Helm値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AWS',
             'region' => 'eu-central-1',
             'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
             'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
           }
           # OPTIONAL: The following lines are only needed if server side encryption is required
           gitlab_rails['object_store']['storage_options'] = {
             'server_side_encryption' => '<AES256 or aws:kms>',
             'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   [AWS IAMプロファイル](#use-amazon-instance-profiles)を使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略します。次に例を示します。

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AWS
         aws_access_key_id: <AWS_ACCESS_KEY_ID>
         aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
         region: eu-central-1
       storage_options:
         server_side_encryption: <AES256 or aws:kms>
         server_side_encryption_key_kms_id: <arn:aws:kms:xxx>
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

   [AWS IAMプロファイル](#use-amazon-instance-profiles)を使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略します。次に例を示します。

   ```yaml
   connection:
     provider: AWS
     region: eu-central-1
     use_iam_profile: true
   ```

1. `/home/git/gitlab-workhorse/config.toml`を編集し、次の行を追加または修正します。

   ```toml
   [object_storage]
     provider = "AWS"

   [object_storage.s3]
     aws_access_key_id = "<AWS_ACCESS_KEY_ID>"
     aws_secret_access_key = "<AWS_SECRET_ACCESS_KEY>"
   ```

   [AWS IAMプロファイル](#use-amazon-instance-profiles)を使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略します。次に例を示します。

   ```yaml
   [object_storage.s3]
     use_iam_profile = true
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## オブジェクトストレージに移行する

既存のローカルデータをオブジェクトストレージに移行するには、次のガイドを参照してください。

- [ジョブアーティファクト](cicd/job_artifacts.md#migrating-to-object-storage)（アーカイブされたジョブログを含む）
- [LFSオブジェクト](lfs/_index.md#migrating-to-object-storage)
- [アップロード](raketasks/uploads/migrate.md#migrate-to-object-storage)
- [マージリクエストの差分](merge_request_diffs.md#using-object-storage)
- [パッケージ](packages/_index.md#migrate-local-packages-to-object-storage)（オプション機能）
- [依存プロキシ](packages/dependency_proxy.md#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage)
- [Terraformステートファイル](terraform_state.md#migrate-to-object-storage)
- [Pagesコンテンツ](pages/_index.md#migrate-pages-deployments-to-object-storage)
- [プロジェクトレベルのセキュアファイル](cicd/secure_files.md#migrate-to-object-storage)

## 統合形式に移行する

ストレージ固有設定の場合:

- CI/CDアーティファクト、LFSファイル、アップロード添付ファイルなど、すべてのオブジェクトタイプに対するオブジェクトストレージの設定は、それぞれ個別に行われます。
- パスワードやエンドポイントURLなどのオブジェクトストア接続パラメーターは、タイプごとに重複することになります。

たとえば、Linuxパッケージインストールでは、次のような設定になることがあります。

```ruby
# Original object storage configuration
gitlab_rails['artifacts_object_store_enabled'] = true
gitlab_rails['artifacts_object_store_direct_upload'] = true
gitlab_rails['artifacts_object_store_proxy_download'] = false
gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts'
gitlab_rails['artifacts_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_direct_upload'] = true
gitlab_rails['uploads_object_store_proxy_download'] = false
gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
gitlab_rails['uploads_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
```

これにより、GitLabが異なるクラウドプロバイダー間でオブジェクトを保存できる柔軟性が得られる一方で、複雑さが増し、不要な冗長性が生じます。GitLab RailsとWorkhorseコンポーネントの両方がオブジェクトストレージにアクセスする必要があるため、統合形式を使用することで、認証情報の過度な重複を回避できます。

統合形式は、元の形式のすべての設定行を省略した場合_にのみ_使用されます。統合形式に移行するには、元の設定（例: `artifacts_object_store_enabled`、`uploads_object_store_connection`）を削除します。

## 別のオブジェクトストレージプロバイダーにオブジェクトを移行する

オブジェクトストレージ内のGitLabデータを、別のオブジェクトストレージプロバイダーに移行する必要が生じる場合があります。次の手順では、[Rclone](https://rclone.org/)を使用して移行する方法を説明します。

ここでは`uploads`バケットを移行することを前提としていますが、他のバケットでも手順は同じです。

前提要件:

- Rcloneを実行するコンピューターを選択します。移行するデータの量によっては、Rcloneを長時間実行する必要があるため、省電力モードになる可能性のあるラップトップまたはデスクトップコンピューターの使用は避けてください。GitLabサーバーを使用してRcloneを実行できます。

1. Rcloneを[インストール](https://rclone.org/downloads/)します。
1. 次を実行して、Rcloneを設定します。

   ```shell
   rclone config
   ```

   設定プロセスはインタラクティブです。少なくとも2つの「リモート」を追加します。1つは現在データが保存されているオブジェクトストレージプロバイダー用（`old`）、もう1つは移行先のプロバイダー用（`new`）です。

1. 移行元のデータを読み取れることを確認します。次の例では`uploads`バケットを参照していますが、実際のバケット名は異なる場合があります。

   ```shell
   rclone ls old:uploads | head
   ```

   これにより、現在`uploads`バケットに保存されているオブジェクトの部分的なリストが出力されます。エラーが発生した場合、またはリストが空の場合は、`rclone config`を使用してRclone設定に戻り、更新します。

1. 初回コピーを実行します。この手順では、GitLabサーバーをオフラインにする必要はありません。

   ```shell
   rclone sync -P old:uploads new:uploads
   ```

1. 最初の同期が完了したら、新しいオブジェクトストレージプロバイダーのWeb UIまたはコマンドラインインターフェースを使用して、新しいバケットにオブジェクトが存在することを確認します。オブジェクトが存在しない場合、または`rclone sync`の実行中にエラーが発生した場合は、Rcloneの設定を確認し、再試行してください。

以前の場所から新しい場所へのRcloneコピーが少なくとも1回成功したら、メンテナンスのスケジュールを計画し、GitLabサーバーをオフラインにします。メンテナンス期間中は、次の2つの作業を行う必要があります。

1. 旧バケットに何も残さないように、ユーザーが新しいオブジェクトを追加できないことを確認したうえで、最後の`rclone sync`を実行します。
1. `uploads`に新しいプロバイダーを使用するように、GitLabサーバーのオブジェクトストレージ設定を更新します。

## ファイルシステムストレージの代替手段

GitLab実装を[スケールアウト](reference_architectures/_index.md)したり、フォールトトレランスや冗長性を追加したりする場合は、ブロックストレージやネットワークファイルシステムへの依存関係を削除することを検討しているかもしれません。次の関連ガイドを参照してください。

1. [`git`ユーザーのホームディレクトリ](https://docs.gitlab.com/omnibus/settings/configuration.html#move-the-home-directory-for-a-user)がローカルディスク上にあることを確認します。
1. 共有の`authorized_keys`ファイルの必要性をなくすため、[SSH鍵のデータベース検索](operations/fast_ssh_key_lookup.md)を設定します。
1. [ジョブログにローカルディスクを使用しない](cicd/job_logs.md#prevent-local-disk-usage)ようにします。
1. [Pagesのローカルストレージを無効](pages/_index.md#disable-pages-local-storage)にします。

## トラブルシューティング

### オブジェクトがGitLabのバックアップに含まれていない

[バックアップドキュメント](backup_restore/backup_gitlab.md#object-storage)に記載されているとおり、オブジェクトはGitLabのバックアップに含まれていません。代わりに、オブジェクトストレージプロバイダーでバックアップを有効にできます。

### 個別のバケットを使用する

GitLabでは、データタイプごとに個別のバケットを使用するアプローチが推奨されます。これにより、GitLabが保存するさまざまなタイプのデータ間で競合が発生しなくなります。[イシュー292958](https://gitlab.com/gitlab-org/gitlab/-/issues/292958)では、単一のバケットの使用を可能にすることが提案されています。

Linuxパッケージインストールおよび自己コンパイルインストールでは、単一の実際のバケットを複数の仮想バケットに分割できます。オブジェクトストレージのバケット名が`my-gitlab-objects`である場合、アップロードは`my-gitlab-objects/uploads`、アーティファクトは`my-gitlab-objects/artifacts`、のように送信先を設定できます。アプリケーションは、これらが個別のバケットであるかのように動作します。バケットプレフィックスを使用すると、[Helmバックアップでは正しく機能しない場合があります](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376)。

Helmベースのインストールでは、[バックアップの復元を処理する](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy)ために個別のバケットが必要です。

### S3 APIの互換性の問題

すべてのS3プロバイダーが、GitLabが使用するFogライブラリと[完全に互換性がある](backup_restore/backup_gitlab.md#other-s3-providers)わけではありません。この問題の兆候として、`production.log`に次のエラーが記録されることがあります。

```plaintext
411 Length Required
```

### アーティファクトが常に`download`というファイル名でダウンロードされる

ダウンロードされるアーティファクトのファイル名は、[GetObjectリクエスト](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html)内の`response-content-disposition`ヘッダーで設定されます。S3プロバイダーがこのヘッダーをサポートしていない場合、ダウンロードされたファイルは常に`download`という名前で保存されます。

### プロキシダウンロード

クライアントは、有効期限付きの署名付きURLを受信するか、GitLabがオブジェクトストレージからクライアントにデータをプロキシ処理することにより、オブジェクトストレージ内のファイルをダウンロードできます。オブジェクトストレージから直接ファイルをダウンロードすることで、GitLabが処理する必要があるエグレストラフィックが削減されます。

ファイルがローカルのブロックストレージまたはNFSに保存されている場合、GitLabがプロキシとして動作する必要があります。オブジェクトストレージを使用している場合、これはデフォルトの動作ではありません。

`proxy_download`設定によってこの動作を制御します。デフォルトは`false`です。各ユースケースのドキュメントでこの設定を確認してください。

GitLabにファイルをプロキシ処理させる場合は、`proxy_download`を`true`に設定します。`proxy_download`を`true`に設定すると、GitLabサーバーで大きなパフォーマンスの低下が発生する可能性があります。GitLabサーバーのデプロイでは、`proxy_download`は`false`に設定されています。

`proxy_download`を`false`にすると、GitLabは[有効期限付きの署名付きオブジェクトストレージURLへのHTTP 302リダイレクト](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298)を返します。これにより、次の問題が発生する可能性があります。

- GitLabがオブジェクトストレージへのアクセスに非セキュアHTTPを使用している場合、クライアントは`https->http`ダウングレードエラーを生成し、リダイレクトの処理を拒否する可能性があります。この問題の解決策は、GitLabがHTTPSを使用することです。たとえば、LFSは次のエラーを生成します。

  ```plaintext
  LFS: lfsapi/client: refusing insecure redirect, https->http
  ```

- クライアントが、オブジェクトストレージ証明書を発行した公開認証局（CA）を信頼している必要があります。信頼していない場合、次のような一般的なTLSエラーが返される可能性があります。

  ```plaintext
  x509: certificate signed by unknown authority
  ```

- クライアントは、オブジェクトストレージへのネットワークアクセスを必要とします。ネットワークファイアウォールがアクセスをブロックする可能性があります。このアクセスが確立されていない場合、次のようなエラーが発生する可能性があります。

  ```plaintext
  Received status code 403 from server: Forbidden
  ```

- オブジェクトストレージのバケットが、GitLabインスタンスのURLからのクロスオリジンリソース共有（CORS）アクセスを許可している必要があります。リポジトリページでPDFを読み込もうとすると、次のエラーが表示される場合があります。

  ```plaintext
  An error occurred while loading the file. Please try again later.
  ```

  詳細については、[LFSのドキュメント](lfs/_index.md#error-viewing-a-pdf-file)を参照してください。

さらに、短期間ではありますが、ユーザーが有効期限付きの署名付きオブジェクトストレージURLを認証なしで他のユーザーと共有する可能性があります。また、オブジェクトストレージプロバイダーとクライアントの間で、帯域幅料金が発生する場合があります。

### ETagの不一致

デフォルトのGitLabの設定を使用している場合、[MinIO](https://gitlab.com/gitlab-org/gitlab/-/issues/23188)や[Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564)など、一部のオブジェクトストレージバックエンドで、`ETag mismatch`エラーが発生する場合があります。

#### Amazon S3の暗号化

Amazon Web Services S3でこのETag不一致エラーが発生している場合は、[バケットの暗号化設定](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html)が原因である可能性があります。この問題を解決するには、次の2つのオプションがあります。

- [統合形式を使用する](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)。
- [Amazonインスタンスプロファイルを使用する](#use-amazon-instance-profiles)。

MinIOを使用している場合は、最初のオプションをおすすめします。それ以外に、[MinIO向けの回避策](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564#note_244497658)は、サーバーで`--compat`パラメーターを使用することです。

統合形式またはインスタンスプロファイルが有効になっていない場合、GitLab Workhorseは、`Content-MD5` HTTPヘッダーが計算されていない署名付きURLを使用して、ファイルをS3にアップロードします。データが破損していないことを確認するため、Workhorseは、送信されたデータのMD5ハッシュが、S3サーバーから返されたETagヘッダーと一致することを確認します。暗号化が有効になっている場合はこれが当てはまらず、Workhorseはアップロード中に`ETag mismatch`エラーを報告します。

統合形式では、次のようになります。

- S3互換のオブジェクトストレージまたはインスタンスプロファイルと一緒に使用する場合、WorkhorseはS3認証情報を持つ内部S3クライアントを使用し、`Content-MD5`ヘッダーを計算できるようにします。これにより、S3サーバーから返されたETagヘッダーを比較する必要がなくなります。
- S3互換のオブジェクトストレージと一緒に使用していない場合、Workhorseは署名付きURLを使用する方式にフォールバックします。

#### Google Cloud Storageの暗号化

{{< history >}}

- [GitLab 16.11で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/441782)。

{{< /history >}}

Google Cloud Storage（GCS）でも、[顧客管理の暗号化キー（CMEK）によるデータ暗号化](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys)を有効にすると、ETag不一致エラーが発生します。

CMEKを使用する場合は、[統合形式](#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用してください。

### マルチスレッドコピー

GitLabは、[S3 Upload Part Copy API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html)を使用して、バケット内のファイルのコピーを高速化しています。[Kraken 11.0.2より前](https://ceph.com/releases/kraken-11-0-2-released/)のCeph S3はこの機能をサポートしておらず、[ファイルのアップロードプロセス中にファイルがコピーされると404エラーを返します](https://gitlab.com/gitlab-org/gitlab/-/issues/300604)。

この機能は、`:s3_multithreaded_uploads`機能フラグを使用して無効にできます。この機能を無効にするには、[Railsコンソールアクセス権](feature_flags.md#how-to-enable-and-disable-features-behind-flags)を持つGitLab管理者に、次のコマンドを実行するよう依頼してください。

```ruby
Feature.disable(:s3_multithreaded_uploads)
```

### Railsコンソールを使用して手動でテストする

状況によっては、Railsコンソールを使用してオブジェクトストレージの設定をテストすると役立つ場合があります。次の例では、指定された一連の接続設定をテストし、テスト用オブジェクトの書き込みを試み、最後にそれを読み取ります。

1. [Railsコンソール](operations/rails_console.md)を起動します。
1. 次の例の形式で、`/etc/gitlab/gitlab.rb`で設定したのと同じパラメーターを使用して、オブジェクトストレージ接続を設定します。

   アクセスキーを使用した接続の例:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       region: 'eu-central-1',
       aws_access_key_id: '<AWS_ACCESS_KEY_ID>',
       aws_secret_access_key: '<AWS_SECRET_ACCESS_KEY>'
     }
   )
   ```

   AWS IAMプロファイルを使用した接続の例:

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       use_iam_profile: true,
       region: 'us-east-1'
     }
   )
   ```

1. テスト対象のバケット名を指定し、テスト用ファイルに書き込み、最後に読み取ります。

   ```ruby
   dir = connection.directories.new(key: '<bucket-name-here>')
   f = dir.files.create(key: 'test.txt', body: 'test')
   pp f
   pp dir.files.head('test.txt')
   ```
