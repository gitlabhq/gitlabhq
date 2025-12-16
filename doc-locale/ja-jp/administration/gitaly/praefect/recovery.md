---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly Cluster (Praefect)のリカバリーオプションとツール
---

Gitaly Cluster (Praefect)は、プライマリノードの失敗と利用できないリポジトリからリカバリーできます。Gitaly Cluster (Praefect)は、データリカバリーを実行でき、Praefectトラッキングデータベースツールを備えています。

## Gitaly Cluster (Praefect)でGitalyノードを管理する {#manage-gitaly-nodes-on-a-gitaly-cluster-praefect}

Gitaly Cluster (Praefect)でGitalyノードを追加および置換できます。

### 新しいGitalyノードを追加する {#add-new-gitaly-nodes}

新しいGitalyノードを追加するには:

1. [ドキュメント](configure.md#gitaly)に従って、新しいGitalyノードをインストールします。
1. `praefect['virtual_storages']`の[Praefect設定](configure.md#praefect)に新しいノードを追加します。
1. 次のコマンドを実行して、Praefectを再設定し、再起動します:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

レプリケーションの動作は、レプリケーション係数の設定によって異なります。

#### カスタムレプリケーション係数 {#custom-replication-factor}

カスタムレプリケーション係数が設定されている場合、Praefectは既存のリポジトリを新しいGitalyノードに自動的にレプリケートしません。`set-replication-factor` Praefectコマンドを使用して、各リポジトリの[レプリケーション係数](configure.md#configure-replication-factor)を設定する必要があります。新しいリポジトリは、[レプリケーション係数](configure.md#configure-replication-factor)に基づいてレプリケートされます。

#### デフォルトのレプリケーション係数 {#default-replication-factor}

デフォルトのレプリケーション係数が使用されている場合、Praefectは、レプリケーション係数を維持するために、設定に追加された新しいGitalyノードにすべてのデータを自動的にレプリケートします。

### 既存のGitalyノードを置き換える {#replace-an-existing-gitaly-node}

既存のGitalyノードを、同じ名前または異なる名前の新しいノードに置き換えることができます。古いノードを削除する前に:

- レプリケーション係数が設定されている場合、データ損失を防ぐために、1より大きい必要があります。
- レプリケーション係数が設定されていない場合、リポジトリは、仮想ストレージ下のすべてのノードでレプリケートされます。

プライマリGitalyノードを削除すると、そのノードによって管理されているリポジトリは、次のいずれかの状態になるまで使用できなくなります:

- ノードが置き換えられてレプリケートされる。
- 置換されたプライマリノードからのデータを含む新しい置換ノードが利用可能になる。

ノードが利用できない間、影響を受けるリポジトリへの読み取りリクエストは`404`エラーで失敗します。Gitalyは、新しいプライマリノードを確立するために、フェイルオーバーをトリガーすることにより、影響を受けるリポジトリへの次回の書き込み試行時に、この状況を自動的に解決します。

#### 同じ名前のノードを使用する {#with-a-node-with-the-same-name}

置換ノードに同じ名前を使用するには、[リポジトリベリファイア](configure.md#enable-deletions)を使用してストレージをスキャンし、未処理のメタデータレコードを削除します。プロセスを高速化するために、交換したストレージの[検証を手動で優先順位付け](configure.md#prioritize-verification-manually)します。

#### 異なる名前のノードを使用する {#with-a-node-with-a-different-name}

Gitaly Cluster (Praefect)で、異なる名前を持つノードでノードを置換する手順は、[レプリケーション係数](configure.md#configure-replication-factor)が設定されているかどうかによって異なります。

カスタムレプリケーション係数が設定されている場合は、[`praefect set-replication-factor`](configure.md#configure-replication-factor)を使用して、新しいストレージが割り当てられるように、リポジトリごとにレプリケーション係数を再度設定します。

たとえば、仮想ストレージ内の2つのノードのレプリケーション係数が2で、新しいノード（`gitaly-3`）が追加された場合は、レプリケーション係数を3に増やす必要があります:

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -relative-path @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 3

current assignments: gitaly-1, gitaly-2, gitaly-3
```

これにより、リポジトリが新しいノードにレプリケートされ、新しいGitalyノードの名前で`repository_assignments`テーブルが更新されます。

[デフォルトのレプリケーション係数](configure.md#configure-replication-factor)が設定されている場合、新しいノードはレプリケーションに自動的に含まれません。前に説明した手順に従う必要があります。

リポジトリが新しいノードに正常にレプリケートされたことを[確認](#check-for-data-loss)した後:

1. `praefect['virtual_storages']`の[Praefect設定](configure.md#praefect)から`gitaly-1`ノードを削除します。
1. Praefectを再設定して再起動します:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

古いGitalyノードを参照するデータベースの状態は無視できます。

別の方法としては、新しいGitalyノードを設定した後、古いストレージから新しいストレージにすべてのリポジトリを再割り当てすることです:

1. Praefectデータベースに接続します:

   ```shell
   /opt/gitlab/embedded/bin/psql -h <psql host> -U <user> -d <database name>
   ```

1. `repository_assignments`テーブルを更新して、古いGitalyノード名（たとえば、`old-gitaly`）を新しいGitalyノード名（たとえば、`new-gitaly`）に置き換えます:

   ```sql
   UPDATE repository_assignments SET storage='new-gitaly' WHERE storage='old-gitaly';
   ```

これにより、システムを望ましい状態に戻すために、適切なレプリケーションジョブがトリガーされます。

## プライマリノードの失敗 {#primary-node-failure}

Gitaly Cluster (Praefect)は、正常なセカンダリを新しいプライマリとしてプロモートすることにより、失敗したプライマリGitalyノードからリカバリーします。Gitaly Cluster (Praefect):

- 完全に最新のリポジトリのコピーを持つ正常なセカンダリを新しいプライマリとして選択します。
- 完全に最新のセカンダリが利用できない場合は、プライマリからのレプリケートされていない書き込みが最も少ないセカンダリを新しいプライマリとして選択します。
- 正常なセカンダリに完全に最新のコピーがない場合、リポジトリは利用できなくなります。それを検出するには、[Praefect `dataloss`サブコマンド](#check-for-data-loss)を使用します。

### 利用できないリポジトリ {#unavailable-repositories}

リポジトリのすべての最新レプリカが利用できない場合、リポジトリは利用できません。自動化されたツールを中断させる可能性のある古いデータの提供を防ぐため、利用できないリポジトリはPraefectからアクセスできません。

### データ損失の確認 {#check-for-data-loss}

Praefect `dataloss`サブコマンドは、利用できないリポジトリを識別します。これにより、潜在的なデータ損失と、最新のレプリカコピーがすべて利用できないためアクセスできなくなったリポジトリを特定できます。

次のパラメータを使用できます:

- 確認する仮想ストレージを指定する`-virtual-storage`。管理者の介入が必要になる可能性があるため、デフォルトの動作は利用できないリポジトリを表示することです。
- 利用可能だが、利用できない割り当てられたコピーが一部あるリポジトリを出力に含めるかどうかを指定する[`-partially-unavailable`](#unavailable-replicas-of-available-repositories)。

{{< alert type="note" >}}

`dataloss`はまだ[ベータ](../../../policy/development_stages_support.md#beta)版であり、出力形式は変更される可能性があります。

{{< /alert >}}

プライマリが古いか、利用できないリポジトリを確認するには、次を実行します:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

設定されたすべての仮想ストレージは、指定されていない場合はチェックされます:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

正常で完全に最新のコピーが利用できないリポジトリは、出力にリストされます。次の情報は、各リポジトリに対して出力されます:

- ストレージディレクトリへのリポジトリの相対パスは、各リポジトリを識別し、関連情報をグループ化します。
- リポジトリが利用できない場合、ディスクパスの横に`(unavailable)`が出力されます。
- プライマリフィールドには、リポジトリの現在のプライマリがリストされます。リポジトリにプライマリがない場合、フィールドには`No Primary`が表示されます。
- In-Sync Storagesには、最新の書き込みが成功し、その前のすべての書き込みがレプリケートされたレプリカがリストされます。
- Outdated Storagesには、リポジトリの古いコピーが含まれているレプリカがリストされます。リポジトリのコピーがないが、コピーが含まれているはずのレプリカもここにリストされます。レプリカに不足している変更の最大数は、レプリカの横にリストされます。古いレプリカが完全に最新であるか、後で変更が含まれている可能性があることに注意することが重要ですが、Praefectはそれを保証できません。

追加情報には以下が含まれます:

- ノードがリポジトリをホストするように割り当てられているかどうかは、各ノードのステータスとともにリストされます。リポジトリの保存を割り当てられているノードの横に`assigned host`が出力されます。テキストは、ノードにリポジトリのコピーが含まれているが、リポジトリを保存するように割り当てられていない場合は省略されます。このようなコピーはPraefectによって同期された状態に保たれていませんが、割り当てられたコピーを最新の状態にするためのレプリケーションソースとして機能する場合があります。
- 異常なGitalyノードにあるコピーの横に`unhealthy`が出力されます。

出力例: 

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (unavailable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host, unhealthy
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

すべてのリポジトリが使用可能な場合、確認が出力されます。例: 

```shell
Virtual storage: default
  All repositories are available!
```

#### 利用可能なリポジトリの利用できないレプリカ {#unavailable-replicas-of-available-repositories}

利用可能だが、割り当てられた一部のノードから利用できないリポジトリの情報もリストするには、`-partially-unavailable`フラグを使用します。

正常で最新のレプリカが利用可能な場合、リポジトリは利用可能です。最新の変更をレプリケートするのを待機している間、割り当てられたセカンダリレプリカの一部は、一時的にアクセスできなくなる可能性があります。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-unavailable]
```

出力例: 

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git:
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

`-partially-unavailable`フラグを設定すると、割り当てられたすべてのレプリカが完全に最新で正常な場合に確認が出力されます。

例: 

```shell
Virtual storage: default
  All repositories are fully available on all assigned storages!
```

### リポジトリのチェックサムを確認する {#check-repository-checksums}

プロジェクトのリポジトリのチェックサムをすべてのGitalyノードで確認するには、メインのGitLabノードで[レプリカRakeタスク](../../raketasks/praefect.md#replica-checksums)を実行します。

### データ損失を受け入れる {#accept-data-loss}

{{< alert type="warning" >}}

`accept-dataloss`は、リポジトリの他のバージョンを上書きすることにより、永続的なデータ損失を引き起こします。使用する前に、データの[リカバリー作業](#data-recovery)を実行する必要があります。

{{< /alert >}}

最新のレプリカの1つをオンラインに戻すことが不可能な場合は、データ損失を受け入れる必要がある場合があります。データ損失を受け入れると、Praefectは選択されたリポジトリのレプリカを最新バージョンとしてマークし、他の割り当てられたGitalyノードにレプリケートします。このプロセスでは、リポジトリの他のバージョンが上書きされるため、注意が必要です。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss
-virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

### 書き込みを有効にするか、データ損失を受け入れる {#enable-writes-or-accept-data-loss}

{{< alert type="warning" >}}

`accept-dataloss`は、リポジトリの他のバージョンを上書きすることにより、永続的なデータ損失を引き起こします。使用する前に、データの[リカバリー作業](#data-recovery)を実行する必要があります。

{{< /alert >}}

Praefectは、書き込みを再度有効にするか、データ損失を受け入れるための次のサブコマンドを提供します。最新のノードの1つをオンラインに戻すことが不可能な場合は、データ損失を受け入れる必要がある場合があります:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

データ損失を受け入れると、Praefectは次のようになります:

1. リポジトリの選択されたコピーを最新バージョンとしてマークします。
1. コピーを他の割り当てられたGitalyノードにレプリケートします。

   このプロセスでは、リポジトリの他のコピーが上書きされるため、注意が必要です。

## データリカバリー {#data-recovery}

何らかの理由でGitalyノードがレプリケーションジョブに失敗した場合、影響を受けるリポジトリの古いバージョンをホストすることになります。Praefectは、自動調整のためのツールを提供します。これらのツールは、古くなったリポジトリを調整して、完全に最新の状態に戻します。

Praefectは、最新の状態ではないリポジトリを自動的に調整します。デフォルトでは、これは5分ごとに行われます。正常なGitalyノードにある古くなったリポジトリごとに、Praefectはレプリケート元の別の正常なGitalyノードにあるリポジトリのランダムで完全に最新のレプリカを選択します。レプリケーションジョブは、ターゲットリポジトリに対して保留中のレプリケーションジョブがない場合にのみスケジュールされます。

調整の頻度は、設定によって変更できます。値には、有効な[Go言語の期間値](https://pkg.go.dev/time#ParseDuration)を指定できます。0未満の値は、この機能を無効にします。

例: 

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '5m', # the default value
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '30s', # reconcile every 30 seconds
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '0', # disable the feature
   },
}
```

### リポジトリを手動で削除する {#manually-remove-repositories}

`remove-repository` Praefectサブコマンドは、Gitaly Cluster (Praefect)からリポジトリを削除し、指定されたリポジトリに関連付けられているすべての状態を削除します。以下を含みます:

- 関連するすべてのGitalyノードのオンディスクリポジトリ。
- Praefectによって追跡されたデータベースの状態。

デフォルトでは、コマンドはドライランモードで動作します。例: 

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository>
```

- `<virtual-storage>`を、リポジトリを含む仮想ストレージの名前に置き換えます。
- 削除するリポジトリの相対パスで`<repository>`を置き換えます。
- オンディスクリポジトリを削除せずにPraefectトラッキングデータベースエントリを削除するには、`-db-only`を追加します。このオプションを使用して、孤立したデータベースエントリを削除し、有効なリポジトリが誤って指定された場合に、オンディスクのリポジトリデータが削除されないように保護します。データベースエントリが誤って削除された場合は、[`track-repository`コマンド](#manually-add-a-single-repository-to-the-tracking-database)を使用してリポジトリを再度追跡します。
- ドライランモードの外部でコマンドを実行してリポジトリを削除するには、`-apply`を追加します。例: 

  ```shell
  sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository> -apply
  ```

- `-virtual-storage`は、リポジトリが配置されている仮想ストレージです。仮想ストレージは、`/etc/gitlab/gitlab.rb`の`praefect['configuration']['virtual_storage]`で設定されており、次のようになります:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  この例では、指定する仮想ストレージは`default`または`storage-1`です。

- `-repository`は、ストレージ内のリポジトリの相対パスです[`@hashed`から始まります](../../repository_storage_paths.md#hashed-storage)。例: 

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

`remove-repository`の実行後も、リポジトリの一部が存在し続ける可能性があります。これは、次の理由による可能性があります:

- 削除エラー。
- リポジトリをターゲットとする飛行中のRPC呼び出し。

これが発生した場合は、`remove-repository`を再度実行します。

## Praefectトラッキングデータベースのメンテナンス {#praefect-tracking-database-maintenance}

このセクションでは、Praefectトラッキングデータベースに関する一般的なメンテナンスタスクについて説明します。

### 追跡されていないリポジトリを一覧表示する {#list-untracked-repositories}

`list-untracked-repositories` Praefectサブコマンドは、次の両方のGitaly Cluster (Praefect)のリポジトリを一覧表示します:

- 少なくとも1つのGitalyストレージに存在します。
- Praefectトラッキングデータベースで追跡されていません。

`-older-than`オプションを追加して、次のリポジトリが表示されないようにします:

- 作成中です。
- Praefectトラッキングデータベースにレコードがまだ存在しないもの。

`<duration>`を時間の長さ（例: `5s`、`10m`、または`1h`）に置き換えます。`6h`がデフォルトです。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories -older-than <duration>
```

指定された時間より前に作成されたリポジトリのみが考慮されます。

コマンドの出力:

- `STDOUT`とコマンドのログへの結果。
- `STDERR`へのエラー。

各エントリは、末尾に改行が付いた完全なJSON文字列です（`-delimiter`フラグを使用して設定可能）。例: 

```plaintext
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567890.git"}
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567891.git"}
```

### トラッキングデータベースに単一のリポジトリを手動で追加する {#manually-add-a-single-repository-to-the-tracking-database}

{{< alert type="warning" >}}

[既知の問題](https://gitlab.com/gitlab-org/gitaly/-/issues/5402)により、Praefectで生成されたレプリカパス（`@cluster`）を使用して、リポジトリをPraefectトラッキングデータベースに追加できません。これらのリポジトリは、GitLabで使用されるリポジトリパスに関連付けられておらず、アクセスできません。

{{< /alert >}}

`track-repository` Praefectサブコマンドは、ディスク上のリポジトリをPraefectトラッキングデータベースに追加して、追跡できるようにします。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage <virtual-storage> -authoritative-storage <storage-name> -relative-path <repository> -replica-path <disk_path> -replicate-immediately
```

- `-virtual-storage`は、リポジトリが配置されている仮想ストレージです。仮想ストレージは、`/etc/gitlab/gitlab.rb`の`praefect['configuration'][:virtual_storage]`で設定されており、次のようになります:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  この例では、指定する仮想ストレージは`default`または`storage-1`です。

- `-relative-path`は、仮想ストレージ内の相対パスです。通常は、[`@hashed`で始まります](../../repository_storage_paths.md#hashed-storage)。例: 

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

- `-replica-path`は、物理ストレージ上の相対パスです。[`@cluster`で始まるか、`relative_path`に一致させることができます](../../repository_storage_paths.md#gitaly-cluster-praefect-storage)。
- `-authoritative-storage`は、Praefectがプライマリとして扱うストレージです。[リポジトリごとのレプリケーション](configure.md#configure-replication-factor)がレプリケーション戦略として設定されている場合に必要です。
- `-replicate-immediately`を指定すると、コマンドはリポジトリをそのセカンダリにすぐにレプリケートします。そうでない場合、レプリケーションジョブはデータベースでの実行がスケジュールされ、Praefectバックグラウンドプロセスによって取得されます。

コマンドの出力:

- 結果を`STDOUT`とコマンドのログに出力します。
- `STDERR`へのエラー。

このコマンドは、次の場合に失敗します:

- リポジトリが、すでにPraefectトラッキングデータベースによって追跡されている場合。
- リポジトリがディスク上に存在しない場合。

### トラッキングデータベースに複数のリポジトリを手動で追加する {#manually-add-many-repositories-to-the-tracking-database}

{{< alert type="warning" >}}

[既知の問題](https://gitlab.com/gitlab-org/gitaly/-/issues/5402)により、Praefectで生成されたレプリカパス（`@cluster`）を使用して、リポジトリをPraefectトラッキングデータベースに追加できません。これらのリポジトリは、GitLabで使用されるリポジトリパスに関連付けられておらず、アクセスできません。

{{< /alert >}}

APIを使用する移行は、自動的にリポジトリをPraefectトラッキングデータベースに追加します。

代わりに既存のインフラストラクチャからリポジトリを手動でコピーする場合は、`track-repositories` Praefectサブコマンドを使用できます。このサブコマンドは、ディスク上のリポジトリの大きなバッチをPraefectトラッキングデータベースに追加します。

```shell
# Omnibus GitLab install
sudo gitlab-ctl praefect track-repositories --input-path /path/to/input.json

# Source install
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repositories -input-path /path/to/input.json
```

このコマンドは、すべてのエントリを検証します:

- 正しくフォーマットされ、必要なフィールドが含まれている。
- ディスク上の有効なGitリポジトリに対応する。
- Praefectトラッキングデータベースで追跡されていない。

いずれかのエントリがこれらのチェックに失敗した場合、コマンドはリポジトリの追跡を試行する前に中断します。

- `input-path`は、改行区切りのJSONオブジェクトとしてフォーマットされたリポジトリのリストを含むファイルへのパスです。オブジェクトには、次のキーが含まれている必要があります:
  - `relative_path`: [`track-repository`](#manually-add-a-single-repository-to-the-tracking-database)の`repository`に対応します。
  - `authoritative-storage`: Praefectがプライマリとして扱うストレージ。
  - `virtual-storage`: リポジトリが配置されている仮想ストレージ。

    例: 

    ```json
    {"relative_path":"@hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git","replica_path":"@cluster/fe/d3/1","authoritative_storage":"gitaly-1","virtual_storage":"default"}
    {"relative_path":"@hashed/f8/9f/f89f8d0e735a91c5269ab08d72fa27670d000e7561698d6e664e7b603f5c4e40.git","replica_path":"@cluster/7b/28/2","authoritative_storage":"gitaly-2","virtual_storage":"default"}
    ```

- `-replicate-immediately`を指定すると、コマンドはリポジトリをそのセカンダリにすぐにレプリケートします。そうでない場合、レプリケーションジョブはデータベースでの実行がスケジュールされ、Praefectバックグラウンドプロセスによって取得されます。

### 仮想ストレージの詳細を一覧表示する {#list-virtual-storage-details}

`list-storages` Praefectサブコマンドは、仮想ストレージと、それに関連付けられたストレージノードを一覧表示します。仮想ストレージが次の場合:

- `-virtual-storage`を使用して指定すると、指定された仮想ストレージのストレージノードのみが一覧表示されます。
- 指定されていない場合、すべての仮想ストレージと、それに関連付けられたストレージノードが表形式で一覧表示されます。

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-storages -virtual-storage <virtual_storage_name>
```

コマンドの出力:

- 結果を`STDOUT`とコマンドのログに出力します。
- `STDERR`へのエラー。
