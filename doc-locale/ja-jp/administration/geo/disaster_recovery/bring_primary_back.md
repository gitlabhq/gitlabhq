---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 降格されたプライマリサイトをオンラインに戻します
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

フェイルオーバー後、降格された**プライマリ**サイトに復元して、元の設定を復元できます。このプロセスは、次の2つのステップで構成されています:

1. 古い**プライマリ**サイトを**セカンダリ**サイトにします。
1. **セカンダリ**サイトを**プライマリ**サイトにプロモートします。

{{< alert type="warning" >}}

このサイトのデータの整合性について疑問がある場合は、最初からセットアップすることをお勧めします。

{{< /alert >}}

## 以前の**プライマリ**サイトを**セカンダリ**サイトとして設定する {#configure-the-former-primary-site-to-be-a-secondary-site}

以前の**プライマリ**サイトは現在の**プライマリ**サイトと同期していないため、まず以前の**プライマリ**サイトを最新の状態にする必要があります。リポジトリやアップロードなど、ディスクに保存されているデータの削除は、以前の**プライマリ**サイトを同期に戻す際には再生されないため、ディスク使用量が増加する可能性があります。または、これを回避するために、[新しい**セカンダリ** GitLabインスタンスをセットアップする](../setup/_index.md)こともできます。

以前の**プライマリ**サイトを最新の状態にするには、次の手順を実行します:

1. 遅れている以前の**プライマリ**サイトにSSHで接続します。
1. `/etc/gitlab/gitlab-cluster.json`が存在する場合は削除します。

   **セカンダリ**サイトとして再度追加されるサイトが`gitlab-ctl geo promote`コマンドでプロモートされた場合、`/etc/gitlab/gitlab-cluster.json`ファイルが含まれている可能性があります。たとえば、`gitlab-ctl reconfigure`の実行中に、次のような出力が表示される場合があります:

   ```plaintext
   The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
   ```

   その場合は、`/etc/gitlab/gitlab-cluster.json`をサイト内のすべてのSidekiq、PostgreSQL、Gitaly、およびRailsノードから削除して、`/etc/gitlab/gitlab.rb`を再び信頼できる唯一の情報源にする必要があります。

1. すべてのサービスが起動していることを確認してください:

   ```shell
   sudo gitlab-ctl start
   ```

   {{< alert type="note" >}}

   [**プライマリ**サイトを完全にブロックした場合](_index.md#step-2-permanently-disable-the-primary-site)は、これらの手順を元に戻す必要があります。Debian/Ubuntu/CentOS7+などのsystemdを搭載したディストリビューションの場合は、`sudo systemctl enable gitlab-runsvdir`を実行する必要があります。CentOS 6などのsystemdを使用しないディストリビューションの場合は、GitLabインスタンスを最初からインストールし、**セカンダリ**サイトとしてセットアップする必要があります（[セットアップ手順](../setup/_index.md)を参照）。この場合、次の手順に従う必要はありません。

   {{< /alert >}}

   {{< alert type="note" >}}

   [DNSレコードを変更した場合](_index.md#step-4-optional-updating-the-primary-domain-dns-record) 、このディザスターリカバリー手順中に、[このサイトへのすべての書き込みをブロックする](planned_failover.md#prevent-updates-to-the-primary-site)必要がある場合があります。

   {{< /alert >}}

1. [Geoをセットアップする](../setup/_index.md)。この場合、**セカンダリ**サイトは以前の**プライマリ**サイトを指します。
   1. [PgBouncer](../../postgresql/pgbouncer.md)が**current secondary**（現在のセカンダリ）サイト（プライマリサイトだったとき）で有効になっている場合は、`/etc/gitlab/gitlab.rb`を編集し、`sudo gitlab-ctl reconfigure`を実行して無効にします。
   1. 次に、**セカンダリ**サイトでデータベースのレプリケーションをセットアップできます。

元の**プライマリ**サイトを紛失した場合は、[セットアップ手順](../setup/_index.md)に従って、新しい**セカンダリ**サイトをセットアップします。

## **セカンダリ**サイトを**プライマリ**サイトにプロモートする {#promote-the-secondary-site-to-primary-site}

最初のレプリケーションが完了し、**プライマリ**サイトと**セカンダリ**サイトがほぼ同期している場合は、[計画されたフェイルオーバー](planned_failover.md)を実行できます。

## **セカンダリ**サイトを復元します {#restore-the-secondary-site}

目標が再び2つのサイトを持つことである場合は、**セカンダリ**サイトに対して、最初の手順（[以前の**プライマリ**サイトを**セカンダリ**サイトとして設定する](#configure-the-former-primary-site-to-be-a-secondary-site)）を繰り返して、**セカンダリ**サイトをオンラインに戻す必要があります。

### 追加の**セカンダリ**サイトの復元 {#restoring-additional-secondary-sites}

**セカンダリ**サイトが複数ある場合は、残りのサイトをオンラインにすることができます。残りの各サイトについて、**プライマリ**サイトとの[レプリケーションプロセスを開始](../setup/database.md#step-3-initiate-the-replication-process)します。

## **セカンダリ**サイトでのデータの再転送のスキップ {#skipping-re-transfer-of-data-on-a-secondary-site}

セカンダリサイトが追加されたときに、プライマリから同期されるデータがサイトに含まれている場合、Geoはデータの再転送を回避します。

- Gitリポジトリは`git fetch`によって転送され、不足しているrefsのみが転送されます。
- Geoのコンテナレジストリ同期コードは、タグ付けとダイジェストのタプルを比較し、不足しているもののみをプルします。
- 最初の同期で[blob](#skipping-re-transfer-of-blobs)が存在する場合、スキップされます。

ユースケース:

- フェイルオーバーを計画し、古いプライマリサイトをセカンダリサイトとしてアタッチして、再構築せずに降格させます。
- 複数のセカンダリGeoサイトがあります。フェイルオーバーを計画し、他のセカンダリGeoサイトを再構築せずに再アタッチします。
- セカンダリサイトをプロモートおよび降格してフェイルオーバーテストを実行し、再構築せずに再アタッチします。
- バックアップを復元し、サイトをセカンダリサイトとしてアタッチします。
- データをセカンダリサイトに手動でコピーして、同期の問題を回避します。
- Geoトラッキングデータベースでレジストリテーブルの行を削除するか、切り詰めるして、問題を回避します。
- Geoトラッキングデータベースをリセットして、問題を回避します。

### BLOBの再転送のスキップ {#skipping-re-transfer-of-blobs}

{{< history >}}

- GitLab 16.8で`geo_skip_download_if_exists`[フラグ](../../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352530)されました。デフォルトでは無効になっています。
- GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435788)になりました。機能フラグ`geo_skip_download_if_exists`は削除されました。

{{< /history >}}

blobデータが既存のセカンダリサイトを追加すると、セカンダリGeoサイトはそのデータの再転送を回避します。これは以下に適用されます:

- CIジョブのアーティファクト
- CIパイプラインアーティファクト
- CIセキュアファイル
- LFSオブジェクト
- マージリクエストの差分
- パッケージファイル
- ページのデプロイ
- Terraform状態バージョン
- アップロード
- 依存プロキシマニフェスト
- 依存プロキシバイナリラージオブジェクト

セカンダリサイトのコピーが実際に破損している場合、バックグラウンド検証は最終的に失敗し、blobが再同期されます。

blobは、Geoトラッキングデータベースに対応するレジストリレコードがない場合にのみ、この方法でスキップされます。再同期はほぼ常に意図的であり、誤って転送をスキップするリスクを冒すことができないため、条件は厳格です。
