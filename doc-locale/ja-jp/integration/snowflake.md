---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Snowflake
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1で監査イベント向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451328)されました。

{{< /history >}}

Snowflake [GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)は、データを[Snowflake](https://www.snowflake.com/en/)にプルします。

Snowflakeでは、すべてのデータを表示、結合、操作、およびレポートできます。GitLab Data Connectorは[GitLab REST API](../api/rest/_index.md)に基づいており、SnowflakeとGitLabの設定が必要です。

## 前提要件 {#prerequisites}

1. GitLabパーソナルアクセストークンをお持ちでない場合:
   1. GitLabにサインインします。
   1. [パーソナルアクセストークンを作成](../user/profile/personal_access_tokens.md#create-a-personal-access-token)するための手順に従います。
1. Snowflakeで[外部アクセスインテグレーション](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access)を作成します。詳細については、`snowflake-connector`プロジェクトの[セットアップに関するドキュメント](https://gitlab.com/gitlab-org/software-supply-chain-security/compliance/engineering/snowflake-connector#setup)を参照してください。
1. Snowflakeで[ウェアハウス](https://docs.snowflake.com/en/user-guide/warehouses-tasks#creating-a-warehouse)を作成します。

## GitLab Data Connectorを設定する {#configure-the-gitlab-data-connector}

1. Snowflakeにサインインします。
1. **Data Products**（データプロダクト） > **Marketplace**を選択します。
1. **GitLab Data Connector**を検索します。
1. **Data Products**（データプロダクト） > **Apps**（アプリ）を選択します。
1. **GitLab Data Connector**を選択します。
1. GitLab Data Connectorが実行される[ウェアハウス](https://docs.snowflake.com/en/user-guide/warehouses)を選択します。
1. **Start Configuration**（構成を開始）を選択します。
1. **Grant privileges**（権限を付与）を選択します。
1. 宛先ウェアハウスとスキーマを入力します。これらは、任意のウェアハウスと必要なスキーマにすることができます。
1. **設定する**を選択します。
1. 外部アクセスインテグレーションを入力します。
1. GitLabパーソナルアクセストークンのシークレットが格納されているパスを入力します。
1. GitLabインスタンスのドメインを入力します。たとえば`gitlab.com`などです。
1. **接続**を選択します。
1. グループ名を入力します。たとえば`my-group`などです。
1. **Finalize configurator**（コンフィギュレーターを確定）を選択します。
1. **設定する**を選択します。

## Snowflakeでデータを表示 {#view-data-in-snowflake}

1. Snowflakeにサインインします。
1. **Data**（データ） > **Databases**（データベース）を選択します。
1. 以前に設定したウェアハウスを選択します。
