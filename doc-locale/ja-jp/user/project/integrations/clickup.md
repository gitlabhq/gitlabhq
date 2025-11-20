---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ClickUp
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732)されました。

{{< /history >}}

[ClickUp](https://clickup.com/)を[外部イシュートラッカー](../../../integration/external-issue-tracker.md)として使用できます。プロジェクトでClickUpインテグレーションを有効にするには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **ClickUp**（ClickUp） を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必須フィールドに入力します:

   - **プロジェクトのURL**: このGitLabプロジェクトにリンクするClickUpプロジェクトのURL。
   - **イシューのURL**: このGitLabプロジェクトにリンクするClickUpプロジェクトイシューのURL。URLには`:id`を含める必要があります。GitLabはこのIDをイシュー番号に置き換えます。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

ClickUpを設定して有効にすると、GitLabプロジェクトページにClickUpリンクが表示され、ClickUpプロジェクトに移動できます。

たとえば、これは`gitlab-ci`という名前のプロジェクトの設定です:

- プロジェクトURL: `https://app.clickup.com/1234567`
- イシューURL: `https://app.clickup.com/t/1234567/:id`

このプロジェクトで[GitLab内部イシュートラッキング](../issues/_index.md)を無効にすることもできます。GitLabイシューを無効にする手順と結果について詳しくは、プロジェクトの[表示レベル](../../public_access.md#change-project-visibility) 、[機能、および権限](../settings/_index.md#configure-project-features-and-permissions)の設定を参照してください。

## GitLabでClickUpイシューを参照 {#reference-clickup-issues-in-gitlab}

ClickUpイシューは、以下を使用して参照できます:

- `#<ID>`。`<ID>`は英数字文字列です（例: `#8wrtcd932`）。
- `CU-<ID>`。`<ID>`は英数字文字列です（例: `CU-8wrtcd932`）。
- `<PROJECT>-<ID>`（例: `API_32-143`）。各識別子の意味は次のとおりです:
  - `<PROJECT>`はClickUpリストのカスタムプレフィックスIDです。
  - `<ID>`は数値です。
- [カスタムタスクID](https://help.clickup.com/hc/en-us/sections/17044579323671-Custom-Task-IDs)を使用している場合は、カスタムプレフィックスを含む完全なカスタムタスクIDも機能します。例: `SOP-1234`。

リンクでは、`CU-`の部分は無視され、イシューのグローバルURLにリンクされます。カスタムプレフィックスがClickUpリストで使用されている場合、プレフィックス部分はリンクの一部になります。

内部と外部の両方のイシュートラッカーが有効になっている場合は、`CU-`形式（`CU-<ID>`）を使用することをお勧めします。短い形式を使用し、同じIDを持つイシューが内部イシュートラッカーに存在する場合、内部イシューがリンクされます。

[カスタムタスクID](https://help.clickup.com/hc/en-us/sections/17044579323671-Custom-Task-IDs)の場合、カスタムプレフィックスを含む完全なIDを**must**（含める必要があります）。たとえば`SOP-1432`などです。
