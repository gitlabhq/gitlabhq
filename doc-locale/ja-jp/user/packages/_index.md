---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージとレジストリ
description: パッケージ管理、コンテナレジストリ、アーティファクトストレージ、依存関係管理。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab[パッケージレジストリ](package_registry/_index.md)は、さまざまな一般的なパッケージマネージャーのプライベートレジストリまたはパブリックレジストリとして機能します。パッケージを公開して共有すると、ダウンストリームプロジェクトで依存関係として簡単に利用できます。

## コンテナレジストリ {#container-registry}

GitLab[コンテナレジストリ](container_registry/_index.md)は、コンテナイメージ用の安全なプライベートレジストリです。これはオープンソースソフトウェア上に構築されており、GitLabに完全に統合されています。GitLab CI/CDを使用してイメージを作成および公開します。GitLab [API](../../api/container_registry.md)を使用して、グループおよびプロジェクト全体のレジストリを管理します。

## Terraformモジュールレジストリ {#terraform-module-registry}

GitLab [Terraformモジュールレジストリ](terraform_module_registry/_index.md)は、Terraformモジュール用の安全なプライベートレジストリです。GitLab CI/CDを使用してモジュールを作成および公開できます。

## 仮想レジストリ {#virtual-registry}

GitLab[仮想レジストリ](virtual_registry/_index.md)は、高度なキャッシュ、プロキシ、およびディストリビューション機能を提供するので、GitLabで外部レジストリからパッケージを管理しやすくなります。

## 依存プロキシ {#dependency-proxy}

[依存プロキシ](dependency_proxy/_index.md)は、頻繁に使用されるアップストリームイメージとパッケージのローカルプロキシです。
