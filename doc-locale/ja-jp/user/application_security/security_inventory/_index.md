---
stage: Security Risk Management
group: Security Platform Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティインベントリ
description: 資産、スキャナーのカバレッジ、および脆弱性のグループレベルの表示レベル。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2で[ベータ](../../../policy/development_stages_support.md)版として[導入](https://gitlab.com/groups/gitlab-org/-/epics/16484)され、`security_inventory_dashboard`という名前のフラグが付けられました。デフォルトでは有効になっています。
- GitLab 18.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619)になりました。機能フラグ`security_inventory_dashboard`は削除されました。

{{< /history >}}

セキュリティインベントリを使用して、保護する必要がある資産を視覚化し、セキュリティを改善するために必要なアクションを理解します。セキュリティにおける一般的なフレーズは、「見えないものは保護できない」です。セキュリティインベントリは、組織のトップレベルグループのセキュリティ対策状況に対する表示レベルを提供し、カバレッジのギャップを特定するのに役立ち、効率的なリスクベースの優先順位付けの決定を可能にします。

セキュリティインベントリは以下を示します:

- グループ、サブグループ、およびプロジェクト。
- スキャナーがどのように有効になっているかにかかわらず、各プロジェクトのセキュリティスキャナーのカバレッジ。ツールのカバレッジは、デフォルトブランチで最も新しいパイプラインのスキャンステータスを反映します。セキュリティスキャナーには以下が含まれます:
  - 静的アプリケーションセキュリティテスト（SAST）
  - 依存関係スキャン
  - コンテナスキャン
  - シークレット検出
  - 動的アプリケーションセキュリティテスト（DAST）
  - Infrastructure as Code（IaC）スキャン
- 各グループまたはプロジェクトにおける重大度レベル別にソートされた脆弱性の数。

[エピック16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939)のセキュリティインベントリの開発を追跡します。この機能の開発が継続されるように、[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/553062)をお寄せください。

## セキュリティインベントリを表示 {#view-the-security-inventory}

前提条件: 

- セキュリティインベントリを表示するには、グループ内でセキュリティマネージャー、デベロッパー、メンテナー、またはオーナーのロールが必要です。

セキュリティインベントリを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**セキュリティ** > **セキュリティインベントリ**を選択します。
1. 次のいずれかのアクションを実行します:
   - グループのサブグループ、プロジェクト、およびセキュリティ資産を表示するには、グループを選択します。
   - グループまたはプロジェクトのスキャナーのカバレッジを表示するには、そのグループまたはプロジェクトを検索します。

## スキャナーカバレッジ {#scanner-coverage}

{{< history >}}

- 無効ステータスがGitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/596022)されました。

{{< /history >}}

デフォルトブランチのパイプラインが完了すると、セキュリティスキャナーのステータスが評価されます。各セキュリティスキャナーは、すべてのプロジェクトまたはグループに対して次のいずれかのカバレッジステータスを表示します:

- **有効ではない**: このスキャナーは設定されていません。
- **有効**: このスキャナーは設定されており、正常に完了しました。
- **失敗**: このスキャナーは実行されましたが、正常に完了しませんでした。
- **無効**: 以前に有効になっていたスキャナーが、過去3回の連続したパイプラインで実行されていません。

## セキュリティインベントリでプロジェクトをフィルタリング {#filter-projects-in-the-security-inventory}

{{< history >}}

- GitLab 18.5で`security_inventory_filtering`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/552224)されました。デフォルトでは有効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

セキュリティインベントリ内のプロジェクトをフィルタリングして、特定の関心領域に焦点を当てることができます。次のフィルタリングを使用できます:

- **脆弱性の件数**: 特定された脆弱性の数に基づいてプロジェクトをフィルタリングします。例えば、`critical vulnerabilities ≥ 10`のプロジェクトを表示します。
- **ツールカバレッジ**: セキュリティアナライザーのステータス（**有効**、**not enabled**、または**失敗**など）でプロジェクトをフィルタリングします。例えば、`Advanced SAST = enabled`のプロジェクトを表示します。
- **プロジェクト名**: 名前で特定のプロジェクトを検索します。

これらのフィルターは、大規模なインベントリで結果を絞り込み、早急な対応が必要なプロジェクトを特定するのに役立ちます。

## 関連トピック {#related-topics}

- [セキュリティダッシュボード](../security_dashboard/_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- GraphQLリファレンス:
  - [AnalyzerGroupStatusType](../../../api/graphql/reference/_index.md#analyzergroupstatustype) \- グループおよびサブグループ内の各アナライザーのステータスのカウント。
  - [AnalyzerProjectStatusType](../../../api/graphql/reference/_index.md#analyzerprojectstatustype) \- プロジェクトのアナライザーのステータス（成功/失敗）。
  - [VulnerabilityNamespaceStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitynamespacestatistictype) \- グループとそのサブグループ内の各脆弱性重大度のカウント。
  - [VulnerabilityStatisticType](../../../api/graphql/reference/_index.md#vulnerabilitystatistictype) \- プロジェクト内の各脆弱性重大度のカウント。

## トラブルシューティング {#troubleshooting}

セキュリティインベントリを使用する際に、次の問題が発生する可能性があります:

### セキュリティインベントリのメニュー項目がない {#security-inventory-menu-item-missing}

一部のユーザーは、**セキュリティインベントリ**メニュー項目にアクセスするために必要な権限を持っていません。このメニュー項目は、認証済みユーザーがセキュリティマネージャー、デベロッパー、メンテナー、またはオーナーのロールを持っている場合にのみ、グループに対して表示されます。
