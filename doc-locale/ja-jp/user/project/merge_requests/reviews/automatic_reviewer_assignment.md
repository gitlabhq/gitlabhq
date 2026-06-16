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
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.10で、`auto_assign_code_owner_reviewers`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175)されました。デフォルトでは無効になっています。

{{< /history >}}

自動レビュアー割り当てを有効にすると、GitLabは変更されたファイルの[コードオーナー](../../codeowners/_index.md)をマージリクエストのレビュアーとして割り当てます。`CODEOWNERS`ファイルからレビュアーを手動で選択する必要はありません。

この機能は[ベータ版](../../../../policy/development_stages_support.md#beta)です。フィードバックを残すには、[イシュー589700](https://gitlab.com/gitlab-org/gitlab/-/issues/589700)にコメントしてください。

## 前提条件 {#prerequisites}

- プロジェクトには[`CODEOWNERS`ファイル](../../codeowners/_index.md)が必要です。
- プロジェクトのメンテナーまたはオーナーのロール。

## 自動レビュアー割り当てを有効にする {#enable-automatic-reviewer-assignment}

プロジェクトの自動レビュアー割り当てを有効にするには:

1. 左サイドバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
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

[GitLab Duo Agent Platform](../../../../user/duo_agent_platform/_index.md)がレビュアーを推奨するプロジェクトでは、**自動レビュアー割り当て**セクションに**Reviewer assignment strategy**が次のオプションとともに表示されます:

- **Do not assign reviewers automatically**: GitLabはレビュアーを変更しません。
- **Assign all code owners as reviewers**: GitLabは、変更されたファイルに一致する`CODEOWNERS`ファイルからのすべてのコードオーナーを割り当てます。
- **Assign reviewers with GitLab Duo Agent Platform**: GitLab Duo Agent Platformは、各承認ルールを満たすために必要な最小数のレビュアーを推奨します。

## 関連トピック {#related-topics}

- [コードオーナー](../../codeowners/_index.md)
- [マージリクエストのレビュー](_index.md)
- [マージリクエスト承認ルール](../approvals/rules.md)
