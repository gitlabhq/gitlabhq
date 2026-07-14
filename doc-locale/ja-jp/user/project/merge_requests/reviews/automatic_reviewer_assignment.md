---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージリクエストが準備完了になったときに、コードオーナーをレビュアーとして自動的に割り当てます。
title: 自動レビュアー割り当て
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10で、`auto_assign_code_owner_reviewers`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175)されました。デフォルトでは無効になっています。
- GitLab 19.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965)になりました。機能フラグ`auto_assign_code_owner_reviewers`は削除されました。

{{< /history >}}

自動レビュアー割り当てを有効にすると、GitLabは変更されたファイルの[コードオーナー](../../codeowners/_index.md)をマージリクエストのレビュアーとして割り当てます。`CODEOWNERS`ファイルからレビュアーを手動で選択する必要はありません。

## 前提条件 {#prerequisites}

- プロジェクトには[`CODEOWNERS`ファイル](../../codeowners/_index.md)が必要です。
- プロジェクトのメンテナーまたはオーナーのロール。

## 自動レビュアー割り当てを有効にする {#enable-automatic-reviewer-assignment}

プロジェクトの自動レビュアー割り当てを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. **自動レビュアー割り当て**セクションに移動します。
1. **Automatically assign all code owners as reviewers**を選択します。
1. **変更を保存**を選択します。

## GitLabがレビュアーを割り当てるタイミング {#when-gitlab-assigns-reviewers}

設定を有効にすると、GitLabは次の場合にコードオーナーをレビュアーとして割り当てます:

- マージリクエストが準備完了状態で作成された場合。
- ドラフトマージリクエストが準備完了としてマークされた場合。

GitLabは、マージリクエストで変更されたファイルに一致するすべてのコードオーナーを割り当てます。

GitLabは次の場合に自動割り当てをスキップします:

- マージリクエストがドラフトである場合。
- マージリクエストにすでにレビュアーがいる場合。[`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)はこのチェックから除外されます。
- マージリクエストで変更されたファイルに一致するコードオーナーがいない場合。
- マージリクエスト作成者がマージリクエストのメタデータを設定する権限を持っていない場合。

## レビュアー割り当て戦略 {#reviewer-assignment-strategy}

{{< history >}}

- **Assign reviewers with GitLab Duo Agent Platform**戦略は、GitLab 19.0で、`dap_powered_recommend_reviewers`という名前の[機能フラグと共に](../../../../administration/feature_flags/_index.md) [導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236211)。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> **Assign reviewers with GitLab Duo Agent Platform**戦略の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

お使いのプロジェクトで[GitLab Duo Agent Platform](../../../../user/duo_agent_platform/_index.md)が利用可能な場合、**自動レビュアー割り当て**セクションには、単一のチェックボックスの代わりに**Reviewer assignment strategy**設定が表示されます。これらのオプションのいずれかを選択してください:

- **Do not assign reviewers automatically**: GitLabはレビュアーを割り当てません。
- **Assign all code owners as reviewers**: GitLabは、変更されたファイルに一致する`CODEOWNERS`ファイルからのすべてのコードオーナーを割り当てます。
- **Assign reviewers with GitLab Duo Agent Platform**: GitLab Duo Agent Platformは、各承認ルールを満たすために必要な最小数のレビュアーを推奨し、割り当てます。

### レビュアーをGitLab Duo Agent Platformで割り当てる {#assign-reviewers-with-gitlab-duo-agent-platform}

この戦略を選択すると、GitLab Duo Agent Platformはマージリクエストの必須承認ルールを読み取ります。各ルールについて、ルールを満たすために必要な最小数のレビュアーを推奨し、それらを割り当て、その選択を説明する注記を追加します。この戦略は、コードオーナーだけでなく、すべての承認ルールタイプに適用されます。

ルールの対象となる承認者の中から選択するために、GitLab Duo Agent Platformは各承認者について以下を考慮します:

- 空き[ステータス](../../../profile/_index.md#set-your-status)に基づいた利用可能性。
- レビューを待っているオープンなマージリクエストの数に基づいたレビューワークロード。
- プロフィールのタイムゾーンに基づいた現地時間。
- 最新のアクティビティ。

GitLabは、マージリクエストの準備が整ったときにレビュアーを割り当てます。これは、コードオーナー戦略と同じです。推奨はバックグラウンドで実行されるため、レビュアーが表示されるまでに時間がかかる場合があります。GitLabは、ゼロ承認を必要とする承認ルールを無視します。

## 関連トピック {#related-topics}

- [コードオーナー](../../codeowners/_index.md)
- [マージリクエストのレビュー](_index.md)
- [マージリクエスト承認ルール](../approvals/rules.md)
