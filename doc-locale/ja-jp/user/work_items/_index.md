---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLabの作業アイテムを使って、チームの作業を整理します。統一されたビューでタスク、エピック、イシュー、目標を追跡することで、戦略と実装を結び付け、進捗を追跡します。"
title: 作業アイテム
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

作業アイテムは、GitLabにおける作業の計画と追跡のための核となる要素です。並べ替え順を昇順と降順の間で変更するには: 作業アイテムは、この基本的なニーズに基づいて設計されており、戦略的な取り組みから個々のタスクまで、あらゆるレベルの作業単位を表す方法を統一します。

作業アイテムの階層的な性質により、異なるレベルの作業間の関係が明確になり、日々のタスクがより大きな目標にどのように貢献するか、また戦略的な目標が実行可能なコンポーネントにどのように分解されるかをチームが理解するのに役立ちます。

この構造は、Scrum、Kanban、ポートフォリオ管理などの様々な計画フレームワークをサポートし、同時にあらゆるレベルでチームが進捗状況を可視化できるようにします。

## 作業アイテムタイプ {#work-item-types}

GitLabは次の作業アイテムタイプをサポートしています:

- [イシュー](../project/issues/_index.md): タスク、機能、バグを追跡します。
- [エピック](../group/epics/_index.md): 複数のマイルストーンとイシューにわたる大規模なイニシアチブを管理します。
- [タスク](../tasks.md): 小さな作業単位を追跡します。
- [目標と主な成果](../okrs.md): 戦略的な目標とその測定可能な結果を追跡します。
- [テストケース](../../ci/test_cases/_index.md): テスト計画をGitLabワークフローに直接統合します。

また、[作業アイテムタイプを設定](configurable_work_item_types.md)して、新しい種類を作成したり、グループやプロジェクト全体での利用可否を管理したりできます。

## すべての作業アイテムを表示する {#view-all-work-items}

{{< history >}}

- GitLab 18.7で`work_item_planning_view`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/11918)されました。デフォルトでは無効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/520452)になりました。機能フラグ`work_item_planning_view`は削除されました。

{{< /history >}}

**作業アイテム**リストは、プロジェクトまたはグループのすべての作業アイテムタイプ（イシュー、エピック、タスクなど）を表示および管理するための一元的な場所となります。このビューを使用して、プロジェクトまたはグループでの作業の完全なスコープを理解し、効果的に優先順位を付けます。

GitLabの以前のバージョンでは、**計画** > **イシュー**および**計画** > **エピック**にイシューとエピックのリストページが別々にありました。GitLab 18.10以降では、これらのページは、すべての作業アイテムタイプを単一のビューに統合する**計画** > **作業アイテム**に置き換えられました。サイドバーに**イシュー**または**エピック**をピン留めしていた場合、それらの場所に**作業アイテム**がピン留めされます。`/epics/:iid`または`/issues/:iid`を含むURLは、自動的に`/work_items/:iid`にリダイレクトされます。

プロジェクトまたはグループの作業アイテムを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**計画** > **作業アイテム**を選択します。

### 作業アイテムをフィルタリングする {#filter-work-items}

**作業アイテム**リストは、デフォルトですべての作業アイテムタイプを表示します。特定のタイプ（例: イシューのみまたはエピックのみ）を表示するには、**タイプ**フィルターを使用します。

作業アイテムリストをフィルタリングするには:

1. ページの上部にあるフィルターバーから、フィルター、演算子、およびその値を選択します。たとえば、エピックのみを表示するには、フィルターに**タイプ**、演算子に**is**、および値に**エピック**を選択します。
1. オプション。検索を絞り込むには、さらにフィルターを追加します。
1. <kbd>Enter</kbd>を押すか、検索アイコン（{{< icon name="search" >}}）を選択します。

#### 利用可能なフィルター {#available-filters}

{{< history >}}

- 説明によるフィルタリングはGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/536876)されました。

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
  - 値: 任意の`Issue`、`Epic`、`Objective`
- リリース
  - 演算子: `is`、`is not`
- 検索対象
  - 演算子: `Titles`、`Descriptions`
- ステート
  - 値: `Any`、`Open`、`Closed`
- タイプ
  - 値: `Issue`、`Incident`、`Task`、`Epic`、`Objective`、`Key Result`、`Test case`
- ウェイト
  - 演算子: `is`、`is not`

最近使用したフィルターにアクセスするには、フィルターバーの左側にある**最近の検索**（{{< icon name="history" >}}）ドロップダウンリストを選択します。

### 作業アイテムを並べ替える {#sort-work-items}

{{< history >}}

- ステータスによる並べ替えは、GitLab 18.5で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/18638)（[機能フラグ](../../administration/feature_flags/_index.md) `work_item_status_mvc2`付き）。デフォルトでは有効になっています。
- ステータスによる並べ替えは、GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/576610)になりました。機能フラグ`work_item_status_mvc2`は削除されました。

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

