---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セカンダリGeoサイトの削除
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

**セカンダリ**サイトは、**プライマリ**サイトのGeo管理ページからGeoクラスタから削除できます。**セカンダリ**サイトを削除するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **ノード**を選択します。
1. 削除する**セカンダリ**サイトで、**削除**を選択します。
1. プロンプトが表示されたら、**削除**を選択して確定します。

**セカンダリ**サイトがGeo管理ページから削除されたら、このサイトを停止してアンインストールする必要があります。セカンダリGeoサイトの各ノードについて:

1. GitLabを停止します:

   ```shell
   sudo gitlab-ctl stop
   ```

1. GitLabをアンインストールします:

   {{< alert type="note" >}}

   GitLabデータもインスタンスから消去する必要がある場合は、[Linuxパッケージとそのすべてのデータをアンインストール](https://docs.gitlab.com/omnibus/installation/#uninstall-the-linux-package-omnibus)する方法を参照してください。

   {{< /alert >}}

   ```shell
   # Stop gitlab and remove its supervision process
   sudo gitlab-ctl uninstall

   # Debian/Ubuntu
   sudo dpkg --remove gitlab-ee

   # Redhat/Centos
   sudo rpm --erase gitlab-ee
   ```

**セカンダリ**サイトの各ノードからGitLabがアンインストールされたら、**プライマリ**サイトのデータベースからレプリケーションスロットを次のように削除する必要があります:

1. **プライマリ**サイトのデータベースノードで、PostgreSQLコンソールセッションを開始します:

   ```shell
   sudo gitlab-psql
   ```

   {{< alert type="note" >}}

   `gitlab-rails dbconsole`を使用しても、レプリケーションスロットの管理にはスーパーユーザー権限が必要なため、機能しません。

   {{< /alert >}}

1. 関連するレプリケーションスロットの名前を見つけます。これは、レプリケートコマンド`gitlab-ctl replicate-geo-database`の実行時に`--slot-name`で指定されるスロットです。

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

1. **セカンダリ**サイトのレプリケーションスロットを削除します:

   ```sql
   SELECT pg_drop_replication_slot('<name_of_slot>');
   ```
