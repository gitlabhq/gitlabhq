---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: クロスリンクイシュー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

クロスリンクは、GitLabのイシュー間の関係を作成します。クロスリンクでは、以下のことができます。

- 追跡の効率や表示レベルを向上させるために、関連するイシューを接続します。
- イシューを関連するコミットとマージリクエストにリンクします。
- コミットメッセージ、ブランチ名、説明を使用した参照を作成します。
- プロジェクトやグループ間で機能します。
- 各イシューの**リンクされたアイテム**セクションに関係を表示します。

クロスリンクは、以下の方法で作成できます。

- [コミットメッセージ](#from-commit-messages)
- [リンクされたイシュー](#from-linked-issues)
- [マージリクエスト](#from-merge-requests)
- [ブランチ名](#from-branch-names)

## コミットメッセージから作成する

コミットメッセージでイシューをメンションするたびに、開発ワークフローの2つのステージ（イシュー自体と、そのイシューに関連する最初のコミット）の間の関係が作成されます。

イシューとコミットするコードの両方が同じプロジェクトにある場合は、コミットメッセージに`#xxx`を追加します。`xxx`はイシュー番号です。

```shell
git commit -m "this is my commit message. Ref #xxx"
```

コミットメッセージは通常`#`で始めることができないため、代替の`GL-xxx`表記も使用できます。

```shell
git commit -m "GL-xxx: this is my commit message"
```

異なるプロジェクトにあるが、同じグループである場合は、コミットメッセージに`projectname#xxx`を追加します。

```shell
git commit -m "this is my commit message. Ref projectname#xxx"
```

同じグループにない場合は、イシューへの完全なURL（`https://gitlab.com/<username>/<projectname>/-/issues/<xxx>`）を追加できます。

```shell
git commit -m "this is my commit message. Related to https://gitlab.com/<username>/<projectname>/-/issues/<xxx>"
```

もちろん、`gitlab.com`を自分のGitLabインスタンスのURLに置き換えることもできます。

最初のコミットをイシューにリンクすることは、[GitLabバリューストリーム分析](https://about.gitlab.com/solutions/value-stream-management/)でプロセスを追跡するのに重要です。そうすることで、イシューの作成から最初のコミットまでの時間、つまりイシューの実装計画に要した時間を測定できます。

## リンクされたイシューから作成する

マージリクエストやその他のイシューでリンクされたイシューをメンションすると、チームメンバーや共同作業者は、同じトピックに関する未解決のイシューがあることを知ることができます。

上記で説明したように、これは[コミットメッセージからイシューをメンション](#from-commit-messages)することで行うことができます。

イシュー`#222`でイシュー`#111`をメンションすると、イシュー`#111`の**アクティビティー**フィードにも通知が表示されます。つまり、関係を一度メンションするだけで、両方のイシューに通知が表示されます。[マージリクエスト](#from-merge-requests)でイシューをメンションする場合も同様です。

イシューのアクティビティーフィードが**履歴のみ表示**または**すべてのアクティビティーを表示**にフィルタリングされると、クロスリンクは`(Username) mentioned in issue #(number) (time ago)`として表示されます。

## マージリクエストから作成する

マージリクエストコメントでイシューをメンションする方法は、[リンクされたイシュー](#from-linked-issues)の場合とまったく同じです。

マージリクエストの説明でイシューをメンションすると、[イシューとマージリクエストがリンクされます](#from-linked-issues)。さらに、マージリクエストがマージされるとすぐに、[イシューが自動的にクローズするように設定](managing_issues.md#closing-issues-automatically)することもできます。

イシューのアクティビティーフィードが**履歴のみ表示**または**すべてのアクティビティーを表示**にフィルタリングされると、クロスリンクは`(Username) mentioned in merge request !(number) (time ago)`として表示されます。

## ブランチ名から作成する

イシューと同じプロジェクトでブランチを作成し、ブランチ名をイシュー番号で始め、その後にハイフンを続けると、イシューと作成したMRがリンクされます。詳細については、[ブランチ名にイシュー番号をプレフィックスとして付ける](../repository/branches/_index.md#prefix-branch-names-with-a-number)を参照してください。
