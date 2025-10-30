---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabでのNFSの使用
description: GitLabでNFSを使用します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

NFSはオブジェクトストレージの代替として使用できますが、通常、パフォーマンス上の理由から推奨されません。

LFS、アップロード、アーティファクトなどのデータオブジェクトの場合、可能な限り、パフォーマンスが向上するため、NFSよりも[Object Storage service](object_storage.md)が推奨されます。NFSの使用をなくす場合は、オブジェクトストレージに移行するだけでなく、[追加の手順を実行](object_storage.md#alternatives-to-file-system-storage)する必要があります。

NFSはリポジトリストレージには使用できません。

ファイルシステムのパフォーマンスをテストするために使用できる手順については、[ファイルシステムのパフォーマンスベンチマーク](operations/filesystem_benchmarking.md)を参照してください。

## 承認されたSSHキーの高速検索 {#fast-lookup-of-authorized-ssh-keys}

[高速SSHキー検索](operations/fast_ssh_key_lookup.md)機能を使用すると、ブロックストレージを使用している場合でも、GitLabインスタンスのパフォーマンスを向上させることができます。

[高速SSHキー検索](operations/fast_ssh_key_lookup.md)は、GitLabデータベースを使用する`authorized_keys`（`/var/opt/gitlab/.ssh`内）の代替です。

NFSはレイテンシーを増加させるため、`/var/opt/gitlab`をNFSに移動する場合は、高速検索をお勧めします。

現在、[デフォルトとしての高速検索の使用](https://gitlab.com/groups/gitlab-org/-/epics/3104)を検討しています。

## NFSサーバー {#nfs-server}

`nfs-kernel-server`パッケージをインストールすると、GitLabアプリケーションを実行しているクライアントとディレクトリを共有できます:

```shell
sudo apt-get update
sudo apt-get install nfs-kernel-server
```

### 必要な機能 {#required-features}

**ファイルロッキング**: GitLabでは、アドバイザリファイルのロックが**必要**です。これはNFSバージョン4でのみネイティブでサポートされています。NFSv3は、Linuxカーネル2.6.5以降を使用している限り、ロックもサポートしています。バージョン4を使用することをお勧めしますが、NFSv3は特にテストしていません。

### 推奨オプション {#recommended-options}

NFSエクスポートを定義するときは、次のオプションも追加することをお勧めします:

- `no_root_squash` - NFSは通常、`root`ユーザーを`nobody`に変更します。これは、NFS共有が多くの異なるユーザーによってアクセスされる場合の優れたセキュリティ対策です。ただし、この場合、GitLabのみがNFS共有を使用するため、安全です。GitLabは、ファイル権限を自動的に管理する必要があるため、`no_root_squash`設定をお勧めします。この設定がないと、Linuxパッケージが権限を変更しようとしたときにエラーが発生する可能性があります。GitLabおよびその他のバンドルされたコンポーネントは、`root`としてではなく、特権のないユーザーとして実行**されません**。`no_root_squash`の推奨事項は、必要に応じて、Linuxパッケージがファイルの所有権と権限を設定できるようにすることです。`no_root_squash`オプションが使用できない場合、`root`フラグで同じ結果を得ることができます。
- `sync` - 同期動作を強制します。デフォルトは非同期であり、特定の状況下では、データが同期される前に障害が発生した場合、データ損失につながる可能性があります。

LinuxパッケージをLDAPで実行することの複雑さと、LDAPなしでIDマッピングを維持することの複雑さにより、ほとんどの場合、システム間の権限管理を簡素化するために、数値UIDとGIDを有効にする必要があります（場合によってはデフォルトでオフになっています）:

- [NetAppの手順](https://docs.netapp.com/a/ontap/7-mode/8.2.4/File-Access-And-Protocols-Management-Guide-For-7-Mode.pdf)
- NetApp以外のデバイスの場合は、[NFSv4 idmapperを有効にする](https://wiki.archlinux.org/title/NFS#Enabling_NFSv4_idmapping)の反対を実行して、NFSv4 `idmapping`を無効にします

### NFSサーバー委任を無効にする {#disable-nfs-server-delegation}

すべてのNFSユーザーがNFSサーバー委任機能を無効にすることをお勧めします。これは、[多数の`TEST_STATEID` NFSメッセージからの過剰なネットワーキングトラフィック](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52017)が原因で、NFSクライアントの速度が急激に低下する[Linuxカーネルのバグ](https://bugzilla.redhat.com/show_bug.cgi?id=1552203)を回避するためです。

NFSサーバーの委任を無効にするには、次の手順を実行します:

1. NFSサーバーで、次を実行します:

   ```shell
   echo 0 > /proc/sys/fs/leases-enable
   sysctl -w fs.leases-enable=0
   ```

1. NFSサーバープロセスを再起動します。たとえば、CentOSで`service nfs restart`を実行します。

{{< alert type="note" >}}

カーネルのバグは、[このコミットを含むより新しいカーネルで修正](https://github.com/torvalds/linux/commit/95da1b3a5aded124dd1bda1e3cdb876184813140)されている可能性があります。Red Hat Enterprise 7は、この問題も解決している可能性のある、2019年8月6日に[カーネルアップデート](https://access.redhat.com/errata/RHSA-2019:2029)をリリースしました。修正されたLinuxカーネルのバージョンを使用していることがわかっている場合は、NFSサーバーの委任を無効にする必要はない場合があります。そうは言っても、GitLabは、インスタンスの管理者がNFSサーバーの委任を無効にしておくことを引き続き推奨しています。

{{< /alert >}}

## NFSクライアント {#nfs-client}

`nfs-common`は、アプリケーションノードで実行する必要のないサーバーコンポーネントをインストールせずに、NFS機能を提供します。

```shell
apt-get update
apt-get install nfs-common
```

### マウントオプション {#mount-options}

`/etc/fstab`に追加するスニペットの例を次に示します:

```plaintext
10.1.0.1:/var/opt/gitlab/.ssh /var/opt/gitlab/.ssh nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/gitlab-ci/builds nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
```

`nfsstat -m`と`cat /etc/fstab`を実行して、マウントされた各NFSファイルシステムに設定された情報とオプションを表示できます。

使用を検討する必要があるオプションがいくつかあります:

| 設定 | 説明 |
| ------- | ----------- |
| `vers=4.1` | v4.0には、古いデータが原因で重大な問題を引き起こす可能性のあるLinux [NFSクライアントのバグがv4.0にある](https://gitlab.com/gitlab-org/gitaly/-/issues/1339)ため、NFS v4.1を使用する必要があります。 |
| `nofail` | このマウントが使用可能になるのを待機しているブートプロセスを停止しないでください。 |
| `lookupcache=positive` | NFSクライアントに`positive`キャッシュ結果を優先するように指示しますが、`negative`キャッシュ結果は無効にします。ネガティブキャッシュの結果は、Gitで問題を引き起こします。具体的には、`git push`は、すべてのNFSクライアント間で均一に登録できない場合があります。ネガティブキャッシュにより、クライアントはファイルが以前に存在しなかったことを「記憶」します。 |
| `hard` | `soft`の代わりに。[詳細](#soft-mount-option)。 |
| `cto` | `cto`はデフォルトのオプションであり、使用する必要があります。`nocto`は使用しないでください。[詳細](#nocto-mount-option)。 |
| `_netdev` | ネットワークがオンラインになるまで、ファイルシステムのマウントを待ちます。「[`high_availability['mountpoint']`](https://docs.gitlab.com/omnibus/settings/configuration.html#only-start-omnibus-gitlab-services-after-a-given-file-system-is-mounted)」オプションも参照してください。 |

#### `soft`マウントオプション {#soft-mount-option}

`soft`を使用する特定の理由がない限り、マウントオプションで`hard`を使用することをお勧めします。

GitLab.comがNFSを使用していたとき、NFSサーバーの再起動と`soft`可用性が向上したことがあったため、`soft`を使用しましたが、すべてのインフラストラクチャが異なります。たとえば、NFSが冗長コントローラーを備えたオンプレミスストレージ配列によって提供されている場合、NFSサーバーの可用性を心配する必要はありません。

NFSのmanレポートには、次のように記載されています:

> "soft" タイムアウトは、特定の場合にサイレントデータ破損を引き起こす可能性があります

[Linux manレポート](https://linux.die.net/man/5/nfs)を読んで違いを理解し、`soft`を使用する場合は、リスクを軽減するための手順を講じていることを確認してください。

コミット終了など、NFSサーバーでのディスクへの書き込みが発生していないことが原因である可能性がある動作が発生した場合は、`hard`オプションを使用してください（manレポートから）:

> クライアントの応答性がデータの整合性よりも重要な場合にのみ、softオプションを使用してください

他のベンダーも同様の推奨事項を作成しています。[読み取り/書き込みディレクトリに推奨されるマウントオプション](https://help.sap.com/docs/SUPPORT_CONTENT/basis/3354611703.html)やNetAppの[ナレッジベース](https://kb.netapp.com/on-prem/ontap/da/NAS/NAS-KBs/What_are_the_differences_between_hard_mount_and_soft_mount)などです。`soft`は、NFSクライアントドライバーがデータをキャッシュする場合、GitLabによる書き込みが実際にディスク上にあるかどうかは不明であることを意味することを強調しています。

オプション`hard`で設定されたマウントポイントは、パフォーマンスが低下する可能性があり、NFSサーバーがダウンすると、`hard`によってプロセスがハングアップし、マウントポイントとのやり取りが発生します。ハングしたプロセスを処理するには、`SIGKILL`（`kill -9`）を使用します。`intr`オプションは[2.6カーネルでは動作しなくなりました](https://access.redhat.com/solutions/157873)。

#### `nocto`マウントオプション {#nocto-mount-option}

`nocto`は使用しないでください。代わりに、デフォルトである`cto`を使用してください。

`nocto`を使用すると、dentryキャッシュは、作成時から最大`acdirmax`秒（属性キャッシュ時間）まで常に使用されます。

これにより、複数のクライアントでdentryキャッシュの問題が発生し、各クライアントはディレクトリの異なる（キャッシュされた）バージョンを表示できます。

[Linux manレポート](https://linux.die.net/man/5/nfs)からの重要な部分を次に示します:

> `nocto`オプションが指定されている場合、クライアントは標準外のヒューリスティックを使用して、サーバー上のファイルがいつ変更されたかを判断します。
>
> `nocto`オプションを使用すると、読み取り専用マウントのパフォーマンスが向上する可能性がありますが、サーバー上のデータがごくまれにしか変更されない場合にのみ使用する必要があります。

[プッシュ](https://gitlab.com/gitlab-org/gitlab/-/issues/326066)後にrefsが見つからない]という問題でこの動作に気付きました。新しく追加された緩いrefsは、ローカルのdentryキャッシュを持つ別のクライアントで見つからないものと見なされる可能性があります（[このイシューで説明されている](https://gitlab.com/gitlab-org/gitlab/-/issues/326066#note_539436931)とおり）。

### 単一のNFSマウント {#a-single-nfs-mount}

既存のデータを手動で移動せずにバックアップを自動的に復元することができるように、すべてのGitLabデータディレクトリをマウント内にネストされた状態にすることをお勧めします。

```plaintext
mountpoint
└── gitlab-data
    ├── builds
    ├── shared
    └── uploads
```

これを行うには、マウントポイント内にネストされた各ディレクトリへのパスを使用して、Linuxパッケージを次のように設定します:

`/gitlab-nfs`をマウントし、次のLinuxパッケージの設定を使用して、各データの場所をサブディレクトリに移動します:

```ruby
gitlab_rails['uploads_directory'] = '/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-nfs/gitlab-data/builds'
```

`sudo gitlab-ctl reconfigure`を実行して、中心的な場所の使用を開始します。既存のデータがある場合は、これらの新しい場所に手動でコピーまたはrsyncしてから、GitLabを再起動する必要があることに注意してください。

### バインドマウント {#bind-mounts}

Linuxパッケージの設定を変更する代わりに、バインドマウントを使用して、NFSマウントにデータを保存できます。

バインドマウントは、1つのNFSマウントのみを指定し、デフォルトのGitLabデータロケーションをNFSマウントにバインドする方法を提供します。まず、通常行うように、単一のNFSマウントポイントを`/etc/fstab`で定義します。NFSマウントポイントが`/gitlab-nfs`であると仮定しましょう。次に、次のバインドマウントを`/etc/fstab`に追加します:

```shell
/gitlab-nfs/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-nfs/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-nfs/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-nfs/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

バインドマウントを使用するには、復元を試みる前に、データディレクトリが空であることを手動で確認する必要があります。[復元の前提条件](backup_restore/_index.md)の詳細をお読みください。

### 複数のNFSマウント {#multiple-nfs-mounts}

デフォルトのLinuxパッケージの設定を使用する場合、すべてのGitLabクラスタリングノード間で3つのデータロケーションを共有する必要があります。他の場所は共有しないでください。共有する必要がある3つの場所を次に示します:

| 場所 | 説明 | デフォルトの設定 |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/gitlab-rails/uploads` | ユーザーがアップロードした添付ファイル | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'` |
| `/var/opt/gitlab/gitlab-rails/shared` | ビルドアーティファクト、GitLab Pages、LFSオブジェクト、一時ファイルなどのオブジェクト。LFSを使用している場合、これはデータの大部分を占める可能性もあります | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'` |
| `/var/opt/gitlab/gitlab-ci/builds` | GitLab CI/CDビルドトレース | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'` |

他のGitLabディレクトリは、ノード間で共有しないでください。これらには、ノード固有のファイルと、共有する必要のないGitLabコードが含まれています。ログを中央の場所に送信するには、リモートsyslogの使用を検討してください。Linuxパッケージは、[UDPログシッピング](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only)の設定を提供します。

複数のNFSマウントを使用するには、復元を試みる前に、データディレクトリが空であることを手動で確認する必要があります。[復元の前提条件](backup_restore/_index.md)の詳細をお読みください。

## NFSのテスト {#testing-nfs}

NFSサーバーとクライアントをセットアップしたら、次のコマンドをテストして、NFSが正しく設定されていることを確認できます:

```shell
sudo mkdir /gitlab-nfs/test-dir
sudo chown git /gitlab-nfs/test-dir
sudo chgrp root /gitlab-nfs/test-dir
sudo chmod 0700 /gitlab-nfs/test-dir
sudo chgrp gitlab-www /gitlab-nfs/test-dir
sudo chmod 0751 /gitlab-nfs/test-dir
sudo chgrp git /gitlab-nfs/test-dir
sudo chmod 2770 /gitlab-nfs/test-dir
sudo chmod 2755 /gitlab-nfs/test-dir
sudo -u git mkdir /gitlab-nfs/test-dir/test2
sudo -u git chmod 2755 /gitlab-nfs/test-dir/test2
sudo ls -lah /gitlab-nfs/test-dir/test2
sudo -u git rm -r /gitlab-nfs/test-dir
```

`Operation not permitted`エラーが発生した場合は、NFSサーバーのエクスポートオプションを調査する必要があります。

## ファイアウォール環境でのNFS {#nfs-in-a-firewalled-environment}

NFSサーバーとNFSクライアント間のトラフィックがファイアウォールによるポートフィルタリングの対象となる場合は、NFS通信を許可するようにそのファイアウォールを再設定する必要があります。

[Linux Documentation Project（TDLP）のこのガイド](https://tldp.org/HOWTO/NFS-HOWTO/security.html#FIREWALLS)では、ファイアウォール環境でのNFSの使用の基本について説明します。さらに、オペレーティングシステムまたはディストリビューションおよびファイアウォールソフトウェアの特定のドキュメントを検索して確認することをお勧めします。

Ubuntuの例:

コマンド`sudo ufw status`を実行して、ホスト上のファイアウォールでクライアントからのNFSトラフィックが許可されていることを確認します。ブロックされている場合は、次のコマンドを使用して、特定のクライアントからのトラフィックを許可できます。

```shell
sudo ufw allow from <client_ip_address> to any port nfs
```

## 既知の問題 {#known-issues}

### クラウドベースのファイルシステムの使用を避ける {#avoid-using-cloud-based-file-systems}

GitLabは、次のようなクラウドベースのファイルシステムの使用を強く推奨していません:

- Amazon Elastic File System（EFS）。
- Google Cloud Filestore。
- Azure Files。

当社のサポートチームは、クラウドベースのファイルシステムアクセスに関連するパフォーマンスの問題を支援できません。

お客様とユーザーから、これらのファイルシステムは、GitLabが要求するファイルシステムアクセスに対して十分に機能しないというレポートが寄せられています。`git`のように、多くの小さなファイルがシリアル化された方法で書き込まれるワークロードは、クラウドベースのファイルシステムには適していません。

これらを使用する場合は、GitLabログファイル（たとえば、`/var/log/gitlab`にあるログファイル）をそこに保存しないでください。パフォーマンスにも影響するためです。ログファイルはローカルボリュームに保存することをお勧めします。

GitLabでのクラウドベースのファイルシステムの使用経験の詳細については、この[Commit Brooklyn 2019ビデオ](https://youtu.be/K6OS8WodRBQ?t=313)をご覧ください。

### CephFSおよびGlusterFSの使用を避ける {#avoid-using-cephfs-and-glusterfs}

GitLabは、CephFSおよびGlusterFSの使用を強く推奨していません。これらの分散ファイルシステムは、Gitが多くの小さなファイルを使用し、アクセス時間とファイルのロック時間が伝播するためにGitアクティビティーが非常に遅くなるため、GitLabの入力/出力アクセスパターンには適していません。

### NFSでPostgreSQLデータベースを使用しないでください {#avoid-using-postgresql-with-nfs}

GitLabは、NFS経由でPostgreSQLデータベースを実行することを強く推奨していません。GitLabサポートチームは、この設定に関連するパフォーマンスの問題を支援できません。

さらに、この設定は、[PostgreSQLのドキュメント](https://www.postgresql.org/docs/16/creating-cluster.html#CREATING-CLUSTER-NFS)で特に警告されています:

>PostgreSQLはNFSファイルシステムに対して特別なことは何もしません。つまり、NFSはローカル接続されたドライブとまったく同じように動作すると想定しています。クライアントまたはサーバーのNFS実装が標準のファイルシステムセマンティクスを提供しない場合、信頼性の問題が発生する可能性があります。具体的には、NFSサーバーへの遅延(非同期)書き込みは、データ破損の問題を引き起こす可能性があります。

サポートされているデータベースアーキテクチャについては、[レプリケーションとフェイルオーバーのためにデータベースを設定する](postgresql/replication_and_failover.md)に関するドキュメントを参照してください。

## トラブルシューティング {#troubleshooting}

### NFSに対して行われているリクエストの検索 {#finding-the-requests-that-are-being-made-to-nfs}

NFS関連の問題が発生した場合は、`perf`を使用して行われているファイルシステムリクエストをトレーシングすると役立つ場合があります:

```shell
sudo perf trace -e 'nfs4:*' -p $(pgrep -fd ',' puma)
```

Ubuntu 16.04では、次を使用します:

```shell
sudo perf trace --no-syscalls --event 'nfs4:*' -p $(pgrep -fd ',' puma)
```
