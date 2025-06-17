---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージとレジストリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabの[パッケージレジストリ](package_registry/_index.md)は、さまざまな一般的なパッケージマネージャーのプライベートレジストリまたはパブリックレジストリとして機能します。パッケージを公開して共有し、ダウンストリームプロジェクトで依存関係として簡単に使用できます。

## コンテナレジストリ

GitLabの[コンテナレジストリ](container_registry/_index.md)は、コンテナイメージ用の安全なプライベートレジストリです。これはオープンソースソフトウェア上に構築されており、GitLabに完全に統合されています。GitLab CI/CDを使用してイメージを作成および公開します。GitLab [API](../../api/container_registry.md)を使用して、グループおよびプロジェクト全体のレジストリを管理します。

## Terraform モジュールレジストリ

GitLabの[Terraform モジュールレジストリ](terraform_module_registry/_index.md)は、Terraform モジュール用の安全なプライベートレジストリです。GitLab CI/CDを使用してモジュールを作成および公開できます。

## 依存プロキシ

[依存プロキシ](dependency_proxy/_index.md)は、頻繁に使用されるアップストリームイメージとパッケージのローカルプロキシです。
