---
stage: GitLab Dedicated
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: オフライン転送を使用してグループとプロジェクトを移行する
description: "オブジェクトストレージを介してGitLabのグループとプロジェクトを移行します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.3で`offline_transfer_exports`、`offline_transfer_imports`、`offline_transfer_ui`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[実験的機能](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/8985)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用は機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

オフライン転送は、ソースインスタンスとデスティネーションインスタンス間の直接のネットワーク接続なしに、オブジェクトストレージを介してGitLabのグループとプロジェクトをインスタンス間でコピーします。ソースインスタンスはデータをストレージバケットにエクスポートし、デスティネーションインスタンスは読み取り可能なバケットからデータをインポートします。

デスティネーションインスタンスがソースインスタンスに接続する必要がある[直接転送による移行](../../group/import/direct_transfer_migrations.md)とは異なり、オフライン転送はエクスポートとインポートを分離します。エクスポートバケットとインポートバケットは、同じバケットである必要はなく、同じオブジェクトストレージプロバイダーを使用する必要もありません。デスティネーションインスタンスがエクスポートバケットにアクセスできない場合は、エクスポートファイルをデスティネーションがアクセスできるバケットに移動してください。GitLabはこれらのファイルを移動しません。

オフライン転送は、機能フラグとアプリケーション設定の両方によってゲートされています。これらはすべてデフォルトでオフになっており、特定の操作には両方のレイヤーをオンにする必要があります:

- エクスポート: `offline_transfer_exports_enabled`アプリケーション設定。
- インポート: `offline_transfer_imports_enabled`アプリケーション設定。

