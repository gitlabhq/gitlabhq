---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabインスタンスでマージリクエストの差分の外部ストレージを設定します。
title: マージリクエストの差分ストレージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

マージリクエストの差分は、マージリクエストに関連付けられたサイズ制限のある差分のコピーです。マージリクエストを表示する場合、パフォーマンス最適化のため、可能な限りこれらのコピーから差分が取得されます。

デフォルトでは、GitLabはマージリクエストの差分を`merge_request_diff_files`という名前のテーブルに格納します。より大規模なインストールでは、このテーブルが大きくなりすぎる可能性があるため、その場合は外部ストレージに切り替える必要があります。

マージリクエストの差分は以下に保存できます:

- 完全に[ディスク上](#using-external-storage)。
- 完全に[オブジェクトストレージ上](#using-object-storage)。
- 現在の差分はデータベースに、[期限切れの差分はオブジェクトストレージに](#alternative-in-database-storage)。

## 外部ストレージの使用 {#using-external-storage}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. 外部差分は`/var/opt/gitlab/gitlab-rails/shared/external-diffs`に保存されます。たとえば`/mnt/storage/external-diffs`にパスを変更するには、`/etc/gitlab/gitlab.rb`を編集して次の行を追加します:

   ```ruby
   gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。GitLabは、既存のマージリクエストの差分を外部ストレージに移行します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   external_diffs:
     enabled: true
   ```

1. 外部差分は`/home/git/gitlab/shared/external-diffs`に保存されます。たとえば`/mnt/storage/external-diffs`にパスを変更するには、`/home/git/gitlab/config/gitlab.yml`を編集して次の行を追加または修正します:

   ```yaml
   external_diffs:
     enabled: true
     storage_path: /mnt/storage/external-diffs
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。GitLabは、既存のマージリクエストの差分を外部ストレージに移行します。

{{< /tab >}}

{{< /tabs >}}

## オブジェクトストレージを使用する {#using-object-storage}

> [!warning]
> オブジェクトストレージへの移行は元に戻せません。

外部差分をディスクに保存する代わりに、AWS S3のようなオブジェクトストレージを使用する必要があります。この設定は、有効な事前設定済みのAWS認証情報に依存します。

> [!note]
> 統合オブジェクトストレージの設定で外部差分用のオブジェクトストレージを設定しても、マージリクエストの差分の外部ストレージが自動的に有効になるわけではありません。`external_diffs_enabled`を明示的に`true`に設定する必要があります。

外部差分用のオブジェクトストレージを設定するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. [統合オブジェクトストレージの設定](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を設定します。
1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   external_diffs:
     enabled: true
   ```

1. [統合オブジェクトストレージの設定](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を設定します。
1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

{{< /tab >}}

{{< /tabs >}}

GitLabを再設定または再起動すると、既存のマージリクエストの差分は外部ストレージに移行されます。

詳細については、[オブジェクトストレージ](object_storage.md)を参照してください。

## データベース内での代替ストレージ {#alternative-in-database-storage}

外部差分を有効にすると、他のデータとは別の操作で取得する必要があるため、マージリクエストのパフォーマンスが低下する可能性があります。期限切れの差分のみを外部に保存し、現在の差分はデータベースに保持することで、妥協点を見出すことができます。

この機能を有効にするには、次の手順を実行します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['external_diffs_when'] = 'outdated'
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します。

   ```yaml
   external_diffs:
     enabled: true
     when: outdated
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

{{< /tab >}}

{{< /tabs >}}

この機能を有効にすると、差分は最初は外部ではなくデータベースに保存されます。以下のいずれかの条件が真になると、外部ストレージに移動されます:

- より新しいマージリクエストの差分のバージョンが存在する
- マージリクエストが7日以上前にマージされた
- マージリクエストが7日以上前にクローズされた

これらのルールは、頻繁にアクセスされる差分のみをデータベースに保存することで、スペースとパフォーマンスのバランスを取ります。アクセスされる可能性の低い差分は、代わりに外部ストレージに移動されます。

## 外部ストレージからオブジェクトストレージへの切り替え {#switching-from-external-storage-to-object-storage}

自動移行はデータベースに保存された差分を移動しますが、ストレージタイプ間で差分を移動することはありません。外部ストレージからオブジェクトストレージに切り替えるには:

1. ローカルまたはNFSストレージに保存されているファイルを、手動でオブジェクトストレージに移動します。
1. データベース内の場所を変更するには、このRakeタスクを実行します。

   Linuxパッケージインストールの場合:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage
   ```

   セルフコンパイルインストールの場合:

   ```shell
   sudo -u git -H bundle exec rake gitlab:external_diffs:force_object_storage RAILS_ENV=production
   ```

   デフォルトでは、`sudo`は既存の環境変数を保持しません。このように、プレフィックスとしてではなく、それらを追加する必要があります:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage START_ID=59946109 END_ID=59946109 UPDATE_DELAY=5
   ```

これらの環境変数は、Rakeタスクの動作を変更します:

| 名前           | デフォルト値 | 目的 |
|----------------|---------------|---------|
| `ANSI`         | `true`        | ANSIエスケープコードを使用して、より理解しやすい出力を作成します。 |
| `BATCH_SIZE`   | `1000`        | このサイズのバッチでテーブルをイテレーションします。 |
| `START_ID`     | `nil`         | 設定されている場合、このIDからスキャンを開始します。 |
| `END_ID`       | `nil`         | 設定されている場合、このIDでスキャンを停止します。 |
| `UPDATE_DELAY` | `1`           | 更新間のスリープ秒数。 |

- テーブルの異なる部分に異なるプロセスを割り当てることで、`START_ID`と`END_ID`を使用して更新を並行して実行できます。
- `BATCH`と`UPDATE_DELAY`により、移行速度とテーブルへの同時アクセスとのトレードオフが可能になります。
- ターミナルがANSIエスケープコードをサポートしていない場合、`ANSI`は`false`に設定する必要があります。

オブジェクトストレージとローカルストレージ間の外部差分の分布を確認するには、次のSQLクエリを使用します:

```shell
gitlabhq_production=# SELECT count(*) AS total,
  SUM(CASE
    WHEN external_diff_store = '1' THEN 1
    ELSE 0
  END) AS filesystem,
  SUM(CASE
    WHEN external_diff_store = '2' THEN 1
    ELSE 0
  END) AS objectstg
FROM merge_request_diffs;
```
