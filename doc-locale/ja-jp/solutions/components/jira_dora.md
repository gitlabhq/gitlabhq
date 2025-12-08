---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: JiraをGitLabと統合してリアルタイムインシデントレプリケーションを実現し、変更失敗率やサービス復旧時間などの正確なDORAメトリクスの追跡を可能にします。
title: JiraからGitLabへのDORAインテグレーション
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、DevOpsのパフォーマンスを測定するために役立つ[DORAメトリクス](../../user/analytics/dora_metrics.md)の表示レベルを得ることができます。4つのメトリクスは次のとおりです:

- **デプロイ頻度**: 本番環境への1日あたりの平均デプロイ回数
- **変更のリードタイム**: 本番環境へのコミットの正常な配信にかかる秒数（コードのコミットから、本番環境で正常に実行されているまで）
- **変更失敗率**: 特定の期間に本番環境でインシデントを引き起こすデプロイの割合
- **平均復旧時間**: 本番環境でインシデントがオープンになっていた時間の中央値

最初の2つのメトリクスはGitLab CI/CDとマージリクエストから生成されますが、後の2つは[GitLabインシデント](../../operations/incident_management/manage_incidents.md)の作成に依存します。

インシデントの追跡にJiraを使用しているチームの場合、これはインシデントをリアルタイムでJiraからGitLabにレプリケートする必要があることを意味します。このプロジェクトでは、そのレプリケーションの設定について説明します。

**注**: 同様のインテグレーションがイシューのレプリケーションにも存在し、バリューストリーム分析のメトリクス（リードタイム、イシューの作成、およびイシューのクローズ）を生成します。VSAメトリクスのイシューレプリケーションに関心がある場合は、[JiraからGitLabへのVSAインテグレーション](jira_vsa.md)を参照してください。

## アーキテクチャ {#architecture}

2つの自動化ワークフローを作成する必要があります:

1. Jiraで作成されたときにGitLabインシデントを作成します。
1. Jiraで解決されたときにGitLabインシデントを解決します。

### インシデントの作成 {#incident-creation}

![JiraインシデントがGitLabでアラートをトリガーする方法を示すワークフロー。](img/jira_dora_creation_flow_v18_1.png)

### インシデントの解決 {#incident-resolution}

![解決されたJiraインシデントがGitLabでインシデントの解決をトリガーする方法を示すワークフロー。](img/jira_dora_resolution_flow_v18_1.png)

## セットアップ {#setup}

### 前提条件 {#pre-requisites}

このチュートリアルでは、以下があると仮定します:

- GitLab Ultimateライセンス
- インシデントをクローンするJiraプロジェクト

