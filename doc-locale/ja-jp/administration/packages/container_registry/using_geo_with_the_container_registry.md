---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabコンテナレジストリメタデータデータベースをGeoと連携して使用する
description: GitLabコンテナレジストリメタデータデータベースをGeoと連携して使用する
---

GitLabコンテナレジストリをGeoと連携して使用し、コンテナイメージをレプリケートする。各Geoサイトのコンテナレジストリメタデータデータベースは独立しており、Postgresのレプリケーションを使用しません。

各セカンダリサイトは、メタデータデータベース用に独自のPostgreSQLインスタンスを持つ必要があります。

## GitLabインスタンスをコンテナレジストリおよびGeoで作成する {#create-a-gitlab-instance-with-the-container-registry-and-geo}

前提条件: 

- 新規GitLabインスタンス。
- データのないインスタンス用に構成されたコンテナレジストリ。

Geoサポートをセットアップするには:

1. プライマリサイトとセカンダリサイト向けにGeoをセットアップします。詳細については、[2つの単一ノードGeoサイト向けにGeoをセットアップする](../../geo/setup/two_single_node_sites.md)を参照してください。
1. プライマリサイトとセカンダリサイトで、各サイト用に個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して[メタデータデータベース](../container_registry_metadata_database_new_install.md)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## 既存のGeoサイトにコンテナレジストリを追加する {#add-container-registries-to-existing-geo-sites}

前提条件: 

- 新規GitLabインスタンス2つをプライマリサイトおよびセカンダリサイトとしてセットアップ済み。
- プライマリサイト用にデータのないコンテナレジストリが設定済み。

既存のGeoセカンダリサイトにコンテナレジストリを追加するには:

1. セカンダリサイトで、[コンテナレジストリを有効にする](../container_registry.md)。
1. プライマリサイトとセカンダリサイトで、各サイト用に個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して[メタデータデータベース](../container_registry_metadata_database_new_install.md)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## 既存のGitLabインスタンスにGeoサポートとコンテナレジストリを追加する {#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab}

前提条件: 

- コンテナレジストリが設定されていない既存のGitLabインスタンス。
- 既存のGeoサイトなし。

既存のインスタンスにGeoサポートとコンテナレジストリを両方のGeoサイトに追加するには:

1. 既存のインスタンス（プライマリ）用にGeoをセットアップし、セカンダリサイトを追加します。詳細については、[2つの単一ノードGeoサイト向けにGeoをセットアップする](../../geo/setup/two_single_node_sites.md)を参照してください。
1. プライマリサイトとセカンダリサイトで:
   1. [コンテナレジストリを有効にする](../container_registry.md#enable-the-container-registry)。
   1. 各サイト用に個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して[メタデータデータベース](../container_registry_metadata_database_new_install.md)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## 設定済みのコンテナレジストリを持つインスタンスにGeoサポートを追加する {#add-geo-support-to-an-instance-with-a-configured-container-registry}

以下のセクションでは、設定済みのコンテナレジストリを持つ既存のGitLabインスタンスにGeoサポートを追加する手順を説明します。

次のいずれかを設定できます:

- 外部データベース接続。
- デフォルトのコンテナレジストリメタデータデータベース。

### 外部コンテナレジストリメタデータデータベースを使用する {#use-an-external-container-registry-metadata-database}

前提条件: 

- コンテナレジストリが設定されている既存のGitLabインスタンス。
- 既存のGeoサイトなし。

既存のインスタンスにGeoサポートとコンテナレジストリをセカンダリサイトに追加するには:

1. 既存のインスタンス（プライマリ）用にGeoをセットアップし、セカンダリサイトを追加します。詳細については、[2つの単一ノードGeoサイト向けにGeoをセットアップする](../../geo/setup/two_single_node_sites.md)を参照してください。
1. セカンダリサイトで:
   1. [コンテナレジストリを有効にします](../container_registry.md#enable-the-container-registry)。
   1. 個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して[メタデータデータベース](../container_registry_metadata_database_new_install.md)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

### デフォルトのコンテナレジストリメタデータデータベースを使用する {#use-the-default-container-registry-metadata-database}

前提条件: 

- コンテナレジストリが設定されている既存のGitLabインスタンス。
- デフォルトのPostgreSQLインスタンスを使用するコンテナレジストリメタデータデータベース。
- 既存のGeoサイトなし。

このシナリオでは、メタデータデータベースを外部PostgreSQLインスタンスに移動する必要があります。

1. ここに示す手順に従って、[メタデータデータベースを外部PostgreSQLインスタンスに移動](../../postgresql/moving.md)します。
1. [既存のGitLabインスタンスにGeoサポートとコンテナレジストリを追加](#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab)する手順に進みます。

## コンテナレジストリをレガシーメタデータから移行する {#migrate-the-container-registry-from-legacy-metadata}

このシナリオでは、既存のGeoサイトにあるコンテナレジストリを、レガシーメタデータから外部PostgreSQLメタデータデータベースに移行する必要があります。

前提条件: 

- GitLab 17.3以降（データベースメタデータサポート）
- プライマリサイトとセカンダリサイトでGeoが設定されていること
- 両サイトのコンテナレジストリがレガシーメタデータを使用していること
- 両方のレジストリに既存のデータ（コンテナイメージがプッシュされたもの）があること

### 移行手順 {#migration-steps}

ダウンタイムはインポート方法によって異なります。インポート方法の推奨事項については、[適切なインポート方法を選択する方法](../container_registry_metadata_database.md#how-to-choose-the-right-import-method)を参照してください。

> [!note]
> 
> 移行中のレジストリは読み取り専用になります。

移行中も、残りのGeoレプリケーションは続行されます。

メタデータデータベースを移行するには:

1. セカンダリサイトで、[既存のレガシーメタデータを新しいメタデータデータベースに移行する](../container_registry_metadata_database.md#enable-the-database-for-existing-registries)。
1. プライマリサイトで、[既存のレガシーメタデータを新しいメタデータデータベースに移行する](../container_registry_metadata_database.md#enable-the-database-for-existing-registries)。
1. Geoレプリケーションが引き続き機能していることを確認します。
