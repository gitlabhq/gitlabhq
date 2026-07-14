---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: "`gitlab-backup-cli` を使用したGitLabのバックアップと復元"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11908)されました。この機能は[実験的機能](../../policy/development_stages_support.md)であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。

{{< /history >}}

このツールは開発中であり、最終的には[GitLabのバックアップと復元に用いられるRakeタスク](backup_gitlab.md)を置き換えることを目的としています。このツールの開発については、以下のエピックで追跡できます: [次世代スケーラブルバックアップと復元](https://gitlab.com/groups/gitlab-org/-/epics/11577)。

このツールに関するフィードバックは、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/457155)で歓迎いたします。

## バックアップの取得 {#taking-a-backup}

現在のGitLabインスタンスのバックアップを作成するには:

```shell
sudo gitlab-backup-cli backup all
```

### オブジェクトストレージのバックアップ {#backing-up-object-storage}

Google Cloudのみがサポートされています。ベンダーを追加する計画については、[エピック11577](https://gitlab.com/groups/gitlab-org/-/epics/11577)を参照してください。

#### GCP {#gcp}

`gitlab-backup-cli`は、Google Cloud [Storage Transfer Service](https://cloud.google.com/storage-transfer-service/)を使用してジョブを作成および実行し、GitLabデータを別のバックアップバケットにコピーします。

前提条件: 

- サービスアカウントを使用して認証するには、[サービスアカウントの概要](https://cloud.google.com/iam/docs/service-account-overview)を確認してください。
- このドキュメントでは、バックアップ管理専用のGoogle Cloudサービスアカウントをセットアップして使用することを前提としています。
- 他の認証情報が提供されておらず、Google Cloud内で実行している場合、ツールはそれが実行されているインフラストラクチャのアクセスを使用しようとします。[セキュリティ上の理由](#security-considerations)から、個別の認証情報を使用してツールを実行し、作成されたバックアップへのアプリケーションからのアクセスを制限する必要があります。

バックアップを作成するには:

1. [ロールの作成](https://cloud.google.com/iam/docs/creating-custom-roles):
   1. `role.yaml`ファイルに以下の定義を作成します:

   ```yaml
   ---
   description: Role for backing up GitLab object storage
   includedPermissions:
      - storagetransfer.jobs.create
      - storagetransfer.jobs.get
      - storagetransfer.jobs.run
      - storagetransfer.jobs.update
      - storagetransfer.operations.get
      - storagetransfer.projects.getServiceAccount
   stage: GA
   title: GitLab Backup Role
   ```

   1. ロールを適用します:

      ```shell
      gcloud iam roles create --project=<YOUR_PROJECT_ID> <ROLE_NAME> --file=role.yaml
      ```

1. バックアップ用のサービスアカウントを作成し、ロールに追加します:

   ```shell
   gcloud iam service-accounts create "gitlab-backup-cli" --display-name="GitLab Backup Service Account"
   # Get the service account email from the output of the following
   gcloud iam service-accounts list
   # Add the account to the role created previously
   gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> --member="serviceAccount:<SERVICE_ACCOUNT_EMAIL>" --role="roles/<ROLE_NAME>"
   ```

1. サービスアカウントを使用して認証するには、[サービスアカウントの認証情報](https://cloud.google.com/iam/docs/service-account-overview#credentials)を参照してください。認証情報はファイルに保存するか、事前定義された環境変数に格納できます。
1. [Google Cloud Storage](https://cloud.google.com/storage/)にバックアップするための宛先バケットを作成します。ここでのオプションは、要件に大きく依存します。
1. バックアップを実行します:

   ```shell
   sudo gitlab-backup-cli backup all --backup-bucket=<BUCKET_NAME>
   ```

   コンテナレジストリバケットをバックアップする場合は、オプション`--registry-bucket=<REGISTRY_BUCKET_NAME>`を追加します。
1. バックアップは、バケット内の各オブジェクトストレージタイプについて、`backups/<BACKUP_ID>/<BUCKET>`の下にバックアップを作成します。

## バックアップディレクトリの構造 {#backup-directory-structure}

バックアップディレクトリ構造の例:

```plaintext
backups
└── 1714053314_2024_04_25_17.0.0-pre
    ├── artifacts.tar.gz
    ├── backup_information.json
    ├── builds.tar.gz
    ├── ci_secure_files.tar.gz
    ├── db
    │   ├── ci_database.sql.gz
    │   └── database.sql.gz
    ├── lfs.tar.gz
    ├── packages.tar.gz
    ├── pages.tar.gz
    ├── registry.tar.gz
    ├── repositories
    │   ├── default
    │   │   ├── @hashed
    │   │   └── @snippets
    │   └── manifests
    │       └── default
    ├── terraform_state.tar.gz
    └── uploads.tar.gz
```

`db`ディレクトリは、GitLab PostgreSQLデータベースを`pg_dump`を使用して[SQLダンプ](https://www.postgresql.org/docs/16/backup-dump.html)を作成し、バックアップするために使用されます。`pg_dump`の出力は、圧縮されたSQLファイルを作成するために`gzip`を介してパイプされます。

`repositories`ディレクトリは、GitLabデータベースにあるGitリポジトリをバックアップするために使用されます。

## バックアップID {#backup-id}

バックアップIDは、個々のバックアップを識別します。GitLabを復元する必要があり、複数のバックアップが利用可能な場合は、バックアップアーカイブのバックアップIDが必要です。

バックアップは、`config/gitlab.yml`ファイルで指定されている`backup_path`に設定されたディレクトリに保存されます。

- デフォルトでは、バックアップは`/var/opt/gitlab/backups`に保存されます。
- デフォルトでは、バックアップディレクトリは`backup_id`という名前で、`<backup-id>`はバックアップが作成された時刻とGitLabバージョンを識別します。

たとえば、バックアップディレクトリ名が`1714053314_2024_04_25_17.0.0-pre`の場合、作成時刻は`1714053314_2024_04_25`で表され、GitLabバージョンは17.0.0-preです。

## バックアップメタデータファイル (`backup_information.json`) {#backup-metadata-file-backup_informationjson}

{{< history >}}

- メタデータバージョン2は、[GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149441)で導入されました。

{{< /history >}}

`backup_information.json`はバックアップディレクトリにあり、バックアップに関するメタデータを格納します。例: 

```json
{
  "metadata_version": 2,
  "backup_id": "1714053314_2024_04_25_17.0.0-pre",
  "created_at": "2024-04-25T13:55:14Z",
  "gitlab_version": "17.0.0-pre"
}
```

## バックアップを復元する {#restore-a-backup}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/469247)されました。

{{< /history >}}

前提条件: 

- `gitlab-backup-cli`を使用して作成されたバックアップのIDが必要です。

現在のGitLabインスタンスのバックアップを復元するには:

- 次のコマンドを実行します:

  ```shell
  sudo gitlab-backup-cli restore all <backup_id>
  ```

### オブジェクトストレージデータの復元 {#restore-object-storage-data}

Google Cloud Storageからデータを復元することができます。[エピック11577](https://gitlab.com/groups/gitlab-org/-/epics/11577)は、他のベンダーのサポートを追加することを提案しています。

前提条件: 

- `gitlab-backup-cli`を使用して作成されたバックアップのIDが必要です。
- 復元する場所に必要な権限を設定しました。
- オブジェクトストレージの設定ファイル`gitlab.rb`または`gitlab.yml`を設定し、バックアップ環境と一致させました。
- ステージング環境で復元するプロセスをテストしました。

オブジェクトストレージデータを復元するには:

- 次のコマンドを実行します:

  ```shell
  sudo gitlab-backup restore <backup_id>
  ```

復元するプロセス:

- 最初に宛先バケットをクリアしません。
- 宛先バケット内の既存のファイルを同じファイル名で上書きします。
- 復元されるデータの量によっては、かなりの時間がかかる場合があります。

復元する中は常にシステムリソースを監視してください。復元するが成功したことを確認するまで、元のファイルを保持してください。

## 既知の問題 {#known-issues}

`gitlab-backup-cli`を使用する場合、次のイシューに遭遇する可能性があります。

### アーキテクチャの互換性 {#architecture-compatibility}

[1Kアーキテクチャ](../reference_architectures/1k_users.md)以外のアーキテクチャで`gitlab-backup-cli`ツールを使用すると、イシューが発生する可能性があります。このツールは1Kアーキテクチャのみでサポートされており、関連する環境でのみ推奨されます。

### バックアップ戦略 {#backup-strategy}

バックアップ中に既存のファイルに変更を加えると、GitLabインスタンスでイシューが発生する可能性があります。このイシューは、ツールの初期バージョンが[コピー戦略](backup_gitlab.md#backup-strategy-option)を使用しないために発生します。

このイシューの回避策は、次のいずれかです:

- GitLabインスタンスを[メンテナンスモード](../maintenance_mode/_index.md)に移行します。
- バックアップ中にサーバーへのトラフィックを制限して、インスタンスリソースを保持します。

コピー戦略の代替案を調査中です。[イシュー428520](https://gitlab.com/gitlab-org/gitlab/-/issues/428520)を参照してください。

## どのようなデータがバックアップされますか？ {#what-data-is-backed-up}

1. Gitリポジトリデータ
1. データベース
1. blob

## どのようなデータがバックアップされませんか？ {#what-data-is-not-backed-up}

1. シークレットと設定

   - [シークレットと設定のバックアップ](backup_gitlab.md#storing-configuration-files)方法に関するドキュメントに従ってください。

1. 一時的なデータとキャッシュデータ

   - Redis: キャッシュ
   - Redis: Sidekiqデータ
   - ログ
   - Elasticsearch
   - 可観測性データ / Prometheusメトリクス

## セキュリティに関する考慮事項 {#security-considerations}

同じ認証情報を使用する代わりに、バックアップを実行するために必要な最小限の権限のみを持つ個別のユーザーアカウントを作成する必要があります。アプリケーションと同じ認証情報でバックアップを実行することは、いくつかの理由からセキュリティ上の好ましくない慣行です:

- 最小特権の原則 - バックアッププロセスには、通常のアプリケーション操作に必要なものよりも広範な権限（すべてのデータへの読み取りアクセスなど）が必要です。ユーザーまたはプロセスは、その機能を実行するために必要な最小限のアクセス権を持つ必要があります。
- 侵害のリスク - アプリケーションの認証情報が侵害された場合、攻撃者はアプリケーションとそのすべてのバックアップデータにアクセスできるようになり、履歴データも公開されます。
- 職務分離 - バックアップとアプリケーションで個別の認証情報を使用することで、職務分離を維持するのに役立ちます。この分離により、単一の侵害されたアカウントが広範囲にわたる損害を引き起こすことをより困難にします。
- 監査証跡 - バックアップに個別の認証情報を使用することで、通常のアプリケーション操作とは独立してバックアップアクティビティを追跡するおよび監査することが容易になります。
- 細かいアクセス制御 - 異なる認証情報により、より細かいアクセス制御が可能になります。バックアップ認証情報にはデータへの読み取り専用アクセス権を付与でき、アプリケーションの認証情報には特定のテーブルまたはスキーマへの読み書きアクセス権が必要になる場合があります。
- コンプライアンス要件 - 多くの規制基準およびコンプライアンスフレームワーク（GDPR、HIPAA、PCI DSSなど）は、職務分離とアクセス制御を要求または強く推奨しており、これらは個別の認証情報を使用することで達成しやすくなります。
- ライフサイクルの管理が容易 - アプリケーションとバックアッププロセスは異なるライフサイクルを持つ場合があります。個別の認証情報を使用することで、これらのライフサイクルを独立して管理することが容易になります。たとえば、他のプロセスに影響を与えることなく認証情報をローテーションまたは失効することができます。
- アプリケーションの脆弱性に対する保護 - アプリケーションにSQLインジェクションまたは他の形式の不正なデータアクセスを許す脆弱性がある場合、個別のバックアップ認証情報を使用することで、バックアッププロセスに追加の保護層が追加されます。