Jiraは、Jiraライセンスに応じて、自動化実行の頻度に[制限](https://www.atlassian.com/software/jira/pricing)を設けています。今日現在、制限は次のとおりです:

| **プラン**   | **制限**                    |
|------------|------------------------------|
| Free       | 1か月あたり100回の実行           |
| スタンダード   | 1か月あたり1700回の実行          |
| Premium    | ユーザーあたり1か月あたり1000回の実行 |
| エンタープライズ | 無制限の実行               |

各インシデントの作成は1回の実行としてカウントされ、各インシデントの解決は1回の実行としてカウントされます。

### GitLabアラートエンドポイント {#gitlab-alert-endpoint}

最初に、GitLabでアラートの作成/ 解決をトリガーできるHTTPエンドポイントを作成する必要があります。これにより、インシデントが作成/ 解決されます。

1. イシューを作成するGitLabプロジェクトに移動します。サイドバーから、**設定** > **モニタリング**に移動します。**アラート**セクションを展開します。
1. **アラート**で、**アラート設定**タブに切り替えます。次のボックスをオンにし、**変更を保存**をクリックします:
   - _インシデントを作成します。トリガーされた各アラートに対してインシデントが作成されます。_
   - _リカバリーアラート通知がアラートを解決するときに、関連付けられたインシデントを自動的にクローズします_
1. **アラート**で、**現在のインテグレーション**タブに切り替えます。**新しいインテグレーションを追加**をクリックします。**Integration type**（インテグレーションタイプ）を`HTTP Endpoint`に設定し、名前（例: `Jira incident sync`）を付けて、**インテグレーションを有効にする**を**有効**に設定します。Jiraの自動化ワークフローを設定したら、アラートペイロードマッピングをカスタマイズするために戻ってきます。
1. **インテグレーションを保存**をクリックします。「インテグレーションが正常に保存されました」というメッセージが表示されます。**URLと認証キーを表示**をクリックします。
1. Jira自動化ワークフローとLambda関数を設定するときに、エンドポイントURLと認可キーが必要になるため、後で使用するために保存してください。

### Jiraインシデント作成ワークフロー {#jira-incident-creation-workflow}

Jiraインシデントの作成時にGitLabアラートエンドポイントを自動的にトリガーするには、[Jira自動化](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)を使用します。

1. インシデントが管理されているJiraプロジェクトに移動します。サイドバーから、**プロジェクトの設定** > **Automation**（自動化）に移動します（少しスクロールダウンして見つける必要がある場合があります）。
1. ここから、Jiraの自動化ワークフローを管理できます。右上にある**Create rule**（ルールを作成）をクリックします。
1. トリガーの場合は、**Issue created**（作成されたイシュー）を検索して選択します。**保存**をクリックします。
1. 次に、**IF: Add a condition**（IF: 条件を追加）を選択します。ここでは、作成されたイシューがインシデントに関連するかどうかを判断するために、チェックする条件を指定できます。このガイドでは、**Issue fields condition**（イシューフィールド条件）を選択します。**フィールド**で、**サマリー**を選択し、**Condition**（条件）を**contains**（含む）に設定し、値を`incident`に設定します。**保存**をクリックします。
1. トリガーと条件を設定したら、**THEN: Add an action**（THEN: アクションを追加）を選択します。**Send web request**（Webリクエストを送信）を検索して選択します。
1. **Web request URL**（WebリクエストURL）を前のセクションのGitLab **WebhookのURL**に設定します。
1. [エンドポイント認証オプション](../../operations/incident_management/integrations.md#authorization)については、GitLabドキュメントを確認してください。このガイドでは、[ベアラー認証ヘッダー](../../operations/incident_management/integrations.md#bearer-authorization-header)メソッドを使用します。Jira自動化設定で、次のヘッダーを追加します:

   | 名前 | 値 |
   | ------ | ------ |
   | 認可 | Bearerエンドポイント**auth key**（認証キー）> |
   | Content-Type | `application/json` |

   - `Authorization`ヘッダーを「非表示」に設定することもできます。
1. **HTTP method**（HTTPメソッド）が**POST**に設定されていることを確認し、**Web request body**（Webリクエストの本文）を**Issue data (Jira format)**（イシューデータ（Jira形式））に設定します。
1. 最後に、**Save**（保存）をクリックし、自動化に名前（例: `Jira incident creation`）を付けて、**Turn it on**（オンにする）をクリックします。右上にある**Return to list**（リストに戻る）をクリックします。
1. 最後に必要なのは、Jiraペイロードの値をGitLabアラートパラメータにマップすることです。**平均復旧時間**メトリクスのインシデント解決も設定する場合は、今のところこのステップをスキップしてください。それ以外の場合は、[Jiraペイロードの値をGitLabアラートパラメータにマップする](#map-jira-payload-values-to-gitlab-alert-parameters)にジャンプし、そこに記載されている手順に従ってください。

ペイロード値をマップしたら、Jiraで作成したインシデントもGitLabで作成されます。これにより、**変更失敗率** DORAメトリクスが表示されます。

### Jiraインシデント解決ワークフロー {#jira-incident-resolution-workflow}

上記のように別のJira自動化ワークフローを作成し、次の変更を加えます:

1. トリガーを**Issue transitioned**（イシューの移行）に設定します。「From status」フィールドは空白のままにすることができます。「To status」（変更後のステータス）フィールドは、ワークフローに従って、インシデントが解決済みであることを示すステータスに設定します（例: `Closed`、`Done`、`Resolved`、`Completed`）。
1. 自動化に適切な名前（例: `Jira incident close`）を付けます。

### Jiraペイロード値をGitLabアラートパラメータにマップする {#map-jira-payload-values-to-gitlab-alert-parameters}

1. Jira自動化ワークフローを作成したら、作成したワークフローをクリックして、**Then: Send web request**（THEN: Webリクエストを送信）を選択します。
1. **Validate your web request configuration**（Webリクエスト設定を検証する）セクションを展開し、テストする*解決済み*イシューキーを入力します（使用できる既存のイシューキーが必要です）。**検証**をクリックします。
1. **Request POST**（リクエストPOST）セクションを展開し、**Payload**（ペイロード）セクションを展開します。ペイロード全体をコピーします。
1. GitLabプロジェクトに戻り、**設定** > **モニタリング** > **アラート** > **現在のインテグレーション**に移動します。以前に作成したインテグレーションの横にある「設定」アイコンをクリックし、**詳細を設定**タブに切り替えます。
1. **Customize alert payload mapping**（アラートペイロードマッピングをカスタマイズする）で、ステップ3でJiraからコピーしたペイロードを貼り付けます。次に、**ペイロードフィールドの解析**をクリックします。
1. 以下に示すようにフィールドをマップします:

    | GitLabアラートキー | ペイロードアラートキー |
    | ------ | ------ |
    | タイトル | issue.fields.summary |
    | 説明 | issue.fields.status.description |
    | 終了時間 | issue.fields.resolutiondate<sup>1</sup> |
    | モニタリングツール | issue.fields.reporter.accountType |
    | 重大度 | issue.fields.priority.name |
    | フィンガープリント | issue.key |
    | 環境 | issue.fields.project.name |

<sup>1</sup>これは、インシデント解決自動化をセットアップした場合にのみ必要です。このフィールドがオプションとして表示されない場合は、上記の手順2でテストするために*解決済み*のイシューキーを入力したことを確認してください。

1. 最後に、**インテグレーションを保存**をクリックします。

この時点で、Jiraで解決したインシデントもGitLabで解決されます。これにより、**平均復旧時間** DORAメトリクスが表示されます。

## リソース {#resources}

- [DORAメトリクス](../../user/analytics/dora_metrics.md)
  - [JiraでDORAメトリクスを測定する](../../user/analytics/dora_metrics.md#with-jira)
- [GitLabインシデント管理](../../operations/incident_management/manage_incidents.md)
- [GitLab HTTPエンドポイント](../../operations/incident_management/integrations.md#alerting-endpoints)
  - [GitLab HTTPエンドポイント認可](../../operations/incident_management/integrations.md#authorization)
  - [GitLabアラートパラメータ](../../operations/incident_management/integrations.md#customize-the-alert-payload-outside-of-gitlab)
  - [GitLabリカバリーアラート](../../operations/incident_management/integrations.md#recovery-alerts)
- [Webリクエストを使用したJira自動化](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
