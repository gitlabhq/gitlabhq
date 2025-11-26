---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoをセットアップする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## 前提要件 {#prerequisites}

- 独立して動作するGitLabサイトが2つ以上必要です:
  - 1つのGitLabサイトが、Geoの**プライマリ**サイトとして機能します。これを設定するには、[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用してください。各Geoサイトに異なるリファレンスアーキテクチャのサイズを使用できます。すでに使用中のGitLabインスタンスがある場合は、**プライマリ**サイトとして使用できます。
  - 2番目のGitLabサイトは、Geoの**セカンダリ**サイトとして機能します。これを設定するには、[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用してください。サインインしてテストすることをお勧めします。ただし、**all of the data on the secondary are lost**（セカンダリ）上のすべてのデータは、**プライマリ**サイトからのレプリケーションのプロセスの一部として失われることに注意してください。

    {{< alert type="note" >}}

    Geoは複数のセカンダリをサポートしています。同じ手順に従って、必要に応じて変更を加えることができます。

    {{< /alert >}}

- **プライマリ**サイトがGeoのロックを解除するには、[GitLab PremiumまたはUltimateプラン](https://about.gitlab.com/pricing/)のサブスクリプションが必要です。すべてのサイトに必要なライセンスは1つだけです。
- すべてのサイトが[Geoの実行要件](../_index.md#requirements-for-running-geo)を満たしていることを確認します。たとえば、サイトは同じGitLabバージョンを使用する必要があり、サイトは特定のポートを介して相互に通信できる必要があります。
- **プライマリ**サイトと**セカンダリ**サイトのストレージ設定が一致することを確認します。プライマリGeoサイトがオブジェクトストレージを使用している場合、セカンダリGeoサイトもそれを使用する必要があります。詳細については、[オブジェクトストレージでのGeo](../replication/object_storage.md)を参照してください。
- **プライマリ**サイトと**セカンダリ**サイトの間でクロックが同期されていることを確認します。Geoが正しく機能するためには、同期されたクロックが必要です。たとえば、**プライマリ**サイトと**セカンダリ**サイト間のクロックドリフトが1分を超えると、レプリケーションが失敗します。

## Linuxパッケージを使用してGitLabをインストールする場合 {#using-linux-package-installations}

Linuxパッケージを使用してGitLabをインストールした場合（強く推奨）、Geoをセットアップするプロセスは、シングルノードのGeoサイトまたはマルチノードのGeoサイトをセットアップする必要があるかどうかによって異なります。

### シングルノードGeoサイト {#single-node-geo-sites}

両方のGeoサイトが[1Kリファレンスアーキテクチャ](../../reference_architectures/1k_users.md)に基づいている場合は、[2つのシングルノードサイトのGeoのセットアップ](two_single_node_sites.md)に従ってください。

外部PostgreSQLサービス（たとえば、Amazon Relational Database Service）を使用している場合は、[（外部PostgreSQLサービスを使用した）2つのシングルノードサイトのGeoのセットアップ](two_single_node_external_services.md)に従ってください。

GitLabのデプロイによっては、LDAP、オブジェクトストレージ、およびコンテナレジストリの[追加設定](#additional-configuration)が必要になる場合があります。

### マルチノードGeoサイト {#multi-node-geo-sites}

サイトの1つ以上が[40 RPS / 2,000ユーザーリファレンスアーキテクチャ](../../reference_architectures/2k_users.md)以上を使用している場合は、[マルチノードのGeoの設定](../replication/multiple_servers.md)を参照してください。

GitLabのデプロイによっては、LDAP、オブジェクトストレージ、およびコンテナレジストリの[追加設定](#additional-configuration)が必要になる場合があります。

### 参照用の一般的な手順 {#general-steps-for-reference}

1. 選択したPostgreSQLインスタンスに基づいてデータベースレプリケーションをセットアップします（`primary (read-write) <-> secondary (read-only)`トポロジ）:
   - [LinuxパッケージのPostgreSQLインスタンスを使用する](database.md)。
   - [外部PostgreSQLインスタンスを使用する](external_database.md)
1. [プライマリサイト](../replication/configuration.md)と**プライマリ**サイトを設定するには、**セカンダリ**。
1. [Geoサイトの使用](../replication/usage.md)ガイドに従ってください。

GitLabのデプロイによっては、LDAP、オブジェクトストレージ、およびコンテナレジストリの[追加設定](#additional-configuration)が必要になる場合があります。

### 追加の設定 {#additional-configuration}

GitLabの使用方法によっては、次の設定が必要になる場合があります:

- **プライマリ**サイトがオブジェクトストレージを使用している場合は、[セカンダリサイト](../replication/object_storage.md)の**セカンダリ**。
- LDAPを使用する場合は、[セカンダリサイト](../../auth/ldap/_index.md)の**セカンダリ**。詳細については、[GeoでのLDAP](../replication/single_sign_on.md#ldap)を参照してください。
- コンテナレジストリを使用する場合は、[プライマリサイト](../replication/container_registry.md)と**プライマリ**で**セカンダリ**。

すべてのGeoサイトに単一の統一URLを使用するには、[統合URLを設定する](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites)必要があります。

## GitLabチャートの使用 {#using-gitlab-charts}

[GitLab Geoを使用してGitLabチャートを設定します](https://docs.gitlab.com/charts/advanced/geo/)。

## Geoとセルフコンパイルインストール {#geo-and-self-compiled-installations}

[自己コンパイルされたGitLabインスタンス](../../../install/self_compiled/_index.md)を使用する場合、Geoはサポートされていません。

## インストール後の作業に関するドキュメント {#post-installation-documentation}

**セカンダリ**サイトにGitLabをインストールして初期設定を実行した後、インストール後の情報については[次のドキュメントを参照してください](../_index.md#post-installation-documentation)。
