---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューリストを並べ替える
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数の方法でイシューのイシューリストをソートできます。利用可能なソートオプションは、リストのコンテキストに基づいて変更される場合があります。

## ブロックイシューによるソート {#sorting-by-blocking-issues}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

**ブロック**でソートすると、各イシューが[ブロック](related_issues.md#blocking-issues)しているイシューの数で降順にソートされるようにイシューリストが変更されます。

## 作成日でソート {#sorting-by-created-date}

**作成日**でソートすると、イシューの作成日で降順にソートされるようにイシューリストが変更されます。最も最近作成されたイシューが最初に表示されます。

## 期日でソート {#sorting-by-due-date}

**期限**でソートすると、イシューの[期日](due_dates.md)で昇順にソートされるようにイシューリストが変更されます。最も早い期日のイシューが最初に表示され、期日のないイシューが最後に表示されます。

## ラベルの優先度によるソート {#sorting-by-label-priority}

**ラベルの優先度**でソートすると、イシューリストは降順にソートされるように変更されます。優先度の最も高いラベルが付いたイシューが最初に表示され、次に他のすべてのイシューが表示されます。

同順位は任意に決定されます。優先順位が最も高いラベルのみがチェックされ、優先順位の低いラベルは無視されます。詳細については、[issue 14523](https://gitlab.com/gitlab-org/gitlab/-/issues/14523)を参照してください。

ラベルの優先度を変更する方法については、[ラベルの優先度](../labels.md#set-label-priority)を参照してください。

## 更新した日でソート {#sorting-by-updated-date}

**更新した日**でソートすると、イシューリストは最後の更新時刻でソートされるように変更されます。最も最近変更されたイシューが最初に表示されます。

## マニュアルソート {#manual-sorting}

**マニュアル**順でソートすると、イシューをドラッグアンドドロップして順序を変更できます。変更された順序は保持され、同じリストにアクセスするすべてのユーザーには、更新されたイシューの順序が表示されます（例外あり）。

各イシューには、相対的な順序の値が割り当てられており、リスト上の他のイシューに対する相対的な順序を表しています。イシューをドラッグアンドドロップで並べ替えると、その相対的な順序の値が変わります。

さらに、手動でソートされたリストにイシューが表示されるたびに、更新された相対的な順序の値が順序付けに使用されます。そのため、誰かがGitLabインスタンスでイシュー`A`をイシュー`B`より上にドラッグすると、それらがリストに一緒に表示されるときはいつでも、この順序が維持されます。

この順序は[issue boards](../issue_board.md#ordering-issues-in-a-list)にも影響します。イシューリストの順序を変更すると、イシューボードの順序が変更され、その逆も同様です。

## マイルストーンの期日によるソート {#sorting-by-milestone-due-date}

**マイルストーンの期日**でソートすると、割り当てられたマイルストーンの期日で昇順にソートされるようにイシューリストが変更されます。最も早い期日のマイルストーンを持つイシューが最初に表示され、期日のないマイルストーンを持つイシューが次に表示されます。

## 人気度によるソート {#sorting-by-popularity}

**人気度**でソートすると、各イシューの同意する数（「賛成」の[絵文字リアクション](../../emoji_reactions.md)）で降順にソートされるようにイシューの順序が変更されます。これを使用して、需要の高いイシューを特定できます。

投票の合計数は集計されません。18件の同意すると5件のダウン同意するがあるイシューは、17件の同意するとダウン同意するがないイシューよりも人気があると見なされます。

## 優先順位によるソート {#sorting-by-priority}

**優先順位**でソートすると、イシューの順序は次の順序でソートされるように変更されます:

1. 期日のあるマイルストーンを持つイシュー（割り当てられた最も早いマイルストーンが最初にリストされます）。
1. 期日のないマイルストーンを持つイシュー。
1. より高い優先ラベルを持つイシュー。
1. 優先順位付けられたラベルのないイシュー。

同順位は任意に決定されます。

ラベルの優先度を変更する方法については、[ラベルの優先度](../labels.md#set-label-priority)を参照してください。

## タイトルによるソート {#sorting-by-title}

**タイトル**でソートすると、イシューの順序は、イシューのタイトルでアルファベット順に、次の順序でソートされるように変更されます:

- 絵文字
- 特殊文字
- 数字
- 文字：最初にラテン文字、次にアクセント付き（例：`ö`）

## 健全性ステータスによるソート {#sorting-by-health-status}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/377841)されました。

{{< /history >}}

**健全性**でソートすると、イシューリストはイシューの[ヘルスステータス](managing_issues.md#health-status)でソートされるように変更されます。降順の場合、イシューは次の順序で表示されます:

1. **危険**イシュー
1. **要注意**イシュー
1. **健全**なイシュー
1. その他のすべてのイシュー

## ウェイトによるソート {#sorting-by-weight}

**ウェイト**でソートすると、イシューリストは[イシューのウェイト](issue_weight.md)で昇順にソートされるように変更されます。最も低いウェイトのイシューが最初に表示され、ウェイトのないイシューが最後に表示されます。

## ステータスによるソート {#sorting-by-status}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.5で`work_item_status_mvc2`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550262)されました。デフォルトでは有効になっています。

{{< /history >}}

**ステータス**でソートすると、イシューリストは[イシューのステータス](../../work_items/status.md)で昇順にソートされるように変更されます。イシューは、最初にステータスカテゴリでソートされます。2つのイシューが同じカテゴリを共有する場合、システムはイシューIDでソートするようにフォールバックします。
