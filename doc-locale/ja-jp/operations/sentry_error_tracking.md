---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プロジェクトでエラートラッキングを行うために、SentryをGitLabに接続します。
title: Sentryエラートラッキング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Sentry](https://sentry.io/)は、オープンソースのエラートラッキングシステムです。GitLabでは、管理者がSentryをGitLabに接続することで、ユーザーがGitLabでSentryエラーの一覧を表示できるようになります。

GitLabは、クラウドでホストされている[Sentry](https://sentry.io)と、[オンプレミスインスタンス](https://github.com/getsentry/self-hosted)にデプロイされたSentryの両方とインテグレーションできます。

## プロジェクトのSentryインテグレーションを有効にする {#enable-sentry-integration-for-a-project}

GitLabには、Sentryをプロジェクトに接続する方法が用意されています。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

Sentryインテグレーションを有効にするには、次の手順に従います:

1. Sentry.ioにサインアップするか、独自の[オンプレミスSentryインスタンス](https://github.com/getsentry/self-hosted)をデプロイします。
1. [新しいSentryプロジェクトを作成](https://docs.sentry.io/product/sentry-basics/integrate-frontend/create-new-project/)します。インテグレーションするGitLabプロジェクトごとに、新しいSentryプロジェクトを作成します。
1. [Sentryの認証トークン](https://docs.sentry.io/api/auth/#auth-tokens)を検索または生成します。SaaSバージョンのSentryの場合は、[https://sentry.io/api/](https://sentry.io/api/)で認証トークンを検索または生成できます。少なくとも次のスコープをトークンに付与します。`project:read`、`event:read`、および`event:write` (解決イベント用)。
1. GitLabで、エラートラッキングを有効にして設定します:
   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
   1. 左側のサイドバーで、**設定**を選択して、プロジェクトを見つけます。**モニタリング** > **エラートラッキング**を選択し、[エラートラッキング]を展開します。
   1. **エラートラッキングを有効にする**で、**有効**を選択します。
   1. **バックエンドのトラッキングエラー**で**Sentry**を選択します。
   1. **Sentry API URL**に、Sentryのホスト名を入力します。たとえば、`https://sentry.example.com`と入力します。SaaSバージョンのSentryの場合、ホスト名は`https://sentry.io`です。EUでホストされているSaaSバージョンのSentryの場合、ホスト名は`https://de.sentry.io`です。
   1. **認証トークン**に、以前に生成したトークンを入力します。
   1. Sentryへの接続をテストし、**プロジェクト**ドロップダウンリストに入力された状態で表示するには、**接続**を選択します。
   1. **プロジェクト**リストから、GitLabプロジェクトにリンクするSentryプロジェクトを選択します。
   1. **変更を保存**を選択します。

Sentryエラーのリストを表示するには、プロジェクトのサイドバーで、**モニタリング** > **エラートラッキング**に移動します。

## GitLabとのSentryのインテグレーションを有効にする {#enable-sentrys-integration-with-gitlab}

[Sentryドキュメント](https://docs.sentry.io/organization/integrations/source-code-mgmt/gitlab/)の手順に従って、SentryのGitLabインテグレーションを有効にすることもできます。

## トラブルシューティング {#troubleshooting}

エラートラッキングを使用していると、次の問題が発生する可能性があります。

### エラー`Connection failed. Check auth token and try again` {#error-connection-failed-check-auth-token-and-try-again}

[プロジェクト設定](../user/project/settings/_index.md#configure-project-features-and-permissions)で**モニタリング**機能が無効になっている場合、[プロジェクトのSentryインテグレーションを有効にする](#enable-sentry-integration-for-a-project)ときにエラーが表示されることがあります。`/project/path/-/error_tracking/projects.json?api_host=https:%2F%2Fsentry.example.com%2F&token=<token>`へのリクエストの結果、404エラーが返されます。

この問題を修正するには、プロジェクトの**モニタリング**機能を有効にします。

### エラー`Connection has failed. Re-check Auth Token and try again` {#error-connection-has-failed-re-check-auth-token-and-try-again}

接続を試みると、オンプレミスのSentryインテグレーションでこの問題が発生する可能性があります。

このイシューを解決するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **アウトバウンドリクエスト**を展開します。
1. **ウェブフックとインテグレーションからローカルネットワークへの要求を許可する**チェックボックスと**システムフックからのローカルネットワークへのリクエストを許可する**チェックボックスを選択します。
1. **変更を保存**を選択します。
