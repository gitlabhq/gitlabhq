---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabで管理されているリポジトリの移動
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabで管理されているすべてのリポジトリを、別のファイルシステムまたは別のサーバーに移動します。

## GitLabインスタンス内のデータを移動 {#move-data-in-a-gitlab-instance}

GitLab APIを使用してGitリポジトリを移動します:

- サーバー間。
- 異なるストレージ間。
- 単一ノードGitalyからGitaly Cluster (Praefect)

GitLabのリポジトリは、プロジェクト、グループ、およびスニペットに関連付けることができます。これらの各タイプには、リポジトリを移動するための個別のAPIがあります。GitLabインスタンス上のすべてのリポジトリを移動するには、各リポジトリのタイプごとにストレージを移動する必要があります。

各リポジトリは、リポジトリの移動中は読み取り専用になり、リポジトリの移動が完了するまで書き込みできません。

リポジトリを移動するには:

1. すべての[ローカルおよびクラスターストレージ](../gitaly/configure_gitaly.md#mixed-configuration)がGitLabインスタンスにアクセスできることを確認します。この例では、これらは`<original_storage_name>`と`<cluster_storage_name>`です。
1. 新しいストレージがすべての新規プロジェクトを受信するように、[リポジトリストレージウェイトを構成](../repository_storage_paths.md#configure-where-new-repositories-are-stored)します。これにより、移行の進行中に、既存のストレージに新規プロジェクトが作成されるのを防ぎます。
1. プロジェクト、スニペット、およびグループのリポジトリの移動をスケジュールします。
1. [Geo](../geo/_index.md)を使用している場合は、すべての[リポジトリを再同期](../geo/replication/troubleshooting/synchronization_verification.md#resync-resources-for-the-selected-component)します。
1. SidekiqポッドでHorizontal Pod Autoscalerを使用する場合は、移行中のスケーリングを防ぐために、[SidekiqポッドのHPAを無効](https://docs.gitlab.com/charts/gitlab/sidekiq/#disable-hpa-scaling)にします。

### プロジェクトを移動する {#move-projects}

すべてのプロジェクトまたは個別のプロジェクトを移動できます。

APIを使用してすべてのプロジェクトを移動するには:

1. APIを使用して、[ストレージシャード上のすべてのプロジェクトのリポジトリストレージの移動をスケジュール](../../api/project_repository_storage_moves.md#create-repository-storage-moves-for-all-projects-on-a-storage-shard)します。例: 例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. APIを使用して、最も最近の[リポジトリの移動をクエリ](../../api/project_repository_storage_moves.md#list-all-project-repository-storage-moves)します。応答は次のいずれかを示します:
   - リポジトリの移動は正常に完了しました。`state`フィールドは`finished`です。
   - リポジトリの移動が進行中です。リポジトリの移動が正常に完了するまで再クエリします。
   - リポジトリの移動は失敗しました。ほとんどの失敗は一時的なものであり、リポジトリの移動を再スケジュールすることで解決されます。

1. リポジトリの移動が完了したら、APIを使用してプロジェクトを[クエリ](../../api/projects.md#list-all-projects)することで、すべてのプロジェクトが移動されたことを確認します。`repository_storage`フィールドが古いストレージに設定されたプロジェクトは返されません。例: 

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   または、Railsコンソールを使用して、すべてのプロジェクトが移動されたことを確認します:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. 必要に応じて各ストレージで繰り返します。

すべてのプロジェクトを移動したくない場合は、[個別のプロジェクトを移動する](../../api/project_repository_storage_moves.md#create-a-repository-storage-move-for-a-project)手順に従ってください。

### スニペットを移動する {#move-snippets}

すべてのスニペットまたは個別のスニペットを移動できます。

APIを使用してすべてのスニペットを移動するには:

1. [ストレージシャード上のすべてのスニペットのリポジトリストレージの移動をスケジュール](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard)します。例: 例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [最も最近のリポジトリの移動をクエリ](../../api/snippet_repository_storage_moves.md#list-all-snippet-repository-storage-moves)します。応答は次のいずれかを示します:
   - リポジトリの移動は正常に完了しました。`state`フィールドは`finished`です。
   - リポジトリの移動が進行中です。リポジトリの移動が正常に完了するまで再クエリします。
   - リポジトリの移動は失敗しました。ほとんどの失敗は一時的なものであり、リポジトリの移動を再スケジュールすることで解決されます。

1. リポジトリの移動が完了したら、Railsコンソールを使用して、すべてのスニペットが移動されたことを確認します:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   このコマンドは、元のストレージのスニペットを返すべきではありません。

1. 必要に応じて各ストレージで繰り返します。

すべてのスニペットを移動したくない場合は、[個別のスニペット](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet)の手順に従ってください。

### グループを移動する {#move-groups}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

すべてのグループまたは個別のグループを移動できます。

APIを使用してすべてのグループを移動するには:

1. [ストレージシャード上のすべてのグループのリポジトリストレージの移動をスケジュール](../../api/group_repository_storage_moves.md#create-group-repository-storage-moves-for-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [最も最近のリポジトリの移動をクエリ](../../api/group_repository_storage_moves.md#list-all-group-repository-storage-moves)します。応答は次のいずれかを示します:
   - リポジトリの移動は正常に完了しました。`state`フィールドは`finished`です。
   - リポジトリの移動が進行中です。リポジトリの移動が正常に完了するまで再クエリします。
   - リポジトリの移動は失敗しました。ほとんどの失敗は一時的なものであり、リポジトリの移動を再スケジュールすることで解決されます。

1. リポジトリの移動が完了したら、Railsコンソールを使用して、すべてのグループが移動されたことを確認します:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   このコマンドは、元のストレージのグループを返すべきではありません。

1. 必要に応じて各ストレージで繰り返します。

すべてのグループを移動したくない場合は、[個別のグループ](../../api/group_repository_storage_moves.md#create-a-group-repository-storage-move)の手順に従ってください。

## 別のGitLabインスタンスへ移行する {#migrate-to-another-gitlab-instance}

新しいGitLab環境に移行する場合は、[APIを使用してデータを移動](#move-data-in-a-gitlab-instance)することはできません。例: 

- 単一ノードのGitLabからスケールアウトアーキテクチャへ。
- プライベートデータセンター内のGitLabインスタンスからクラウドプロバイダーへ。

この場合、シナリオに応じてすべてのリポジトリを`/var/opt/gitlab/git-data/repositories`から`/mnt/gitlab/repositories`にコピーする方法があります:

- ターゲットディレクトリが空である。
- ターゲットディレクトリにリポジトリの古いコピーが含まれている。
- リポジトリが数千ある場合。

> [!warning]いずれのアプローチも、ターゲットディレクトリ`/mnt/gitlab/repositories`のデータを上書きする可能性があります。ソースとターゲットを正しく指定する必要があります。

### バックアップと復元を使用する（推奨） {#use-backup-and-restore-recommended}

GitalyまたはGitaly Cluster (Praefect)のターゲットには、GitLabの[バックアップと復元機能](../backup_restore/_index.md)を使用する必要があります。Gitリポジトリは、GitalyによってデータベースとしてGitLabサーバー上でアクセス、管理、保存されます。`rsync`のようなツールを使用してGitalyファイルに直接アクセスしてコピーすると、データ損失が発生する可能性があります。次のことができます: 

- [複数のリポジトリを同時に処理](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently)することで、バックアップパフォーマンスを向上させます。
- [スキップ機能](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)を使用して、リポジトリのみのバックアップを作成します。

Gitaly Cluster (Praefect)ターゲットには、バックアップと復元の方法を使用する必要があります。

### `tar`を使用する {#use-tar}

次の場合、`tar`パイプを使用してリポジトリを移動できます:

- Gitalyターゲットを指定し、Gitalyクラスターターゲットは指定しません。
- ターゲットディレクトリ`/mnt/gitlab/repositories`が空である。

この方法はオーバーヘッドが低く、`tar`は通常システムにプリインストールされています。ただし、中断された`tar`パイプを再開することはできません。`tar`が中断された場合、ターゲットディレクトリを空にし、すべてのデータを再度コピーする必要があります。

`tar`プロセスの進行状況を確認するには、`-xf`を`-xvf`に置き換えます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### 別のサーバーへの`tar`パイプの使用 {#use-a-tar-pipe-to-another-server}

Gitalyターゲットの場合、`tar`パイプを使用してデータを別のサーバーにコピーできます。`git`ユーザーが`git@<newserver>`として新しいサーバーにSSHアクセスできる場合、SSH経由でデータをパイプできます。

ネットワークを介してデータを転送する前にデータを圧縮したい場合（これによりCPU使用率が増加します）は、`ssh`を`ssh -C`に置き換えることができます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### `rsync`を使用する {#use-rsync}

次の場合、`rsync`を使用してリポジトリを移動できます:

- Gitalyターゲットを指定し、Gitalyクラスターターゲットは指定しません。
- ターゲットディレクトリにすでにリポジトリの部分的または古いコピーが含まれているため、`tar`でデータをすべて再度コピーするのは非効率です。

> [!warning] 
> 
> `rsync`を使用する場合は、`--delete`オプションを使用する必要があります。`rsync`を`--delete`なしで使用すると、データ損失やリポジトリの破損を引き起こす可能性があります。詳細については、[イシュー270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422)を参照してください。

以下のコマンドの`/.`は非常に重要です。そうしないと、ターゲットディレクトリで誤ったディレクトリ構造になる可能性があります。進行状況を確認したい場合は、`-a`を`-av`に置き換えます。

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### 別のサーバーへの`rsync`の使用 {#use-rsync-to-another-server}

Gitalyターゲットの場合、ソースシステム上の`git`ユーザーがターゲットサーバーにSSHアクセスできる場合、`rsync`でリポジトリをネットワーク経由で送信できます。

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## 関連トピック {#related-topics}

- [Gitalyを設定する](../gitaly/configure_gitaly.md)
- [Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md)
- [プロジェクトリポジトリストレージの移動API](../../api/project_repository_storage_moves.md)
- [グループリポジトリストレージ移動API](../../api/group_repository_storage_moves.md)
- [スニペットリポジトリストレージの移動API](../../api/snippet_repository_storage_moves.md)
