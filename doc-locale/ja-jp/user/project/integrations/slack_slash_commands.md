---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Slackのスラッシュコマンド
description: "GitLab Self-ManagedインスタンスのSlack slashコマンドを設定します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

この機能は、GitLab Self-Managedでのみ設定可能です。GitLab.comの場合は、代わりに[GitLab for Slackアプリ](gitlab_slack_application.md)を使用してください。

{{< /alert >}}

[slash commands](gitlab_slack_application.md#slash-commands)を使用すると、イシューの作成など、一般的なGitLab操作を[Slack](https://slack.com/)チャット環境から実行できます。Slackでslash commandsを実行するには、SlackとGitLabの両方を設定する必要があります。

GitLabは、[Slack通知](gitlab_slack_application.md#slack-notifications)の一部として、イベント（`issue created`など）をSlackに送信することもできます。

利用可能なslash commandsの一覧は、[Slash commands](gitlab_slack_application.md#slash-commands)を参照してください。

## インテグレーションを設定する {#configure-the-integration}

Slack slash commandsは、プロジェクトのスコープに設定されます。Slack slash commandsを設定するには、次の手順に従ってください:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Slack slash commands**を選択し、このブラウザータブを開いたままにします。
1. 新しいブラウザータブで、Slackにサインインし、[新しいslash commandを追加](https://my.slack.com/services/new/slash-commands)します。
1. slash commandのトリガー名を入力します。プロジェクト名を使用できます。
1. **Add Slash Command Integration**を選択します。
1. Slackブラウザータブで、以下を行います:
   1. GitLabブラウザータブの情報でフィールドを完了します。
   1. **Save Integration**を選択し、**パイプライントークン**の値をコピーします。
1. GitLabブラウザータブで、以下を行います:
   1. トークンを貼り付け、**有効**チェックボックスが選択されていることを確認します。
   1. **変更を保存**を選択します。

これで、Slackでslash commandsを実行できます。
