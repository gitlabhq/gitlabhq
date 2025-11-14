---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 強化 - CI/CDの推奨事項
---

一般的な強化のガイドラインと原則は、[主な強化に関するドキュメント](hardening.md)に記載されています。

CI/CDの強化に関する推奨事項と概念については、次のセクションで説明します。

## 基本的な推奨事項 {#basic-recommendations}

さまざまなCI/CD設定をどのように構成するかは、CI/CDの使用方法によって異なります。たとえば、パッケージをビルドするために使用している場合、Dockerイメージや外部コードリポジトリなどの外部リソースにリアルタイムでアクセスする必要があることがよくあります。Infrastructure as Code（IaC）に使用している場合、外部システムのデプロイを自動化するために、認証情報を保存する必要があることがよくあります。これらや他の多くのシナリオでは、CI/CDの運用中に使用するために、潜在的な機密情報を保存する必要があります。個々のシナリオ自体は多数あるため、CI/CDプロセスを強化するために役立つ基本的な情報をまとめました。

一般的なガイドラインは次のとおりです:

- シークレットを保護します。
- ネットワーク通信が暗号化されていることを確認します。
- 監査およびトラブルシューティングの目的で、徹底的なログ記録を使用します。

## 特定のおすすめ {#specific-recommendations}

パイプラインは、プロジェクトのユーザーに代わってジョブをステージで実行し、タスクを自動化するGitLab CI/CDのコアコンポーネントです。パイプラインの取り扱いに関する具体的なガイドラインについては、[パイプラインセキュリティ](../ci/pipeline_security/_index.md)に関する情報を参照してください。

デプロイは、特定の環境との関係において、パイプラインの結果をデプロイするCI/CDの一部です。デフォルトの設定では多くの制限は課せられず、さまざまな役割と責任を持つさまざまなユーザーがそれらの環境と対話できるパイプラインをトリガーできるため、これらの環境を制限する必要があります。詳細については、[保護された環境](../ci/environments/protected_environments.md)を参照してください。
