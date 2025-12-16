---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リンクされたイシュー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で、必要な最小ロールがレポーター（trueの場合）からゲストに[変更](https://gitlab.com/groups/gitlab-org/-/epics/10267)されました。

{{< /history >}}

リンクされたイシューは、2つのイシュー間の双方向の関係で、イシューの説明の下のブロッカーに表示されます。異なるプロジェクトでイシューをリンクできます。

この関係は、ユーザーが両方のイシューを表示できる場合にのみUIに表示されます。オープンなブロッカーがあるイシューを閉じようとすると、警告が表示されます。

{{< alert type="note" >}}

当社のAPIを介してリンクされたイシューを管理するには、[Issue links API](../../../api/issue_links.md)を参照してください。

{{< /alert >}}

## リンクされたイシューを追加する {#add-a-linked-issue}

前提要件: 

- 両方のプロジェクトで、少なくともゲストロールが必要です。

あるイシューを別のイシューにリンクするには、次の手順に従います:

1. イシューの**リンクされたアイテム**セクションで、リンクされたイシューの追加ボタン（{{< icon name="plus" >}}）を選択します。
1. 2つのイシュー間の関係を選択します。次のいずれかの操作を行います:
   - **次のアイテムに関連している**
   - **[次のアイテムをブロックしている](#blocking-issues)**
   - **[次のアイテムにブロックされている](#blocking-issues)**
1. イシュー番号を入力するか、イシューの完全なURLを貼り付けます。

   ![現在のイシューと関連するイシューをリンクする](img/related_issues_add_v15_3.png)

   同じプロジェクトのイシューは、参照番号だけで指定できます。別のプロジェクトのイシューは、グループやプロジェクト名などの追加情報を必要とします。例: 

   - 同じプロジェクト: `#44`
   - 同じグループ: `project#44`
   - 異なるグループ: `group/project#44`

   有効な参照は、確認できる一時リストに追加されます。

1. リンクされたすべてのイシューを追加したら、**追加**を選択します。

リンクされたすべてのイシューの追加が完了すると、関係を視覚的に理解しやすいように分類表示されます。

![関連するイシューを表示または管理するセクション](img/related_issue_block_v15_3.png)

コミットメッセージまたは別のイシューまたはマージリクエストの説明から、リンクされたイシューを追加することもできます。詳細については、[クロスリンク](crosslinking_issues.md)を参照してください。

## リンクされたイシューを削除する {#remove-a-linked-issue}

イシューの**リンクされたアイテム**セクションで、削除する各イシュートークンの右側にある削除ボタン（{{< icon name="close" >}}）を選択します。

双方向の関係のため、いずれのイシューにもこの関係は表示されなくなります。

![現在のイシューから関連するイシューのリンクを解除する](img/related_issues_remove_v15_3.png)

詳細については、[権限](../../permissions.md)ページにアクセスしてください。

## ブロックされたイシュー {#blocking-issues}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[リンクされたイシューを追加](#add-a-linked-issue)すると、別のイシューを**次のアイテムをブロックしている**か、**次のアイテムにブロックされている**かを示すことができます。

他のイシューによってブロックされたイシューには、タイトルに隣接してアイコン（{{< icon name="entity-blocked" >}}）が表示され、イシューリストと[ボード](../issue_board.md)に表示されます。ブロックしているイシューが閉じられたり、関係が変更されたり、[削除](#remove-a-linked-issue)されたりすると、アイコンは消えます。

「イシューを閉じる」ボタンを使用してブロックされたイシューを閉じようとすると、確認メッセージが表示されます。
