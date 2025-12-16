---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoの無効化
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

テスト後に通常のLinuxパッケージインストール設定に戻す場合、またはディザスターリカバリーが発生し、Geoを一時的に無効にする場合は、これらの手順に従ってGeo設定を無効にできます。

正しく削除した場合、Geoを無効にすることと、セカンダリGeoサイトがないアクティブなGeo設定を持つこととの間に機能的な違いはないはずです。

Geoを無効にするには、次の手順に従います:

1. [すべてのセカンダリGeoサイトを削除](#remove-all-secondary-geo-sites)。
1. [UIからプライマリサイトを削除](#remove-the-primary-site-from-the-ui)。
1. [セカンダリレプリケーションスロットを削除](#remove-secondary-replication-slots)。
1. [Geo関連の設定を削除](#remove-geo-related-configuration)。
1. [オプション。PostgreSQLの設定を元に戻して、パスワードを使用しIPでリッスンするようにする](#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip)。

## すべてのセカンダリGeoサイトを削除 {#remove-all-secondary-geo-sites}

Geoを無効にするには、まずすべてのセカンダリGeoサイトを削除する必要があります。つまり、これらのサイトではレプリケーションはもう行われません。ドキュメントに従って、[すべてのセカンダリGeoサイトを削除できます](remove_geo_site.md)。

現在使用しているサイトがセカンダリサイトである場合は、最初にプライマリにプロモートする必要があります。[セカンダリサイトをプロモートする方法](../disaster_recovery/_index.md#step-3-promoting-a-secondary-site)の手順を使用できます。

## UIからプライマリサイトを削除 {#remove-the-primary-site-from-the-ui}

**プライマリ**サイトを削除するには、次の手順を実行します:

1. [すべてのセカンダリGeoサイトを削除](remove_geo_site.md)
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**Geo** > **ノード**を選択します。
1. **削除**を選択して**プライマリ**ノードを選択します。
1. **削除**を選択して、プロンプトが表示されたら確定します。

## セカンダリレプリケーションスロットを削除 {#remove-secondary-replication-slots}

セカンダリレプリケーションスロットを削除するには、PostgreSQLコンソール（`sudo gitlab-psql`）でプライマリGeoノードのいずれかのクエリを実行します:

- PostgreSQLクラスターが既にある場合は、個々のレプリケーションスロットを名前で削除して、同じクラスターからセカンダリデータベースが削除されないようにします。次のクエリを使用すると、すべての名前を取得し、個々のスロットを削除できます:

  ```sql
  SELECT slot_name, slot_type, active FROM pg_replication_slots; -- view present replication slots
  SELECT pg_drop_replication_slot('slot_name'); -- where slot_name is the one expected from the previous command
  ```

- すべてのセカンダリレプリケーションスロットを削除するには、次の手順を実行します:

  ```sql
  SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots;
  ```

## Geo関連の設定を削除 {#remove-geo-related-configuration}

1. プライマリGeoサイトの各ノードで、SSHを使用してノードに接続し、rootとしてサインインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`geo_primary_role`を有効にした行を削除して、Geo関連の設定を削除します:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_primary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_primary_role']
   ```

1. これらの変更を加えた後、変更を有効にするには、[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## （オプション）パスワードを使用し、IPでリッスンするようにPostgreSQL設定を元に戻します {#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip}

PostgreSQL固有の設定を削除してデフォルト（代わりにソケットを使用）に戻す場合は、`/etc/gitlab/gitlab.rb`ファイルから次の行を安全に削除できます:

```ruby
postgresql['sql_user_password'] = '...'
gitlab_rails['db_password'] = '...'
postgresql['listen_address'] = '...'
postgresql['md5_auth_cidr_addresses'] =  ['...', '...']
```
