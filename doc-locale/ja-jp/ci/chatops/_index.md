---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ChatOps
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab ChatOpsを使用して、Slackなどのチャットサービスを介してCI/CDのジョブを操作します。

多くの組織では、SlackやMattermostを使用して共同作業、トラブルシューティングを行う、作業計画を行っています。ChatOpsを使用すると、チームと作業について話し合い、CI/CDのジョブを実行し、ジョブの出力を表示するすべての操作を同じアプリケーションから行えます。

## スラッシュコマンドのインテグレーション {#slash-command-integrations}

[`run`スラッシュコマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)でChatOpsをトリガーすることができます。

利用可能な次のインテグレーションがあります:

- [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md) (Slackに推奨)
- [Slackのスラッシュコマンド](../../user/project/integrations/slack_slash_commands.md)
- [Mattermostのスラッシュコマンド](../../user/project/integrations/mattermost_slash_commands.md)

## ChatOpsのワークフローとCI/CDの設定 {#chatops-workflow-and-cicd-configuration}

ChatOpsはプロジェクトのデフォルトブランチにある[`.gitlab-ci.yml`](../yaml/_index.md)で指定されたジョブを探します。ジョブが見つかった場合、ChatOpsは指定されたジョブのみを含むパイプラインを作成します。`when: manual`を設定した場合、ChatOpsはパイプラインを作成しますが、ジョブは自動的に開始されません。

ChatOpsで実行されるジョブは、GitLabから実行されるジョブと同じ機能を持っています。ジョブは、既存の[CI/CD変数](../variables/_index.md#predefined-cicd-variables)（`GITLAB_USER_ID`など）を使用して追加の権限検証を実行できますが、これらの変数は[オーバーライド](../variables/_index.md#cicd-variable-precedence)できます。

標準のCI/CDパイプラインの一部としてジョブが実行されないように、[`rules`](../yaml/_index.md#rules)を設定する必要があります。

ChatOpsは次の[CI/CD変数](../variables/_index.md#predefined-cicd-variables)をジョブに渡します:

- `CHAT_INPUT` - `run`スラッシュコマンドに渡される引数。
- `CHAT_CHANNEL` - ジョブが実行されるチャットチャンネルの名前。
- `CHAT_USER_ID` - ジョブを実行するユーザーのチャットサービスID。

ジョブの実行時:

- ジョブが30分未満で完了した場合、ChatOpsはジョブの出力をチャットチャンネルに送信します。
- ジョブが30分を超えて完了した場合、[Slack API](https://api.slack.com/)のような方法を使用してチャンネルにデータを送信する必要があります。

### ChatOpsからジョブを除外する {#exclude-a-job-from-chatops}

ジョブがチャットから実行されるのを防ぐには:

- `.gitlab-ci.yml`で、ジョブを`except: [chat]`に設定します。

### ChatOpsの返信をカスタマイズ {#customize-the-chatops-reply}

ChatOpsは、単一のコマンドを持つジョブの出力を、返信としてチャンネルに送信します。たとえば、次のジョブが実行されると、チャットの返信は`Hello world`となります:

```yaml
stages:
- chatops

hello-world:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "Hello World"
```

ジョブに複数のコマンドが含まれている場合、または`before_script`が設定されている場合、ChatOpsはコマンドとその出力をチャンネルに送信します。コマンドはANSIカラーコードでラップされます。

1つのコマンドの出力で選択的に返信するには、出力を`chat_reply`セクションに配置します。たとえば、次のジョブは現在のディレクトリのファイルをリスト表示します:

```yaml
stages:
- chatops

ls:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## ChatOpsを使用してCI/CDジョブをトリガーする {#trigger-a-cicd-job-using-chatops}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。
- プロジェクトはスラッシュコマンドのインテグレーションを使用するように設定されています。

SlackまたはMattermostからデフォルトブランチでCI/CDジョブを実行できます。

CI/CDジョブをトリガーするスラッシュコマンドは、プロジェクトにどのスラッシュコマンドインテグレーションが設定されているかによって異なります。

- GitLab for Slack appの場合、`/gitlab <project-name> run <job name> <arguments>`を使用します。
- SlackまたはMattermostスラッシュコマンドの場合、`/<trigger-name> run <job name> <arguments>`を使用します。

各項目の説明は以下のとおりです: 

- `<job name>`は実行するCI/CDジョブの名前です。
- `<arguments>`はCI/CDジョブに渡す引数です。
- `<trigger-name>`はSlackまたはMattermostインテグレーション用に設定されたトリガー名です。

ChatOpsは、指定されたジョブのみを含むパイプラインをスケジュールします。

## 関連トピック {#related-topics}

- GitLabがGitLab.comとやり取りするために使用する[共通のChatOpsスクリプトのリポジトリ](https://gitlab.com/gitlab-com/chatops)
- [GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_application.md)
- [Slackのスラッシュコマンド](../../user/project/integrations/slack_slash_commands.md)
- [Mattermostのスラッシュコマンド](../../user/project/integrations/mattermost_slash_commands.md)
