---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
description: 依存関係とコンプライアンスのスキャン
title: 'チュートリアル: アプリケーションを保護し、コンプライアンスを確認する'
---

GitLabは、アプリケーションのセキュリティ脆弱性を確認し、コンプライアンス要件を満たしているかをチェックできます。

## セキュリティの基本を学ぶ {#learn-security-fundamentals}

GitLabにおけるセキュリティの基本を理解するために、ここから始めてください。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLab Security Essentials](https://university.gitlab.com/learning-paths/gitlab-security-essentials-v100) | この自己学習コースでは、GitLabの主要なセキュリティ機能について学びます。 | {{< icon name="star" >}}  |
| [Get started with GitLab AppSec](../user/application_security/get-started-security.md) | セキュリティツールを設定するための推奨手順に従ってください。 | |

## 基本的なセキュリティ検出を設定する {#set-up-basic-security-detection}

脆弱性を特定するために、基本的なスキャンを作成します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [依存関係スキャンをセットアップする](dependency_scanning.md) | アプリケーションの依存関係における脆弱性を検出する方法を学びます。 | {{< icon name="star" >}} |
| [Dockerコンテナの脆弱性をスキャンする](container_scanning/_index.md) | コンテナスキャンテンプレートを使用して、プロジェクトにコンテナスキャンを追加する方法を学びます。 | {{< icon name="star" >}} |
| [A comprehensive guide to GitLab DAST](https://about.gitlab.com/blog/comprehensive-guide-to-gitlab-dast/) | 動的アプリケーションセキュリティテストを設定し、スキャンを実行し、セキュリティポリシーを実装する方法を学びます。 | {{< icon name="star" >}} |

## シークレットの漏洩から保護する {#protect-against-secret-exposure}

機密データがリポジトリにコミットされるのを防ぎます。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [シークレットプッシュ保護でプロジェクトを保護する](../user/application_security/secret_detection/push_protection_tutorial.md) | プロジェクトでシークレットプッシュ保護を有効にします。 | {{< icon name="star" >}} |
| [Detect secrets committed to a project](../user/application_security/secret_detection/pipeline/tutorial.md) | プロジェクトのリポジトリにコミットされたシークレットを検出して修正する方法を学びます。 | {{< icon name="star" >}} |
| [コミットからシークレットを削除する](../user/application_security/secret_detection/remove_secrets_tutorial.md) | コミット履歴からシークレットを削除する方法を学びます。 | {{< icon name="star" >}} |

## セキュリティポリシーとガバナンスを実装する {#implement-security-policies-and-governance}

プロジェクト全体でセキュリティ要件を適用します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [スキャン実行ポリシーをセットアップする](scan_execution_policy/_index.md) | プロジェクトのセキュリティスキャンを強制するためのスキャン実行ポリシーを作成する方法を学びます。 | {{< icon name="star" >}} |
| [パイプライン実行ポリシーをセットアップする](pipeline_execution_policy/_index.md) | パイプラインの一部として、プロジェクト全体でセキュリティスキャンを強制するためのパイプライン実行ポリシーを作成する方法を学びます。 | {{< icon name="star" >}} |
| [マージリクエスト承認ポリシーをセットアップする](scan_result_policy/_index.md) | スキャン結果に基づいてアクションを起こすマージリクエスト承認ポリシーを設定する方法を学びます。 | {{< icon name="star" >}} |

## コンプライアンスとレポートを確立する {#establish-compliance-and-reporting}

規制要件を満たし、コンプライアンスドキュメントを生成します。

| トピック | 説明 | 初心者向け |
|-------|-------------|--------------------|
| [GitLabパッケージレジストリでソフトウェア部品表を生成する](../user/packages/package_registry/tutorial_generate_sbom.md) | グループ内のすべてのプロジェクトでSBOMを生成する方法を学びます。 | {{< icon name="star" >}} |
| [Export dependency list in SBOM format](export_sbom.md) | アプリケーションの依存関係をCycloneDX SBOM形式にエクスポートする方法を学びます。 | {{< icon name="star" >}} |
