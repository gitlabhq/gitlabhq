---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: JiraプロジェクトのイシューをGitLabにインポートする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Jiraインポーターを使用すると、JiraイシューをGitLab.comまたはGitLab Self-Managedにインポートできます。

Jiraイシューのインポートは最低限実現可能な変更のプロジェクトレベルの機能です。つまり、複数のJiraプロジェクトのイシューを1つのGitLabプロジェクトにインポートできます。最低限実現可能な変更バージョンのインポートでは、イシューのタイトル、説明、およびその他のイシューメタデータを、イシューの説明のセクションとしてインポートします。

## 既知の制限事項 {#known-limitations}

GitLabは、次の情報を直接インポートします:

- 件名、説明、ラベル。
- インポートの準備をする際に、JiraのユーザーをGitLabプロジェクトのメンバーにマップすることもできます。

GitLabイシューフィールドに正式にマップされていない他のJiraイシューメタデータは、プレーンテキストとしてGitLabイシューの説明にインポートされます。

JiraイシューのテキストはGitLab Flavored Markdownに解析されないため、テキストの書式が崩れる可能性があります。詳細については、[issue 379104](https://gitlab.com/gitlab-org/gitlab/-/issues/379104)を参照してください。

イシューの担当者、コメントなどを将来のイテレーションで追加することを追跡する[エピック](https://gitlab.com/groups/gitlab-org/-/epics/2738)があります。

## 前提要件 {#prerequisites}

- Jiraプロジェクトからイシューをインポートできるようにするには、Jiraイシューに対する読み取りアクセス権と、インポート先のGitLabプロジェクトに対するメンテナーロール以上が必要です。
- この機能は、既存のGitLab [Jiraイシューインテグレーション](../../../integration/jira/_index.md)を使用します。Jiraイシューのインポートを試みる前に、インテグレーションが設定されていることを確認してください。

## GitLabにJiraイシューをインポートする {#import-jira-issues-to-gitlab}

{{< alert type="note" >}}

Jiraイシューのインポートは非同期バックグラウンドジョブとして実行されるため、インポートキューの負荷、システム負荷、またはその他の要因に基づいて遅延が発生する可能性があります。大規模なプロジェクトのインポートは、インポートのサイズによっては数分かかる場合があります。

{{< /alert >}}

GitLabプロジェクトにJiraイシューをインポートするには:

1. {{< icon name="issues" >}} **イシュー**ページで、**アクション** ({{< icon name="ellipsis_v" >}}) > **Jiraからのインポート**を選択します。

   ![Jiraからイシューをインポートボタン](img/jira/import_issues_from_jira_button_v16_3.png)

   **Jiraからのインポート**オプションは、[正しい権限](#prerequisites)がある場合にのみ表示されます。

   次のフォームが表示されます。以前に[Jiraイシューインテグレーション](../../../integration/jira/_index.md)を設定した場合は、ドロップダウンリストでアクセスできるJiraプロジェクトを確認できるようになりました。

   ![Jiraからイシューをインポートフォーム](img/jira/import_issues_from_jira_form_v13_2.png)

1. **インポート元**ドロップダウンリストを選択し、イシューのインポート元のJiraプロジェクトを選択します。

   **Jira-GitLabユーザーマッピングテンプレート**セクションでは、テーブルに、JiraユーザーがマップされているGitLabユーザーが表示されます。フォームが表示されると、ドロップダウンリストはインポートを実行しているユーザーにデフォルト設定されます。

1. マッピングを変更するには、**GitLabのユーザー名**列のドロップダウンリストを選択し、各Jiraユーザーにマップするユーザーを選択します。

   ドロップダウンリストにすべてのユーザーが表示されない場合があるため、検索バーを使用して、このGitLabプロジェクト内の特定のユーザー名を見つけます。

1. **次に進む**を選択します。インポートが開始されたことを確認するメッセージが表示されます。

   インポートがバックグラウンドで実行されている間は、**イシュー**ページに移動して、リストに新しいイシューが表示されるのを確認できます。

1. インポートのステータスを確認するには、もう一度Jiraインポートページにアクセスします。
