---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Prevent an incomplete merge request from merging until it's ready by setting it as a draft.
title: 下書きマージリクエスト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストのマージ準備ができていない場合は、[準備済みとしてマークする](#mark-merge-requests-as-ready)までマージされないようにすることができます。**下書き**としてマークされたマージリクエストは、他のすべてのマージ条件を満たしていても、**下書き**フラグを削除するまでマージできません。

![マージがブロックされました](img/merge_request_draft_blocked_v16_0.png)

## マージリクエストを下書きとしてマークする

{{< history >}}

- 切替としての`/draft`クイックアクションはGitLab 15.4で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92654)になりました。
- GitLab 15.8で、チェックボックスを使用するように下書き状態を[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108073)しました。

{{< /history >}}

次の複数の方法で、マージリクエストに下書きのフラグを付けることができます。

- **マージリクエストを表示**: マージリクエストの右上隅で、**マージリクエストのアクション**({{< icon name="ellipsis_v" >}})を選択し、**Draftとしてマーク**を選択します。
- **マージリクエストを作成または編集**: `[Draft]`、`Draft:`、または`(Draft)`をマージリクエストのタイトルの先頭に追加するか、**タイトル**フィールドの下にある**Draftとしてマーク**を選択します。
- **既存のマージリクエストにコメント**:コメントに`/draft`[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を追加します。マージリクエストを準備済みとしてマークするには、`/ready`を使用します。
- **コミットを作成**:マージリクエストのソースブランチを対象とするコミットメッセージの先頭に、`draft:`、`Draft:`、`fixup!`、または`Fixup!`を追加します。この方法は切替ではありません。このテキストを後続のコミットで再度追加しても、マージリクエストは準備済みとしてマークされません。

## マージリクエストを準備済みとしてマークする

マージリクエストのマージ準備ができたら、次の複数の方法で`Draft`フラグを削除できます。

- **マージリクエストを表示**: マージリクエストの右上隅で、**準備済みとしてマーク**を選択します。デベロッパーロール以上を持つユーザーは、マージリクエストの説明の一番下までスクロールして、**準備済みとしてマーク**を選択することもできます。
- **既存のマージリクエストを編集**: タイトルの先頭から`[Draft]`、`Draft:`、または`(Draft)`を削除するか、**タイトル**フィールドの下にある**Draftとしてマーク**をクリアします。
- **既存のマージリクエストにコメント**:マージリクエストのコメントに`/ready`[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を追加します。

マージリクエストを準備済みとしてマークすると、GitLabは[マージリクエストの参加者とウォッチャー](../../profile/notifications.md#notifications-on-issues-merge-requests-and-epics)に通知します。

## 検索時に下書きを含めるまたは除外する

プロジェクトのマージリクエストリストを表示または検索するときに、下書きマージリクエストを含めるか除外するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを見つけます。
1. **コード > マージリクエスト**を選択します。
1. マージリクエストの状態でフィルタリングするには、ナビゲーションバーで**オープン**、**マージ済み**、**クローズ**、または**すべて**を選択します。
1. 検索ボックスを選択してフィルターのリストを表示し、**下書き**を選択するか、単語`draft`を入力します。
1. `=`を選択します。
1. 下書きを含める場合は**はい**を、除外する場合は**いいえ**を選択し、**Return**キーを押してマージリクエストのリストを更新します。

   ![下書きマージリクエストをフィルターする](img/filter_draft_merge_requests_v16_0.png)

## 下書きのパイプライン

下書きマージリクエストは、準備済みとしてマークされたマージリクエストと同じパイプラインを実行します。

GitLab 15.0以前では、[マージ結果パイプライン](../../../ci/pipelines/merged_results_pipelines.md)を実行する場合は、[マージリクエストを準備済みとしてマーク](#mark-merge-requests-as-ready)する必要があります。

下書きマージリクエストのパイプラインをスキップする方法については、「[下書きマージリクエストのパイプラインをスキップする](../../../ci/yaml/workflow.md#skip-pipelines-for-draft-merge-requests)」を参照してください。

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that might go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
