---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira DVCSコネクタ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

Jira Cloud用Jira DVCSコネクターは、GitLab 15.1で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/362168)となり、16.0で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126)。代わりに[GitLab for Jira Cloud app](../connect-app.md)を使用してください。Jira DVCSコネクターも、Jira 8.13以前のバージョンでは非推奨となり、削除されました。Jira DVCSコネクタは、Jira 8.14以降のJira Data CenterまたはJira Serverでのみ使用できます。JiraインスタンスをJira 8.14以降にアップグレードして、GitLabインスタンスでJiraイシューのインテグレーションを再構成してください。

{{< /alert >}}

JiraインスタンスをJira Data CenterまたはJira Serverでセルフホストし、[Jira開発パネル](../development_panel.md)を使用する場合は、Jira DVCS（分散型バージョン管理システム）コネクターを使用します。Jira DVCSコネクターは、Atlassianによって開発およびメンテナンスされています。

Jira DVCSコネクターを構成するには、[DVCSを使用した開発ツールとの統合](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html)を参照してください。JiraはGitLabプロジェクトにWebhookを作成して、リアルタイムの更新を提供します。このWebhookを構成するには、プロジェクトのメンテナーロール以上が必要です。詳細については、[webhookのセキュリティの構成](https://confluence.atlassian.com/adminjiraserver/configuring-webhook-security-1299913153.html)を参照してください。

Jira Cloudをご利用の場合は、GitLab for Jira Cloudアプリに移行してください。詳細については、[GitLab for Jira Cloudアプリをインストールする](../connect-app.md#install-the-gitlab-for-jira-cloud-app)を参照してください。

## Jiraにインポートされたデータを更新する {#refresh-data-imported-to-jira}

デフォルトでは、JiraはGitLabプロジェクトのコミットとブランチを60分ごとにインポートします。Jiraでデータを手動で更新するには、次の手順に従います:

1. インテグレーションを構成したユーザーとして、Jiraインスタンスにサインインします。
1. 上部のバーの右上隅で、**Administration**（管理）（{{< icon name="settings" >}}）> **Applications**（アプリケーション）を選択します。
1. 左側のサイドバーで、**DVCS accounts**（DVCSアカウント）を選択します。
1. DVCSアカウントで1つ以上のリポジトリを更新するには、次の手順に従います:
   - **For all repositories**（すべてのリポジトリの場合）、アカウントの横にある省略記号（{{< icon name="ellipsis_h" >}}）> **Refresh repositories**（更新リポジトリ）を選択します。
   - **For a single repository**（単一のリポジトリの場合）:
     1. アカウントを選択します。
     1. 更新するリポジトリにカーソルを合わせ、**最後のアクティビティー**列で、**Click to sync repository**（リポジトリを同期するにはクリック）（{{< icon name="retry" >}}）を選択します。
