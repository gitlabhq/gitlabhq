---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly Cluster (Praefect)のトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitaly Cluster (Praefect)のトラブルシューティングを行う際は、以下の情報を参照してください。Gitalyのトラブルシューティングについては、[Gitalyのトラブルシューティング](../troubleshooting.md)を参照してください。

## クラスターのヘルスチェック {#check-cluster-health}

`check` Praefectサブコマンドは、一連のチェックを実行して、Gitaly Cluster (Praefect)のヘルスチェックの状態を判断します。

```shell
gitlab-ctl praefect check
```

Praefectチャートを使用してPraefectをデプロイする場合は、バイナリを直接実行してください。

```shell
/usr/local/bin/praefect check
```

以下のセクションでは、実行されるチェックについて説明します。

### Praefectの移行 {#praefect-migrations}

データベースの移行がPraefectの正常な動作のために最新である必要があるため、Praefectの移行が最新であるかどうかをチェックします。

このチェックに失敗した場合:

1. データベースの`schema_migrations`テーブルを参照して、どの移行が実行されたかを確認します。
1. `praefect sql-migrate`を実行して、移行を最新の状態にします。

### ノードの接続性とディスクアクセス {#node-connectivity-and-disk-access}

PraefectがすべてのGitalyノードに到達できるかどうか、および各Gitalyノードがすべてのストレージへの読み取りおよび書き込みアクセス権を持っているかどうかをチェックします。

このチェックに失敗した場合:

1. ネットワークアドレスとトークンが正しく設定されていることを確認します:
   - Praefect設定内。
   - 各Gitalyノードの設定内。
1. Gitalyノードで、`gitaly`プロセスが`git`として実行されていることを確認します。Gitalyがストレージディレクトリにアクセスできないようにするアクセス許可の問題が発生している可能性があります。
1. PraefectをGitalyノードに接続するネットワークに問題がないことを確認します。

### データベースの読み取りと書き込みのアクセス {#database-read-and-write-access}

Praefectがデータベースから読み取り、データベースに書き込みできるかどうかをチェックします。

このチェックに失敗した場合:

1. Praefectデータベースがリカバリーモードになっているかどうかを確認します。リカバリーモードでは、テーブルは読み取り専用になる場合があります。確認するには、以下を実行します:

   ```sql
   select pg_is_in_recovery()
   ```

1. PraefectがPostgreSQLへの接続に使用するユーザーに、データベースへの読み取りおよび書き込みアクセス権があることを確認します。
1. データベースが読み取り専用モードになっているかどうかを確認します。確認するには、以下を実行します:

   ```sql
   show default_transaction_read_only
   ```

### アクセスできないリポジトリ {#inaccessible-repositories}

プライマリー割り当てがないか、プライマリーが利用できないために、アクセスできないリポジトリの数を確認します。

このチェックに失敗した場合:

1. Gitalyノードがダウンしているかどうかを確認します。`praefect ping-nodes`を実行して確認します。
1. Praefectデータベースに高い負荷がかかっているかどうかを確認します。Praefectデータベースの応答が遅い場合、ヘルスチェックがデータベースに永続化できなくなり、Praefectはノードが異常であると認識する可能性があります。

## ログ内のPraefectエラー {#praefect-errors-in-logs}

エラーが発生した場合は、`/var/log/gitlab/gitlab-rails/production.log`を確認してください。

一般的なエラーと潜在的な原因を以下に示します:

- 500レスポンスコード
  - `ActionView::Template::Error (7:permission denied)`
    - `praefect['configuration'][:auth][:token]`と`gitlab_rails['gitaly_token']`がGitLabサーバーで一致しません。
    - `gitlab_rails['repositories_storages']`ストレージ設定がSidekiqサーバーにありません。
  - `Unable to save project. Error: 7:permission denied`
    - GitLabサーバーの`praefect['configuration'][:virtual_storage]`のシークレットトークンが、1つ以上のGitalyサーバーの`gitaly['auth_token']`の値と一致しません。
