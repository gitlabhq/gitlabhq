---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: ロールベースのアクセス制御を含む、GitLabの職務分離ソリューションの概要。主要コンポーネント、ワークフロー、および監査機能が含まれています。
title: GitLabチュートリアル職務分離ガイド
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、ロールベースのアクセス制御（RBAC）によるGitLabの職務分離ソリューションの概要について説明します。このソリューションは、ソフトウェア開発ライフサイクルにおける重要なプロセスを単一の担当者が完全に制御することを防ぐことにより、セキュリティ原則へのコンプライアンスを確保します。

## はじめに {#getting-started}

### ソリューションコンポーネントへのアクセス {#access-the-solution-component}

1. アカウントチームから招待コードを取得します。
1. 招待コードを使用して、[ソリューションコンポーネントのウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントにアクセスします。

## 職務分離とは {#what-is-separation-of-duties}

職務分離は、単一の担当者が重要なプロセスを完全に制御できないようにする基本的なセキュリティ原則です。ソフトウェア開発において、SoDは、異なるロールとチーム間で責任を分担することにより、不正または偶発的なコードのリリースを本番環境に防ぎます。

ロールベースのアクセス制御（RBAC）を通じてSoDを実装するGitLabのアプローチは、以下を提供します:

- 開発ロールとデプロイロール間の明確な分離
- デプロイアクセスを制御するための保護された環境
- 不正なコードの変更を防ぐための保護されたブランチ
- コードレビューを強制するためのマージリクエスト承認ポリシー
- コンプライアンス検証のための組み込み監査機能

## GitLab SoDソリューションの主要コンポーネント {#key-components-of-gitlab-sod-solution}

### ロールベースのアクセス制御（RBAC） {#role-based-access-control-rbac}

RBACは、SoDを実装および強制するためのフレームワークを形成します。これは、プラットフォーム全体の権限と責任を管理し、最小特権の原則に準拠していることを保証します。RBACを通じて、組織は以下を行うことができます:

- きめ細かいロールベースのアクセス制御による全体的なユーザー管理を実装する
- 最小特権アクセス原則でロールを割り当てる
- 監査/レポートを通じてロールと権限の可視性を維持する

### フィーチャーブランチワークフロー {#feature-branch-workflow}

フィーチャーブランチワークフローは、開発アクティビティーと本番デプロイ間の明確な境界を定義することにより、SoDをサポートします:

- 開発チームは、フィーチャーブランチでコードを変更し、テストパイプラインをトリガーできます
- セキュリティチームは、品質ゲートの承認ポリシーを管理します
- マージリクエストには、作成者以外の独立したレビューが必要です

### 保護されたブランチと環境 {#protected-branches--environments}

デフォルトのブランチは、SoDの実施に重要な役割を果たします:

- 保護された環境は、指定されたチームへのデプロイを制限します
- デプロイチームは、デプロイメントを実行する権限を持っていますが、ソースコードの変更は制限されています
- 保護されたブランチは、不正なマージとプッシュを防ぎます

### 監査とコンプライアンス機能 {#audit--compliance-capabilities}

GitLabは、コンプライアンス要件をサポートするための堅牢な監査機能を提供します:

- 自動的に生成されたリリースエビデンス
- デフォルトのブランチアクティビティーのイベントログ

### 前提要件 {#prerequisites}

GitLab SoDソリューションを完全に実装するには、組織は以下が必要です:

- GitLab Ultimateライセンス
- 適切に構成されたCI/CDパイプライン
- 開発ロールとデプロイロールが明確に分離されたユーザーグループ

### 追加リソース {#additional-resources}

GitLab SoD実装の詳細については、以下を参照してください:

- [GitLabロールと権限のドキュメント](../../user/permissions.md)
- [保護されたブランチのドキュメント](../../user/project/repository/branches/protected.md)
- [保護された環境のドキュメント](../../ci/environments/protected_environments.md)
- [マージリクエスト承認のドキュメント](../../user/project/merge_requests/approvals/_index.md)
