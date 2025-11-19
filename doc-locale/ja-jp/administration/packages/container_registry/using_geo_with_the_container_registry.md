---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabコンテナレジストリメタデータデータベースをGeoで使用する
description: GitLabコンテナレジストリメタデータデータベースをGeoで使用する
---
GitLabコンテナレジストリをGeoで使用してコンテナイメージをレプリケートする。各サイトのコンテナレジストリメタデータデータベースは独立しており、Postgresレプリケーションを使用しません。

各セカンダリサイトは、メタデータデータベース用に独自の個別のPostgreSQLインスタンスが必要です。

## コンテナレジストリとGeoでGitLabインスタンスを作成する {#create-a-gitlab-instance-with-the-container-registry-and-geo}

前提要件: 

- GitLabの新しいインスタンス。
- データのないインスタンス用に構成されたコンテナレジストリ。

Geoサポートを設定するには、次の手順を実行します:

1. プライマリサイトとセカンダリサイトのGeoを設定します。詳細については、[2つのシングルノードサイトのGeoのセットアップ](../../geo/setup/two_single_node_sites.md)を参照してください。
1. プライマリサイトとセカンダリサイトで、サイトごとに個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して、[メタデータデータベース](../container_registry_metadata_database.md#new-installations)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## 既存のGeoサイトにコンテナレジストリを追加する {#add-container-registries-to-existing-geo-sites}

前提要件: 

- プライマリサイトおよびセカンダリサイトとして設定された、2つの新しいGitLabインスタンス。
- データのないプライマリサイト用に構成されたコンテナレジストリ。

既存のGeoセカンダリサイトにコンテナレジストリを追加するには、次の手順を実行します:

1. セカンダリサイトで、[コンテナレジストリを有効にする](../container_registry.md)。
1. プライマリサイトとセカンダリサイトで、サイトごとに個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して、[メタデータデータベース](../container_registry_metadata_database.md#new-installations)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## GitLabの既存のインスタンスにGeoサポートとコンテナレジストリを追加する {#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab}

前提要件: 

- コンテナレジストリが構成されていない、既存のGitLabインスタンス。
- Geoサイトは存在しません。

Geoサポートを既存のインスタンスに追加し、コンテナレジストリを両方のGeoサイトに追加するには、次の手順を実行します:

1. 既存のインスタンス（プライマリ）のGeoを設定し、セカンダリサイトを追加します。詳細については、[2つのシングルノードサイトのGeoのセットアップ](../../geo/setup/two_single_node_sites.md)を参照してください。
1. プライマリサイトとセカンダリサイトで:
   1. [コンテナレジストリ](../container_registry.md#enable-the-container-registry)を有効にします。
   1. サイトごとに個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して、[メタデータデータベース](../container_registry_metadata_database.md#new-installations)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

## 構成済みのコンテナレジストリを持つインスタンスにGeoサポートを追加する {#add-geo-support-to-an-instance-with-a-configured-container-registry}

次のセクションでは、構成済みのコンテナレジストリを使用して、GitLabの既存のインスタンスにGeoサポートを追加する手順について説明します。

次のいずれかを設定できます:

- 外部データベース接続。
- コンテナレジストリのレジストリメタデータデータベースのデフォルト。

### 外部データベースコンテナレジストリメタデータデータベースを使用する {#use-an-external-container-registry-metadata-database}

前提要件: 

- 構成済みのコンテナレジストリを持つ、既存のGitLabインスタンス。
- Geoサイトは存在しません。

Geoサポートを既存のインスタンスに追加し、コンテナレジストリをセカンダリサイトに追加するには、次の手順を実行します:

1. 既存のインスタンス（プライマリ）のGeoを設定し、セカンダリサイトを追加します。詳細については、[2つのシングルノードサイトのGeoのセットアップ](../../geo/setup/two_single_node_sites.md)を参照してください。
1. セカンダリサイトでは、:
   1. [コンテナレジストリ](../container_registry.md#enable-the-container-registry)を有効にします。
   1. 個別の[外部データベース](../container_registry_metadata_database.md#using-an-external-database)を使用して、[メタデータデータベース](../container_registry_metadata_database.md#new-installations)をセットアップします。
1. [コンテナレジストリのレプリケーション](../../geo/replication/container_registry.md#configure-container-registry-replication)を設定します。

### デフォルトのコンテナレジストリメタデータデータベースを使用する {#use-the-default-container-registry-metadata-database}

前提要件: 

- 構成済みのコンテナレジストリを持つ、既存のGitLabインスタンス。
- デフォルトのPostgreSQLインスタンスを使用するコンテナレジストリメタデータデータベース。
- Geoサイトは存在しません。

このシナリオでは、メタデータデータベースを外部データベースPostgreSQLインスタンスに移動する必要があります。

1. メタデータデータベースを[外部データベースPostgreSQLインスタンスに移動する](../../postgresql/moving.md)には、こちらの手順に従ってください。
1. [GitLabの既存のインスタンスにGeoサポートとコンテナレジストリを追加する](#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab)手順に進みます。

## レガシーメタデータからコンテナレジストリを移行する {#migrate-the-container-registry-from-legacy-metadata}

このシナリオでは、既存のGeoサイトで、レガシーメタデータから外部データベースPostgreSQLメタデータデータベースにコンテナレジストリを移行する必要があります。

前提要件: 

- GitLab 17.3以降（データベースメタデータサポート）
- プライマリサイトとセカンダリサイトでGeoが構成されている
- レガシーメタデータを使用している両方のサイトのコンテナレジストリ
- 両方のレジストリに既存のデータ（イメージがプッシュされたもの）が必要です

### 移行手順 {#migration-steps}

ダウンタイムはインポート方法によって異なります。インポート方法の推奨事項については、[適切なインポート方法の選択方法](../container_registry_metadata_database.md#how-to-choose-the-right-import-method)を参照してください。

{{< alert type="note" >}}

移行されるレジストリは、インポート中は読み取り専用です。

{{< /alert >}}

移行中、Geoレプリケーションの残りの部分は継続されます。

メタデータデータベースを移行するには:

1. セカンダリサイトで、[既存のレガシーメタデータを新しいメタデータデータベースに移行します](../container_registry_metadata_database.md#existing-registries)。
1. プライマリサイトで、[既存のレガシーメタデータを新しいメタデータデータベースに移行します](../container_registry_metadata_database.md#existing-registries)。
1. Geoレプリケーションが引き続き機能していることを確認します。
