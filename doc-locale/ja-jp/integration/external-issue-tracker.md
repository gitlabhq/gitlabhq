---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部イシュートラッカー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabには独自の[イシュートラッカー](../user/project/issues/_index.md)がありますが、GitLabプロジェクトごとに外部イシュートラッカーを設定することもできます。次に、以下を使用できます:

- 外部イシュートラッカーとGitLabイシュートラッカー
- 外部イシュートラッカーのみ

外部トラッカーでは、`CODE-123`の形式を使用して、GitLabマージリクエスト、コミット、およびコメントで外部イシューを言及できます:

- `CODE`は、トラッカーの一意のコードです。
- `123`は、トラッカー内のイシュー番号です。

参照はイシューリンクとして表示されます。

## GitLabイシュートラッカーを無効にする {#disable-the-gitlab-issue-tracker}

プロジェクトのGitLabイシュートラッカーを無効にするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **イシュー**で、切替をオフにします。
1. **変更を保存**を選択します。

GitLabイシュートラッカーを無効にした後:

- [外部イシュートラッカーが設定されている](#configure-an-external-issue-tracker)場合、**イシュー**は左側のサイドバーに表示されますが、外部イシュートラッカーにリダイレクトされます。
- 外部イシュートラッカーが設定されていない場合、**イシュー**は左側のサイドバーに表示されません。

## 外部イシュートラッカーを設定します {#configure-an-external-issue-tracker}

次の外部イシュートラッカーのいずれかを設定できます:

- [Bugzilla](../user/project/integrations/bugzilla.md)
- [ClickUp](../user/project/integrations/clickup.md)
- [カスタムイシュートラッカー](../user/project/integrations/custom_issue_tracker.md)
- [Engineering Workflow Management（EWM）](../user/project/integrations/ewm.md)
- [Jira](jira/_index.md)
- [Linear](../user/project/integrations/linear.md)
- [Phorge](../user/project/integrations/phorge.md)
- [Redmine](../user/project/integrations/redmine.md)
- [YouTrack](../user/project/integrations/youtrack.md)
