---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLabの作業アイテムを使って、チームの作業を整理しましょう。統一されたビューでタスク、エピック、イシュー、目標を追跡することで、戦略と実装を結び付け、進捗を追跡します。"
title: 作業アイテム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

作業アイテムは、GitLabにおける作業の計画と追跡のための核となる要素です。製品開発の計画と追跡には、より大きな全体像とのつながりを維持しながら、作業を小さく管理しやすい部分に分割することがしばしば求められます。作業アイテムは、この基本的なニーズに基づいて設計されており、戦略的な取り組みから個々のタスクまで、あらゆるレベルの作業単位を表す統一された方法を提供します。

作業アイテムの階層的な性質により、異なるレベルの作業間の明確な関係が可能になり、チームが日々のタスクがより大きな目標にどのように貢献するか、また戦略的な目標が実行可能なコンポーネントにどのように分解されるかを理解するのに役立ちます。

この構造は、Scrum、Kanban、ポートフォリオ管理などの様々な計画フレームワークをサポートし、同時にあらゆるレベルでチームに進捗状況の可視性を提供します。

## 作業アイテムの種類 {#work-item-types}

GitLabは次の作業アイテムの種類をサポートしています:

- [イシュー](../project/issues/_index.md): タスク、機能、バグを追跡します。
- [エピック](../group/epics/_index.md): 複数のマイルストーンとイシューにわたる大規模なイニシアチブを管理します。
- [Tasks](../tasks.md): 小さな作業単位を追跡します。
- [目標と主な成果](../okrs.md): 戦略的な目標とその測定可能な結果を追跡します。
- [テストケース](../../ci/test_cases/_index.md): テスト計画をGitLabワークフローに直接統合します。

## すべての作業アイテムを表示 {#view-all-work-items}

{{< history >}}

- GitLab 18.7で`work_item_planning_view`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/11918)されました。デフォルトでは無効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/520452)になりました。機能フラグ`work_item_planning_view`は削除されました。

{{< /history >}}

**作業アイテム**リストは、プロジェクトまたはグループのすべての作業アイテムタイプ（イシュー、エピック、タスクなど）を表示および管理するための中央の場所です。このビューを使用して、プロジェクトまたはグループでの作業の完全なスコープを理解し、効果的に優先順位を付けます。

GitLabの以前のバージョンでは、**Plan** > **イシュー**と**Plan** > **エピック**の下にイシューとエピックのリストページが別々にありました。GitLab 18.10以降では、これらのページは、すべての作業アイテムタイプを単一のビューに統合する**Plan** > **作業アイテム**に置き換えられました。サイドバーに**イシュー**または**エピック**をピン留めしていた場合、それらの場所に**作業アイテム**がピン留めされます。`/epics/:iid`または`/issues/:iid`を含むURLは、自動的に`/work_items/:iid`にリダイレクトされます。

プロジェクトまたはグループの作業アイテムを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**Plan** > **作業アイテム**を選択します。

### 作業アイテムをフィルターする {#filter-work-items}

**作業アイテム**リストは、デフォルトですべての作業アイテムタイプを表示します。特定のタイプを表示するには、**タイプ**フィルターを使用します。

作業アイテムリストをフィルターするには:

1. ページの上部にあるフィルターバーから、フィルター、演算子、およびその値を選択します。たとえば、エピックのみを表示するには、フィルター**タイプ**、演算子**等しい**、および値**エピック**を選択します。
1. オプション。オプション。検索を絞り込むには、さらにフィルターを追加します。
1. <kbd>Enter</kbd>を押すか、検索アイコン（{{< icon name="search" >}}）を選択します。

#### 利用可能なフィルター {#available-filters}

{{< history >}}

- 説明によるフィルターはGitLab 18.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/536876)。

{{< /history >}}

これらのフィルターは作業アイテムで利用できます:

- 担当者
  - 演算子: `is`、`is not one of`、`is one of`
- 作成者
  - 演算子: `is`、`is not one of`、`is one of`
