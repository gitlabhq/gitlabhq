---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code用GitLab Workflow拡張機能を使用すると、一般的なGitLabタスクをVS Codeで直接処理できます。
title: VS Code拡張機能のCI/CDパイプライン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895): GitLab 18.1以降のGitLab VS Code用GitLab Workflow拡張機能6.14.0。
- GitLab 18.1以降の[ダウンストリームパイプラインログ](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)を追加。

{{< /history >}}

GitLabプロジェクトでCI/CDパイプラインを使用している場合、VS Code用GitLab Workflow拡張機能からCI/CDパイプラインを開始、監視、デバッグできます。Gitブランチでローカルに作業する場合、下部のステータスバーには次のいずれかが表示されます:

- 最新のパイプラインのステータス。
- **No pipeline**（パイプラインがまだ実行されていない場合）。

![最新のパイプラインが失敗したことを示す、下部のステータスバー。](img/status_bar_pipeline_v17_6.png)

使用可能なステータスは次のとおりです:

- パイプラインがキャンセルされました
- パイプラインが失敗しました
- パイプラインに合格しました
- パイプラインが保留中です
- パイプラインが実行中です
- パイプラインがスキップされました

## パイプライン情報を表示 {#view-pipeline-information}

この拡張機能を使用して、GitLabでCI/CDパイプラインを開始、監視、デバッグします。

前提要件: 

- プロジェクトでCI/CDパイプラインを使用している。
- 現在のGitブランチにマージリクエストが存在する。
- 現在のGitブランチの最新コミットにCI/CDパイプラインがある。

パイプライン情報を表示するには:

1. VS Codeの下部ステータスバーで、パイプラインステータスを選択して、コマンドパレットにアクションを表示します。
1. コマンドパレットで、目的のアクションを選択します:

   - **Create New Pipeline From Current Branch**（現在のブランチから新しいパイプラインを作成）: 新しいパイプラインを開始する。
   - **Cancel Last Pipeline**（最後のパイプラインをキャンセル）
   - **Download Artifacts from Latest Pipeline**（最新パイプラインからアーティファクトをダウンロード）: パイプラインアーティファクトをZIPまたはJSON形式でダウンロードします。
   - **Retry Last Pipeline**（最後のパイプラインを再試行）
   - **View Latest Pipeline on GitLab**（GitLabで最新のパイプラインを表示）: ブラウザータブでパイプラインのページを開きます。

## パイプラインアラートを表示 {#show-pipeline-alerts}

この拡張機能は、現在のブランチのパイプラインが完了すると、VS Codeにアラートを表示できます:

![パイプラインの失敗を示すアラート](img/pipeline_alert_v17_6.png)

現在のGitブランチのアラートを表示するには:

1. VS Codeの上部メニューで、**コード** > **設定** > **設定**を選択します。
1. 構成に応じて、**ユーザー**または**Workplace**（ワークプレース）の設定を選択します。
1. メインタブで、**Extensions**（拡張機能） > **GitLab Workflow**を選択して、この拡張機能の設定を表示します。
1. **Show Pipeline Update Notifications**（パイプライン更新通知を表示）で、**Show notification in VS Code when the pipeline status changes**（パイプラインステータスが変更されたときにVS Codeに通知を表示する）チェックボックスをオンにします。

## CI/CDジョブ出力 {#view-cicd-job-output}

現在のブランチのCI/CDジョブの出力を表示するには:

1. 左側の垂直メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能サイドバーを表示します。
1. サイドバーで、**For current branch**（現在のブランチの場合）を展開して、最新のパイプラインを表示します。
1. 目的のジョブを選択して、新しいVS Codeタブで開きます:

   ![合格、失敗を許可、および失敗しているCI/CDジョブを含むパイプライン。](img/view_job_output_v17_6.png)

   ダウンストリームパイプラインは、パイプラインの下に表示されます。ダウンストリームパイプラインジョブログを開くには:

   1. 矢印アイコンを選択して、ダウンストリームパイプラインの表示レベルを展開または折りたたむします。
   1. ダウンストリームパイプラインを選択します。ジョブログが新しいVS Codeタブで開きます。

### GitLab CI/CDの設定をテストする {#test-gitlab-cicd-configuration}

`GitLab: Validate GitLab CI Config`コマンドを使用して、プロジェクトのGitLab CI/CD構成をローカルでテストします。

1. VS Codeで、`.gitlab-ci.yml`ファイルを開き、ファイルのタブがアクティブになっていることを確認します。
1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで、`GitLab: Validate GitLab CI Config`を検索し、<kbd>Enter</kbd>キーを押します。

拡張機能は、構成に問題が検出されたアラートを表示します。

### マージされたGitLab CI/CD構成を表示 {#show-merged-gitlab-cicd-configuration}

このコマンドを使用すると、すべてのインクルードと参照が解決された、マージされたCI/CD設定ファイルのプレビューを表示できます。

1. VS Codeで、`.gitlab-ci.yml`ファイルを開き、ファイルのタブがアクティブになっていることを確認します。
1. 右上にある**Show Merged GitLab CI/CD Configuration**（マージされたGitLab CI/CD構成を表示）を選択します:

   ![マージされた結果を表示するアイコンを示すVS Codeアプリケーション。](img/show_merged_configuration_v17_6.png)

VS Codeは、完全な情報を含む新しいタブ(`.gitlab-ci (Merged).yml`)を開きます。

### CI/CD変数オートコンプリート {#cicd-variable-autocompletion}

CI/CD変数オートコンプリートを使用して、探しているCI/CD変数をすばやく見つけます。

前提要件: 

- ファイルには、次のいずれかの名前が付けられています:
  - `.gitlab-ci.yml`。
  - `.gitlab-ci`で始まり、`.yml`または`.yaml`で終わる`.gitlab-ci.production.yml`のようになります。

変数を自動補完するには:

1. VS Codeで、`.gitlab-ci.yml`ファイルを開き、ファイルのタブがアクティブになっていることを確認します。
1. 自動補完オプションを表示するには、変数の名前の入力を開始します。
1. オプションを選択して使用します:

   ![文字列に表示されるオートコンプリートオプション](img/ci_variable_autocomplete_v16_6.png)
