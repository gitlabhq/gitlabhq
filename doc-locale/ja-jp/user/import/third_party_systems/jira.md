---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: Jiraから移行
description: Jiraから移行するためのオプション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Jiraを使用している場合は、次のいずれかを実行できます:

- Jiraから移行せずにGitLabで新しく開始します。そうすれば、GitLabを使用するメリットを最大化するために、プロセスとワークフローを設定することに集中できます。
- いくつかのオプションのいずれかを使用して、JiraからGitLabへ移行します。

| 移行オプション             | 説明 |
|:-----------------------------|:------------|
| GitLabプロフェッショナルサービス | [GitLabプロフェッショナルサービス](https://about.gitlab.com/services/)に移行を実行してもらいます。 |
| `Jira2Lab`                   | `jira2gitlab`のGitLabプロフェッショナルサービスによるフォークである[`Jira2Lab`](https://about.gitlab.com/blog/seamlessly-migrate-from-jira-to-gitlab-with-jira2lab-at-scale/)を使用します。 |
| サードパーティスクリプト           | 例えば、移行には[`jira2gitlab`](https://github.com/swingbit/jira2gitlab)を使用します。 |
| Jiraインポーター                | GitLabに組み込まれている[Jiraインポーターを使用](#use-the-jira-importer)します。 |
| CSVファイルインポート              | [CSVファイルを使用](#use-a-csv-file)して、JiraからGitLabへデータを移動します。 |
| 独自のスクリプト              | GitLab RESTまたはGraphQL APIを使用する[独自のスクリプトを作成](#write-your-own-script)します。 |
| サードパーティサービス          | GitLabとJiraを同期させるサードパーティサービス（[Unito](https://marketplace.atlassian.com/apps/1218054/gitlab-2-way-integration-for-jira)や[Getint](https://marketplace.atlassian.com/apps/1223999/gitlab-integration-for-jira-two-way-sync-forge)など）を使用します。 |

## Jiraインポーターを使用 {#use-the-jira-importer}

Jiraインポーターを使用して、JiraイシューをGitLabにインポートできます。複数のJiraプロジェクトからのイシューをGitLabプロジェクトにインポートできます。GitLabは、イシューのタイトル、説明、およびラベルを直接インポートします。インポートの準備中に、JiraユーザーをGitLabプロジェクトのメンバーにマッピングすることもできます。

GitLabイシューフィールドに正式にマッピングされていないその他のJiraイシューメタデータは、GitLabイシューの説明にプレーンテキストとしてインポートされます。

Jiraイシュー内のテキストはGitLab Flavored Markdownに解析されないため、テキストの書式設定が破損する可能性があります。詳細については、[イシュー379104](https://gitlab.com/gitlab-org/gitlab/-/issues/379104)を参照してください。

[Epic 2738](https://gitlab.com/groups/gitlab-org/-/epics/2738)では、イシューの割り当て者、コメント、およびその他の改善をGitLab Jiraインポーターに追加することが提案されています。

### 前提条件 {#prerequisites}

- Jiraイシューへの読み取りアクセスと、インポート先のGitLabプロジェクトのMaintainerまたはOwnerロール。
- GitLab [Jiraイシューインテグレーション](../../../integration/jira/_index.md)を設定します。

### Jiraイシューのインポート {#import-jira-issues}

Jiraイシューのインポートは非同期のバックグラウンドジョブとして実行されるため、次の要因に基づいて遅延が発生する可能性があります:

- インポートキューのロード。
- システムロード。
- その他の要因。

大規模なプロジェクトのインポートには、インポートのサイズによっては数分かかることがあります。

JiraイシューをGitLabプロジェクトにインポートするには:

1. {{< icon name="work-items" >}} **作業アイテム**ページで、**アクション** ({{< icon name="ellipsis_v" >}}) > **Jiraからのインポート**を選択します。

1. **インポート元**ドロップダウンリストを選択し、イシューをインポートしたいJiraプロジェクトを選択します。

   **Jira-GitLabユーザーマッピングテンプレート**セクションでは、テーブルにJiraユーザーがどのGitLabユーザーにマッピングされているかを示します。フォームが表示されると、ドロップダウンリストはインポートを実行するユーザーにデフォルトで設定されます。

1. マッピングを変更するには、**GitLabのユーザー名**列のドロップダウンリストを選択し、各Jiraユーザーにマッピングしたいユーザーを選択します。

   ドロップダウンリストにはすべてのユーザーが表示されない場合があるため、検索バーを使用してこのGitLabプロジェクトの特定のユーザーを見つけてください。

1. **続行する**を選択します。インポートが開始されたことを確認するメッセージが表示されます。

   インポートがバックグラウンドで実行されている間、**作業アイテム**ページに移動して、リストに新しいイシュー (Issueタイプの作業アイテム) が表示されていることを確認できます。

1. インポートのステータスを確認するには、もう一度Jiraインポートページにアクセスしてください。

## CSVファイルを使用 {#use-a-csv-file}

JiraイシューデータをCSVファイルからGitLabプロジェクトにインポートするには:

1. Jiraデータをエクスポート:
   1. Jiraインスタンスにログインし、移行したいプロジェクトに移動します。
   1. プロジェクトデータをCSVファイルとしてエクスポートします。
   1. CSVファイルを編集して、[GitLab CSVインポーターに必要な列名](../../project/issues/csv_import.md)に合わせます。
      - `title`、`description`、`due_date`、`milestone`のみがインポートされます。
      - インポートプロセス中に他のイシューメタデータを自動的に設定するために、説明テンプレートフィールドに[クイックアクション](../../project/quick_actions.md)を追加できます。
1. 新しいGitLabグループとプロジェクトを作成します:
   1. GitLabアカウントにサインインし、移行されたプロジェクトをホストする[グループを作成](../../group/_index.md#create-a-group)します。
   1. 新しいグループで、移行されたJiraイシューを保持する[新しいプロジェクトを作成](../../project/_index.md#create-a-blank-project)します。
1. JiraデータをGitLabにインポートします:
   1. 新しいGitLabプロジェクトで、左サイドバーの**Plan** > **作業アイテム**を選択します。
   1. **アクション** ({{< icon name="ellipsis_v" >}}) > **Jiraからのインポート**を選択します。
   1. 画面の指示に従ってインポートプロセスを完了します。
1. 移行を確認します:
   1. インポートされたイシューをレビューして、プロジェクトがGitLabに正常に移行されたことを確認します。
   1. 移行されたJiraプロジェクトの機能をGitLabでテストします。
1. ワークフローと設定を調整します:
   1. GitLabの[プロジェクト設定](../../project/settings/_index.md)を次のようにカスタマイズします:
      - [説明テンプレート](../../project/description_templates.md)。
      - [ラベル](../../project/labels.md)。
      - [マイルストーン](../../project/milestones/_index.md)。
   1. チームにGitLabインターフェースと、移行によって導入された新しいワークフローやプロセスを熟知させます。
1. 移行に満足したら、Jiraインスタンスの廃止とGitLabへの完全な移行を行うことができます。

## 独自のスクリプトを作成 {#write-your-own-script}

移行プロセスを完全に制御するために、ニーズに正確に適合する方法でJiraイシューをGitLabに移行する独自のカスタムスクリプトを作成できます。GitLabは、移行の自動化を支援するAPIを提供しています:

- [REST API](../../../api/rest/_index.md)
- [GraphQL API](../../../api/graphql/_index.md)

まず、以下のGitLab APIエンドポイントについて理解を深めてください:

- [イシュー](../../../api/issues.md)
- [プロジェクト](../../../api/projects.md)
- [ラベル](../../../api/labels.md)
- [マイルストーン](../../../api/milestones.md)

スクリプトを作成する際は、Jiraイシューフィールドを対応するGitLabの同等フィールドにマッピングする必要があります。

| Jiraイシューフィールド | 考えられるGitLabの同等物 |
|:----|:-------|
| オプションの数が固定されているカスタムフィールド | フィールド名をスコープ付きラベルキーとして、フィールド値をスコープ付きラベルセットの値として設定した[スコープ付きラベル](../../project/labels.md#scoped-labels)セットを作成します。例: `input name::value1`、`input name::value2`。 |
| テキスト文字列または整数値を持つカスタムフィールド | カスタムフィールド名と値をイシューの説明内のセクションに挿入します。 |
| ステータス | [ステータス](../../work_items/status.md)を使用します。 |
| 優先度 | 優先度をスコープ付きラベルキーとして、優先度値をスコープ付きラベルセットの値として設定した[スコープ付きラベル](../../project/labels.md#scoped-labels)を作成します。例: `priority::1`。 |
| ストーリーポイント | この値をGitLabイシューの**weight**値にマッピングします。 |
| スプリント | この値をGitLabイシューの**イテレーション**値にマッピングします。この値は、未完了のイシューまたは将来のスプリントにスケジュールされているイシューの場合にのみ意味があります。データをインポートする前に、プロジェクトの親グループに必要な[イテレーション](../../group/iterations/_index.md#iteration-cadences)を作成します。 |

Atlassian Document Formatを解析し、それをGitLab Flavored Markdownにマッピングする必要もあります。これにはさまざまなアプローチがあります。参考として、[コミットの例をご覧ください](https://gitlab.com/gitlab-org/gitlab/-/commit/4292a286d3f4ab26466f8e89125a4dbd194a9f3e)。このコミットは、Atlassian Document FormatをGitLab Flavored Markdownに解析し、Jiraインポーター用にマッピングするメソッドを追加しました。

ローカルでGitLabを実行している場合、Atlassian Document FormatをGitLab Flavored MarkdownにRailsコンソールで手動で変換することもできます。これを行うには、以下を実行します:

```ruby
text = <document in Atlassian Document Format>
project = <project that wiki is in> or nil
Banzai.render(text, pipeline: :adf_commonmark, project: project)
```

## 関連トピック {#related-topics}

- [インポートとエクスポートの設定](../../../administration/settings/import_and_export_settings.md)。
- [インポートに関するSidekiqの設定](../../../administration/sidekiq/configuration_for_imports.md)。
- [複数のSidekiqプロセスの実行](../../../administration/sidekiq/extra_sidekiq_processes.md)。
- [特定のジョブクラスの処理](../../../administration/sidekiq/processing_specific_job_classes.md)。
