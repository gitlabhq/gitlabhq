---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: Jira移行のオプション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数のオプションを使用して、JiraプロジェクトをGitLabに移行できます。移行戦略を決定する前に、JiraイシューをGitLabに移行する必要があるかどうかを決定してください。多くの場合、Jiraイシューデータは関連性がなく、実用的でもありません。GitLabで新たに開始することで、プロセスとワークフローのセットアップに集中し、GitLabを使用するメリットを最大限に高めることができます。

Jiraイシューを移行することを選択した場合、いくつかの移行オプションから選択できます:

- GitLab Jiraインポーターを使用します。
- CSVファイルをインポートします。
- GitLabプロフェッショナルサービスに移行を依頼します。
- サードパーティサービスを使用して、一方向または双方向のデータ同期プロセスをビルドします。
- サードパーティスクリプトを使用します。
- 独自のスクリプトを作成します。

## GitLab Jiraインポーター {#use-gitlab-jira-importer}

GitLabには、Jiraイシューデータをインポートするためのビルドインツールがあります。GitLab Jiraインポーターを使用するには、次の手順に従います:

1. [ターゲットプロジェクトでGitLab Jiraイシューインテグレーションを設定する](../../../integration/jira/configure.md#configure-the-integration)
1. [JiraプロジェクトイシューをGitLabにインポートします](jira.md)

または、プロセスの完全なデモを視聴できます: <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [JiraプロジェクトイシューをGitLabにインポートします](https://www.youtube.com/watch?v=OTJdJWmODFA)
<!-- Video published on 2023-07-27 -->

## CSVファイルをインポートする {#import-a-csv-file}

JiraイシューデータをCSVファイルからGitLabプロジェクトにインポートするには、次の手順に従います:

1. Jiraデータをエクスポートします:
   1. Jiraインスタンスにログインして、移行するプロジェクトに移動します。
   1. プロジェクトデータをCSVファイルとしてエクスポートします。
   1. [GitLab CSVインポーターに必要なカラム名](../issues/csv_import.md)と一致するようにCSVファイルを編集します。
      - `title`、`description`、`due_date`、`milestone`のみがインポートされます。
      - インポートプロセス中に他のイシューメタデータを自動的に設定するには、[説明フィールドにクイックアクションを追加](../quick_actions.md)できます。
1. 新しいGitLabグループとプロジェクトを作成します:
   1. GitLabアカウントにサインインし、[移行されたプロジェクトをホストするためのグループを作成](../../group/_index.md#create-a-group)します。
   1. 新しいグループで、[移行されたJiraイシューを保持するための新しいプロジェクトを作成](../_index.md#create-a-blank-project)します。
1. JiraデータをGitLabにインポートします:
   1. 新しいGitLabプロジェクトの左側のサイドバーで、**Plan** > **イシュー**を選択します。
   1. **アクション** ({{< icon name="ellipsis_v" >}}) > **Jiraからのインポート**を選択します。
   1. 画面の指示に従って、インポートプロセスを完了します。
1. 移行を確認します:
   1. インポートされたイシューをレビューして、プロジェクトがGitLabに正常に移行されたことを確認します。
   1. GitLabで移行されたJiraプロジェクトの機能をテストします。
1. ワークフローと設定を調整します:
   1. チームのニーズに合わせて、GitLabの[プロジェクト設定](../settings/_index.md) （[説明テンプレート](../description_templates.md) 、[ラベル](../labels.md) 、[マイルストーン](../milestones/_index.md)など）をカスタマイズします。
   1. チームにGitLabインターフェースと、移行によって導入された新しいワークフローまたはプロセスを理解してもらいます。
1. Jiraインスタンスを停止します:
   1. 移行に満足したら、Jiraインスタンスを停止し、GitLabに完全に移行できます。

## GitLabプロフェッショナルサービスに移行を依頼します {#let-gitlab-professional-services-handle-the-migration-for-you}

Jira移行サービスの概要については、[Jira移行サービス](https://drive.google.com/file/d/1p0rv02OnjfSiNoeDT2u4MhviozS--Yan/view)データシートを参照してください。

パーソナライズされた見積もりを取得するには、[GitLabプロフェッショナルサービス](https://about.gitlab.com/services/)ページにアクセスし、**Request Service**（サービスをリクエスト）を選択してください。

## サードパーティサービスを使用した一方向または双方向のデータ同期を確立します {#establish-a-one-way-or-two-way-data-synchronization-using-a-third-party-service}

JiraとGitLabの間で一方向または双方向のデータ同期を確立するには、次のサードパーティサービスを使用できます:

- **Unito.io**: [GitLab + Jiraインテグレーションドキュメント](https://guide.unito.io/gitlab-jira-integration) 、[GitLab + Jira双方向同期Marketplaceアドオン](https://marketplace.atlassian.com/apps/1218054/gitlab-jira-two-way-sync?tab=overview&hosting=cloud)
- **Getint**: [GitLab Jira同期Marketplaceアドオン](https://marketplace.atlassian.com/apps/1223999/gitlab-jira-sync-integration-by-getint?tab=overview&hosting=cloud)

## サードパーティスクリプトを使用します {#use-a-third-party-script}

利用可能なオープンソースの移行スクリプトのいずれかを使用して、JiraイシューをGitLabに移行できます。

多くのお客様が[`jira2gitlab`](https://github.com/swingbit/jira2gitlab)を使用して成功を収めています。

プロセスの完全なデモをご覧ください: <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [JiraからJira2GitLabを使用してGitLabへの移行](https://www.youtube.com/watch?v=aJfnTZrS4t4)
<!-- Video published on 2024-01-09 -->

## ファーストパーティースクリプトを使用する {#use-a-first-party-script}

[GitLabプロフェッショナルサービス](https://about.gitlab.com/services/)は、以前に言及した`jira2gitlab`スクリプトのフォークである`Jira2Lab`をビルドしました:

- ブログ投稿: [Jira2Labを使用して、JiraからGitLabにシームレスに移行](https://about.gitlab.com/blog/2024/10/10/seamlessly-migrate-from-jira-to-gitlab-with-jira2lab-at-scale/)
- [リポジトリ](https://gitlab.com/gitlab-org/professional-services-automation/tools/migration/jira2lab)

`Jira2Lab` Readmeに記載されているように:

> ユーザーが両方のツールを比較して、移行のニーズに最適に対応することをお勧めします。

## 独自のスクリプトを作成します {#write-your-own-script}

移行プロセスを完全に制御するために、ニーズに正確に合う方法でJiraイシューをGitLabに移行する独自のカスタムスクリプトを作成できます。GitLabは、移行を自動化するために役立つAPIを提供します:

- [REST API](../../../api/rest/_index.md)
- [GraphQL API](../../../api/graphql/_index.md)

開始するには、次のGitLab APIエンドポイントについて理解してください:

- [イシュー](../../../api/issues.md)
- [プロジェクト](../../../api/projects.md)
- [ラベル](../../../api/labels.md)
- [マイルストーン](../../../api/milestones.md)

スクリプトを作成するときは、Jiraイシューフィールドを、対応するGitLabの同等物にマップする必要があります。ヒントをいくつか紹介します:

- **Custom fields with a fixed number of options**（オプションの数が固定されているカスタムフィールド）: フィールド名をスコープ付きラベルキーとして、フィールド値をスコープ付きラベルセット値として持つ[スコープ付きラベル](../labels.md#scoped-labels)セットを作成します（例: `input name::value1`、`input name::value2`）。
- **Custom fields with text strings or integer values**（テキスト文字列または整数値を持つカスタムフィールド）: カスタムフィールド名と値をイシューの説明のセクションに挿入します。
- **ステータス**: ステータスをスコープ付きラベルキーとして、ステータス値をスコープ付きラベルセット値として持つ[スコープ付きラベル](../labels.md#scoped-labels)を作成します（例: `status::in progress`）。
- **優先順位**: 優先順位をスコープ付きラベルキーとして、優先順位値をスコープ付きラベルセット値として持つ[スコープ付きラベル](../labels.md#scoped-labels)を作成します（例: `priority::1`）。
- **Story Point**（ストーリー）ポイント: この値をGitLabイシューの**weight**（ウェイト）値にマップします。
- **Sprint**（スプリント）: この値をGitLabイシューの**イテレーション**値にマップします。この値は、完了していないイシュー、または将来のスプリントにスケジュールされているイシューにのみ意味があります。データをインポートする前に、プロジェクトの親グループに必要な[イテレーション](../../group/iterations/_index.md#iteration-cadences)を作成します。

解析中のAtlassianドキュメント形式を処理し、GitLab Flavored Markdownにマッピングする必要がある場合もあります。これにはさまざまな方法で取り組むことができます。インスピレーションを得るために、[コミットの例をレビューします](https://gitlab.com/gitlab-org/gitlab/-/commit/4292a286d3f4ab26466f8e89125a4dbd194a9f3e)。このコミットは、GitLab JiraインポーターのAtlassianドキュメント形式をGitLab Flavored Markdownに解析するためのメソッドを追加しました。

GitLabをローカルで実行する場合は、RailsコンソールでAtlassianドキュメント形式をGitLab Flavored Markdownに手動で変換することもできます。これを行うには、次を実行します:

```ruby
text = <document in Atlassian Document Format>
project = <project that wiki is in> or nil
Banzai.render(text, pipeline: :adf_commonmark, project: project)
```
