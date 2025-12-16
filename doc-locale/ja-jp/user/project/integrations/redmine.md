---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redmine
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件: 

- プロジェクトで[GitLab](../issues/_index.md)の内部イシュートラッキングを無効にする必要があります。GitLabイシューを無効にする手順と結果について詳しくは、[プロジェクトの表示レベルを変更する](../../public_access.md#change-project-visibility)と[プロジェクトの機能と権限を設定する](../settings/_index.md#configure-project-features-and-permissions)をご覧ください。

[Redmine](https://www.redmine.org/)を[外部イシュートラッカー](../../../integration/external-issue-tracker.md)として使用できます。プロジェクトでRedmineインテグレーションを有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Redmine**（Redmine）を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必須フィールドに入力します:

   - **プロジェクトのURL**: このGitLabプロジェクトにリンクするRedmineプロジェクトのURL。
   - **イシューのURL**: このGitLabプロジェクトにリンクするRedmineプロジェクトイシューのURL。URLには`:id`を含める必要があります。GitLabはこのIDをイシュー番号に置き換えます。
   - **新しいイシューのURL**: このGitLabプロジェクトにリンクされているRedmineプロジェクトに新しいイシューを作成するために使用するURL。
     <!-- The line below was originally added in January 2018: https://gitlab.com/gitlab-org/gitlab/-/commit/778b231f3a5dd42ebe195d4719a26bf675093350 -->
     **このURLは使用されておらず、将来のリリースで削除される予定です**。詳細については、[イシュー327503](https://gitlab.com/gitlab-org/gitlab/-/issues/327503)を参照してください。

1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Redmineを設定して有効にすると、GitLabプロジェクトページにRedmineリンクが表示され、Redmineプロジェクトに移動します。

たとえば、これは`gitlab-ci`という名前のプロジェクトの設定です:

- プロジェクトURL: `https://redmine.example.com/projects/gitlab-ci`
- イシューURL: `https://redmine.example.com/issues/:id`
- 新しいイシューのURL: `https://redmine.example.com/projects/gitlab-ci/issues/new`

## GitLabでRedmineイシューを参照する {#reference-redmine-issues-in-gitlab}

Redmineイシューは、次の形式で参照できます:

- `#<ID>`。`<ID>`は数字です（例: `#143`）。
- `<PROJECT>-<ID>`（例: `API_32-143`）。各識別子の意味は次のとおりです:
  - `<PROJECT>`は大文字で始まり、その後に大文字、数字、またはアンダースコアが続きます。
  - `<ID>`は数値です。

リンクでは、`<PROJECT>`の部分は無視され、常に**イシューのURL**で指定されたアドレスを指します。

内部と外部の両方のイシュー追跡が有効になっている場合は、より長い形式（`<PROJECT>-<ID>`）を使用することをお勧めします。短い形式を使用し、同じIDを持つイシューが内部イシュートラッカーに存在する場合、内部イシューがリンクされます。
