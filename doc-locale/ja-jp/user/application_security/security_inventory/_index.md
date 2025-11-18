---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュリティインベントリ
description: 資産、スキャナーカバレッジ、脆弱性のグループレベルでの可視性。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/16484)されたのはGitLab 18.2で、`security_inventory_dashboard`というフラグが使用されました。デフォルトでは有効になっています。この機能は[ベータ](../../../policy/development_stages_support.md)版です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

セキュリティインベントリを使用して、保護する必要のある資産を可視化し、セキュリティを向上させるために必要なアクションを理解します。セキュリティにおける一般的なフレーズは、「見えないものは保護できない」ということです。セキュリティインベントリは、組織のトップレベルグループのセキュリティ対策状況を可視化し、カバレッジのギャップを特定し、効率的でリスクに基づいた優先順位の決定を可能にします。

セキュリティインベントリには、以下が表示されます:

- グループ、サブグループ、プロジェクト。
- スキャナーがどのように有効になっているかに関係なく、各プロジェクトのセキュリティスキャナーのカバレッジ。セキュリティスキャナーには以下が含まれます:
  - 静的アプリケーションセキュリティテスト（SAST）
  - 依存関係スキャン
  - コンテナスキャン
  - シークレット検出
  - 動的アプリケーションセキュリティテスト（DAST）
  - Infrastructure as Code（IaC）スキャン
- 各グループまたはプロジェクト内の脆弱性の数（脆弱性の重大度レベル別に分類）。

この機能はベータです。セキュリティインベントリの開発を[エピック16484](https://gitlab.com/groups/gitlab-org/-/epics/16484)で追跡する。この機能の開発を継続するにあたり、[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/553062)をお寄せください。セキュリティインベントリはデフォルトで有効になっています。

## セキュリティインベントリを表示する {#view-the-security-inventory}

前提要件: 

- セキュリティインベントリを表示するには、グループ内で少なくともデベロッパーロールが必要です。

セキュリティインベントリを表示するには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. 次のいずれかの操作を実行します:
   - グループのサブグループ、プロジェクト、およびセキュリティ資産を表示するには、グループを選択します。
   - グループまたはプロジェクトのスキャナーカバレッジを表示するには、グループまたはプロジェクトを検索します。

## セキュリティインベントリのプロジェクトをフィルタリングする {#filter-projects-in-the-security-inventory}

{{< history >}}

- GitLab 18.5で`security_inventory_filtering`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/552224)されました。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

セキュリティインベントリでプロジェクトをフィルタリングして、特定の関心のある領域に焦点を当てることができます。次のフィルターを使用できます:

- **Vulnerability count**（脆弱性の数）: 特定された脆弱性の数に基づいてプロジェクトをフィルタリングします。たとえば、`critical vulnerabilities ≥ 10`のプロジェクトを表示します。
- **Tool coverage**（ツールカバレッジ）: セキュリティアナライザー（**有効**、**not enabled**（無効）、または**失敗**など）のステータスでプロジェクトをフィルタリングします。たとえば、`Advanced SAST = enabled`のプロジェクトを表示します。
- **プロジェクト名**: 名前で特定のプロジェクトを検索します。

これらのフィルターを使用すると、大規模なインベントリの結果を絞り込み、早急な対応が必要なプロジェクトを簡単に見つけることができます。

## 関連トピック {#related-topics}

- [セキュリティダッシュボード](../security_dashboard/_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- GraphQL参照:
  - [AnalyzerGroupStatusType](../../../api/graphql/reference/_index.md#analyzergroupstatustype)-グループとサブグループの各アナライザーのステータスの数。
  - [AnalyzerProjectStatusType](../../../api/graphql/reference/_index.md#analyzerprojectstatustype)-プロジェクトのアナライザーのステータス（成功/失敗）。
  - [VulnerabilityNamespaceStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitynamespacestatistictype)-グループとそのサブグループの各脆弱性の重大度の数。
  - [VulnerabilityStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitystatistictype)-プロジェクト内の各脆弱性の重大度の数。

## トラブルシューティング {#troubleshooting}

セキュリティインベントリを使用する場合、次の問題が発生する可能性があります:

### セキュリティインベントリのメニュー項目が見つからない {#security-inventory-menu-item-missing}

**セキュリティインベントリ**メニュー項目にアクセスするための必要な権限がない認証済みユーザーがいます。このメニュー項目は、認証済みユーザーに少なくともデベロッパーロールがある場合にのみグループに表示されます。
