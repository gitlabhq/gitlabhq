---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Linux, Helm, Docker, Operator, source, or scripts.
title: インストール方法
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

GitLabはいくつかの[クラウドプロバイダー](cloud_providers.md)にインストールできます。または、次のいずれかの方法を使用することもできます。

## Linuxパッケージ

Linuxパッケージには、公式の`deb`および`rpm`パッケージが含まれています。このパッケージには、GitLab、PostgreSQL、Redis、Sidekiqなどの依存コンポーネントが含まれています。

最も成熟した、スケーラブルな方法が必要な場合に使用します。このバージョンはGitLab.comでも使用されています。

詳細については、以下を参照してください。

- [Linuxパッケージ](https://docs.gitlab.com/omnibus/installation/)
- [リファレンスアーキテクチャー](../administration/reference_architectures/_index.md)
- [システム要件](requirements.md)
- [サポートされているLinuxオペレーティングシステム](../administration/package_information/supported_os.md)

## Helmチャート

チャートを使用して、KubernetesにGitLabのクラウドネイティブバージョンとそのコンポーネントをインストールします。

インフラストラクチャがKubernetes上にあり、その仕組みを理解している場合に使用します。

このインストール方法を使用する前に、以下を検討してください。

- 管理、可観測性、およびその他のいくつかの概念は、従来のデプロイとは異なります。
- 管理とトラブルシューティングには、Kubernetesの知識が必要です。
- 小規模なインストールでは、より高価になる可能性があります。
- デフォルトのインストールでは、ほとんどのサービスが冗長な方法でデプロイされるため、単一ノードのLinuxパッケージのデプロイよりも多くのリソースが必要です。

詳細については、[Helmチャート](https://docs.gitlab.com/charts/)を参照してください。

## GitLab Operator

KubernetesにGitLabのクラウドネイティブバージョンとそのコンポーネントをインストールするには、GitLab Operatorを使用します。このインストールおよび管理方法は、[Kubernetes Operatorパターン](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)に従います。

インフラストラクチャがKubernetesまたは[OpenShift](openshift_and_gitlab/_index.md)上にあり、Operatorの仕組みに慣れている場合に使用します。

このインストール方法では、[GitLabのアップグレード手順](https://docs.gitlab.com/operator/gitlab_upgrades.html)の自動化など、Helmチャートのインストール方法にはない追加機能が提供されます。Helmチャートに関する考慮事項も当てはまります。

[GitLab Operatorの既知のイシュー](https://docs.gitlab.com/operator/#known-issues)によって制限がある場合は、Helmチャートのインストール方法を検討してください。

詳細については、[GitLab Operator](https://docs.gitlab.com/operator/)を参照してください。

## Docker

DockerコンテナにGitLabパッケージをインストールします。

Dockerに慣れている場合に使用します。

詳細については、[Docker](docker/_index.md)を参照してください。

## ソース

GitLabとそのコンポーネントをゼロからインストールします。

前述の方法がいずれもプラットフォームで使用できない場合に使用します。\*BSDなどサポートされていないシステムに使用できます。

詳細については、[ソース](installation.md)を参照してください。

## GitLab Environment Toolkit（GET）

[GitLab Environment Toolkit（GET）](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation)は、一連の確立されたTerraformおよびAnsibleスクリプトです。

いくつかの主要なクラウドプロバイダーに[リファレンスアーキテクチャー](../administration/reference_architectures/_index.md)をデプロイするために使用します。

このインストール方法にはいくつかの[制限](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of)があり、本番環境を手動でセットアップする必要があります。

## サポートされていないLinuxディストリビューションおよびUnix系のオペレーティングシステム

- Arch Linux
- Fedora
- FreeBSD
- Gentoo
- macOS

これらのオペレーティングシステムへのGitLabのインストールは可能ですが、サポートされていません。

詳細については、以下を参照してください。

- [インストールガイド](https://about.gitlab.com/install/)
- [LinuxパッケージインストールでサポートされているOSバージョンとサポートされていないOSバージョン](../administration/package_information/supported_os.md#os-versions-that-are-no-longer-supported)

## Microsoft Windows

GitLabはLinuxベースのオペレーティングシステム向けに開発されています。Microsoft Windows上では**動作しません**。近い将来サポートする予定はありません。最新の開発状況については、こちらの[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/22337)を参照してください。仮想マシンを使用してGitLabを実行することを検討してください。
