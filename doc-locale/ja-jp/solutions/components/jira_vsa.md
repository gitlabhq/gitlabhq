---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: JiraからGitLab VSAへのバリューストリーム分析統合
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabの[バリューストリーム分析（VSA）](../../user/group/value_stream_analytics/_index.md)は、開発ワークフローに関する強力なインサイトを提供し、次のような主要なメトリクスを追跡します:

- **リードタイム**: イシューの作成から完了までの時間
- **作成されたイシュー**: 特定の期間に作成された新しいイシューの数
- **クローズされたイシュー**: 特定の期間に解決されたイシューの数

Jiraをイシュートラッキングに使用し、GitLabを開発に利用しているチームにとって、この統合により、JiraイシューをGitLabにリアルタイムで自動的にレプリケートすることができます。これにより、チームが既存のJiraワークフローを変更しなくても、正確なVSAメトリクスが保証されます。

この統合により、GitLabの**バリューストリームダッシュボード**も入力状態になり、主要なDevSecOpsメトリクスの概要が提供されます。これはGitLabプロジェクトまたはグループの**分析** > **分析ダッシュボード**にあります。

**注**: 同様の統合がインシデントレプリケーションにも存在し、特定のDORAメトリクス（変更失敗率とサービス復旧時間）を生成します。インシデントレプリケーションに関心がある場合は、[Jiraインシデントリプリケーター](jira_dora.md)を参照してください。

## アーキテクチャ {#architecture}

Jiraオートメーションを使用して2つの自動化ワークフローを作成します:

1. Jiraで作成されたときにGitLabイシューを作成する
1. Jiraで解決されたときにGitLabイシューをクローズする

### イシュー作成 {#issue-creation}

Jiraで新しいイシューが作成されると、自動化ワークフローはPOSTリクエストをGitLabイシューAPIに送信し、指定されたGitLabプロジェクトに対応するイシューを作成します。

### イシューの解決 {#issue-resolution}

Jiraイシューが解決済み状態（クローズ、完了、解決済み）に移行すると、自動化ワークフローはPUTリクエストを送信して、対応するGitLabイシューをクローズします。

## セットアップ {#setup}

### 前提条件 {#pre-requisites}

このチュートリアルでは、以下を前提としています:

- VSAアナリティクスを生成するGitLabプロジェクト
- イシューをレプリケートする元のJiraプロジェクト
- GitLab UltimateまたはPremiumライセンス（バリューストリーム分析機能の場合）

