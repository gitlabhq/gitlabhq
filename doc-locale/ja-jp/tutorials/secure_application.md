---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: 依存関係とコンプライアンスのスキャン
title: 'チュートリアル: アプリケーションを保護し、コンプライアンスを確認する'
---

GitLabは、アプリケーションのセキュリティ脆弱性をチェックし、コンプライアンス要件を満たしているか確認できます。

## セキュリティの基礎を学ぶ {#learn-security-fundamentals}

GitLabでのセキュリティの基本を理解するには、ここから始めてください。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLab Security Essentials](https://university.gitlab.com/courses/security-essentials) | この自分のペースで進められるコースで、GitLabの重要なセキュリティ機能について学びます。 | {{< icon name="star" >}}  |
| [GitLabアプリケーションセキュリティの概要](../user/application_security/get-started-security.md) | 推奨される手順に従って、セキュリティツールを設定します。 | |

## 基本的なセキュリティ検出の設定 {#set-up-basic-security-detection}

基本的なスキャンを作成して、脆弱性を特定します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [依存関係スキャンをセットアップする](dependency_scanning.md) | アプリケーションの依存関係の脆弱性を検出する方法について説明します。 | {{< icon name="star" >}} |
| [Dockerコンテナの脆弱性をスキャンする](container_scanning/_index.md) | コンテナスキャンテンプレートを使用して、コンテナスキャンをプロジェクトに追加する方法について説明します。 | {{< icon name="star" >}} |
| [GitLab DASTの包括的なガイド](https://about.gitlab.com/blog/comprehensive-guide-to-gitlab-dast/) | 動的アプリケーションセキュリティテストを設定し、スキャンを実行し、セキュリティポリシーを実装する方法について説明します。 | {{< icon name="star" >}} |

## シークレットの漏洩に対する保護 {#protect-against-secret-exposure}

機密データがリポジトリにコミットされるのを防ぎます。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [シークレットプッシュ保護でプロジェクトを保護する](../user/application_security/secret_detection/push_protection_tutorial.md) | プロジェクトでシークレットプッシュ保護を有効にします。 | {{< icon name="star" >}} |
| [プロジェクトにコミットされたシークレットの検出](../user/application_security/secret_detection/pipeline/tutorial.md) | プロジェクトのリポジトリにコミットされたシークレットを検出して修正する方法について説明します。 | {{< icon name="star" >}} |
| [コミットからシークレットを削除する](../user/application_security/secret_detection/remove_secrets_tutorial.md) | コミット履歴からシークレットを削除する方法について説明します。 | {{< icon name="star" >}} |

## セキュリティポリシーとガバナンスの実装 {#implement-security-policies-and-governance}

プロジェクト全体のセキュリティ要件を強化します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [スキャン実行ポリシーをセットアップする](scan_execution_policy/_index.md) | スキャン実行ポリシーを作成して、プロジェクトのセキュリティスキャンを強化する方法について説明します。 | {{< icon name="star" >}} |
| [パイプライン実行ポリシーをセットアップする](pipeline_execution_policy/_index.md) | パイプライン実行ポリシーを作成して、パイプラインの一部としてプロジェクト全体のセキュリティスキャンを強化する方法について説明します。 | {{< icon name="star" >}} |
| [マージリクエスト承認ポリシーをセットアップする](scan_result_policy/_index.md) | スキャン結果に基づいてアクションを実行するマージリクエスト承認ポリシーを構成する方法について説明します。 | {{< icon name="star" >}} |

## コンプライアンスとレポートの確立 {#establish-compliance-and-reporting}

規制要件を満たし、コンプライアンスドキュメントを生成します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLabパッケージレジストリでソフトウェア部品表を生成する](../user/packages/package_registry/tutorial_generate_sbom.md) | グループ内のすべてのプロジェクトでソフトウェア部品表を生成する方法について説明します。 | {{< icon name="star" >}} |
| [SBOM形式で依存関係リストをエクスポート](export_sbom.md) | アプリケーションの依存関係をCycloneDX SBOM形式にエクスポートする方法について説明します。 | {{< icon name="star" >}} |
