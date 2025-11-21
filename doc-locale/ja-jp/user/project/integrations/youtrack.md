---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: YouTrack
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

JetBrains [YouTrack](https://www.jetbrains.com/youtrack/)は、ウェブベースのイシュートラッキングおよびプロジェクト管理プラットフォームです。

YouTrackをGitLabで[外部イシュートラッカー](../../../integration/external-issue-tracker.md)として構成できます。

プロジェクトでYouTrackインテグレーションを有効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **YouTrack**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. 必須フィールドに入力します:
   - **プロジェクトのURL**: YouTrackのプロジェクトのURL。
   - **イシューのURL**: YouTrackプロジェクトでイシューを表示するためのURL。URLには`:id`を含める必要があります。GitLabは`:id`をイシュー番号に置き換えます。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

YouTrackを構成して有効にすると、GitLabプロジェクトページにリンクが表示されます。このリンクをクリックすると、該当するYouTrackプロジェクトに移動します。

このプロジェクトで[GitLab内部イシュートラッキング](../issues/_index.md)を無効にすることもできます。GitLabイシューを無効にする手順と結果について詳しくは、プロジェクトの[表示レベル](../../public_access.md#change-project-visibility) 、[機能、および権限](../settings/_index.md#configure-project-features-and-permissions)の構成に関するドキュメントをご覧ください。

## GitLabでYouTrackイシューを参照 {#reference-youtrack-issues-in-gitlab}

YouTrackのイシューは、`<PROJECT>-<ID>`（たとえば、`YT-101`、`Api_32-143`、`gl-030`）を使用して参照できます。ここで:

- `<PROJECT>`は文字で始まり、その後に文字、数字、またはアンダースコアが続きます。
- `<ID>`は数字です。

マージリクエスト、コミット、またはコメント内の`<PROJECT>-<ID>`への参照は、YouTrackイシューURLに自動的にリンクされます。
