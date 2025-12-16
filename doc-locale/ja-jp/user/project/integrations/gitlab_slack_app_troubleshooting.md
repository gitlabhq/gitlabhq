---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SlackアプリのGitLabのトラブルシューティング
description: "SlackアプリのGitLabのトラブルシューティングガイド。プロジェクトの欠落や通知の問題など、一般的な問題を網羅しています。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab for Slackアプリを使用する際に、次の問題が発生する可能性があります。

管理者向けドキュメントについては、[GitLab for Slackアプリの管理](../../../administration/settings/slack_app.md#troubleshooting)を参照してください。

## インテグレーションのリストにアプリが表示されない場合 {#app-does-not-appear-in-the-list-of-integrations}

SlackアプリのGitLabがインテグレーションのリストに表示されない場合があります。GitLab Self-ManagedインスタンスでSlackアプリのGitLabを使用するには、管理者が[インテグレーションを有効にする](../../../administration/settings/slack_app.md)必要があります。GitLab.comでは、SlackアプリのGitLabはデフォルトで使用できます。

## エラー: `Project or alias not found` {#error-project-or-alias-not-found}

一部のSlackコマンドには、プロジェクトのフルパスまたはエイリアスが必要であり、プロジェクトが見つからない場合は、次のエラーで失敗します:

```plaintext
GitLab error: project or alias not found
```

この問題を解決するには、以下を確認してください:

- プロジェクトのフルパスが正しい。
- [プロジェクトのエイリアス](gitlab_slack_application.md#create-a-project-alias)を使用している場合は、エイリアスが正しい。
- SlackアプリのGitLabが[プロジェクトに対して有効になっている](gitlab_slack_application.md#from-the-project-or-group-settings)。

## スラッシュコマンドがSlackで`dispatch_failed`を返す {#slash-commands-return-dispatch_failed-in-slack}

スラッシュコマンドがSlackで`/gitlab failed with the error "dispatch_failed"`を返す場合があります。

このイシューを解決するには、管理者がGitLab Self-Managedインスタンスで[SlackアプリのGitLab設定](../../../administration/settings/slack_app.md)を適切に構成していることを確認してください。

## チャンネルに通知が届かない {#notifications-not-received-to-a-channel}

Slackチャンネルに通知が届かない場合は、以下を確認してください:

- 構成したチャンネル名が正しい。
- チャンネルがプライベートの場合は、[SlackアプリのGitLabをチャンネルに追加](gitlab_slack_application.md#receive-notifications-to-a-private-channel)してください。

## App Homeが正しく表示されない {#app-home-does-not-display-properly}

[App Home](https://api.slack.com/start/overview#app_home)が正しく表示されない場合は、[アプリが最新の状態](gitlab_slack_application.md#reinstall-the-gitlab-for-slack-app)であることを確認してください。

## エラー: `This alias has already been taken` {#error-this-alias-has-already-been-taken}

新しいプロジェクトでセットアップしようとすると、エラー`422: The change you requested was rejected`が発生する可能性があります。返されるRailsエラーは次のとおりです:

```plaintext
"exception.message": "Validation failed: Alias This alias has already been taken"
```

この問題を解決するには、以下を実行します:

1. 同様の名前を持ち、SlackアプリのGitLabが有効になっているプロジェクトについて、ネームスペースを検索します。
1. これらのプロジェクトの中で、失敗したプロジェクトと同じエイリアス名を持つプロジェクトを確認します。
1. エイリアスを編集して別のものにし、失敗したプロジェクトのSlackアプリのGitLabの有効化を再試行します。