Jiraは、Jiraライセンスに応じて、自動化実行の頻度に[制限](https://www.atlassian.com/software/jira/pricing)を設けています:

| **プラン**   | **制限**                    |
|------------|------------------------------|
| Free       | 1か月あたり100回の実行           |
| スタンダード   | 1か月あたり1700回の実行          |
| Premium    | 1ユーザーあたり1か月あたり1000回の実行 |
| エンタープライズ | 無制限の実行               |

各イシューの作成は1回の実行としてカウントされ、各イシューの解決も1回の実行としてカウントされます。

### GitLabプロジェクトアクセストークン {#gitlab-project-access-token}

まず、API経由でイシューを作成および更新するために必要な権限を持つGitLabプロジェクトアクセストークンを作成する必要があります。

1. JiraイシューをレプリケートしたいGitLabプロジェクトに移動します。サイドバーから、**設定** > **アクセストークン**に移動します。
1. **新しいトークンを追加**をクリックします。
1. 次の設定を行います:
   - **トークン名**: `Jira VSA Integration`（または任意のわかりやすい名前）
   - **有効期限**: セキュリティポリシーに従って設定します
   - **ロール**: `Owner`（カスタムイシューIDを設定するために必要です）
   - **スコープ**: `api`（フルAPIアクセス）を確認してください

**重要**: 認可には、GitLabでイシューを作成する際に、カスタムイシューIDを強制的に設定する必要があるため、**オーナー**レベルのアクセストークンが必要です。これにより、Jiraイシューがクローズされると、オートメーションは同じIDマッピングを使用して、対応するGitLabイシューを識別してクローズできます。オーナーロールがない場合、GitLab APIはカスタムイシューIDの設定を許可せず、JiraイシューのクローズとGitLabイシューのクローズ間の同期が中断されます。

1. **Create project access token**（プロジェクトアクセストークンを作成）をクリックし、生成されたトークンを安全に保存します。これはJiraオートメーションの設定に必要になります。

### Jiraイシュー作成ワークフロー {#jira-issue-creation-workflow}

Jiraイシューが作成されたときにGitLabイシューを自動的に作成するには、[Jiraオートメーション](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)を使用します。

1. Jiraプロジェクトに移動します。サイドバーから、**Project settings**（プロジェクトの設定） > **Automation**（オートメーション）に移動します。
1. 右上にある**Create rule**（ルールを作成）をクリックします。
1. トリガーの場合は、**Issue created**（作成されたイシュー）を検索して選択します。**保存**をクリックします。
1. *任意*: どのイシューをレプリケートするかをフィルタリングする条件を追加します。たとえば、特定の種類のイシューまたは特定のラベルのイシューのみをレプリケートするために、**Issue fields condition**（イシューフィールド条件）を追加できます。
1. **THEN: Add an action**（THEN: アクションを追加）を選択します。**Send web request**（Webリクエストを送信）を検索して選択します。
1. Webリクエストを設定します:
   - **Web request URL**（WebリクエストURL）: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues`（セルフホストの場合は`gitlab.com`をGitLabインスタンスURLに置き換え、`<GITLAB_PROJECT_ID>`をGitLabプロジェクトの数値IDに置き換えます。例: `42718690`）
   - **HTTP method**（HTTPメソッド）: **POST**
   - **Web request body**（Webリクエストボディ）: **Custom data**（カスタムデータ）
1. 次のヘッダーを追加します:

    | 名前 | 値 |
    | ------ | ------ |
    | 認可 | Bearer `<YOUR_GITLAB_TOKEN>` |
    | Content-Type | `application/json` |

   セキュリティのために、AuthZヘッダーを「非表示」に設定します。

1. **Custom data**（カスタムデータ）フィールドに、次のように入力します:

   ```json
   {
     "title": "{{issue.summary}}",
     "iid": {{issue.key.replace("VSA-", "1000")}}
   }
   ```

   `"VSA-"`をJiraプロジェクトのプレフィックスに置き換えます（たとえば、Jiraイシューの番号が`PROJ-123`の場合は、`"PROJ-"`を使用します）。`1000`は、UIを介してGitLab自体の中で直接作成された可能性のあるイシューとの競合が発生しないようにするために追加されるベース番号です。必要に応じてこの値を調整できます。

1. **保存**をクリックし、オートメーションにわかりやすい名前（`Jira to GitLab Issue Creation`など）を付けて、**Turn it on**（オンにする）をクリックします。

### Jiraイシュー解決ワークフロー {#jira-issue-resolution-workflow}

2番目の自動化ワークフローを作成して、Jiraイシューが解決されたときにGitLabイシューをクローズします:

1. 作成ワークフローの手順1〜2に従って、新しいルールを開始します。
1. トリガーを**Issue transitioned**（イシューの移行）に設定します:
   - 「From status」（元のステータス）フィールドを空白のままにします
   - 「To status」（変更後のステータス）は、`Closed`、`Done`、`Resolved`など、解決済みであることを示すステータスに設定します（Jiraワークフローに基づいて調整します）
1. （必要に応じて、カスタム条件を追加するか、カスタム条件をスキップします）。
1. 次の**Send web request**（Webリクエストを送信）アクションを追加します:
   - **Web request URL**（WebリクエストURL）: `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{{issue.key.replace("<JIRA_PROJECT_PREFIX>-", "1000").urlEncode}}`（セルフホストの場合は`gitlab.com`をGitLabインスタンスURLに置き換え、`<GITLAB_PROJECT_ID>`をGitLabプロジェクトの数値IDに置き換え、`<JIRA_PROJECT_PREFIX>`を`VSA`や`PROJ`のようなJiraプロジェクトのプレフィックスに置き換えます）
   - **HTTP method**（HTTPメソッド）: **PUT**
   - **Web request body**（Webリクエストボディ）: **Custom data**（カスタムデータ）
1. 作成ワークフローと同じヘッダーを使用します。
1. **Custom data**（カスタムデータ）フィールドに、次のように入力します:

   ```json
   {
     "state_event": "close"
   }
   ```

1. わかりやすい名前（`Jira to GitLab Issue Closer`など）で自動化ルールを保存して有効にします。

## バリューストリーム分析設定 {#value-stream-analytics-configuration}

自動化ワークフローがアクティブになると、GitLabはイシューデータの受信を開始します。アナリティクスにアクセスする方法は次のとおりです:

### バリューストリームダッシュボード（自動 - Ultimateのみ） {#value-streams-dashboard-automatic---ultimate-only}

**バリューストリームダッシュボード**には、レプリケートされたイシューからのメトリクスが自動的に入力状態になり、GitLab Ultimateで利用できます:

1. GitLabプロジェクトまたはグループで、**分析** > **分析ダッシュボード**に移動します
1. **バリューストリームダッシュボード**をクリックします
1. 作成されたイシュー、クローズされたイシュー、リードタイム、サイクルタイムなどのメトリクスが表示されます。

### バリューストリーム分析（設定が必要 - PremiumおよびUltimate） {#value-stream-analytics-requires-setup---premium-and-ultimate}

より詳細なアナリティクスとカスタムバリューストリーム（GitLab PremiumおよびUltimateで利用可能）の場合:

1. GitLabプロジェクトまたはグループで、**分析** > **バリューストリーム分析**に移動します
1. **新しいバリューストリーム**をクリックして、カスタムバリューストリームを作成します
1. 開発プロセスに応じてステージングとワークフローを設定する
1. リードタイムや新しいイシュー数などのメトリクスが自動的に生成され、作成したステージングの横に表示されます
1. 詳細な設定手順については、[GitLabバリューストリーム分析ドキュメント](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)を参照してください

## 複数プロジェクトの考慮事項 {#multi-project-considerations}

単一のオートメーションルールセットを使用して複数のJiraプロジェクトからイシューをレプリケートする場合は、プロジェクトプレフィックスメソッドの代わりに、タイムスタンプベースのアプローチを使用して一意のイシューIDを生成することを検討してください:

カスタムデータの`iid`値を次のように置き換えます:

```json
"iid": {{issue.created.replace("-","").replace("T","").replace(":","").replace(".","").replace("+","")}}
```

これにより、作成タイムスタンプ（形式: `2025-02-15T09:45:32.7+0000`）が数値に変換されます。このアプローチでは、イシューIDが非常に長くなる可能性があり、2つのイシューがまったく同じ時間に作成された場合に競合のリスクがわずかに高くなる可能性があることに注意してください。

## リソース {#resources}

- [GitLabのバリューストリーム分析](../../user/group/value_stream_analytics/_index.md)
  - [バリューストリームを作成](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)
- [GitLabバリューストリームダッシュボード](../../user/analytics/value_streams_dashboard.md)
- [GitLabイシューAPI](../../api/issues.md)
  - [新しいイシューの作成](../../api/issues.md#new-issue)
  - [イシューを編集](../../api/issues.md#edit-an-issue)
- [GitLabプロジェクトアクセストークン](../../user/project/settings/project_access_tokens.md)
- [Webリクエストを使用したJiraオートメーション](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
