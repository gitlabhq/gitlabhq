---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabの作業アイテムに数値のウェイトを割り当てて、見積もられた労力、価値、または複雑さを表し、計画と優先順位付けに役立てます。
title: 作業アイテムのウェイト
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.11で[エピックで導入](https://gitlab.com/groups/gitlab-org/-/work_items/12273)されました。

{{< /history >}}

作業アイテムがたくさんある場合、概要を把握するのが難しいことがあります。ウェイト付きの作業アイテムを使用すると、特定の作業アイテムにかかる時間、価値、複雑さがどれくらいか、よりよく把握できます。どの作業アイテムを優先すべきかを確認するために、[ウェイトでソートする](_index.md#sort-work-items)こともできます。

## 作業アイテムのウェイトを表示 {#view-the-work-item-weight}

作業アイテムのウェイトは以下で確認できます:

- 各作業アイテムの右サイドバー。
- ウェイトアイコン（{{< icon name="weight" >}}）の横にある、[作業アイテムリスト](_index.md#view-all-work-items)。
- ウェイトアイコン（{{< icon name="weight" >}}）の横にある、[イシューボード](../project/issue_board.md)。
- [マイルストーン](../project/milestones/_index.md)ページ。作業アイテムウェイトの合計として表示されます。

## 作業アイテムのウェイトを設定 {#set-the-work-item-weight}

{{< history >}}

- 作業アイテムのウェイトを設定するための最低ロールが、GitLab 17.7で[レポーターからプランナーに変わりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

前提条件: 

- 親プロジェクトまたはグループのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

以下が適用されます:

- 作業アイテムを作成または編集する際に、作業アイテムのウェイトを設定できます。
- 正の整数を入力する必要があります。
- 作業アイテムのウェイトを変更すると、新しい値が以前の値を上書きします。

### 作業アイテムを作成する際 {#when-you-create-a-work-item}

作業アイテムを作成する際に作業アイテムウェイトを設定するには、**ウェイト**の下に数値を入力します。

### 既存の作業アイテムから {#from-an-existing-work-item}

既存の作業アイテムから作業アイテムのウェイトを設定するには、:

1. 作業アイテムに移動します。
1. 右サイドバーの**ウェイト**セクションで、**編集**を選択します。
1. 新しいウェイトを入力します。
1. ドロップダウンリストの外側の領域を選択します。

### イシューボードから {#from-an-issue-board}

[イシューボードからイシューを編集](../project/issue_board.md#edit-an-issue)する際に、イシューのウェイトを設定するには:

1. イシューボードに移動します。
1. イシューカードを選択します（タイトルではありません）。
1. 右サイドバーの**ウェイト**セクションで、**編集**を選択します。
1. 新しいウェイトを入力します。
1. ドロップダウンリストの外側の領域を選択します。

## 作業アイテムウェイトを削除 {#remove-work-item-weight}

{{< history >}}

- 作業アイテムウェイトを削除するための最低ロールが、GitLab 17.7で[レポーターからプランナーに変わりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

前提条件: 

- 親プロジェクトまたはグループのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

作業アイテムウェイトを削除するには、[作業アイテムウェイトを設定する](#set-the-work-item-weight)場合と同じ手順に従い、**ウェイトを削除**を選択します。
