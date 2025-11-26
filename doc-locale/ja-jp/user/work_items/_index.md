---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "GitLabの作業アイテムでチームの作業を整理します。タスク、エピック、イシュー、目標を統合ビューで追跡して、戦略と実装を結び付け、進捗を監視します。"
title: 作業アイテム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

作業アイテムは、GitLabで作業を計画および追跡するための中心的な要素です。製品開発を計画および追跡するには、より大きな全体像とのつながりを維持しながら、作業をより小さく、管理しやすい部分に分割することが必要になることがよくあります。作業アイテムは、この基本的なニーズを中心に設計されており、戦略的イニシアチブから個々のタスクまで、あらゆるレベルの作業単位を表現する統一的な方法を提供します。

作業アイテムの階層的な性質により、さまざまなレベルの作業間の明確な関係が可能になり、チームは日々のタスクがより大きな目標にどのように貢献するか、戦略的な目標がどのように実用的なコンポーネントに分解されるかを理解できます。

この構造は、Scrum、Kanban、ポートフォリオ管理アプローチなどのさまざまな計画フレームワークをサポートすると同時に、チームにあらゆるレベルでの進捗状況の可視性を提供します。作業アイテムを使用すると、Scrum、Kanban、ポートフォリオ管理アプローチを含む、さまざまな計画フレームワークをサポートする共通の構造を使用して、チームの作業を整理できます。

## 作業アイテムタイプ {#work-item-types}

GitLabは、次の作業アイテムタイプをサポートしています:

- [イシュー](../project/issues/_index.md): タスク、機能、バグを追跡します。
- [エピック](../group/epics/_index.md): 複数のマイルストーンとイシューにわたる大規模なイニシアチブを管理します。
- [タスク](../tasks.md): 小さな作業単位を追跡します。
- [目標と主な成果](../okrs.md): 戦略的目標と、その測定可能な成果を追跡します。
- [テストケース](../../ci/test_cases/_index.md): テストケースは、テスト計画をGitLabのワークフローに直接統合します。

## すべての作業アイテムを表示 {#view-all-work-items}

{{< history >}}

- GitLab 17.10で`work_item_planning_view`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513092)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

作業アイテム（イシュー、エピック、タスクなど）を並べて整理するには、統合された作業アイテムビューを使用します。このビューは、作業の全体的なスコープを理解し、効果的に優先順位を付けるのに役立ちます。

この機能を有効にすると、以下が行われます:

- グループおよびプロジェクトの左側のサイドバーから、**Plan** > **イシュー**と**Plan** > **エピック**を削除します。
- 左側のサイドバーに**Plan** > **作業アイテム**を追加します。
- 以前に**Plan** > **イシュー**または**Plan** > **エピック**をピン留めしていた場合、プロジェクトとグループの左側のサイドバーに**作業アイテム**をピン留めします。

前提要件: 

- Freeプランでは、管理者が[flag](../../administration/feature_flags/_index.md) `namespace_level_work_items`を有効にする必要があります。
- PremiumおよびUltimateプランでは、管理者が[flag](../../administration/feature_flags/_index.md) `work_item_epics`を有効にする必要があります。

プロジェクトまたはグループの作業アイテムを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **Plan** > **作業アイテム**を選択します。

### 作業アイテムの絞り込み {#filter-work-items}

**作業アイテム**ページで、フィルターを使用してリストを絞り込むことができます:

1. ページの上部にあるフィルターバーから、フィルター、演算子、およびその値を選択します。
1. オプション。フィルターをさらに追加します。
1. <kbd>Enter</kbd>キーを押すか、検索アイコン{{< icon name="search" >}}を選択します。

#### 利用可能なフィルター {#available-filters}

{{< history >}}

- 説明によるフィルタリングは、GitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/536876)。

{{< /history >}}

<!-- When the feature flag work_item_planning_view is removed, move more information from
managing_issues.md#filter-the-list-of-issues here -->

これらのフィルターは、作業アイテムに使用できます:

- 担当者
  - 演算子: `is`、`is not one of`、`is one of`
- 作成者
  - 演算子: `is`、`is not one of`、`is one of`
- 機密
  - 値: `Yes`、`No`
- 連絡先
  - オペレーター: `is`
- ステータス
  - オペレーター: `is`
- ヘルスステータス
  - 演算子: `is`、`is not`
- イテレーション
  - 演算子: `is`、`is not`
- ラベル
  - 演算子: `is`、`is not one of`、`is one of`
- マイルストーン
  - 演算子: `is`、`is not`
- 自分のリアクション
  - 演算子: `is`、`is not`
- 組織
  - オペレーター: `is`
- 親
  - 演算子: `is`、`is not`
  - 値: 任意: `Issue`、`Epic`、`Objective`
- リリース
  - 演算子: `is`、`is not`
- 検索範囲
  - 演算子: `Titles`、`Descriptions`
- ステート
  - 値: `Any`、`Open`、`Closed`
- 型
  - 値: `Issue`、`Incident`、`Task`、`Epic`、`Objective`、`Key Result`、`Test case`
- ウェイト
  - 演算子: `is`、`is not`

最近使用したフィルターにアクセスするには、フィルターバーの左側にある**最近の検索** ({{< icon name="history" >}}) ドロップダウンリストを選択します。

### 作業アイテムのソート {#sort-work-items}

{{< history >}}

- ステータスによるソートは、GitLab 18.5 で`work_item_status_mvc2`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/18638)されました。デフォルトでは有効になっています。

{{< /history >}}

<!-- When the feature flag work_item_planning_view is removed, move information from
sorting_issue_lists.md to this page and redirect here -->

次の項目で作業アイテムのリストをソートします:

- 作成日
- 更新日
- 開始日
- 期限
- タイトル
- ステータス

ソート条件を変更するには:

- フィルターバーの右側にある**作成日**ドロップダウンリストを選択します。

昇順と降順の間でソート順を切り替えるには:

- フィルターバーの右側で、**ソート順** ({{< icon name="sort-lowest" >}}または{{< icon name="sort-highest" >}}) を選択します。

ソートロジックの詳細については、[イシューリストのソートと順序付け](../project/issues/sorting_issue_lists.md)を参照してください。

## 作業アイテムのMarkdown参照 {#work-item-markdown-reference}

{{< history >}}

- GitLab 18.1で`extensible_reference_filters`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352861)されました。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052)になりました。機能フラグ`extensible_reference_filters`は削除されました。

{{< /history >}}

GitLab Flavored Markdownフィールドでは、`[work_item:123]`を使用して作業アイテムを参照できます。詳細については、[GitLab固有の参照](../markdown.md#gitlab-specific-references)をご覧ください。

## 関連トピック {#related-topics}

- [リンクされたイシュー](../project/issues/related_issues.md)
- [リンクされたエピック](../group/epics/linked_epics.md)
- [イシューボード](../project/issue_board.md)
- [ラベル](../project/labels.md)
- [イテレーション](../group/iterations/_index.md)
- [マイルストーン](../project/milestones/_index.md)
- [カスタムフィールド](custom_fields.md)
