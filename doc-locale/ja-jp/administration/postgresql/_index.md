---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: スケーリングのためのPostgreSQLの設定
description: スケーリングのためにPostgreSQLを設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセクションでは、[リファレンスアーキテクチャ](../reference_architectures/_index.md)のいずれかでGitLabが使用するPostgreSQLデータベースの設定方法について説明します。

## 設定オプション {#configuration-options}

以下のPostgreSQLの設定オプションから1つ選択してください:

### Linuxパッケージインストール用のスタンドアロンPostgreSQL {#standalone-postgresql-for-linux-package-installations}

このセットアップは、[Linuxパッケージ](https://about.gitlab.com/install/)（CEまたはEE）を使用してGitLabをインストールした際に、バンドルされているPostgreSQLのサービスのみを有効化して使用する場合を対象としています。

Linuxパッケージインストール用の[スタンドアロンPostgreSQLインスタンスをセットアップする方法](standalone.md)を読んでください。

### 独自のPostgreSQLインスタンスを提供する {#provide-your-own-postgresql-instance}

このセットアップは、[Linuxパッケージ](https://about.gitlab.com/install/)（CEまたはEE）を使用してGitLabをインストールした際、または[自己コンパイル](../../install/self_compiled/_index.md)でインストールした際に、独自の外部PostgreSQLサーバーを使用する場合を対象としています。

[外部PostgreSQLインスタンスをセットアップする方法](external.md)を読んでください。

外部データベースをセットアップする際には、モニタリングとトラブルシューティングに役立ついくつかのメトリクスがあります。外部データベースをセットアップする際には、様々なデータベース関連の問題をトラブルシューティングするために、モニタリングとロギングの設定が必要です。[外部データベースのモニタリングとロギングのセットアップ](external_metrics.md)について、詳細はこちらをお読みください。

### Linuxパッケージインストール用のPostgreSQLレプリケーションおよびフェイルオーバー {#postgresql-replication-and-failover-for-linux-package-installations}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセットアップは、[Linux **Enterprise Edition**（EE）パッケージ](https://about.gitlab.com/install/?version=ee)を使用してGitLabをインストールした場合を対象としています。

PostgreSQL、PgBouncer、Patroniなど、必要なすべてのツールはパッケージにバンドルされているため、それを使用してPostgreSQLインフラストラクチャ全体（プライマリ、レプリカ）をセットアップできます。

Linuxパッケージインストール用の[PostgreSQLレプリケーションとフェイルオーバーのセットアップ方法](replication_and_failover.md)を読んでください。

## 関連トピック {#related-topics}

- [バンドルされているPgBouncerサービスの使用](pgbouncer.md)
- [データベースロードバランシング](database_load_balancing.md)
- [GitLabデータベースを別のPostgreSQLインスタンスに移行する](moving.md)
- GitLab開発用データベースガイド
- [外部データベースをアップグレードする](external_upgrade.md)
- [PostgreSQL用のオペレーティングシステムをアップグレードする](upgrading_os.md)
