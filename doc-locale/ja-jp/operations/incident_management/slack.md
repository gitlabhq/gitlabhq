---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab for Slackアプリを使用して、SlackからGitLabインシデントを直接管理します。インシデントの宣言、クイックアクションの使用、通知の受信などが可能です。
title: Slackでのインシデント管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 15.7で`incident_declare_slash_command`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344856)されました。デフォルトでは無効になっています。
- [GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/378072)で有効になったのは、GitLab 15.10の[ベータ](../../policy/development_stages_support.md#beta)版からです。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

多くのチームが、Slackでのインシデント発生時にアラートを受信し、リアルタイムで連携しています。GitLab for Slackアプリで以下が可能です:

- SlackからGitLabインシデントを作成します。
- インシデントの通知を受信します。

Slackのインシデント管理は、GitLab.comでのみ利用可能です。説明されている機能の一部は、[GitLab Self-Managed Slackアプリ](../../user/project/integrations/slack_slash_commands.md)で利用できる場合があります。

最新情報を得るには、[epic 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211)をフォローしてください。

## Slackからインシデントを管理する {#manage-an-incident-from-slack}

前提要件:

1. [GitLab for Slackアプリ](../../user/project/integrations/gitlab_slack_application.md)をインストールします。これにより、Slackでスラッシュコマンドを使用して、GitLabインシデントを作成および更新できます。
1. [Slackの通知](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)を有効にします。`Incident`イベントの通知を有効にし、関連する通知を受信するSlackチャンネルを定義してください。
1. GitLabがユーザーのSlackユーザーの代わりにアクションを実行することを認可します。各ユーザーは、インシデントスラッシュコマンドを使用する前に、これを行う必要があります。

   認可フローを開始するには、`/gitlab <project-alias> issue show <id>`のような、インシデントではない[Slackスラッシュコマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)を実行してみてください。選択した`<project-alias>`は、GitLab for Slackアプリが設定されているプロジェクトである必要があります。選択モーダルのハード制限は100プロジェクトです。詳細については、[イシュー377548](https://gitlab.com/gitlab-org/gitlab/-/issues/377548)を参照してください。

GitLab for Slackアプリが設定されると、既存の[Slackスラッシュコマンド](../../user/project/integrations/slack_slash_commands.md)も使用できます。

## インシデントを宣言する {#declare-an-incident}

SlackからGitLabインシデントを宣言するには:

1. Slackの任意のチャンネルまたはDMで、`/gitlab incident declare`スラッシュコマンドを入力します。
1. モーダルから、関連するインシデントの詳細（以下を含む）を選択します:

   - インシデントのタイトルと説明。
   - インシデントを作成するプロジェクト。
   - インシデントの重大度。

   プロジェクトに既存の[incident template](alerts.md#trigger-actions-from-alerts)がある場合、そのテンプレートが説明テキストボックスに自動的に適用されます。テンプレートが適用されるのは、説明テキストボックスが空の場合のみです。

   説明テキストボックスにGitLabの[クイックアクション](../../user/project/quick_actions.md)を含めることもできます。たとえば、`/link https://example.slack.com/archives/123456789 Dedicated Slack channel`と入力すると、作成したインシデントに専用のSlackチャンネルが追加されます。インシデントのクイックアクションの完全なリストについては、[GitLabクイックアクションの使用](#use-gitlab-quick-actions)を参照してください。
1. オプション。既存のZoomミーティングへのリンクを追加します。
1. **作成**を選択します。

インシデントが正常に作成されると、Slackに確認通知が表示されます。

### GitLabクイックアクションを使用する {#use-gitlab-quick-actions}

SlackからGitLabインシデントを作成するときは、説明テキストボックスで[クイックアクション](../../user/project/quick_actions.md)を使用します。次のクイックアクションは、ユーザーに最も関連性が高い可能性があります:

| コマンド                  | 説明                               |
| ------------------------ | ----------------------------------------- |
| `/assign @user1 @user2`  | GitLabインシデントに担当者を追加します。  |
| `/label ~label1 ~label2` | GitLabインシデントにラベルを追加します。       |
| `/link <URL> <text>`     | 専用のSlackチャンネル、手順書、または関連リソースへのリンクをインシデントの`Related resources`セクションに追加します。 |
| `/zoom <URL>`            | Zoomミーティングリンクをインシデントに追加します。 |

## SlackにGitLabインシデントの通知を送信する {#send-gitlab-incident-notifications-to-slack}

インシデントの[通知を有効](#manage-an-incident-from-slack)にしている場合は、インシデントが開かれたり、閉じられたり、更新されたりするたびに、選択したSlackチャンネルに通知が届くはずです。
