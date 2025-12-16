---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スケールするためのPostgreSQLの設定
description: スケールするためにPostgreSQLを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセクションでは、[リファレンスアーキテクチャ](../reference_architectures/_index.md)のいずれかでGitLabが使用するPostgreSQLデータベースの設定方法について説明します。

## 設定オプション {#configuration-options}

次のいずれかのPostgreSQL設定オプションを選択します:

### Linuxパッケージインストール用のスタンドアロンPostgreSQL {#standalone-postgresql-for-linux-package-installations}

このセットアップは、[Linuxパッケージ](https://about.gitlab.com/install/)（CEまたはEE）を使用してGitLabをインストールした際に、バンドルされているPostgreSQLのサービスのみを有効化して使用する場合を対象としています。

Linuxパッケージインストール用に[スタンドアロンPostgreSQLインスタンスをセットアップする](standalone.md)方法をお読みください。

### 独自のPostgreSQLインスタンスを提供する {#provide-your-own-postgresql-instance}

このセットアップは、[Linuxパッケージ](https://about.gitlab.com/install/)（CEまたはEE）を使用してGitLabをインストールした際、または[自己コンパイル](../../install/self_compiled/_index.md)でインストールした際に、独自の外部PostgreSQLサーバーを使用する場合を対象としています。

[外部PostgreSQLインスタンスをセットアップする](external.md)方法をお読みください。

外部データベースをセットアップする場合、モニタリングとトラブルシューティングに役立つメトリクスがいくつかあります。外部データベースをセットアップする場合、さまざまなデータベース関連の問題をトラブルシューティングするために必要なモニタリングおよびログ設定があります。[外部データベースのモニタリングおよびログセットアップ](external_metrics.md)の詳細をお読みください。

### Linuxパッケージインストール用のPostgreSQLレプリケーションとフェイルオーバー {#postgresql-replication-and-failover-for-linux-package-installations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセットアップは、[Linux **Enterprise Edition**（EE）パッケージ](https://about.gitlab.com/install/?version=ee)を使用してGitLabをインストールした場合のものです。

PostgreSQL、PgBouncer、Patroniなど、必要なツールはすべてパッケージにバンドルされているため、これを使用してPostgreSQLインフラストラクチャ全体（プライマリ、レプリカ）をセットアップできます。

Linuxパッケージインストール用に[PostgreSQLレプリケーションとフェイルオーバーをセットアップする](replication_and_failover.md)方法をお読みください。

## 関連トピック {#related-topics}

- [バンドルPgBouncerサービスの使用](pgbouncer.md)
- [データベースロードバランシング](database_load_balancing.md)
- [別のPostgreSQLインスタンスへのGitLabデータベースの移動](moving.md)
- GitLab開発用データベースガイド
- [外部データベースをアップグレードする](external_upgrade.md)
- [PostgreSQL用のオペレーティングシステムをアップグレードする](upgrading_os.md)
