---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabによって管理されているリポジトリの移動
description: プロジェクト、スニペット、およびグループをサーバー間やリポジトリストレージ間で移動します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabによって管理されているすべてのリポジトリを、別のファイルシステムまたは別のサーバーに移動します。

## GitLabインスタンス内のデータの移動 {#move-data-in-a-gitlab-instance}

GitLab APIを使用してGitリポジトリを移動します:

- サーバー間。
- 異なるリポジトリストレージ間。
- 単一ノードGitalyからGitalyクラスター (Praefect)へ。

GitLabリポジトリは、プロジェクト、グループ、およびスニペットに関連付けることができます。これらの各タイプには、リポジトリを移動するための個別のAPIがあります。GitLabインスタンス上のすべてのリポジトリを移動するには、各タイプのリポジトリを各リポジトリストレージに移動する必要があります。

各リポジトリは移動中読み取り専用になり、移動が完了するまで書き込みできません。

リポジトリを移動するには:

1. すべての[ローカルおよびクラスターリポジトリストレージ](../gitaly/configure_gitaly.md#mixed-configuration)がGitLabインスタンスにアクセスできることを確認します。この例では、これらは`<original_storage_name>`と`<cluster_storage_name>`です。
1. 新しいリポジトリストレージがすべての新規プロジェクトを受け取るように、[リポジトリストレージのウェイトを設定](../repository_storage_paths.md#configure-where-new-repositories-are-stored)します。これにより、移行の進行中に既存のリポジトリストレージで新規プロジェクトが作成されるのを防ぎます。
1. プロジェクト、スニペット、およびグループのリポジトリ移動をスケジュールします。
1. あなたが[Geo](../geo/_index.md)を使用している場合は、すべてのリポジトリを[再同期](../geo/replication/troubleshooting/synchronization_verification.md#resync-resources-for-the-selected-component)します。
1. SidekiqポッドでHorizontal Pod Autoscalerを使用している場合、移行中のスケールを防ぐために[SidekiqポッドのHPAを無効にします](https://docs.gitlab.com/charts/gitlab/sidekiq/#disable-hpa-scaling)。

### プロジェクトを移動する {#move-projects}

すべてのプロジェクト、または個々のプロジェクトを移動できます。

APIを使用してすべてのプロジェクトを移動するには:

1. APIを使用して、[ストレージシャード上のすべてのプロジェクトのリポジトリストレージ移動をスケジュール](../../api/project_repository_storage_moves.md#create-repository-storage-moves-for-all-projects-on-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. APIを使用して、[最新のリポジトリ移動をクエリします](../../api/project_repository_storage_moves.md#list-all-project-repository-storage-moves)。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドが`finished`です。
   - 移動が進行中です。完了するまでリポジトリ移動を再クエリします。
   - 移動は失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、APIを使用してプロジェクトを[クエリ](../../api/projects.md#list-all-projects)し、すべてのプロジェクトが移動したことを確認します。古いリポジトリストレージに設定された`repository_storage`フィールドでプロジェクトが返されないようにする必要があります。例: 

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   または、Railsコンソールを使用して、すべてのプロジェクトが移動したことを確認します:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. 必要に応じて、各リポジトリストレージに対して繰り返します。

すべてのプロジェクトを移動しない場合は、[個々のプロジェクトの移動](../../api/project_repository_storage_moves.md#create-a-repository-storage-move-for-a-project)に関する指示に従ってください。

### スニペットを移動する {#move-snippets}

すべてのスニペット、または個々のスニペットを移動できます。

APIを使用してすべてのスニペットを移動するには:

1. [ストレージシャード上のすべてのスニペットのリポジトリストレージ移動をスケジュール](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [最新のリポジトリ移動をクエリします](../../api/snippet_repository_storage_moves.md#list-all-snippet-repository-storage-moves)。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドが`finished`です。
   - 移動が進行中です。完了するまでリポジトリ移動を再クエリします。
   - 移動は失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、Railsコンソールを使用して、すべてのスニペットが移動したことを確認します:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   このコマンドは、元のリポジトリストレージのスニペットを返さないはずです。

1. 必要に応じて、各リポジトリストレージに対して繰り返します。

すべてのスニペットを移動しない場合は、[個々のスニペット](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet)に関する指示に従ってください。

### グループを移動する {#move-groups}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

すべてのグループ、または個々のグループを移動できます。

APIを使用してすべてのグループを移動するには:

1. [ストレージシャード上のすべてのグループのリポジトリストレージ移動をスケジュール](../../api/group_repository_storage_moves.md#create-group-repository-storage-moves-for-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [最新のリポジトリ移動をクエリします](../../api/group_repository_storage_moves.md#list-all-group-repository-storage-moves)。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドが`finished`です。
   - 移動が進行中です。完了するまでリポジトリ移動を再クエリします。
   - 移動は失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、Railsコンソールを使用して、すべてのグループが移動したことを確認します:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   このコマンドは、元のリポジトリストレージのグループを返さないはずです。

1. 必要に応じて、各リポジトリストレージに対して繰り返します。

すべてのグループを移動しない場合は、[個々のグループ](../../api/group_repository_storage_moves.md#create-a-group-repository-storage-move)に関する指示に従ってください。

## 別のGitLabインスタンスに移行する {#migrate-to-another-gitlab-instance}

新しいGitLab環境に移行する場合、[APIを使用してデータを移動](#move-data-in-a-gitlab-instance)することはできません。例: 

- 単一ノードGitLabからスケールアウトされたアーキテクチャへ。
- プライベートデータセンターのGitLabインスタンスからクラウドプロバイダーへ。

この場合、シナリオに応じて、すべてのリポジトリを`/var/opt/gitlab/git-data/repositories`から`/mnt/gitlab/repositories`にコピーする方法があります:

- ターゲットディレクトリが空です。
- ターゲットディレクトリには、古いリポジトリのコピーが含まれています。
- 数千のリポジトリがある場合。

> [!warning]
> これらのアプローチのそれぞれが、ターゲットディレクトリ`/mnt/gitlab/repositories`内のデータを上書きする可能性があります。ソースとターゲットを正しく指定する必要があります。

### バックアップと復元を使用（推奨） {#use-backup-and-restore-recommended}

GitalyまたはGitalyクラスター (Praefect)のターゲットの場合、GitLabの[バックアップと復元機能](../backup_restore/_index.md)を使用する必要があります。Gitリポジトリは、GitalyによってデータベースとしてGitLabサーバー上でアクセス、管理、保存されます。`rsync`のようなツールを使用してGitalyファイルに直接アクセスしてコピーすると、データ損失が発生する可能性があります。次のことが可能です。

- [複数のリポジトリを同時に処理](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently)することで、バックアップパフォーマンスを向上させます。
- [スキップ機能](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)を使用して、リポジトリのみのバックアップを作成します。

Gitalyクラスター (Praefect)ターゲットには、バックアップおよび復元方法を使用する必要があります。

### `tar`を使用する {#use-tar}

`tar`パイプを使用してリポジトリを移動できます（次の場合）:

- Gitalyターゲットを指定し、Gitalyクラスターターゲットは指定しない場合。
- ターゲットディレクトリ`/mnt/gitlab/repositories`が空である場合。

この方法はオーバーヘッドが低く、`tar`は通常システムにプリインストールされています。ただし、中断された`tar`パイプは再開できません。`tar`が中断された場合、ターゲットディレクトリを空にし、すべてのデータを再度コピーする必要があります。

`tar`プロセスの進行状況を確認するには、`-xf`を`-xvf`に置き換えます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### 別のサーバーに`tar`パイプを使用する {#use-a-tar-pipe-to-another-server}

Gitalyターゲットの場合、`tar`パイプを使用してデータを別のサーバーにコピーできます。あなたの`git`ユーザーが`git@<newserver>`として新しいサーバーにSSHアクセスできる場合、SSHを介してデータをパイプできます。

ネットワーク経由でデータを転送する前にデータを圧縮したい場合（CPU使用率が増加します）は、`ssh`を`ssh -C`に置き換えることができます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### `rsync`を使用する {#use-rsync}

`rsync`を使用してリポジトリを移動できます（次の場合）:

- Gitalyターゲットを指定し、Gitalyクラスターターゲットは指定しない場合。
- ターゲットディレクトリに既にリポジトリの部分的または古いコピーが含まれているため、`tar`ですべてのデータを再度コピーすることは非効率です。

> [!warning]
> `rsync`を使用する際は、`--delete`オプションを使用する必要があります。`--delete`なしで`rsync`を使用すると、データ損失およびリポジトリの破損を引き起こす可能性があります。詳細については、[イシュー270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422)を参照してください。

次のコマンドの`/.`は非常に重要です。そうしないと、ターゲットディレクトリに間違ったディレクトリ構造が作成される可能性があります。進行状況を確認したい場合は、`-a`を`-av`に置き換えます。

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### 別のサーバーに`rsync`を使用する {#use-rsync-to-another-server}

Gitalyターゲットの場合、ソースシステム上の`git`ユーザーがターゲットサーバーへのSSHアクセス権を持っている場合、`rsync`でリポジトリをネットワーク経由で送信できます。

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## 関連トピック {#related-topics}

- [Gitalyを設定する](../gitaly/configure_gitaly.md)
- [Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md)
- [プロジェクトリポジトリストレージ移動API](../../api/project_repository_storage_moves.md)
- [ストレージ間グループリポジトリ移動API](../../api/group_repository_storage_moves.md)
- [スニペットリポジトリストレージ移動API](../../api/snippet_repository_storage_moves.md)
