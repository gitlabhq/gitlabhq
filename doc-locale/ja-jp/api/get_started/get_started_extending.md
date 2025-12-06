---
stage: none
group: none
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabとプログラムでやり取りします。
title: GitLabの拡張を始めましょう
---

GitLabとプログラムでやり取りします。タスクの自動化、他のツールとのインテグレーション、カスタムワークフローの作成を行います。GitLabはプラグインとカスタムフックもサポートしています。

GitLabの拡張について詳しく知るには、以下の手順に従ってください。

## ステップ1: インテグレーションのセットアップ {#step-1-set-up-integrations}

GitLabには、開発ワークフローを効率化できる主要なインテグレーションがいくつかあります。

これらのインテグレーションは、次のようなさまざまな分野を網羅しています:

- **認証**: OAuth、SAML、LDAP
- **Planning**（プランニング）: Jira、Bugzilla、Redmine、Pivotal Tracker
- **Communication**（コミュニケーション）: Slack、Microsoft Teams、Mattermost
- **セキュリティ**: Checkmarx、Veracode、Fortify

詳細については、以下を参照してください:

- [インテグレーションの一覧](../../integration/_index.md)

## ステップ2: Webhookのセットアップ {#step-2-set-up-webhooks}

Webhookを使用して、GitLabイベントに関する外部サービスに通知します。

Webhookは、プッシュ、マージ、コミットなどの特定のイベントをリッスンします。これらのイベントのいずれかが発生すると、GitLabは設定されたWebhookのURLにHTTP POSTペイロードを送信します。Webhookによって送信されるペイロードは、イベント名、プロジェクトID、ユーザーとコミットの詳細など、イベントに関する詳細を提供します。次に、外部システムがイベントを識別して処理します。

たとえば、コードがGitLabにプッシュされるたびに、新しいJenkinsビルドをトリガーするWebhookを設定できます。

Webhookは、プロジェクトごと、またはGitLabインスタンス全体に対して構成できます。プロジェクトごとのWebhookは、特定のプロジェクトのイベントをリッスンします。

Webhookを使用すると、CI/CDシステム、チャットおよびメッセージングプラットフォーム、モニタリングおよびログ記録ツールなど、さまざまな外部ツールとGitLabをインテグレーションできます。

詳細については、以下を参照してください:

- [Webhook](../../user/project/integrations/webhooks.md)

## ステップ3: APIを使用する {#step-3-use-the-apis}

REST APIまたはGraphQL APIを使用して、GitLabとプログラムでやり取りし、カスタムインテグレーションを構築したり、データを取得したり、プロセスを自動化したりできます。これらのAPIは、プロジェクト、イシュー、マージリクエスト、リポジトリなど、GitLabのさまざまな側面を網羅しています。

GitLab REST APIは、RESTfulの原則に従い、リクエストとレスポンスのデータ形式としてJSONを使用します。これらのリクエストとレスポンスは、パーソナルアクセストークンまたはOAuth 2.0トークンを使用して認証できます。

GitLabは、データのクエリ時に、より柔軟で効率的なGraphQL APIも提供します。

cURLまたはRESTクライアントでAPIを調査して、リクエストとレスポンスを理解することから始めます。次に、APIを使用して、プロジェクトの作成やグループへのメンバーの追加などのタスクを自動化します。

詳細については、以下を参照してください:

- [REST API](../api_resources.md)
- [GraphQL API](../graphql/reference/_index.md)

## ステップ4: GitLab CLIを使用する {#step-4-use-the-gitlab-cli}

GitLab CLIは、さまざまなGitLab操作を完了し、GitLabインスタンスを管理するのに役立ちます。

GitLab CLIを使用すると、次のようなあらゆる種類のバルクタスクをより迅速に実行できます:

- 新しいプロジェクト、グループ、その他のGitLabリソースの作成
- ユーザーと権限の管理
- GitLabインスタンス間でのプロジェクトのインポートとエクスポート
- CI/CDパイプラインのトリガー

詳細については、以下を参照してください:

- [GitLab CLIをインストールする](https://gitlab.com/gitlab-org/cli/#installation)
