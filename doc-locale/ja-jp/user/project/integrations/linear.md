---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Linear
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)されました。

{{< /history >}}

[Linear](https://linear.app/)を[外部イシュートラッカー](../../../integration/external-issue-tracker.md)として使用できます。プロジェクトでLinearインテグレーションを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Linear**（Linear）を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必須フィールドに入力します:

   - **ワークスペースURL**: このGitLabプロジェクトにリンクするLinearワークスペースプロジェクトのURL。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Linearを設定して有効にすると、GitLabプロジェクトページにLinearリンクが表示され、Linearワークスペースに移動します。

たとえば、これは`example`という名前のワークスペースの設定です:

- ワークスペースURL: `https://linear.app/example`

このプロジェクトで[GitLab内部イシュートラッキング](../issues/_index.md)を無効にすることもできます。GitLabイシューを無効にする手順と結果について詳しくは、プロジェクトの[表示レベル](../../public_access.md#change-project-visibility) 、[機能、および権限](../settings/_index.md#configure-project-features-and-permissions)の設定を参照してください。

## GitLabでLinearイシューを参照する {#reference-linear-issues-in-gitlab}

Linearイシューは、以下を使用して参照できます:

- `<TEAM>-<ID>`（例: `API-123`）。各識別子の意味は次のとおりです:
  - `<TEAM>`はチーム識別子です
  - `<ID>`は数値です。
