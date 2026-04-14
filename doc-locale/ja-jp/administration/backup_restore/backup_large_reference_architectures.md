---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 大規模リファレンスアーキテクチャをバックアップおよび復元する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabのバックアップは、大規模なGitLabのデプロイにおけるデータの一貫性を保ち、ディザスターリカバリーを可能にします。このプロセス:

- 分散ストレージコンポーネント全体でデータバックアップを調整します。
- 数テラバイトまでのPostgreSQLデータベースを保持します。
- 外部サービスでオブジェクトストレージデータを保護します。
- 大規模なGitリポジトリコレクションのバックアップの整合性を維持します。
- 設定ファイルとシークレットファイルの復元可能なコピーを作成します。
- システムデータを最小限のダウンタイムで復元できるようにします。

3,000人以上のユーザーをサポートするリファレンスアーキテクチャを実行しているGitLab環境向けの以下の手順に従ってください。クラウドベースのデータベースとオブジェクトストレージに関する特別な考慮事項を含みます。

> [!note]
> このドキュメントは、以下の環境で使用することを想定しています:
>
> - [Linuxパッケージ（Omnibus）とクラウドネイティブハイブリッドリファレンスアーキテクチャ（60 RPS / 3,000ユーザー以上）](../reference_architectures/_index.md)
> - [RDS](https://aws.amazon.com/rds/)（PostgreSQLデータベース用）
> - [S3](https://aws.amazon.com/s3/)（オブジェクトストレージ用）
> - [オブジェクトストレージ](../object_storage.md) （[blob](backup_gitlab.md#blobs)やコンテナ[レジストリ](backup_gitlab.md#container-registry)を含む、可能な限りのすべてを保存するため）

## 毎日のバックアップを設定する {#configure-daily-backups}

### PostgreSQLデータベースのバックアップを設定する {#configure-backup-of-postgresql-data}

The [バックアップコマンド](backup_gitlab.md)は`pg_dump`を使用しますが、これは[100 GBを超えるデータベースには適していません](backup_gitlab.md#postgresql-databases)。ネイティブで堅牢なバックアップ機能を備えたPostgreSQLソリューションを選択する必要があります。

{{< tabs >}}

{{< tab title="AWS" >}}

1. [AWS Backupを設定](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html)して、RDS（およびS3）データをバックアップします。保護を最大限にするため、[継続的なバックアップとスナップショットのバックアップを設定](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html)します。
1. AWS Backupを設定して、バックアップを別のリージョンにコピーします。AWSがバックアップを取得すると、そのバックアップは保存されたリージョンでのみ復元することができます。
1. AWS Backupが少なくとも1回スケジュールされたバックアップを実行した後、必要に応じて[オンデマンドバックアップを作成](https://docs.aws.amazon.com/aws-backup/latest/devguide/recov-point-create-on-demand-backup.html)できます。

{{< /tab >}}

{{< tab title="Google" >}}

Schedule [Google Cloud SQLデータの自動デイリーバックアップをスケジュール](https://cloud.google.com/sql/docs/postgres/backup-recovery/backing-up#schedulebackups)します。毎日のバックアップは最長1年間[保持](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#retention)でき、トランザクションログは、ポイントインタイムリカバリーのためにデフォルトで7日間保持できます。

{{< /tab >}}

{{< /tabs >}}

### オブジェクトストレージデータのバックアップを設定する {#configure-backup-of-object-storage-data}

[オブジェクトストレージ](../object_storage.md) （[NFSではない](../nfs.md) ）は、[blob](backup_gitlab.md#blobs)やコンテナ[レジストリ](backup_gitlab.md#container-registry)を含むGitLabデータの保存に推奨されます。

{{< tabs >}}

{{< tab title="AWS" >}}

AWS Backupを設定して、S3データをバックアップします。これは、[PostgreSQLデータベースのバックアップを設定](#configure-backup-of-postgresql-data)するときと同時に行うことができます。

{{< /tab >}}

{{< tab title="Google" >}}

1. [GCSにバックアップバケットを作成](https://cloud.google.com/storage/docs/creating-buckets)します。
1. 各GitLabオブジェクトストレージバケットをバックアップバケットにコピーする[Storage Transfer Serviceジョブを作成](https://cloud.google.com/storage-transfer/docs/create-transfers)します。これらのジョブは一度作成すれば、[毎日実行するようにスケジュール](https://cloud.google.com/storage-transfer/docs/schedule-transfer-jobs)できます。ただし、これでは新しいオブジェクトストレージデータと古いデータが混ざり合い、GitLabで削除されたファイルもバックアップに残ることになります。これは復元する後にストレージを無駄にしますが、それ以外は問題ありません。これらのファイルはGitLabデータベースに存在しないため、GitLabユーザーにはアクセスできません。復元する後に[これらの孤立したファイルの一部を削除](../raketasks/cleanup.md#clean-up-project-upload-files-from-object-storage)できますが、このクリーンアップRakeタスクはファイルの一部のみを操作します。
   1. `When to overwrite`には`Never`を選択します。GitLabのオブジェクトストレージに保存されたファイルは、イミュータブルであるように設計されています。この選択は、悪意のあるアクターがGitLabファイルの改ざんに成功した場合に役立つ可能性があります。
   1. `When to delete`には`Never`を選択します。バックアップバケットをソースに同期すると、ファイルが誤ってまたは悪意を持ってソースから削除された場合にリカバリーできません。
1. あるいは、オブジェクトストレージを日ごとに分離されたバケットまたはサブディレクトリにバックアップすることも可能です。これにより、復元する後の孤立したファイルの問題を回避し、必要に応じてファイルバージョンのバックアップをサポートします。しかし、バックアップストレージのコストが大幅に増加します。これは、[Cloud SchedulerによってトリガーされるCloud Function](https://cloud.google.com/scheduler/docs/tut-gcf-pub-sub)を使用するか、cronjobによって実行されるスクリプトを使用することで実現できます。部分的な例:

   ```shell
   # Set GCP project so you don't have to specify it in every command
   gcloud config set project example-gcp-project-name

   # Grant the Storage Transfer Service's hidden service account permission to write to the backup bucket. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.objectAdmin gs://backup-bucket

   # Grant the Storage Transfer Service's hidden service account permission to list and read objects in the source buckets. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-artifacts
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-ci-secure-files
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-dependency-proxy
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-lfs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-mr-diffs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-packages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-pages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-registry
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-terraform-state
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-uploads

   # Create transfer jobs for each bucket, targeting a subdirectory in the backup bucket.
   today=$(date +%F)
   gcloud transfer jobs create gs://gitlab-bucket-artifacts/ gs://backup-bucket/$today/artifacts/ --name "$today-backup-artifacts"
   gcloud transfer jobs create gs://gitlab-bucket-ci-secure-files/ gs://backup-bucket/$today/ci-secure-files/ --name "$today-backup-ci-secure-files"
   gcloud transfer jobs create gs://gitlab-bucket-dependency-proxy/ gs://backup-bucket/$today/dependency-proxy/ --name "$today-backup-dependency-proxy"
   gcloud transfer jobs create gs://gitlab-bucket-lfs/ gs://backup-bucket/$today/lfs/ --name "$today-backup-lfs"
   gcloud transfer jobs create gs://gitlab-bucket-mr-diffs/ gs://backup-bucket/$today/mr-diffs/ --name "$today-backup-mr-diffs"
   gcloud transfer jobs create gs://gitlab-bucket-packages/ gs://backup-bucket/$today/packages/ --name "$today-backup-packages"
   gcloud transfer jobs create gs://gitlab-bucket-pages/ gs://backup-bucket/$today/pages/ --name "$today-backup-pages"
   gcloud transfer jobs create gs://gitlab-bucket-registry/ gs://backup-bucket/$today/registry/ --name "$today-backup-registry"
   gcloud transfer jobs create gs://gitlab-bucket-terraform-state/ gs://backup-bucket/$today/terraform-state/ --name "$today-backup-terraform-state"
   gcloud transfer jobs create gs://gitlab-bucket-uploads/ gs://backup-bucket/$today/uploads/ --name "$today-backup-uploads"
   ```

   1. これらのTransferジョブは、実行後に自動的に削除されません。スクリプトで古いジョブのクリーンアップを実装できます。
   1. サンプルスクリプトは古いバックアップを削除しません。必要に応じて、目的の保持ポリシーに従って古いバックアップのクリーンアップを実装できます。
1. データの一貫性の低下を避けるため、バックアップがCloud SQLバックアップと同時またはそれ以降に実行されるようにしてください。

{{< /tab >}}

{{< /tabs >}}

### Gitリポジトリのバックアップを設定する {#configure-backup-of-git-repositories}

Gitalyサーバーサイドバックアップを実行するようにcronjobを設定します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. [サーバーサイドバックアップを設定](../gitaly/configure_gitaly.md#configure-server-side-backups)する手順に従い、すべてのGitalyノードでGitalyサーバーサイドバックアップの保存先を設定します。このバケットは、Gitalyがリポジトリデータを保存するために排他的に使用されます。
1. Gitalyが、以前に設定された指定のオブジェクトストレージバケット内のすべてのGitリポジトリデータをバックアップする一方で、バックアップユーティリティツール（`gitlab-backup`）は追加のバックアップデータをアップロードします。このデータには、復元するための重要なメタデータを含む`tar`ファイルが含まれます。他のバックアップと同じバケットを使用することも、別のバケットを使用することもできます。このバックアップデータが適切にリモートストレージ（クラウド）にアップロードされるようにするには、[バックアップをリモートストレージ（クラウド）にアップロード](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage)の手順に従ってアップロードバケットを設定してください。
1. （オプション）このバックアップデータの耐久性を強化するには、以前に設定したすべてのバケットを、それぞれのオブジェクトストレージプロバイダで、[オブジェクトストレージデータのバックアップ](#configure-backup-of-object-storage-data)に追加してバックアップします。
1. PumaまたはSidekiqを実行しているGitLab RailsノードにSSH接続します。
1. Gitデータの完全なバックアップを作成します。`REPOSITORIES_SERVER_SIDE`変数を使用し、PostgreSQLデータをスキップします:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db
   ```

   これにより、GitalyノードはGitデータと一部のメタデータをリモートストレージにアップロードします。アップロード、アーティファクト、LFSなどのblobは明示的にスキップする必要はありません。`gitlab-backup`コマンドはデフォルトでオブジェクトストレージをバックアップしないためです。

1. 次のステップで必要となるバックアップの[バックアップID](backup_archive_process.md#backup-id)をメモしてください。例えば、バックアップコマンドが`2024-02-22 02:17:47 UTC -- Backup 1708568263_2024_02_22_16.9.0-ce is done.`と出力した場合、バックアップIDは`1708568263_2024_02_22_16.9.0-ce`です。
1. 完全なバックアップが、Gitalyバックアップバケットと通常のバックアップバケットの両方にデータを作成したことを確認します。
1. 再度[バックアップコマンド](backup_gitlab.md#backup-command)を実行し、今回は[Gitリポジトリの増分バックアップ](backup_gitlab.md#incremental-repository-backups)とバックアップIDを指定します。前のステップの例のIDを使用すると、コマンドは次のようになります:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce
   ```

   `PREVIOUS_BACKUP`の値はこのコマンドでは使用されませんが、コマンドで必須です。この不要な要件を削除するための[イシュー429141](https://gitlab.com/gitlab-org/gitlab/-/issues/429141)があります。

1. 増分バックアップが成功し、オブジェクトストレージにデータが追加されたことを確認します。
1. [cronを設定して毎日バックアップを作成](backup_gitlab.md#configuring-cron-to-make-daily-backups)します。`root`ユーザーのcrontabを編集します。

   ```shell
   sudo su -
   crontab -e
   ```

1. そこで、毎月毎日午前2時にバックアップをスケジュールするために、以下の行を追加します。バックアップを復元するのに必要な増分数を制限するため、毎月1日にGitリポジトリの完全なバックアップが取得され、残りの日は増分バックアップが取得されます:

   ```plaintext
   0 2 1 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db CRON=1
   0 2 2-31 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce CRON=1
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [サーバーサイドバックアップを設定](../gitaly/configure_gitaly.md#configure-server-side-backups)する手順に従い、すべてのGitalyノードでGitalyサーバーサイドバックアップの保存先を設定します。このバケットは、Gitalyがリポジトリデータを保存するために排他的に使用されます。
1. Gitalyが、以前に設定された指定のオブジェクトストレージバケット内のすべてのGitリポジトリデータをバックアップする一方で、バックアップユーティリティツール（`gitlab-backup`）は追加のバックアップデータをアップロードします。このデータには、復元するための重要なメタデータを含む`tar`ファイルが含まれます。他のバックアップと同じバケットを使用することも、別のバケットを使用することもできます。このバックアップデータが適切にリモートストレージ（クラウド）にアップロードされるようにするには、[バックアップをリモートストレージ（クラウド）にアップロード](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage)の手順に従ってアップロードバケットを設定してください。
1. （オプション）このバックアップデータの耐久性を強化するには、以前に設定したすべてのバケットを、それぞれのオブジェクトストレージプロバイダで、[オブジェクトストレージデータのバックアップ](#configure-backup-of-object-storage-data)に追加してバックアップします。
1. PumaまたはSidekiqを実行しているGitLab RailsノードにSSH接続します。
1. Gitデータの完全なバックアップを作成します。`REPOSITORIES_SERVER_SIDE`変数を使用し、他のすべてのデータをスキップします:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   これにより、GitalyノードはGitデータと一部のメタデータをリモートストレージにアップロードします。[Toolboxに含まれるツール](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#toolbox-included-tools)を参照してください。

1. 完全なバックアップが、Gitalyバックアップバケットと通常のバックアップバケットの両方にデータを作成したことを確認します。サーバーサイドリポジトリバックアップでは`backup-utility`による増分リポジトリバックアップはサポートされていません。[チャートイシュー3421](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3421)を参照してください。
1. [cronを設定して毎日バックアップを作成](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup)します。具体的には、`gitlab.toolbox.backups.cron.extraArgs`を次のように設定します:

   ```shell
   --repositories-server-side --skip db --skip repositories --skip uploads --skip builds --skip artifacts --skip pages --skip lfs --skip terraform_state --skip registry --skip packages --skip ci_secure_files
   ```

{{< /tab >}}

{{< /tabs >}}

### 設定ファイルのバックアップを設定する {#configure-backup-of-configuration-files}

設定とシークレットがデプロイメントの外部で定義され、その後デプロイされる場合、バックアップ戦略の実装は特定のセットアップと要件に依存します。例として、[AWS Secret Manager](https://aws.amazon.com/secrets-manager/)にシークレットを保存し、[複数リージョンへのレプリケーション](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html)を設定して、スクリプトでシークレットを自動的にバックアップできます。

設定とシークレットがデプロイ内部でのみ定義されている場合:

1. [設定ファイルの保存](backup_gitlab.md#storing-configuration-files)では、設定ファイルとシークレットファイルを抽出する方法について説明します。
1. これらのファイルは、より制限の厳しい別のオブジェクトストレージアカウントにアップロードする必要があります。

## バックアップを復元する {#restore-a-backup}

GitLabインスタンスのバックアップを復元する。

### 前提条件 {#prerequisites}

バックアップを復元する前に:

1. [動作するターゲットGitLabインスタンス](restore_gitlab.md#the-destination-gitlab-instance-must-already-be-working)を選択します。
1. ターゲットGitLabインスタンスが、AWSバックアップが保存されているリージョンにあることを確認してください。
1. バックアップデータが作成された[ターゲットGitLabインスタンスが、まったく同じバージョンとタイプ（CEまたはEE）のGitLabを使用している](restore_gitlab.md#the-destination-gitlab-instance-must-have-the-exact-same-version)ことを確認してください。たとえば、CE 15.1.4などです。
1. [バックアップされたシークレットをターゲットGitLabインスタンスに復元する](restore_gitlab.md#gitlab-secrets-must-be-restored)。
1. [ターゲットGitLabインスタンスに同じリポジトリストレージが設定されている](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment)ことを確認してください。追加のストレージがあっても問題ありません。
1. [オブジェクトストレージが設定されている](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment)ことを確認してください。
1. 新しいシークレットや設定を使用し、復元する中の予期せぬ設定変更を回避するには:

   - すべてのノードでのLinuxパッケージインストール:
     1. ターゲットGitLabインスタンスを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
     1. ターゲットGitLabインスタンスを[再起動](../restart_gitlab.md#restart-a-linux-package-installation)します。

   - Helmチャート（Kubernetes）インストール:

     1. すべてのGitLab Linuxパッケージノードで、以下を実行します:

        ```shell
        sudo gitlab-ctl reconfigure
        sudo gitlab-ctl start
        ```

     1. チャートをデプロイして、GitLabインスタンスが稼働していることを確認してください。以下のコマンドを実行して、Toolboxポッドが有効かつ稼働していることを確認してください:

        ```shell
        kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
        ```

     1. Webservice、Sidekiq、およびToolboxポッドは再起動する必要があります。これらのポッドを再起動する最も安全な方法は、以下を実行することです:

        ```shell
        kubectl delete pods -lapp=sidekiq,release=<helm release name>
        kubectl delete pods -lapp=webservice,release=<helm release name>
        kubectl delete pods -lapp=toolbox,release=<helm release name>
        ```

1. ターゲットGitLabインスタンスがまだ動作していることを確認します。例: 

   - [ヘルスチェックエンドポイント](../monitoring/health_check.md)へのリクエストを行います。
   - [GitLabチェックRakeタスクを実行](../raketasks/maintenance.md#check-gitlab-configuration)します。

1. PostgreSQLデータベースに接続するGitLabサービスを停止します。

   - PumaまたはSidekiqを実行しているすべてのノードでのLinuxパッケージインストールで、以下を実行します:

     ```shell
     sudo gitlab-ctl stop
     ```

   - Helmチャート（Kubernetes）インストール:

     1. 以降の再起動のために、データベースクライアントの現在のレプリカ数をメモします:

        ```shell
        kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        ```

     1. 復元するプロセスにロックが干渉するのを防ぐため、データベースのクライアントを停止します:

        ```shell
        kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
        ```

### オブジェクトストレージデータを復元する {#restore-object-storage-data}

{{< tabs >}}

{{< tab title="AWS" >}}

各バケットはAWS内で個別のバックアップとして存在し、各バックアップは既存または新しいバケットに復元することができます。

1. バケットを復元するには、正しい権限を持つIAMロールが必要です:

   - `AWSBackupServiceRolePolicyForBackup`
   - `AWSBackupServiceRolePolicyForRestores`
   - `AWSBackupServiceRolePolicyForS3Restore`
   - `AWSBackupServiceRolePolicyForS3Backup`

1. 既存のバケットを使用している場合、それらには[アクセス制御リストが有効](https://docs.aws.amazon.com/AmazonS3/latest/userguide/managing-acls.html)になっている必要があります。
1. [組み込みのツールを使用してS3バケットを復元する](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-s3.html)。
1. 復元するジョブが実行されている間に、[PostgreSQLデータベースデータの復元する](#restore-postgresql-data)に進むことができます。

{{< /tab >}}

{{< tab title="Google" >}}

1. [Storage Transfer Serviceジョブを作成](https://cloud.google.com/storage-transfer/docs/create-transfers)し、バックアップされたデータをGitLabバケットに転送します。
1. 転送ジョブが実行されている間に、[PostgreSQLデータベースデータの復元する](#restore-postgresql-data)に進むことができます。

{{< /tab >}}

{{< /tabs >}}

### PostgreSQLデータベースデータを復元する {#restore-postgresql-data}

{{< tabs >}}

{{< tab title="AWS" >}}

1. [組み込みのツールを使用してAWSRDSデータベースを復元する](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html)と、新しいRDSインスタンスが作成されます。
1. 新しいRDSインスタンスは異なるエンドポイントを持つため、ターゲットGitLabインスタンスを再設定して新しいデータベースを指すようにする必要があります:

   - Linuxパッケージインストールの場合は、[パッケージ化されていないPostgreSQLデータベース管理サーバーの使用](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server)に従ってください。

   - Helmチャート（Kubernetes）インストールの場合は、[外部データベースでのGitLabチャートの設定](https://docs.gitlab.com/charts/advanced/external-db/)に従ってください。

1. 次に進む前に、新しいRDSインスタンスが作成され、使用可能になるまで待機します。

{{< /tab >}}

{{< tab title="Google" >}}

1. [組み込みのツールを使用してGoogle Cloud SQLデータベースを復元する](https://cloud.google.com/sql/docs/postgres/backup-recovery/restoring)。
1. 新しいデータベースインスタンスに復元する場合、GitLabを再設定して新しいデータベースを指すようにします:

   - Linuxパッケージインストールの場合は、[パッケージ化されていないPostgreSQLデータベース管理サーバーの使用](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server)に従ってください。

   - Helmチャート（Kubernetes）インストールの場合は、[外部データベースでのGitLabチャートの設定](https://docs.gitlab.com/charts/advanced/external-db/)に従ってください。

1. 次に進む前に、Cloud SQLインスタンスが使用可能になるまで待機します。

{{< /tab >}}

{{< /tabs >}}

### Gitリポジトリを復元する {#restore-git-repositories}

まず、[オブジェクトストレージデータの復元する](#restore-object-storage-data)の一部として、すでに以下を完了している必要があります:

- GitalyサーバーサイドバックアップのGitリポジトリを含むバケットを復元する。
- `*_gitlab_backup.tar`ファイルを含むバケットを復元する。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. PumaまたはSidekiqを実行しているGitLab RailsノードにSSH接続します。
1. バックアップバケット内で、復元するしたPostgreSQLおよびオブジェクトストレージデータと整合するタイムスタンプに基づいて`*_gitlab_backup.tar`ファイルを選択します。
1. `/var/opt/gitlab/backups/`に`tar`ファイルをダウンロードします。
1. 復元するするバックアップのIDを指定し、名前から`_gitlab_backup.tar`を省略してバックアップを復元するします:

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce SKIP=db
   ```

   バックアップtarファイルとインストールされているGitLabのバージョンとの間に不一致がある場合、復元するコマンドはエラーメッセージを出して中断します。[正しいバージョンのGitLab](https://packages.gitlab.com/gitlab/)をインストールしてから、再度試してください。

1. GitLabを再設定し、開始して[確認](../raketasks/maintenance.md#check-gitlab-configuration)します:

   1. すべてのPostgreSQLノードで、以下を実行します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. すべてのPumaまたはSidekiqノードで、以下を実行します:

      ```shell
      sudo gitlab-ctl start
      ```

   1. 1つのPumaまたはSidekiqノードで、以下を実行します:

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. 特に`/etc/gitlab/gitlab-secrets.json`が復元するされた場合、または異なるサーバーが復元するのターゲットである場合に、[データベース値が復号化するできる](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)ことを確認します:

   PumaまたはSidekiqノードで、以下を実行します:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. さらに確実性を高めるため、[アップロードされたファイルの整合性チェック](../raketasks/check.md#uploaded-files-integrity)を実行できます。

   PumaまたはSidekiqノードで、以下を実行します:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   不足または破損したファイルが見つかっても、必ずしもバックアップと復元するプロセスが失敗したことを意味するわけではありません。例えば、ソースのGitLabインスタンスでファイルが見つからないか破損している可能性があります。以前のバックアップと相互参照する必要があるかもしれません。GitLabを新しい環境に移行する場合、ソースのGitLabインスタンスで同じチェックを実行して、整合性チェックの結果が以前から存在するものなのか、それともバックアップと復元するプロセスに関連するものなのかを判断できます。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. ToolboxポッドにSSH接続します。
1. バックアップバケット内で、復元するしたPostgreSQLおよびオブジェクトストレージデータと整合するタイムスタンプに基づいて`*_gitlab_backup.tar`ファイルを選択します。
1. `/var/opt/gitlab/backups/`に`tar`ファイルをダウンロードします。
1. 復元するするバックアップのIDを指定し、名前から`_gitlab_backup.tar`を省略してバックアップを復元するします:

   ```shell
   # This command will overwrite the contents of Gitaly!
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t 11493107454_2018_04_25_10.6.4-ce --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   バックアップtarファイルとインストールされているGitLabのバージョンとの間に不一致がある場合、復元するコマンドはエラーメッセージを出して中断します。[正しいバージョンのGitLab](https://packages.gitlab.com/gitlab/)をインストールしてから、再度試してください。

1. GitLabを再起動して[確認](../raketasks/maintenance.md#check-gitlab-configuration)します:

   1. [前提条件](#prerequisites)に記載されているレプリカ数を使用して、停止しているデプロイを開始します:

      ```shell
      kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<original value>
      ```

   1. Toolboxポッドで、以下を実行します:

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. 特に`/etc/gitlab/gitlab-secrets.json`が復元するされた場合、または異なるサーバーが復元するのターゲットである場合に、[データベース値が復号化するできる](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)ことを確認します:

   Toolboxポッドで、以下を実行します:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. さらに確実性を高めるため、[アップロードされたファイルの整合性チェック](../raketasks/check.md#uploaded-files-integrity)を実行できます。

   これらのコマンドはすべての行をイテレーションするため、時間がかかることがあります。したがって、Toolboxポッドではなく、GitLab Railsノードで以下のコマンドを実行します:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   不足または破損したファイルが見つかっても、必ずしもバックアップと復元するプロセスが失敗したことを意味するわけではありません。例えば、ソースのGitLabインスタンスでファイルが見つからないか破損している可能性があります。以前のバックアップと相互参照する必要があるかもしれません。GitLabを新しい環境に移行する場合、ソースのGitLabインスタンスで同じチェックを実行して、整合性チェックの結果が以前から存在するものなのか、それともバックアップと復元するプロセスに関連するものなのかを判断できます。

{{< /tab >}}

{{< /tabs >}}

復元が完了しました。
