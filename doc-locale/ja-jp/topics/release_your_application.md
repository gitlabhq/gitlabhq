---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Environments, packages, review apps, GitLab Pages.
title: アプリケーションをデプロイおよびリリースする
---

デプロイとは、アプリケーションを最終的なターゲットインフラストラクチャにデプロイするソフトウェアデリバリープロセスを指します。

アプリケーションは、社内向けにも一般公開用にもデプロイ可能す。アプリレビューでリリースをプレビューし、機能フラグを使用して機能を段階的にリリースします。

| | | |
|--|--|--|
| [**はじめに**](../user/get_started/get_started_deploy_release.md)<br>機能連携の概要 | [**パッケージとレジストリ**](../user/packages/_index.md)<br>パッケージ管理、コンテナレジストリ、アーティファクトストレージ、依存関係管理 | [**環境**](../ci/environments/_index.md)<br>環境、変数、ダッシュボード、アプリレビュー |
| [**デプロイ**](../ci/environments/deployments.md)<br>デプロイ、ロールバック、安全性、承認 | [**リリース**](../user/project/releases/_index.md)<br>リリース、バージョニング、アセット、タグ、マイルストーン、エビデンス | [**アプリケーションを段階的にロールアウトする**](../ci/environments/incremental_rollouts.md)<br>Kubernetes、CI/CD、リスク軽減、デプロイ |
| [**機能フラグ**](../operations/feature_flags.md)<br>段階的デリバリー、制御されたデプロイ、リスク軽減 | [**GitLab Pages**](../user/project/pages/_index.md)<br>静的サイトホスティング、ドキュメント公開、プロジェクトウェブサイト、カスタムドメイン | |

## 関連トピック

- [Auto DevOps](autodevops/_index.md)はGitLab CI/CDを活用した自動化ワークフローです。ソフトウェアサプライチェーン全体（アプリケーションのビルド、テスト、Lint、パッケージ化、デプロイ、セキュリティ対策、監視）をサポートします。大多数のユースケースに対応する、すぐに使える一連のテンプレートを提供します。
- [Auto Deploy](autodevops/stages.md#auto-deploy)（自動デプロイ）は、GitLab CI/CDを使用したソフトウェアデプロイに特化したDevOpsステージです。Auto Deploy（自動デプロイ）には、EC2およびECSデプロイメントのサポートが組み込まれています。
- [GitLabエージェント](../user/clusters/agent/install/_index.md)を使用してKubernetesクラスターにデプロイします。
- GitLab CI/CDからAWSコマンドを実行するには、Dockerイメージを使用します。[AWSへのデプロイ](../ci/cloud_deployment/_index.md)を円滑にするには、テンプレートを使用します。
- GitLab CI/CDを使用して、GitLab Runnerからアクセス可能なあらゆる種類のインフラストラクチャをターゲットにします。[ユーザー定義および事前定義済みの環境変数](../ci/variables/_index.md)とCI/CDテンプレートは、様々なデプロイ戦略のセットアップをサポートします。
- GitLabの[Cloud Seed](../cloud_seed/_index.md)（オープンソースのインキュベーションエンジニアリングプログラム）を使用して、デプロイの認証情報を設定し、最小限の手間でアプリケーションをGoogle Cloud Runにデプロイします。
