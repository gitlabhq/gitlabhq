---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linuxパッケージに同梱されているPostgreSQLバージョン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

この表には、PostgreSQLバージョンに関してパッケージに重要な変更があったGitLabバージョンのみが記載されており、すべてが記載されているわけではありません。

{{< /alert >}}

通常、PostgreSQLバージョンは、GitLabのメジャーリリースまたはマイナーリリースで変更されます。ただし、Linuxパッケージのパッチバージョンでは、PostgreSQLのパッチレベルが更新されることがあります。PostgreSQLのアップグレードのために年間のケイデンスを確立し、新しいバージョンが必要になる前のリリースでデータベースの自動アップグレードをトリガーします。

例: 

- Linuxパッケージ12.7.6には、PostgreSQL 9.6.14および10.9が同梱されていました。
- Linuxパッケージ12.7.7には、PostgreSQL 9.6.17および10.12が同梱されていました。

各Linuxパッケージリリースに、[どのバージョンのPostgreSQL（およびその他のコンポーネント）が同梱されているか](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)を確認してください。

サポートされているPostgreSQLの最低バージョンは、[インストール要件](../../install/requirements.md#postgresql)に記載されています。

PostgreSQLの[アップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)で、更新ポリシーと警告の詳細をお読みください。

| 最初のGitLabバージョン | PostgreSQLのバージョン | 新規インストール時のデフォルトバージョン | アップグレード時のデフォルトバージョン | 備考 |
| -------------- | ------------------- | ---------------------------------- | ---------------------------- | ----- |
| 18.4.1、18.3.3、18.2.7 | 16.10 | 16.10 | 16.10 | |
| 18.0.0 | 16.8 | 16.8 | 16.8 | PostgreSQLがすでに16にアップグレードされていない場合、パッケージのアップグレードは中断されます。 |
| 17.11.0 | 14.17、16.8 | 16.8 | 16.8 | GeoまたはHAクラスタリングの一部ではないノードの場合、[オプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)しない限り、パッケージのアップグレードにより、PostgreSQL 16へのアップグレードが自動的に実行されます。 |
| 17.10.0 | 14.17、16.8 | 16.8 | 16.8 | 新規インストールでは、PostgreSQL 16がデフォルトになりました。 |
| 17.9.2、17.8.5、17.7.7 | 14.17、16.8 | 14.17 | 16.8 | |
| 17.8.0 | 14.15、16.6 | 14.15 | 16.6 | |
| 17.5.0 | 14.11、16.4 | 14.11 | 16.4 | PostgreSQL 14からPostgreSQL 16への単一ノードアップグレードがサポートされるようになりました。GitLab 17.5.0以降、Geoデプロイで新規インストールとアップグレードの両方に対してPostgreSQL 16が完全にサポートされるようになりました（17.4.0からの制限は適用されなくなりました）。 |
| 17.4.0 | 14.11、16.4 | 14.11 | 14.11 | [Geo](../geo/_index.md#requirements-for-running-geo)または[Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)を使用していない場合、PostgreSQL 16を新規インストールに使用できます。 |
| 17.0.0 | 14.11 | 14.11 | 14.11 | PostgreSQLがすでに14にアップグレードされていない場合、パッケージのアップグレードは中断されます。 |
| 16.10.1、16.9.3、16.8.5 | 13.14、14.11 | 14.11 | 14.11 | |
| 16.6.7、16.7.5、16.8.2 | 13.13、14.10 | 14.10 | 14.10 | |
| 16.7.0 | 13.12、14.9 | 14.9 | 14.9 | |
| 16.4.3、16.5.3、16.6.1 | 13.12、14.9 | 13.12 | 13.12 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)に従って、14.9に手動でアップグレードできます。 |
| 16.2.0 | 13.11、14.8 | 13.11 | 13.11 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)に従って、14.8に手動でアップグレードできます。 |
| 16.0.2 | 13.11 | 13.11 | 13.11 | |
| 16.0.0 | 13.8  | 13.8  | 13.8  | |
| 15.11.7 | 13.11 | 13.11 | 12.12 | |
| 15.10.8 | 13.11 | 13.11 | 12.12 | |
| 15.6 | 12.12、13.8 | 13.8 | 12.12 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)に従って、13.8に手動でアップグレードできます。 |
| 15.0 | 12.10、13.6 | 13.6 | 12.10 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)に従って、13.6に手動でアップグレードできます。 |
| 14.1 | 12.7、13.3 | 12.7 | 12.7 | [Geo](../geo/_index.md#requirements-for-running-geo)または[Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)を使用していない場合、PostgreSQL 13を新規インストールに使用できます。 |
| 14.0 | 12.7       | 12.7 | 12.7 | repmgrを使用した高可用性インストールはサポートされなくなり、Linuxパッケージ14.0へのアップグレードは阻止されます |
| 13.8 | 11.9、12.4 | 12.4 | 12.4 | パッケージのアップグレードにより、GeoまたはHAクラスタリングの一部ではないノードに対して、PostgreSQLのアップグレードが自動的に実行されました。 |
| 13.7 | 11.9、12.4 | 12.4 | 11.9 | アップグレードについては、[アップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)に従って、12.4に手動でアップグレードできます。 |
| 13.4 | 11.9、12.4 | 11.9 | 11.9 | PostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます |
| 13.3 | 11.7、12.3 | 11.7 | 11.7 | PostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます |
| 13.0 | 11.7 | 11.7 | 11.7 | PostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます |
| 12.10 | 9.6.17、10.12、および11.7 | 11.7 | 11.7 | パッケージのアップグレードにより、Geoまたはrepmgrクラスタリングの一部ではないノードに対して、PostgreSQLのアップグレードが自動的に実行されました。 |
| 12.8 | 9.6.17、10.12、および11.7 | 10.12 | 10.12 | アップグレードについては、アップグレードドキュメントに従って、11.7に手動でアップグレードできます。 |
| 12.0 | 9.6.11および10.7 | 10.7 | 10.7 | パッケージのアップグレードにより、PostgreSQLのアップグレードが自動的に実行されました。 |
| 11.11 | 9.6.11および10.7 | 9.6.11 | 9.6.11 | アップグレードについては、アップグレードドキュメントに従って、10.7に手動でアップグレードできます。 |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | 9.2を使用している場合、パッケージのアップグレードは中断されます。 |
| 9.0 | 9.2.18および9.6.1 | 9.6.1 | 9.6.1 | パッケージのアップグレードにより、PostgreSQLのアップグレードが自動的に実行されました。 |
| 8.14 | 9.2.18および9.6.1 | 9.2.18 | 9.2.18 | アップグレードについては、アップグレードドキュメントに従って、9.6に手動でアップグレードできます。 |
