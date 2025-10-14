---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 環境、パッケージ、レビューアプリ、GitLab Pages。
title: アプリケーションをデプロイおよびリリースする
---

デプロイとは、アプリケーションを最終的なターゲットインフラストラクチャにデプロイするソフトウェアデリバリープロセスを指します。

アプリケーションは、社内向けにも一般公開用にもデプロイ可能です。レビューアプリでリリースをプレビューし、機能フラグを使用して機能を段階的にリリースします。

{{< cards >}}

- [はじめに](../user/get_started/get_started_deploy_release.md)
- [パッケージとレジストリ](../user/packages/_index.md)
- [環境](../ci/environments/_index.md)
- [デプロイ](../ci/environments/deployments.md)
- [リリース](../user/project/releases/_index.md)
- [アプリケーションの段階的なロールアウト](../ci/environments/incremental_rollouts.md)
- [機能フラグ](../operations/feature_flags.md)
- [GitLab Pages](../user/project/pages/_index.md)

{{< /cards >}}

## 関連トピック {#related-topics}

- [Auto DevOps](autodevops/_index.md)はGitLab CI/CDを活用した自動化ワークフローです。ソフトウェアサプライチェーン全体（アプリケーションのビルド、テスト、lint、パッケージ化、デプロイ、セキュリティ対策、監視）をサポートします。大多数のユースケースに対応する、すぐに使える一連のテンプレートを提供します。
- [自動デプロイ](autodevops/stages.md#auto-deploy)は、GitLab CI/CDを使用したソフトウェアのデプロイに特化したDevOpsステージです。自動デプロイには、EC2およびECSのデプロイメントのサポートが組み込まれています。
- Kubernetesクラスターにデプロイするには、[Kubernetes向けGitLabエージェント](../user/clusters/agent/install/_index.md)を使用してください。
- Dockerイメージを使用してGitLab CI/CDからAWSコマンドを実行します。[AWSへのデプロイ](../ci/cloud_deployment/_index.md)を円滑にするには、テンプレートを使用します。
- GitLab Runnerからアクセス可能なあらゆる種類のインフラストラクチャをターゲットにするには、GitLab CI/CDを使用します。[ユーザー定義および事前定義済みの環境変数](../ci/variables/_index.md)とCI/CDテンプレートは、さまざまなデプロイ戦略の設定をサポートします。
- GitLabの[Cloud Seed](../cloud_seed/_index.md)を使用してデプロイの認証情報を設定し、最小限の手間でアプリケーションをGoogle Cloud Runにデプロイします。
