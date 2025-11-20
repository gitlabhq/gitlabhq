---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jira開発パネル
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Jira開発パネルを使用すると、JiraイシューのGitLabアクティビティーをJiraで直接表示できます。Jira開発パネルをセットアップするには、次の手順に従います:

- **Jira Cloud**では、GitLabで開発および保持されている[Jira Cloudアプリ用のGitLab](connect-app.md)を使用します。
- **Jira Data CenterまたはJira Server**では、Atlassianで開発および保持されている[Jira DVCS connector](dvcs/_index.md)を使用します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Jira開発パネルのインテグレーション](https://www.youtube.com/watch?v=VjVTOmMl85M)を参照してください。

## 機能の可用性 {#feature-availability}

{{< history >}}

- ブランチを削除する機能は、`jira_connect_remove_branches`という名前の[フラグを使用](../../administration/feature_flags/_index.md)して、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148712)。デフォルトでは無効になっています。
- ブランチを削除する機能は、GitLab 17.2で[一般提供されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158224)。機能フラグ`jira_connect_remove_branches`は削除されました。

{{< /history >}}

この表は、Jira DVCSコネクターとJira Cloudアプリ用GitLabで使用できる機能を示しています:

| 機能                              | Jira DVCSコネクタ    | GitLab for Jira Cloudアプリ |
|:-------------------------------------|:-----------------------|:--------------------------|
| スマートコミット                        | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応    |
| マージリクエストの同期                  | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応    |
| ブランチの同期                        | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応    |
| コミットの同期                         | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応    |
| 既存データの同期                   | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}はい（[Jiraと同期されたGitLabのデータ](connect-app.md#gitlab-data-synced-to-jira)を参照） |
| ビルドの同期                          | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応    |
| デプロイの同期                     | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応    |
| 機能フラグの同期                   | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応    |
| 同期間隔                        | 最大60分       | リアルタイム                 |
| ブランチの削除                      | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応    |
| ブランチからマージリクエストを作成 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応    |
| Jiraイシューからブランチを作成    | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応    |

## GitLabで接続されたプロジェクト {#connected-projects-in-gitlab}

Jira開発パネルは、すべてのプロジェクトを持つJiraインスタンスを以下に接続します:

- **[Jira Cloudアプリ用GitLab](connect-app.md)の場合**、リンクされたGitLabグループまたはサブグループとそのプロジェクト
- **[Jira DVCSコネクター](dvcs/_index.md)の場合**、リンクされたGitLabグループ、サブグループ、または個人のネームスペースとそのプロジェクト

## 開発パネルに表示される情報 {#information-displayed-in-the-development-panel}

Jira開発パネルで[Jiraイシューに関するGitLabアクティビティーを表示](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)するには、GitLabでID別にJiraイシューを参照します。開発パネルに表示される情報は、GitLabでJiraイシューのIDをどこに記述するかによって異なります。

[Jira Cloudアプリ用GitLab](connect-app.md)では、次の情報が表示されます。

| GitLab: JiraイシューのIDを記述する場所 | Jira開発パネル: 表示される情報 |
|---------------------------------------------|-------------------------------------------------------|
| マージリクエストのタイトルまたは説明          | マージリクエストへのリンク<br>デプロイへのリンク<br>マージリクエストのタイトルを介したパイプラインへのリンク<br>マージリクエストの説明を介したパイプラインへのリンク（GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390888)）。<br>ブランチへのリンク（GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/354373)）<br>レビュアー情報と承認ステータス（GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)） |
| ブランチ名                                 | ブランチへのリンク<br>デプロイへのリンク          |
| コミットメッセージ                              | コミットへのリンク<br>環境への最後のデプロイが成功した後、最大2,000コミットからのデプロイへのリンク<sup>1</sup> <sup>2</sup> |
| [Jiraスマートコミット](#jira-smart-commits)    | カスタムコメント、記録された時間、またはワークフローの移行   |

**脚注**: 

1. GitLab 16.2で`jira_deployment_issue_keys`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)されました。デフォルトでは有効になっています。
1. [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/415025)はGitLab 16.3で開始されました。機能フラグ`jira_deployment_issue_keys`は削除されました。

## Jiraスマートコミット {#jira-smart-commits}

前提要件: 

- 同じメールアドレスまたはユーザー名を持つGitLabおよびJiraユーザーアカウントが必要です。
- コマンドは、コミットメッセージの最初の行に記述する必要があります。
- コミットメッセージが複数行にわたることはできません。

Jiraスマートコミットは、Jiraイシューを処理するための特別なコマンドです。これらのコマンドを使用すると、GitLabを使用して以下を実行できます:

- Jiraイシューにカスタムコメントを追加します。
- Jiraイシューに対して時間を記録します。
- プロジェクトのワークフローで定義された任意のステータスにJiraイシューを遷移させます。

スマートコミットは、この構文に従う必要があります:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

単一のコミットで1つまたは複数のコマンドを実行できます。

### スマートコミットの構文 {#smart-commit-syntax}

| コマンド                                        | 構文                                                       |
|-------------------------------------------------|--------------------------------------------------------------|
| コメントを追加                                   | `KEY-123 #comment Bug is fixed`                              |
| 時間を記録                                        | `KEY-123 #time 2w 4d 10h 52m Tracking work time`             |
| イシューをクローズ                                  | `KEY-123 #close Closing issue`                               |
| 時間を記録してイシューをクローズ                     | `KEY-123 #time 2d 5h #close`                                 |
| コメントを追加して**進行中**に移行 | `KEY-123 #comment Started working on the issue #in-progress` |

スマートコミットの動作方法と使用可能なコマンドの詳細については、以下を参照してください:

- [スマートコミットでイシューを処理する](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
- [スマートコミットの使用](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)

## デプロイ {#jira-deployments}

Jiraデプロイを使用すると、ソフトウェアリリースの進捗状況をJiraで直接追跡および視覚化できます。

以下の場合、GitLabは環境とデプロイに関する情報をJiraに送信します:

- プロジェクトの`.gitlab-ci.yml`ファイルに[`environment`](../../ci/yaml/_index.md#environment)キーワードが含まれている。
- JiraイシューIDが[GitLabの特定の箇所で言及され](#information-displayed-in-the-development-panel)、パイプラインがトリガーされた。

詳細については、[環境とデプロイ](../../ci/environments/_index.md)を参照してください。

## 関連トピック {#related-topics}

- [Jiraサーバーで開発パネルの問題を解決する](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html)