- 機密
  - 値: `Yes`、`No`
- 連絡先
  - 演算子: `is`
- ステータス
  - 演算子: `is`
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
  - 演算子: `is`
- 親
  - 演算子: `is`、`is not`
  - 値: すべて`Issue`、`Epic`、`Objective`
- リリース
  - 演算子: `is`、`is not`
- 検索対象
  - 演算子: `Titles`、`Descriptions`
- ステート
  - 値: `Any`、`Open`、`Closed`
- 種類
  - 値: `Issue`、`Incident`、`Task`、`Epic`、`Objective`、`Key Result`、`Test case`
- ウェイト
  - 演算子: `is`、`is not`

最近使用したフィルターにアクセスするには、フィルターバーの左側にある**最近の検索** ({{< icon name="history" >}}) ドロップダウンリストを選択します。

### 作業アイテムを並べ替える {#sort-work-items}

{{< history >}}

- ステータスによる並べ替えは、GitLab 18.5で[導入され](https://gitlab.com/groups/gitlab-org/-/epics/18638)、`work_item_status_mvc2`という名前の[フラグ](../../administration/feature_flags/_index.md)が付けられました。デフォルトでは有効になっています。
- ステータスによる並べ替えは、GitLab 18.6で[一般公開されました](https://gitlab.com/gitlab-org/gitlab/-/issues/576610)。機能フラグ`work_item_status_mvc2`は削除されました。

{{< /history >}}

作業アイテムのリストを次で並べ替えます:

- 作成日
- 更新日
- 開始日
- 期限
- タイトル
- ステータス
- ウェイト

並べ替えの基準を変更するには:

- フィルターバーの右側にある**作成日**ドロップダウンリストを選択します。

並べ替え順序を昇順と降順で切替するには:

- フィルターバーの右側にある**ソート順** ({{< icon name="sort-lowest" >}}または{{< icon name="sort-highest" >}}) を選択します。

並べ替えロジックの詳細については、[イシューリストの並べ替えと順序付け](../project/issues/sorting_issue_lists.md)を参照してください。

## リスト表示の環境設定を構成する {#configure-list-display-preferences}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393559) in GitLab 18.2.
- イシューのサポートはGitLab 18.7で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/520791)。

{{< /history >}}

作業アイテムがリストページにどのように表示されるかを、特定のメタデータフィールドの表示/非表示を切り替えたり、ビューの環境設定を構成したりしてカスタマイズします。

GitLabは、異なるレベルで表示設定を保存します: 

- **フィールド**: ネームスペースごとに保存されます。お客様のワークフローのニーズに基づいて、異なるグループやプロジェクトに対して異なるフィールドの表示レベルを設定できます。たとえば、あるグループやプロジェクトでは担当者とラベルを表示し、別のグループやプロジェクトではそれらを非表示にすることができます。
- **設定**: すべてのプロジェクトとグループでグローバルに保存されます。これにより、作業アイテムの表示方法の設定が常に一貫したものになります。

表示の環境設定を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**Plan** > **作業アイテム**を選択します。
1. フィルターバーの右側にある**表示オプション** ({{< icon name="preferences" >}}) を選択します。
1. **フィールド**で、表示するメタデータをオンまたはオフにします: 
   - ステータス（イシュー用）
   - 担当者
   - ラベル
   - ウェイト（イシュー用）
   - マイルストーン
   - イテレーション（イシュー用）
   - 日付: 期日と日付範囲
   - 健全性: 健全性ステータスインジケーター
   - ブロック済み/ブロック中: ブロック関係インジケーター
   - コメント: コメント数
   - 人気度: 人気度メトリクス
1. **Your preferences**で、**サイドパネルにアイテムを開く**をオンまたはオフにして、エピックを選択したときにエピックをどのように開くかを選択します: 
   - オン（デフォルト）: 項目は画面右側のドロワーで開きます。
   - オフ: 項目は全ページビューで開きます。

設定は保存され、すべてのセッションとデバイスで記憶されます。

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