エクスポートとインポートを実行するには、[オフライン転送REST API](https://api.gitlab.com/rest/#tag/offline-transfers)を使用します。GitLab UIでのオフライン転送のサポートは、[作業アイテム19870](https://gitlab.com/groups/gitlab-org/-/work_items/19870)で提案されています。

## バージョンの要件 {#version-requirements}

オフライン転送エクスポートを作成するには、ソースインスタンスがGitLab 19.3以降を実行している必要があります。エクスポートをインポートするには、デスティネーションインスタンスがGitLab 19.3以降を実行している必要があります。

すべてのエクスポートは、それを作成したソースインスタンスのバージョンを記録します。そのバージョンがデスティネーションインスタンスがサポートする最小バージョンより以前の場合、インポートは`Unsupported GitLab version`エラーで失敗します。

## サポート対象のオブジェクトストレージプロバイダー {#supported-object-storage-providers}

オフライン転送は、以下のオブジェクトストレージプロバイダーをサポートしています:

| プロバイダー | 説明 |
| -------- | ----------- |
| AWS S3 | Amazon S3オブジェクトストレージ。 |
| S3互換 | MinIOおよびその他のS3互換プロバイダー。管理者が[S3互換オブジェクトストレージをオンにする](../../../administration/settings/import_and_export_settings.md#allow-s3-compatible-object-storage-for-offline-transfer)必要があります。 |
| Google Cloud Storage（サービスアカウント） | サービスアカウントJSONキーで認証されたGoogle Cloud Storage。 |
| Google Cloud Storage（HMAC） | S3相互運用性HMACキーで認証されたGoogle Cloud Storage。 |
| アプリケーションデフォルト認証情報を使用したGoogle Cloud Storage | アプリケーションデフォルト認証情報（ADC）で認証されたGoogle Cloud Storage。管理者と特定のバケットに制限されており、GitLab.comでは利用できません。詳細については、[アプリケーションデフォルト認証情報](#application-default-credentials)を参照してください。 |

### 必要な権限 {#required-permissions}

提供するオブジェクトストレージ認証情報は、以下の権限を持っている必要があります。

AWS S3の場合:

- エクスポート: `s3:PutObject`および`s3:ListBucket`
- インポート: `s3:GetObject`および`s3:ListBucket`

サービスアカウントを使用したGoogle Cloud Storageの場合:

- エクスポート: `storage.buckets.get`、`storage.objects.create`、および`storage.objects.list`
- インポート: `storage.objects.get`

ADCを使用したGoogle Cloud Storageは、指定するキーではなく、インスタンスのサービスアカウントによって保持される同じ権限を必要とします。

Google Cloud Storage HMACキーはS3相互運用性APIを介して認証するため、`storage.*`権限ではなく、上記のAWS S3権限が必要です。

他のS3互換プロバイダーの権限は、プロバイダーによって異なります。上記にリストされているAWS S3権限と同等の読み取りおよび書き込み権限でプロバイダーを設定してください。

### アプリケーションデフォルト認証情報 {#application-default-credentials}

ADCを使用したGoogle Cloud Storageは、転送を開始するユーザーとしてではなく、GitLabを実行するインスタンスのサービスアカウントとして認証します。そのサービスアカウントは通常、個々のユーザーよりも特権的であるため、GitLabはADC転送を管理者と`gitlab-offline-transfer-`で始まる名前のバケットに制限します。

管理者はインスタンスのADCもオンにする必要があります。セキュリティ上の影響と制限の全リストについては、[オフライン転送にアプリケーションデフォルト認証情報を許可する](../../../administration/settings/import_and_export_settings.md#allow-application-default-credentials-for-offline-transfer)を参照してください。

## 移行されたアイテム {#migrated-items}

オフライン転送は、直接転送による移行と同じグループおよびプロジェクトアイテムをインポートします。完全なリストについては、[移行されたグループアイテム](../../group/import/migrated_items.md#migrated-group-items)と[移行されたプロジェクトアイテム](../../group/import/migrated_items.md#migrated-project-items)を参照してください。

以下のアイテムはオフライン転送ではインポートされません:

- グループおよびプロジェクトのメンバーシップ。メンバーシップのインポートのサポートは、[作業アイテム538356](https://gitlab.com/gitlab-org/gitlab/-/work_items/538356)で提案されています。
- Wiki。Wikiのインポートのサポートは、[作業アイテム538858](https://gitlab.com/gitlab-org/gitlab/-/work_items/538858)で提案されています。
- スニペット。スニペットのインポートのサポートは、[作業アイテム538347](https://gitlab.com/gitlab-org/gitlab/-/work_items/538347)で提案されています。
- バッジ。バッジのインポートのサポートは、[作業アイテム538355](https://gitlab.com/gitlab-org/gitlab/-/work_items/538355)で提案されています。

グループをインポートすると、エクスポートに存在する場合、そのサブグループとプロジェクトは常にインポートされます。

## ユーザーコントリビュートのマッピング {#user-contribution-mapping}

オフライン転送は、デスティネーションインスタンス上に実際のユーザーを作成することはありません。代わりに、インポートされたコントリビュートは[プレースホルダーユーザー](../../import/mapping/post_migration_mapping.md#placeholder-users)にマップされます。インポートが完了したら、[プレースホルダーユーザーを](../../import/mapping/reassignment.md)デスティネーションインスタンス上のユーザーに再割り当てします。

オフライン転送はグループおよびプロジェクトのメンバーシップをインポートしないため、インポートされたグループおよびプロジェクトにメンバーを自分で追加する必要があります。

## 表示レベルのルール {#visibility-rules}

オフライン転送は、直接転送による移行と同じ表示レベルルールを適用します。詳細については、[表示レベルルール](../../group/import/_index.md#visibility-rules)を参照してください。

## グループまたはプロジェクトを移行する {#migrate-a-group-or-project}

前提条件: 

- プロジェクトをエクスポートするには、プロジェクトのメンテナーロール以上が必要です。
- グループをエクスポートするには、グループのオーナーロールが必要です。
- グループにインポートするには、デスティネーショングループのオーナーロールが必要です。
- グループをトップレベルグループとしてインポートするには、グループを作成する権限が必要です。
- アプリケーションデフォルト認証情報をエクスポートまたはインポートに使用するには、管理者アクセス権が必要です。

グループまたはプロジェクトを移行する手順:

1. ソースインスタンスで、REST APIを使用してオブジェクトストレージバケットに[オフライン転送エクスポートを作成](https://api.gitlab.com/rest/#tag/offline-transfers/POST/api/v4/offline_exports)します。
1. エクスポートが完了すると、GitLabはエクスポートプレフィックスを記載したメールを送信します。インポートを開始するにはこのプレフィックスが必要です。メールを受信しない場合、エクスポートプレフィックスはオブジェクトストレージサービスで確認できます。
1. デスティネーションインスタンスがエクスポートバケットにアクセスできない場合は、エクスポートファイルをデスティネーションがアクセスできるバケットに移動してください。
1. デスティネーションインスタンスで、バケットとエクスポートプレフィックスから[オフライン転送インポートを作成](https://api.gitlab.com/rest/#tag/offline-transfers/POST/api/v4/offline_imports)します。
1. [直接転送APIによるグループおよびプロジェクトの移行](../../../api/bulk_imports.md#retrieve-a-group-or-project-migration)でインポートを監視します。

## エクスポート全体をインポート {#import-an-entire-export}

デフォルトでは、オフライン転送インポートには、インポートするすべてのグループまたはプロジェクトとそれらを配置する場所をリストする`entities`配列が必要です。代わりに、`import_all`オブジェクトを渡すことで、エクスポート内のすべてのトップレベルグループとそのサブグループおよびプロジェクトをインポートし、デスティネーションネームスペースの下にソースインスタンスの構造を再作成できます。`entities`または`import_all`のいずれか一方のみが必要です。

エクスポート全体をインポートするには、`destination_namespace`属性を持つ`import_all`を[オフライン転送インポート作成](https://api.gitlab.com/rest/#tag/offline-transfers/POST/api/v4/offline_imports)APIに渡します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/offline_imports" \
  --data '{
    "bucket": "example-bucket",
    "export_prefix": "example-export-prefix",
    "aws_s3_configuration": {
      "aws_access_key_id": "<aws_access_key_id>",
      "aws_secret_access_key": "<aws_secret_access_key>",
      "region": "us-east-1"
    },
    "import_all": {
      "destination_namespace": "dest-group"
    }
  }'
```

`destination_namespace`を既存のグループのフルパス（例: `dest-group/subgroup`）に設定して、そのグループの下に構造を再作成します。空の文字列（`""`）に設定すると、新しいトップレベルグループとして構造が再作成されます。

インポートされるのはトップレベルグループのみです:

- エクスポートに、トップレベルグループ自体がエクスポートされていないパス（例: エクスポートに`group-a/subgroup-b`が含まれるが`group-a`は含まれない）が含まれている場合、GitLabは不足している親グループを作成する代わりにそのパスをスキップします。
- トップレベルグループのパスがデスティネーションネームスペース内の既存のグループと競合する場合、GitLabはそのグループとその下にあるすべてをスキップします。残りのエクスポートは引き続きインポートされます。
- すべてのトップレベルグループが既存のデスティネーションパスと衝突する場合、インポートは失敗します。
- エクスポートにトップレベルグループが含まれていない場合、インポートは失敗します。

[直接転送APIによるグループおよびプロジェクトの移行](../../../api/bulk_imports.md#retrieve-a-group-or-project-migration)でインポートを監視します。

## レート制限 {#rate-limits}

オフライン転送のエクスポートとインポートにはレート制限が適用されます。詳細については、[設定不可能なレート制限](../../../rate_limits/non_configurable.md)を参照してください。

## 関連トピック {#related-topics}

- [直接転送を使用してグループとプロジェクトを移行する](../../group/import/direct_transfer_migrations.md)

## トラブルシューティング {#troubleshooting}

オフライン転送を使用して実行された移行で問題が発生した場合は、考えられる解決策について以下のセクションを参照してください。

### オブジェクトストレージからエクスポートデータをクリアする {#clear-export-data-from-object-storage}

各エクスポートはオブジェクトストレージに新しいプレフィックスを生成するため、あるエクスポートが別のエクスポートを上書きすることはありません。失敗したエクスポートから保存されたデータを削除することは、エクスポートの再試行には必要ありませんが、オブジェクトストレージのコストを削減できる可能性があります。

オブジェクトストレージからエクスポートデータを削除するには、提供したバケットとエクスポートAPIから返された`export_prefix`を使用してデータを特定し、削除します。オブジェクトストレージの設定によっては、これは元に戻せない場合があります。

### インポートエラーの特定 {#identify-import-errors}

- 関連するエラーについては、`exceptions_json.log`と`importer.log`を確認してください。
- Railsコンソールからエラーを抽出する方法については、[直接転送による移行のトラブルシューティング](../../group/import/troubleshooting.md)を参照してください。

### インポートの再試行 {#retry-an-import}

インポートを再試行するには:

1. 再試行するグループまたはプロジェクトを削除します。インポート全体を再試行するか、グループまたはプロジェクトのサブセットをターゲットにすることができます:

   - [グループをすぐに削除する](../../group/_index.md#delete-a-group-immediately)
   - [プロジェクトを直ちに削除する](../../project/working_with_projects.md#delete-a-project-immediately)

1. REST APIを使用してインポート全体を再試行するか、`entities`パラメータに以前に失敗したエンティティのみを指定します。
