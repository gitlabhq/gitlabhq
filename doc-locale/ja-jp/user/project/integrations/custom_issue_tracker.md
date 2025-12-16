---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムイシュートラッカー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[外部](../../../integration/external-issue-tracker.md)イシュートラッカーをGitLabとインテグレーションできます。ご希望のイシュートラッカーが[インテグレーションリスト](../../../integration/external-issue-tracker.md#configure-an-external-issue-tracker)に表示されていない場合は、カスタムイシュートラッカーを有効にできます。

カスタムイシュートラッカーを有効にすると、イシュートラッカーへのリンクがプロジェクトの左側のサイドバーに表示されます。

![カスタムイシュートラッカーのリンク](img/custom_issue_tracker_v18_3.png)

## カスタムイシュートラッカーを有効にする {#enable-a-custom-issue-tracker}

プロジェクトでカスタムイシュートラッカーを有効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **カスタムイシュートラッカー**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必須フィールドに入力します:

   - **プロジェクトのURL**: カスタムイシュートラッカー内のすべてのイシューを表示するためのURL。
   - **イシューのURL**: カスタムイシュートラッカーでイシューを表示するためのURL。URLには`:id`を含める必要があります。GitLabは`:id`をイシュー番号に置き換えます（例: `https://customissuetracker.com/project-name/:id`が`https://customissuetracker.com/project-name/123`になります）。
   - **新しいイシューのURL**:
     <!-- The line below was originally added in January 2018: https://gitlab.com/gitlab-org/gitlab/-/commit/778b231f3a5dd42ebe195d4719a26bf675093350 -->
     **このURLは使用されておらず、削除するための[issueが存在](https://gitlab.com/gitlab-org/gitlab/-/issues/327503)します**。任意のURLを入力します。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

## カスタムイシュートラッカーでイシューを参照する {#reference-issues-in-a-custom-issue-tracker}

カスタムイシュートラッカーでイシューを参照するには、次の方法を使用します:

- `#<ID>`。`<ID>`は数字です（例: `#143`）。
- `<PROJECT>-<ID>`（例: `API_32-143`）説明:
  - `<PROJECT>`は、大文字で始まり、その後に大文字、数字、またはアンダースコアが続きます。
  - `<ID>`は数字です。

`<PROJECT>`部分はリンクでは無視され、常に**イシューのURL**で指定されたアドレスを指します。

内部と外部の両方のイシュートラッカーを有効にしている場合は、より長い形式（`<PROJECT>-<ID>`）を使用することをお勧めします。短い形式を使用し、同じIDのイシューが内部イシュートラッカーに存在する場合、内部イシューがリンクされます。
