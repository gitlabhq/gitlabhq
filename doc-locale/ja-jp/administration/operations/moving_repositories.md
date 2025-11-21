---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabで管理されているリポジトリの移動
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabで管理されているすべてのリポジトリを、別のファイルシステムまたは別のサーバーに移動します。

## GitLabインスタンス内のデータを移動する {#move-data-in-a-gitlab-instance}

Gitリポジトリを移動するには、GitLab APIを使用します:

- サーバー間。
- 異なるリポジトリストレージ間。
- シングルノードGitalyからGitalyクラスタリング（Praefect）へ。

GitLabリポジトリは、プロジェクト、グループ、およびスニペットに関連付けることができます。これらのタイプごとに、リポジトリを移動するための個別のAPIがあります。GitLabインスタンス上のすべてのリポジトリを移動するには、リポジトリのタイプごとに、リポジトリストレージごとに移動する必要があります。

各リポジトリは、移動中は読み取り専用になり、移動が完了するまで書き込みできません。

リポジトリを移動するには、次の手順に従います:

1. すべての[ローカルおよびクラスタリングストレージ](../gitaly/configure_gitaly.md#mixed-configuration)がGitLabインスタンスにアクセスできることを確認してください。この例では、これらは`<original_storage_name>`と`<cluster_storage_name>`です。
1. 新しいストレージがすべての新しいプロジェクトを受信するように、[リポジトリのストレージのウェイトを構成する](../repository_storage_paths.md#configure-where-new-repositories-are-stored)。これにより、移行の進行中に、既存のストレージに新しいプロジェクトが作成されなくなります。
1. プロジェクト、スニペット、およびグループのリポジトリの移動をスケジュールします。
1. [GitLab](../geo/_index.md)を使用している場合は、[すべてのリポジトリを再同期](../geo/replication/troubleshooting/synchronization_verification.md#resync-all-resources-of-one-component)します。

### プロジェクトの移動 {#move-projects}

すべてのプロジェクトまたは個々のプロジェクトを移動できます。

APIを使用して、すべてのプロジェクトを移動するには、次の手順を実行します:

1. APIを使用して、[ストレージシャード上のすべてのプロジェクトのリポジトリストレージの移動をスケジュール](../../api/project_repository_storage_moves.md#schedule-repository-storage-moves-for-all-projects-on-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "Private-Token: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. APIを使用して、[最新のリポジトリの移動をクエリする](../../api/project_repository_storage_moves.md#retrieve-all-project-repository-storage-moves)します。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドは`finished`です。
   - 移動が進行中です。正常に完了するまで、リポジトリの移動を再度クエリします。
   - 移動に失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、APIを使用して[プロジェクトをクエリする](../../api/projects.md#list-all-projects)し、すべてのプロジェクトが移動したことを確認します。`repository_storage`フィールドが古いストレージに設定された状態でプロジェクトが返されないようにする必要があります。例: 

   ```shell
   curl --header "Private-Token: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   または、Railsコンソールを使用して、すべてのプロジェクトが移動したことを確認します:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. 必要に応じて、ストレージごとに繰り返します。

すべてのプロジェクトを移動しない場合は、[個々のプロジェクトの移動](../../api/project_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-project)に関する指示に従ってください。

### スニペットの移動 {#move-snippets}

すべてのスニペットまたは個々のスニペットを移動できます。

APIを使用して、すべてのスニペットを移動するには、次の手順を実行します:

1. [ストレージシャード上のすべてのスニペットのリポジトリストレージの移動をスケジュール](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "Private-Token: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [最新のリポジトリの移動をクエリする](../../api/snippet_repository_storage_moves.md#retrieve-all-snippet-repository-storage-moves)。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドは`finished`です。
   - 移動が進行中です。正常に完了するまで、リポジトリの移動を再度クエリします。
   - 移動に失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、Railsコンソールを使用して、すべてのスニペットが移動したことを確認します:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   コマンドは、元のストレージのスニペットを返さないようにする必要があります。

1. 必要に応じて、ストレージごとに繰り返します。

すべてのスニペットを移動しない場合は、[個々のスニペット](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet)に関する指示に従ってください。

### グループの移動 {#move-groups}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

すべてのグループまたは個々のグループを移動できます。

APIを使用して、すべてのグループを移動するには、次の手順を実行します:

1. [ストレージシャード上のすべてのグループのリポジトリストレージの移動をスケジュール](../../api/group_repository_storage_moves.md#schedule-repository-storage-moves-for-all-groups-on-a-storage-shard)します。例: 

   ```shell
   curl --request POST --header "Private-Token: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [最新のリポジトリの移動をクエリする](../../api/group_repository_storage_moves.md#retrieve-all-group-repository-storage-moves)。応答は次のいずれかを示します:
   - 移動が正常に完了しました。`state`フィールドは`finished`です。
   - 移動が進行中です。正常に完了するまで、リポジトリの移動を再度クエリします。
   - 移動に失敗しました。ほとんどの失敗は一時的なものであり、移動を再スケジュールすることで解決されます。

1. 移動が完了したら、Railsコンソールを使用して、すべてのグループが移動したことを確認します:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   コマンドは、元のストレージのグループを返さないようにする必要があります。

1. 必要に応じて、ストレージごとに繰り返します。

すべてのグループを移動しない場合は、[個々のグループ](../../api/group_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-group)に関する指示に従ってください。

## 別のGitLabインスタンスへの移行 {#migrate-to-another-gitlab-instance}

新しいGitLab環境に移行する場合、[APIを使用してデータを移動](#move-data-in-a-gitlab-instance)することはできません。例: 

- シングルノードのGitLabからスケールアウトされたアーキテクチャへ。
- プライベートデータセンター内のGitLabインスタンスからクラウドプロバイダーへ。

この場合、シナリオに応じて、`/var/opt/gitlab/git-data/repositories`から`/mnt/gitlab/repositories`にすべてのリポジトリをコピーする方法があります:

- ターゲットディレクトリが空です。
- ターゲットディレクトリには、リポジトリの古いコピーが含まれています。
- 数千のリポジトリがある場合。

{{< alert type="warning" >}}

どのアプローチも、ターゲットディレクトリ`/mnt/gitlab/repositories`内のデータを上書きする可能性があります。ソースとターゲットを正しく指定する必要があります。

{{< /alert >}}

### バックアップとリストアを使用する（推奨） {#use-backup-and-restore-recommended}

GitalyまたはGitalyクラスタリング（Praefect）ターゲットのいずれかに対して、GitLabの[バックアップとリストアの機能](../backup_restore/_index.md)を使用する必要があります。Gitリポジトリは、データベースとしてGitalyによってGitLabサーバー上でアクセス、管理、およびストレージされます。`rsync`などのツールを使用してGitalyファイルに直接アクセスしてコピーすると、データが失われる可能性があります。次のことができます: 

- [複数のリポジトリを同時に処理する](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently)ことで、バックアップのパフォーマンスを向上させます。
- [スキップ機能](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)を使用して、リポジトリだけのバックアップを作成します。

Gitalyクラスタリング（Praefect）ターゲットには、バックアップとリストアの方法を使用する必要があります。

### `tar`を使用する {#use-tar}

次の場合、`tar`パイプを使用してリポジトリを移動できます:

- Gitalyターゲットを指定し、Gitalyクラスタリングターゲットを指定しない。
- ターゲットディレクトリ`/mnt/gitlab/repositories`が空です。

この方法のオーバーヘッドは低く、通常、`tar`はシステムにプリインストールされています。ただし、中断された`tar`パイプを再開することはできません。`tar`が中断された場合は、ターゲットディレクトリを空にして、すべてのデータを再度コピーする必要があります。

`tar`プロセスの進行状況を確認するには、`-xf`を`-xvf`に置き換えます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### 別のサーバーへの`tar`パイプを使用する {#use-a-tar-pipe-to-another-server}

Gitalyターゲットの場合、`tar`パイプを使用して、別のサーバーにデータをコピーできます。`git`ユーザーが`git@<newserver>`として新しいサーバーへのSSHアクセス権を持っている場合は、SSHを介してデータをパイプできます。

ネットワーク経由でデータを送信する前に（CPU使用率が向上します）、データを圧縮する場合は、`ssh`を`ssh -C`に置き換えることができます。

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### `rsync`を使用する {#use-rsync}

次の場合、`rsync`を使用してリポジトリを移動できます:

- Gitalyターゲットを指定し、Gitalyクラスタリングターゲットを指定しない。
- ターゲットディレクトリにリポジトリの部分的または古いコピーがすでに含まれている場合は、`tar`ですべてのデータを再度コピーするのは非効率的です。

{{< alert type="warning" >}}

`rsync`を使用する場合は、`--delete`オプションを使用する必要があります。`--delete`なしで`rsync`を使用すると、データが失われたり、リポジトリが破損したりする可能性があります。詳細については、[issue 270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422)を参照してください。

{{< /alert >}}

次のコマンドの`/.`は非常に重要です。そうしないと、ターゲットディレクトリのディレクトリ構造が間違っている可能性があります。進行状況を確認する場合は、`-a`を`-av`に置き換えます。

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### 別のサーバーへの`rsync`を使用する {#use-rsync-to-another-server}

Gitalyターゲットの場合、ソースシステムの`git`ユーザーがターゲットサーバーへのSSHアクセス権を持っている場合は、`rsync`を使用してネットワーク経由でリポジトリを送信できます。

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## 関連トピック {#related-topics}

- [Gitalyを設定する](../gitaly/configure_gitaly.md)
- [Gitaly Cluster (Praefect)](../gitaly/praefect/_index.md)
- [プロジェクトリポジトリストレージの移動API](../../api/project_repository_storage_moves.md)
- [グループリポジトリストレージ移動API](../../api/group_repository_storage_moves.md)
- [スニペットリポジトリストレージ移動API](../../api/snippet_repository_storage_moves.md)
