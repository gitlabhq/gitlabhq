---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabイシューに数値ウェイトを割り当てて、見積もり工数、価値、または複雑さを表し、計画と優先順位付けを支援します。
title: イシューウェイト
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

イシューが大量にあると、概要を把握するのが困難になる場合があります。ウェイト付けされたイシューを使用すると、特定のイシューの時間、価値、または複雑さ、またはコストをより適切に把握できます。どのイシューを優先すべきかを確認するために、[ウェイトでソート](sorting_issue_lists.md#sorting-by-weight)することもできます。

## イシューのイシューのウェイトを表示 {#view-the-issue-weight}

イシューのイシューのウェイトは、以下で表示できます:

- 各イシューの右側のサイドバー。
- ウェイトアイコン（{{< icon name="weight" >}}）の横にあるイシューページ。
- ウェイトアイコン（{{< icon name="weight" >}}）の横にある[イシューボード](../issue_board.md)。
- イシューのウェイトの合計としての[マイルストーン](../milestones/_index.md)ページ。

## イシューのイシューのウェイトを設定 {#set-the-issue-weight}

{{< history >}}

- イシューのウェイトを設定するための最小ロールは、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

イシューを作成または編集するときに、イシューのウェイトを設定できます。

正の整数を入力する必要があります。

イシューのウェイトを変更すると、新しい値は前の値を上書きします。

### イシューを作成するとき {#when-you-create-an-issue}

[イシューを作成](create_issues.md)するときにイシューのウェイトを設定するには、**ウェイト**の下に数値を入力します。

### 既存のイシューから {#from-an-existing-issue}

既存のイシューからイシューのウェイトを設定するには、次の手順に従います:

1. イシューに移動します。
1. 右側のサイドバーの**ウェイト**セクションで、**編集**を選択します。
1. 新しいウェイトを入力します。
1. ドロップダウンリストの外側の領域を選択します。

### イシューボードから {#from-an-issue-board}

[イシューボードからイシューを編集](../issue_board.md#edit-an-issue)するときにイシューのウェイトを設定するには、次の手順に従います:

1. イシューボード
1. イシューカード（タイトルではない）を選択します。
1. 右側のサイドバーの**ウェイト**セクションで、**編集**を選択します。
1. 新しいウェイトを入力します。
1. ドロップダウンリストの外側の領域を選択します。

## イシューのウェイトを削除 {#remove-issue-weight}

{{< history >}}

- イシューのウェイトを削除するための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件: 

- プロジェクトのプランナーロール以上が必要です。

イシューのウェイトを削除するには、[イシューのウェイトを設定](#set-the-issue-weight)するときと同じ手順に従い、**ウェイトを削除**を選択します。
