---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: SnykをGitLab CI/CDとアプリケーションセキュリティのためにインテグレーションする方法、ワークフローのセットアップ、SARIFスキャン、脆弱性のレポートなどについて説明します。
title: Snykと統合されたGitLabアプリケーションセキュリティワークフロー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## はじめに {#getting-started}

### ソリューションコンポーネントをダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントwebstore](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

## Snykインテグレーション {#snyk-integration}

これは、GitLab CI/CDコンポーネントを介したSnykとGitLab CI間のインテグレーションです。

## Snykワークフロー {#snyk-workflow}

このプロジェクトには、Snykコマンドラインインターフェースを実行し、SARIF形式でスキャンレポートを出力するコンポーネントがあります。Semgrepベースイメージに基づくジョブを使用して、SARIFをGitLab脆弱性レコード形式に変換する別のコンポーネントを呼び出します。

Snykコマンドラインインターフェースが上にインストールされたノードベースイメージを持つコンテナレジストリにバージョン管理されたコンテナがあります。これは、Snykコンポーネントジョブで使用されるイメージです。`.gitlab-ci.yml`ファイルは、コンテナイメージをビルドし、テストし、コンポーネントをバージョニングします。

### バージョニング {#versioning}

このプロジェクトは、セマンティックバージョニングに従います。