- 503レスポンスコード
  - `GRPC::Unavailable (14:failed to connect to all addresses)`
    - GitLabがPraefectに到達できませんでした。
  - `GRPC::Unavailable (14:all SubCons are in TransientFailure...)`
    - Praefectが1つ以上の子Gitalyノードに到達できません。Praefect接続チェッカーを実行して診断してみてください。

## CPU負荷が高いPraefectデータベース {#praefect-database-experiencing-high-cpu-load}

PraefectデータベースでCPU使用率が上昇する一般的な理由には、次のものがあります:

- Prometheusメトリクスが[コストのかかるクエリを実行してスクレイプする](https://gitlab.com/gitlab-org/gitaly/-/issues/3796)。`praefect['configuration'][:prometheus_exclude_database_from_default_metrics] = true`を`gitlab.rb`に設定します。
- [読み取り分散キャッシュ](configure.md#reads-distribution-caching)が無効になっているため、ユーザートラフィックが多い場合にデータベースに対して行われるクエリの数が増加します。読み取り分散キャッシュが有効になっていることを確認してください。

## プライマリGitalyノードを特定する {#determine-primary-gitaly-node}

リポジトリのプライマリノードを特定するには、[`praefect metadata`](#view-repository-metadata)サブコマンドを使用します。

## リポジトリのメタデータを表示 {#view-repository-metadata}

Gitaly Cluster (Praefect)は、クラスターに格納されているリポジトリに関する[メタデータデータベース](_index.md#components)を保持します。`praefect metadata`サブコマンドを使用して、トラブルシューティングのメタデータを検査します。

リポジトリのメタデータは、Praefectによって割り当てられたリポジトリIDで取得できます:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id <repository-id>
```

物理ストレージ上の物理パスが`@cluster`で始まる場合、[リポジトリIDを物理パスで確認できます](_index.md#praefect-generated-replica-paths)。

リポジトリのメタデータは、仮想ストレージと相対パスで取得することもできます:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage <virtual-storage> -relative-path <relative-path>
```

### 例 {#examples}

Praefectによって割り当てられたリポジトリIDが1のリポジトリのメタデータを取得するには:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id 1
```

仮想ストレージが`default`、相対パスが`@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`のリポジトリのメタデータを取得するには:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage default -relative-path @hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git
```

これらの例のいずれかを実行すると、リポジトリのメタデータ例が取得されます:

```plaintext
Repository ID: 54771
Virtual Storage: "default"
Relative Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Replica Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Primary: "gitaly-1"
Generation: 1
Replicas:
- Storage: "gitaly-1"
  Assigned: true
  Generation: 1, fully up to date
  Healthy: true
  Valid Primary: true
  Verified At: 2021-04-01 10:04:20 +0000 UTC
- Storage: "gitaly-2"
  Assigned: true
  Generation: 0, behind by 1 changes
  Healthy: true
  Valid Primary: false
  Verified At: unverified
- Storage: "gitaly-3"
  Assigned: true
  Generation: replica not yet created
  Healthy: false
  Valid Primary: false
  Verified At: unverified
```

### 利用可能なメタデータ {#available-metadata}

`praefect metadata`によって取得されたメタデータには、次のテーブルのフィールドが含まれています。

| フィールド             | 説明                                                                                                        |
|:------------------|:-------------------------------------------------------------------------------------------------------------------|
| `Repository ID`   | Praefectによってリポジトリに割り当てられた永続的な一意のID。GitLabがリポジトリに使用するIDとは異なります。      |
| `Virtual Storage` | リポジトリが格納されている仮想ストレージの名前。                                                           |
| `Relative Path`   | 仮想ストレージ内のリポジトリのパス。                                                                          |
| `Replica Path`    | Gitalyノードのディスク上のリポジトリのレプリカが格納されている場所。                                                |
| `Primary`         | リポジトリの現在のプライマリ。                                                                                 |
| `Generation`      | Praefectがリポジトリの変更を追跡するために使用します。リポジトリへの書き込みごとに、リポジトリの世代が増加します。 |
| `Replicas`        | 存在するか、または存在することが予想されるレプリカのリスト。                                                            |

各レプリカについて、次のメタデータを使用できます:

| `Replicas`フィールド | 説明                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Storage`        | レプリカを含むGitalyストレージの名前。                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Assigned`       | レプリカがストレージに存在することが予想されるかどうかを示します。Gitalyノードがクラスターから削除された場合、またはリポジトリのレプリケーションファクターが減少した後でストレージに余分なコピーが含まれている場合は、`false`になる可能性があります。                                                                                                                                                                                                                       |
| `Generation`     | レプリカの最新の確認済みの世代。それは以下を示します:<br><br>\- 世代がリポジトリの世代と一致する場合、レプリカは完全に最新の状態です。<br>\- レプリカの世代がリポジトリの世代よりも低い場合、レプリカは古くなっています。<br>\- ストレージにレプリカがまだ存在しない場合は、`replica not yet created`。                                                                                                          |
| `Healthy`        | このレプリカをホストしているGitalyノードが、Praefectノードのコンセンサスによって正常と見なされているかどうかを示します。                                                                                                                                                                                                                                                                                                                               |
| `Valid Primary`  | レプリカがプライマリノードとして機能するのに適しているかどうかを示します。リポジトリのプライマリが有効なプライマリでない場合、別のレプリカが有効なプライマリである場合、リポジトリへの次の書き込みでフェイルオーバーが発生します。レプリカが有効なプライマリである条件:<br><br>\- 正常なGitalyノードに格納されている。<br>\- 完全に最新の状態である。<br>\- レプリケーションファクターの減少による保留中の削除ジョブの対象になっていない。<br>\- 割り当てられている。 |
| `Verified At` | [検証ワーカー](configure.md#repository-verification)によるレプリカの最後の検証成功を示します。レプリカがまだ検証されていない場合は、最後の検証成功時刻の代わりに`unverified`が表示されます。 |

### 「リポジトリが見つかりません」というコマンドが失敗する {#command-fails-with-repository-not-found}

`-virtual-storage`に指定された値が正しくない場合、コマンドは次のエラーを返します:

```plaintext
get metadata: rpc error: code = NotFound desc = repository not found
```

ドキュメント化された例では、`-virtual-storage default`を指定します。`/etc/gitlab/gitlab.rb`のPraefectサーバーの設定`praefect['configuration'][:virtual_storage]`を確認してください。

## リポジトリが同期していることを確認します {#check-that-repositories-are-in-sync}

[一部のケース](_index.md#known-issues)では、Praefectデータベースが基盤となるGitalyノードと同期しなくなる可能性があります。特定のリポジトリがすべてのノードで完全に同期されていることを確認するには、Railsノードで[`gitlab:praefect:replicas` Rakeタスク](../../raketasks/praefect.md#replica-checksums)を実行します。このRakeタスクは、すべてのGitalyノードのリポジトリをチェックサムします。

[Praefect `dataloss`](recovery.md#check-for-data-loss)コマンドは、Praefectデータベース内のリポジトリの状態のみをチェックし、このシナリオでは同期の問題を検出するために信頼することはできません。

### `dataloss`コマンドは、`@failed-geo-sync`リポジトリを同期していない状態で表示します {#dataloss-command-shows-failed-geo-sync-repositories-as-out-of-sync}

`@failed-geo-sync`は、プロジェクトの同期に失敗した場合にGeoがGitLab 16.1以前で使用していたレガシーパスであり、[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/375640)になりました。

GitLab 16.2以降では、このパスを安全に削除できます。`@failed-geo-sync`ディレクトリは、Gitalyノードの[リポジトリパス](../../repository_storage_paths.md)の下にあります。

## リレーションが存在しないエラー {#relation-does-not-exist-errors}

デフォルトでは、Praefectデータベーステーブルは`gitlab-ctl reconfigure`タスクによって自動的に作成されます。

ただし、Praefectデータベーステーブルは最初の再設定では作成されず、次のいずれかの場合はリレーションが存在しないというエラーが発生する可能性があります:

- `gitlab-ctl reconfigure`コマンドが実行されていません。
- 実行中にエラーが発生します。

例: 

- `ERROR:  relation "node_status" does not exist at character 13`
- `ERROR:  relation "replication_queue_lock" does not exist at character 40`
- このエラー:

  ```json
  {"level":"error","msg":"Error updating node: pq: relation \"node_status\" does not exist","pid":210882,"praefectName":"gitlab1x4m:0.0.0.0:2305","time":"2021-04-01T19:26:19.473Z","virtual_storage":"praefect-cluster-1"}
  ```

これを解決するには、`praefect`コマンドの`sql-migrate`サブコマンドを使用して、データベーススキーマの移行を実行できます:

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-migrate
praefect sql-migrate: OK (applied 21 migrations)
```

## 「リポジトリのスコープ: 無効なリポジトリ」エラーでリクエストが失敗する {#requests-fail-with-repository-scoped-invalid-repository-errors}

これは、[Praefect設定](configure.md#praefect)で使用されている仮想ストレージ名が、GitLabの[`gitaly['configuration'][:storage][<index>][:name]`設定](configure.md#gitaly)で使用されているストレージ名と一致しないことを示します。

PraefectとGitLab設定で使用されている仮想ストレージ名を一致させることで、これを解決します。

## クラウドプラットフォームでのGitaly Cluster (Praefect)のパフォーマンスの問題 {#gitaly-cluster-praefect-performance-issues-on-cloud-platforms}

Praefectは多くのCPUやメモリを必要とせず、小さな仮想マシン上で実行できます。クラウドサービスでは、ディスクIOやネットワーク帯域幅など、小さなVMで使用できるリソースに他の制限が課せられる場合があります。

Praefectノードは大量のネットワーキングトラフィックを生成します。クラウドサービスによってネットワーク帯域幅が制限されている場合、次の症状が見られることがあります:

- Git操作のパフォーマンスが低い。
- 高いネットワークレイテンシー。
- Praefectによる高いメモリ使用量。

考えられる解決策:

- より大きなネットワーキングトラフィック許容量にアクセスするために、より大きなVMをプロビジョニングします。
- クラウドサービスのモニタリングとログを使用して、Praefectノードがトラフィック許容量を使い果たしていないことを確認します。

## Praefect設定エラーで`gitlab-ctl reconfigure`が失敗する {#gitlab-ctl-reconfigure-fails-with-a-praefect-configuration-error}

`gitlab-ctl reconfigure`が失敗した場合、次のエラーが表示されることがあります:

```plaintext
STDOUT: praefect: configuration error: error reading config file: toml: cannot store TOML string into a Go int
```

このエラーは、`praefect['database_port']`または`praefect['database_direct_port']`が整数ではなく文字列として設定されている場合に発生します。

## 一般的なレプリケーションエラー {#common-replication-errors}

以下に、考えられる解決策を備えた一般的なレプリケーションエラーをいくつか示します。

### ロックファイルが存在する {#lock-file-exists}

ロックファイルは、同じrefsへの複数の更新を防ぐために使用されます。ロックファイルが古くなり、レプリケーションがエラー`error: cannot lock ref`で失敗することがあります。

古い`*.lock`ファイルをクリアするには、[Railsコンソール](../../operations/rails_console.md)で`OptimizeRepositoryRequest`をトリガーできます:

```ruby
p = Project.find <Project ID>
client = Gitlab::GitalyClient::RepositoryService.new(p.repository)
client.optimize_repository
```

`OptimizeRepositoryRequest`のトリガーが機能しない場合は、ファイルを手動で調べて作成日を確認し、`*.lock`ファイルを手動で削除できるかどうかを判断します。24時間以上前に作成されたロックファイルは安全に削除できます。

### Git `fsck`エラー {#git-fsck-errors}

無効なオブジェクトを持つGitalyリポジトリは、次のようなGitalyログのエラーでレプリケーションの失敗につながる可能性があります:

- `exit status 128, stderr: "fatal: git upload-pack: not our ref"`。
- `"fatal: bad object 58....e0f... ssh://gitaly/internal.git did not send all necessary objects`。

いずれかのGitalyノードにリポジトリの正常なコピーがまだある限り、これらの問題を修正できます:

1. [Praefectデータベースからリポジトリを削除](recovery.md#manually-remove-repositories)します。
1. [Praefect `track-repository`サブコマンド](recovery.md#manually-add-a-single-repository-to-the-tracking-database)を使用して、再度追跡します。

これにより、権限のあるGitalyノードからのリポジトリのコピーを使用して、他のすべてのGitalyノードのコピーを上書きします。これらのコマンドを実行する前に、リポジトリの最新のバックアップが作成されていることを確認してください。

1. 問題のあるリポジトリを移動します:

   ```shell
   run `mv <REPOSITORY_PATH> <REPOSITORY_PATH>.backup`
   ```

   例: 

   ```shell
   mv /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335 /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335.backup
   ```

1. Praefectコマンドを実行して、レプリケーションをトリガーします:

   ```shell
   # Validate you have the correct repository.
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only

   # Run again with '--apply' flag to remove repository from the Praefect tracking database
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only --apply

   # Re-track the repository, overwriting the secondary nodes
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage gitaly -authoritative-storage '<healthy_gitaly>' -relative-path '<relative_path>' -replica-path '<replica_path>'-replicate-immediately
   ```

### レプリケーションがサイレントに失敗する {#replication-fails-silently}

[Praefect `dataloss`](recovery.md#check-for-data-loss)が[リポジトリの一部が利用できない](recovery.md#unavailable-replicas-of-available-repositories)ことを示し、[`accept-dataloss`コマンド](recovery.md#accept-data-loss)がログにエラーが表示されずにリポジトリを同期できない場合は、`storage_repositories`テーブルの`repository_id`フィールドのPraefectデータベースの不一致が原因である可能性があります。不一致を確認するには:

1. Praefectデータベースに接続します。
1. 次のクエリを実行します:

   ```sql
   select * from storage_repositories where relative_path = '<relative-path>';
   ```

   `<relative-path>`を、[`@hashed`で始まる](../../repository_storage_paths.md#hashed-storage)リポジトリパスに置き換えます。

### 代替ディレクトリが存在しません {#alternate-directory-does-not-exists}

GitLabでは、Gitの代替メカニズムを使用して重複排除を行っています。`alternates`は、オブジェクトをフェッチするために、`@pool`リポジトリの`objects`ディレクトリを指すテキストファイルです。このファイルが無効なパスを指している場合、レプリケーションは以下のいずれかのエラーで失敗する可能性があります:

- `"error":"no alternates directory exists", "warning","msg":"alternates file does not point to valid git repository"`
- `"error":"unexpected alternates content:`
- `remote: error: unable to normalize alternate object path`

このエラーの原因を調査するには、以下を実行します:

1. プロジェクトがプールの一部であるかどうかを、[Railsコンソール](../../operations/rails_console.md)を使用して確認します:

   ```ruby
   project = Project.find_by_id(<project id>)
   project.pool_repository
   ```

1. プールリポジトリのパスがディスクに存在し、`alternates`ファイルの内容と一致することを確認します。
1. `alternates`ファイル内のパスが、プロジェクト内の`objects`ディレクトリから到達可能であることを確認します。

これらのチェックを実行した後、収集した情報を添えてGitLabサポートにお問い合わせください。
