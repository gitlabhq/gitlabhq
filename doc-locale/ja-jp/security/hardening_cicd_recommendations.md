---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 強化 - CI/CDの推奨事項
---

一般的な強化のガイドラインと理念は、[メインの強化ドキュメント](hardening.md)に概説されています。

強化の推奨事項とCI/CDの概念については、次のセクションで説明します。

## 基本的な推奨事項 {#basic-recommendations}

さまざまなCI/CD設定をどのように構成するかは、CI/CDの使用方法によって異なります。たとえば、パッケージをビルドするために使用する場合、Dockerイメージや外部コードリポジトリなどの外部リソースへのリアルタイムアクセスが必要になることがよくあります。Infrastructure as Code (IaC) に使用する場合、外部システムがデプロイを自動化するための認証情報を保存する必要があることがよくあります。これらおよびその他の多くのシナリオでは、CI/CD操作中に使用される可能性のある機密情報を保存する必要があります。個々のシナリオは多数あるため、CI/CDプロセスを強化するのに役立ついくつかの基本的な情報がまとめられています。

一般的なガイダンスは次のとおりです:

- シークレットを保護します。
- ネットワーク通信が暗号化されたことを確認します。
- 監査およびトラブルシューティングのために、徹底的なログを使用します。

## 具体的な推奨事項 {#specific-recommendations}

パイプラインは、GitLab CI/CDのコアコンポーネントであり、プロジェクトユーザーのためにタスクを自動化するためにステージでジョブを実行します。パイプラインの処理に関する具体的なガイドラインについては、[パイプラインセキュリティ](../ci/pipeline_security/_index.md)に関する情報を参照してください。

デプロイとは、指定された環境に関連してパイプラインの結果をデプロイするCI/CDの一部です。デフォルトの設定には多くの制限が課されておらず、異なるロールと責任を持つさまざまなユーザーがそれらの環境と対話できるパイプラインをトリガーすることができるため、これらの環境を制限する必要があります。詳細については、[保護環境](../ci/environments/protected_environments.md)を参照してください。
