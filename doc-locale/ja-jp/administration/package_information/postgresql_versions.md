---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージに同梱されているPostgreSQLのバージョン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!note]
> この表には、PostgreSQLのバージョンに関してパッケージで重要な変更があったGitLabのバージョンのみをリストしており、すべてではありません。

通常、PostgreSQLのバージョンは、GitLabのメジャーまたはマイナーリリースとともに変更されます。しかし、Linuxパッケージのパッチバージョンは、PostgreSQLのパッチレベルを更新することがあります。PostgreSQLアップグレードの年次ケイデンスを確立し、新しいバージョンが必要になる前のリリースでデータベースの自動アップグレードをトリガーします。

例: 

- Linuxパッケージ12.7.6にはPostgreSQL 9.6.14と10.9が同梱されていました。
- Linuxパッケージ12.7.7にはPostgreSQL 9.6.17と10.12が同梱されていました。

各Linuxパッケージリリースに同梱されている[PostgreSQLのバージョン（およびその他のコンポーネント）](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)を確認してください。

サポートされているPostgreSQLの最低バージョンは、[インストール要件](../../install/requirements.md#postgresql)に記載されています。

更新ポリシーと警告の詳細については、PostgreSQLの[アップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)を参照してください。

| 最初のGitLabバージョン | PostgreSQLのバージョン | 新規インストール用のデフォルトバージョン | アップグレード用のデフォルトバージョン | 備考 |
| -------------- | ------------------- | ---------------------------------- | ---------------------------- | ----- |
| 19.3.0 | 17.10, 18.4 | 17.10 | 17.10 | PostgreSQL 18.4は、新規インストールでオプトインオプションとして利用できます。 |
| 19.0.0 | 17.8 | 17.8 | 17.8 | PostgreSQLがすでに17にアップグレードされていない場合、パッケージのアップグレードは中断されます。 |
| 18.11.0 | 16.11, 17.7 | 17.7 | 17.7 | 新規インストールはPostgreSQL 17をデフォルトとします。[オプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)しない限り、Linuxパッケージインスタンスのアップグレードは、GeoまたはHAクラスターの一部ではないノードに対してPostgreSQL 17へのアップグレードを自動的に実行します。 |
| 18.4.1、18.3.3、18.2.7 | 16.10 | 16.10 | 16.10 | |
| 18.0.0 | 16.8 | 16.8 | 16.8 | PostgreSQLがすでに16にアップグレードされていない場合、パッケージのアップグレードは中断されます。 |
| 17.11.0 | 14.17, 16.8 | 16.8 | 16.8 | [オプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)しない限り、パッケージのアップグレードは、GeoまたはHAクラスターの一部ではないノードに対してPostgreSQL 16へのアップグレードを自動的に実行します。 |
| 17.10.0 | 14.17, 16.8 | 16.8 | 16.8 | 新規インストールはPostgreSQL 16をデフォルトとします。 |
| 17.9.2、17.8.5、17.7.7 | 14.17, 16.8 | 14.17 | 16.8 | |
| 17.8.0 | 14.15, 16.6 | 14.15 | 16.6 | |
| 17.5.0 | 14.11, 16.4 | 14.11 | 16.4 | PostgreSQL 14からPostgreSQL 16への単一ノードのアップグレードがサポートされました。GitLab 17.5.0以降、PostgreSQL 16はGeoデプロイメントでの新規インストールとアップグレードの両方で完全にサポートされています（17.4.0からの制限は適用されなくなりました）。 |
| 17.4.0 | 14.11, 16.4 | 14.11 | 14.11 | [Geo](../geo/_index.md#requirements-for-running-geo)または[Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)を使用していない場合、PostgreSQL 16は新規インストールで利用できます。 |
| 17.0.0 | 14.11 | 14.11 | 14.11 | PostgreSQLがすでに14にアップグレードされていない場合、パッケージのアップグレードは中断されます。 |
| 16.10.1、16.9.3、16.8.5 | 13.14, 14.11 | 14.11 | 14.11 | |
| 16.6.7, 16.7.5, 16.8.2 | 13.13, 14.10 | 14.10 | 14.10 | |
| 16.7.0 | 13.12, 14.9 | 14.9 | 14.9 | |
| 16.4.3, 16.5.3, 16.6.1 | 13.12, 14.9 | 13.12 | 13.12 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)に従って手動で14.9にアップグレードできます。 |
| 16.2.0 | 13.11, 14.8 | 13.11 | 13.11 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_16_changes.md#linux-package-installations-2)に従って手動で14.8にアップグレードできます。 |
| 16.0.2 | 13.11 | 13.11 | 13.11 | |
| 16.0.0 | 13.8  | 13.8  | 13.8  | |
| 15.11.7 | 13.11 | 13.11 | 12.12 | |
| 15.10.8 | 13.11 | 13.11 | 12.12 | |
| 15.6 | 12.12, 13.8 | 13.8 | 12.12 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)に従って手動で13.8にアップグレードできます。 |
| 15.0 | 12.10, 13.6 | 13.6 | 12.10 | アップグレードについては、[アップグレードドキュメント](../../update/versions/gitlab_15_changes.md#linux-package-installations-2)に従って手動で13.6にアップグレードできます。 |
| 14.1 | 12.7, 13.3 | 12.7 | 12.7 | [Geo](../geo/_index.md#requirements-for-running-geo)または[Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations)を使用していない場合、PostgreSQL 13は新規インストールで利用できます。 |
| 14.0 | 12.7       | 12.7 | 12.7 | repmgrを使用したHAインストールはサポートされなくなり、Linuxパッケージ14.0へのアップグレードは防止されます。 |
| 13.8 | 11.9, 12.4 | 12.4 | 12.4 | GeoまたはHAクラスターの一部ではないノードに対して、パッケージのアップグレードによりPostgreSQLのアップグレードが自動的に実行されました。 |
| 13.7 | 11.9, 12.4 | 12.4 | 11.9 | アップグレードについては、[アップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)に従って手動で12.4にアップグレードできます。 |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | ユーザーがすでにPostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます。 |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | ユーザーがすでにPostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます。 |
| 13.0 | 11.7 | 11.7 | 11.7 | ユーザーがすでにPostgreSQL 11を実行していない場合、パッケージのアップグレードは中断されます。 |
| 12.10 | 9.6.17, 10.12, and 11.7 | 11.7 | 11.7 | Geoまたはrepmgrクラスターの一部ではないノードに対して、パッケージのアップグレードによりPostgreSQLのアップグレードが自動的に実行されました。 |
| 12.8 | 9.6.17, 10.12, and 11.7 | 10.12 | 10.12 | ユーザーは、アップグレードドキュメントに従って手動で11.7にアップグレードできます。 |
| 12.0 | 9.6.11 and 10.7 | 10.7 | 10.7 | パッケージのアップグレードによりPostgreSQLのアップグレードが自動的に実行されました。 |
| 11.11 | 9.6.11 and 10.7 | 9.6.11 | 9.6.11 | ユーザーは、アップグレードドキュメントに従って手動で10.7にアップグレードできます。 |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | ユーザーがまだ9.2の場合、パッケージのアップグレードは中断されます。 |
| 9.0 | 9.2.18 and 9.6.1 | 9.6.1 | 9.6.1 | パッケージのアップグレードによりPostgreSQLのアップグレードが自動的に実行されました。 |
| 8.14 | 9.2.18 and 9.6.1 | 9.2.18 | 9.2.18 | ユーザーは、アップグレードドキュメントに従って手動で9.6にアップグレードできます。 |
