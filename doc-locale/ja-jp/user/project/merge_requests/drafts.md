---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: マージリクエストをドラフトとして設定することにより、準備できるまで不完全なマージリクエストがマージされないようにします。
title: ドラフトマージリクエスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストのマージ準備ができていない場合は、[準備完了としてマークする](#mark-merge-requests-as-ready)までマージされないようにすることができます。**ドラフト**としてマークされたマージリクエストは、他のすべてのマージ条件を満たしていても、**ドラフト**フラグを削除するまでマージできません:

![マージがブロックされました](img/merge_request_draft_blocked_v16_0.png)

## マージリクエストをドラフトとしてマークする {#mark-merge-requests-as-drafts}

次の複数の方法で、マージリクエストを下書きとしてマークできます:

- マージリクエストを表示: マージリクエストの右上隅で、**マージリクエストのアクション**（{{< icon name="ellipsis_v" >}}）を選択し、**ドラフトとしてマーク**を選択します。
- マージリクエストを作成または編集: `[Draft]`、`Draft:`、または`(Draft)`をマージリクエストのタイトルの先頭に追加するか、**タイトル**フィールドの下にある**ドラフトとしてマーク**を選択します。
- 既存のマージリクエストにコメント: コメントに`/draft`[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を追加します。マージリクエストを準備完了としてマークするには、`/ready`を使用します。
- コミットを作成: マージリクエストのソースブランチを対象とするコミットメッセージの先頭に、`draft:`、`Draft:`、`fixup!`、または`Fixup!`を追加します。この方法では切り替えはできません。このテキストを後続のコミットで再度追加しても、マージリクエストは準備完了としてマークされません。

## マージリクエストを準備完了としてマークする {#mark-merge-requests-as-ready}

マージリクエストのマージ準備ができたら、次の複数の方法で`Draft`フラグを削除できます:

- マージリクエストを表示: マージリクエストの右上隅で、**準備完了としてマーク**を選択します。デベロッパーロール以上のユーザーは、マージリクエストの説明の一番下までスクロールして、**準備完了としてマーク**を選択することもできます。
- 既存のマージリクエストを編集: タイトルの先頭から、`[Draft]`、`Draft:`、または`(Draft)`を削除するか、**タイトル**フィールドの下にある**ドラフトとしてマーク**をクリアします。
- 既存のマージリクエストにコメント: マージリクエストのコメントに、`/ready`[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を追加します。

マージリクエストを準備完了としてマークすると、GitLabは[マージリクエストの参加者とウォッチャー](../../profile/notifications.md#notifications-on-issues-merge-requests-and-epics)に通知します。

## 検索時にドラフトを含めるか除外する {#include-or-exclude-drafts-when-searching}

プロジェクトのマージリクエストリストを表示または検索するときに、ドラフトマージリクエストを含めるか除外するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **マージリクエスト**を選択します。
1. マージリクエストの状態でフィルタリングするには、ナビゲーションバーで**オープン**、**マージ済み**、**クローズ**、または**すべて**を選択します。
1. 検索ボックスを選択してフィルターのリストを表示し、**ドラフト**を選択するか、単語`draft`を入力します。
1. `=`を選択します。
1. ドラフトを含める場合は**可能**を、除外する場合は**いいえ**を選択し、**Return**キーを押してマージリクエストのリストを更新します:

   ![ドラフトマージリクエストをフィルタリングする](img/filter_draft_merge_requests_v16_0.png)

## ドラフトのパイプライン {#pipelines-for-drafts}

ドラフトマージリクエストは、準備完了としてマークされたマージリクエストと同じパイプラインを実行します。

下書きマージリクエストのパイプラインをスキップする方法については、[ドラフトマージリクエストのパイプラインをスキップする](../../../ci/yaml/workflow.md#skip-pipelines-for-draft-merge-requests)を参照してください。