1. フィルターバーの右側にある**ディスプレイ**（{{< icon name="preferences" >}}）を選択して、表示設定ドロワーを開きます。
1. ドロワーの上部にある**並べ替え**ドロップダウンリストを選択します。

ソート順を昇順と降順の間で変更するには、:

1. フィルターバーの右側にある**ディスプレイ**（{{< icon name="preferences" >}}）を選択して、表示設定ドロワーを開きます。
1. ドロワーの上部にある**並べ替え**ドロップダウンリストの横にある**ソート順**（{{< icon name="sort-lowest" >}}または{{< icon name="sort-highest" >}}）を選択します。

並べ替えロジックの詳細については、[イシューリストの並べ替えと順序付け](../project/issues/sorting_issue_lists.md)を参照してください。

## リスト表示の環境設定を構成する {#configure-list-display-preferences}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)されました。
- イシューのサポートはGitLab 18.7で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/520791)されました。

{{< /history >}}

リストページでの作業アイテムの表示方法をカスタマイズするには、特定のメタデータフィールドを表示または非表示にして、ビューの環境設定を構成します。

GitLabは、異なるレベルで表示設定を保存します: 

- **フィールド**: ネームスペースごとに保存されます。ワークフローのニーズに基づいて、異なるグループやプロジェクトに対して異なるフィールドの表示レベルを設定できます。たとえば、あるグループやプロジェクトでは担当者とラベルを表示し、別のグループやプロジェクトではそれらを非表示にすることができます。
- **環境設定**: すべてのプロジェクトとグループでグローバルに保存されます。これにより、作業アイテムの表示方法の設定が常に一貫したものになります。

表示の環境設定を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**計画** > **作業アイテム**を選択します。
1. フィルターバーの右側にある**ディスプレイ**（{{< icon name="preferences" >}}）を選択して、表示設定ドロワーを開きます。
1. **フィールド**で、表示するメタデータをオンまたはオフにします: 
   - ステータス（イシュー用）
   - 担当者
   - ラベル
   - ウェイト（イシュー用）
   - マイルストーン
   - イテレーション（イシュー用）
   - 日付: 期限と日付の範囲
   - ヘルス: ヘルスステータスインジケーター
   - ブロック済み/ブロック中: ブロック関係インジケーター
   - コメント: コメント数
   - 人気度: 人気度メトリクス

   有効にしたフィールドは**表示**の下に表示されます。無効にしたフィールドは**非表示**の下に表示されます。
1. オプション。特定のフィールドを検索するには、**フィールドを検索**入力を使用します。
1. **設定**で、**サイドパネルにアイテムを開く**をオンまたはオフにして、作業アイテムを選択したときに開く方法を選択します:
   - オン（デフォルト）: アイテムは画面右側のドロワーで開きます。
   - オフ: アイテムは全ページ表示で開きます。

設定は保存され、すべてのセッションとデバイスで記憶されます。

## 作業アイテムのMarkdown参照 {#work-item-markdown-reference}

{{< history >}}

- GitLab 18.1で`extensible_reference_filters`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352861)されました。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197052)になりました。機能フラグ`extensible_reference_filters`は削除されました。

{{< /history >}}

GitLab Flavored Markdownフィールドでは、`[work_item:123]`を使用して作業アイテムを参照できます。詳細については、[GitLab固有の参照](../markdown.md#gitlab-specific-references)をご覧ください。

## マージリクエスト内の作業アイテム {#work-items-in-merge-requests}

{{< history >}}

- GitLab 18.11で`mr_related_work_items`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/plan-stage/-/work_items/456)されました。デフォルトでは無効になっています。
- GitLab 19.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/233554)になりました。機能フラグ`mr_related_work_items`は削除されました。

{{< /history >}}

マージリクエストの説明で作業アイテムを参照すると、マージリクエストサイドバーの**作業アイテム**ウィジェットに自動的に表示されます。ウィジェットは作業アイテムを2つのカテゴリにグループ化します:

- **クロージング**: 作業アイテムは、[クローズパターン](../project/issues/managing_issues.md#closing-issues-automatically)（例: `Closes #123`）とリンクされています。これらの作業アイテムは、MRがマージされると自動的にクローズされます。
- **メンション済み**: 説明で参照されているが、クローズパターンとリンクされていない作業アイテム（例: `Related to #456`）。これらの作業アイテムは、MRがマージされるときにクローズされません。

ウィジェットに3つ以上の作業アイテムが含まれている場合、デフォルトで折りたたまれます。ウィジェットヘッダーを選択して、展開します。任意の作業アイテムを選択して、ドロワーで開きます。

## 関連トピック {#related-topics}

- [リンクされたイシュー](../project/issues/related_issues.md)
- [リンクされたエピック](../group/epics/linked_epics.md)
- [イシューボード](../project/issue_board.md)
- [ラベル](../project/labels.md)
- [イテレーション](../group/iterations/_index.md)
- [マイルストーン](../project/milestones/_index.md)
- [カスタムフィールド](custom_fields.md)
- [設定可能な作業アイテムタイプ](configurable_work_item_types.md)
- [Workplan](workplan.md)
