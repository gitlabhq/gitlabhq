---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code用GitLab Workflow拡張機能を使用すると、一般的なGitLabタスクをVS Codeで直接処理できます。
title: VS Code用GitLab Workflow拡張機能
---

Visual Studio Code用[GitLab Workflow拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)は、GitLab Duoやその他のGitLabの機能をIDEに直接統合します。GitLab WorkflowパネルがVS Codeのサイドバーに追加されます。このパネルでは、イシュー、マージリクエスト、パイプラインを表示し、[カスタムクエリ](custom_queries.md)で表示を拡張することができます。

利用を開始するには、[拡張機能をインストールして設定](setup.md)します。

設定が完了すると、この拡張機能により、日常的に使用するGitLabの機能がVS Code環境に直接組み込まれます:

- イシューを作成し、表示します。
- マージリクエストを作成、表示、レビューします。
- Visual Studio Codeコマンドパレットから[一般的なコマンドを実行](settings.md#command-palette-commands)する。
- [GitLab CI/CD設定をテスト](cicd.md#test-gitlab-cicd-configuration)する。
- [パイプラインのステータス](cicd.md)と[ジョブの出力](cicd.md#view-cicd-job-output)を表示する。
- スニペットを作成および管理する。
- リポジトリをクローンせずに[参照](remote_urls.md#browse-a-repository-in-read-only-mode)する。
- セキュリティ検出結果を表示する。
- SASTスキャンを実行する。

さらに、GitLab Workflow拡張機能は、AIアシスト機能によってVS Codeのワークフローを効率化します:

- [GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-vs-code): VS Code内でAIアシスタントと直接やり取りできます。
- [GitLab Duoコード提案](../../user/project/repository/code_suggestions/_index.md#use-code-suggestions): 現在のコード行に対する補完が提案されます。また、自然言語でコードコメントを書くと、より具体的な提案が得られます。

VS CodeでGitLabプロジェクトを表示すると、拡張機能は現在のブランチに関する情報を表示します:

- ブランチの最新のCI/CDパイプラインのステータス。
- このブランチのマージリクエストへのリンク。
- マージリクエストに[イシューのクローズパターン](../../user/project/issues/managing_issues.md#closing-issues-automatically)が含まれている場合は、そのイシューへのリンク。

## VS CodeでGitLabアカウントを切り替える {#switch-gitlab-accounts-in-vs-code}

GitLab Workflow拡張機能は、[VS Codeワークスペース](https://code.visualstudio.com/docs/editor/workspaces)（ウィンドウ）ごとに1つのアカウントを使用します。この拡張機能は、次の場合にアカウントを自動的に選択します:

- 拡張機能にGitLabアカウントを1つだけ追加した場合。
- VS Codeウィンドウ内のすべてのワークスペースが、`git remote`の設定に基づいて同じGitLabアカウントを使用している場合。

拡張機能がステータスバーに表示する内容は、アカウントの設定によって異なります:

![複数のGitLabアカウントを持つユーザーのステータスバー（1つは選択済み）。](img/preselected_account_v17_11.png)

- GitLabアカウントが1つしかない場合、ステータスバーには何も表示されません。
- 複数のGitLabアカウントが存在し、拡張機能が使用するアカウントを特定できる場合、ステータスバーにはタヌキ（{{< icon name="tanuki">}}）アイコンの横にアカウント名が表示されます。
- 複数のGitLabアカウントが存在し、拡張機能が使用するアカウントを特定できない場合、ステータスバーに**Multiple GitLab Accounts**（複数のGitLabアカウント）（{{< icon name="question-o">}}）と表示されます。

アクティブなVS Codeウィンドウで使用するGitLabアカウントを選択するには、ステータスバーのアイテムを選択するか、次の手順に従います:

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンド`GitLab: Select Account for this Workspace`を実行します。
1. リストから使用するアカウントを選択します。

## GitLabプロジェクトを選択する {#select-your-gitlab-project}

Gitリポジトリが複数のGitLabプロジェクトに関連付けられている場合、拡張機能は使用するアカウントを判断できません。これは、次のように複数のリモートがある場合に発生する可能性があります:

- `origin`: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork`: `git@gitlab.com:myusername/gitlab-vscode-extension.git`

このような場合、拡張機能は**(multiple projects)**（複数のプロジェクト）ラベルを追加して、アカウントを選択する必要があることを示します。

アカウントを選択するには、次の手順に従います:

1. 垂直メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. **Issues and Merge Requests**（イシューとマージリクエスト）を展開します。
1. **(multiple projects, click to select)**（複数プロジェクト、クリックして選択）を含む行を選択します。
1. ご希望のプロジェクトを選択します:

   ![プロジェクトとアカウントの組み合わせを選択](img/select-project-account_v17_7.png)

**Issues and Merge requests**（イシューとマージリクエスト）リストが、選択したプロジェクトの情報で更新されます。

### 選択内容を変更する {#change-your-selection}

プロジェクトの選択を変更するには、次の手順に従います:

1. 垂直メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. **Issues and Merge Requests**（イシューとマージリクエスト）を展開して、プロジェクトリストを表示します。
1. プロジェクトを選択します。
1. プロジェクト名の横にある**Clear Selected Project** {{< icon name="close-xs" >}}を選択します。

## スラッシュコマンドを使用する {#use-slash-commands}

イシューとマージリクエストでは、VS Codeでアクションを直接実行できるように、[GitLabのスラッシュコマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)がサポートされています。

## スニペットを作成する {#create-a-snippet}

[スニペット](../../user/snippets.md)を作成して、コードやテキストの一部を保存し、他のユーザーと共有できます。スニペットは、選択範囲またはファイル全体を指定して作成できます。

VS Codeでスニペットを作成するには、次の手順に従います:

1. スニペットの内容を選択します:
   - **Snippet from file**（ファイルからスニペット）を作成する場合は、ファイルを開きます。
   - **Snippet from selection**（選択範囲からスニペット）を作成する場合は、ファイルを開き、含める行を選択します。
1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで、コマンド`GitLab: Create Snippet`を実行します。
1. スニペットのプライバシーレベルを選択します:
   - **プライベート**スニペットは、プロジェクトメンバーのみに表示されます。
   - **公開**スニペットは、すべてのユーザーに表示されます。
1. スニペットのスコープを選択します:
   - **Snippet from file**（ファイルからスニペット）を作成する場合は、アクティブなファイル全体の内容を使用します。
   - **Snippet from selection**（選択範囲からスニペット）を作成する場合は、アクティブなファイルで選択した行を使用します。

GitLabは、新しいブラウザタブで新しいスニペットのページを開きます。

### パッチファイルを作成する {#create-a-patch-file}

マージリクエストをレビューするとき、複数のファイルにわたる変更を提案する場合は、スニペットパッチを作成します。

1. ローカルマシンで、変更を提案するブランチをチェックアウトします。
1. VS Codeで、変更するすべてのファイルを編集します。変更をコミットしないでください。
1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで、`GitLab: Create snippet patch`と入力し、候補に表示されたコマンドを選択します。このコマンドは`git diff`コマンドを実行し、プロジェクト内にGitLabスニペットを作成します。
1. **Patch name**（パッチ名）を入力し、<kbd>Enter</kbd>キーを押します。GitLabはこの名前をスニペットのタイトルとして使用し、拡張子`.patch`が付加されたファイル名に変換します。
1. スニペットのプライバシーレベルを選択します:
   - **プライベート**スニペットは、プロジェクトメンバーのみに表示されます。
   - **公開**スニペットは、すべてのユーザーに表示されます。

VS Codeは、新しいブラウザタブでスニペットパッチを開きます。スニペットパッチの説明には、パッチを適用する手順が記載されています。

### スニペットを挿入する {#insert-a-snippet}

メンバーになっているプロジェクトから既存の単一ファイルまたは[複数ファイル](../../user/snippets.md#add-or-remove-multiple-files)のスニペットを挿入するには、次の手順に従います:

1. スニペットを挿入する位置にカーソルを置きます。
1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. `GitLab: Insert Snippet`と入力し、候補に表示されたコマンドを選択します。
1. スニペットを含むプロジェクトを選択します。
1. 適用するスニペットを選択します。
1. 複数ファイルのスニペットの場合は、適用するファイルを選択します。

## イシューとマージリクエストを表示する {#view-issues-and-merge-requests}

特定のプロジェクトのイシューとマージリクエストを表示するには、次の手順に従います:

1. メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. サイドバーで**イシューとマージリクエスト**を展開します。
1. 目的のプロジェクトを選択して展開します。
1. 次のいずれかの結果タイプを選択します:
   - **自分にアサインされたイシュー**
   - **Issues created by me**（Issues created by me（自分が作成したイシュー））
   - **自分にアサインされたマージリクエスト**
   - **Merge requests I'm reviewing**（Merge requests I'm reviewing（自分がレビュー中のマージリクエスト））
   - **Merge requests created by me**（Merge requests created by me（自分が作成したマージリクエスト））
   - **All project merge requests**（All project merge requests（プロジェクトのすべてのマージリクエスト））
   - Your custom queries（自分の[カスタムクエリ](custom_queries.md)）

イシューまたはマージリクエストを選択すると、新しいVS Codeタブで開きます。

## イシューを作成 {#create-an-issue}

現在のプロジェクトでイシューを作成するには:

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab: 現在のプロジェクトで新しいイシューを作成**し、<kbd>Enter</kbd>キーを押します。

GitLabにより、**新規イシュー**ページがデフォルトのブラウザで開きます。

## マージリクエストを作成する {#create-a-merge-request}

現在のプロジェクトでマージリクエストを作成するには、下のステータスバーで**Create MR**（MRの作成） ({{< icon name="merge-request-open" >}}) を選択するか、または以下の手順に従ってください:

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab: 現在のプロジェクトから新しいマージリクエストを作成**し、<kbd>Enter</kbd>キーを押します。

GitLabにより、**新しいマージリクエスト**ページがデフォルトのブラウザで開きます。

## マージリクエストをレビューする {#review-a-merge-request}

この拡張機能を使用すると、VS Codeを離れることなく、マージリクエストのレビュー、コメント、承認を行えます:

1. GitLab Workflowサイドバーで、**Issues and Merge Requests**（イシューとマージリクエスト）を展開し、プロジェクトを選択します。
1. レビューするマージリクエストを選択します。そのサイドバーのエントリが展開され、詳細情報が表示されます。
1. マージリクエストの番号とタイトルの下にある**説明**を選択して、マージリクエストの詳細を確認します。
1. 提案されたファイルの変更をレビューするには、リストからファイルを選択してVS Codeタブに表示します。GitLabは、差分コメントをタブ内にインライン表示します。リストでは、削除されたファイルは赤色で表示されます:

   ![このマージリクエストで変更されたファイルと変更タイプのアルファベット順リスト](img/vscode_view_changed_file_v17_6.png)

差分を使用して次の操作を行います:

- ディスカッションをレビューおよび作成する。
- ディスカッションを解決および再オープンする。
- 個々のコメントを削除および編集する。

### デフォルトブランチと比較する {#compare-with-default-branch}

<!-- vale gitlab_base.InclusiveLanguage = NO -->

マージリクエストを作成せずに、自分のブランチをプロジェクトのデフォルトブランチと比較するには、次の手順に従います:

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab: Compare current branch with master**（GitLab: 現在のブランチをマスターと比較する）を検索し、<kbd>Enter</kbd>キーを押します。

拡張機能が新しいブラウザタブを開き、自分のブランチの最新コミットと、プロジェクトのデフォルトブランチの最新コミットの差分を表示します。

<!-- vale gitlab_base.InclusiveLanguage = YES -->

### GitLab UIで現在のファイルを開く {#open-current-file-in-gitlab-ui}

現在のGitLabプロジェクトのファイルをGitLab UIで開き、特定の行を強調表示するには、次の手順に従います:

1. VS Codeで目的のファイルを開きます。
1. 強調表示する行を選択します。
1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab: Open active file on GitLab**（GitLab: GitLabでアクティブなファイルを開く）を選択し、<kbd>Enter</kbd>キーを押します。

## セキュリティ検出結果を表示する {#view-security-findings}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件: 

- GitLab Workflowバージョン3.74.0以降を使用していること。
- プロジェクトには、静的アプリケーションセキュリティテスト（SAST）、動的アプリケーションセキュリティテスト（DAST）、コンテナスキャン、または依存関係スキャンなどの[セキュリティリスク管理](https://about.gitlab.com/features/?stage=secure)機能が含まれています。
- [セキュリティリスク管理](../../user/application_security/secure_your_application.md)機能が設定されていることを確認してください。

セキュリティ検出結果を表示するには、次の手順に従います:

1. 垂直メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. サイドバーで**セキュリティスキャン**を展開します。
1. **New findings**（新しい検出結果）または**Fixed findings**（修正された検出結果）のいずれかを選択します。
1. 表示する重大度レベルを選択します。
1. 検出結果を選択すると、VS Codeタブで開きます。

## SASTスキャンを実行する {#perform-sast-scanning}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- VS Code拡張機能バージョン5.31で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675)されました。

{{< /history >}}

VS Codeの静的アプリケーションセキュリティテスト（SAST）は、アクティブなファイルの脆弱性を検出します。早期に検出することで、変更をデフォルトブランチにマージする前に脆弱性を修正できます。

SASTスキャンをトリガーすると、アクティブなファイルの内容がGitLabに渡され、SAST脆弱性ルールに照らしてチェックされます。GitLabは、プライマリサイドバーにスキャン結果を表示します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>SASTスキャンのセットアップについては、GitLab Unfilteredの[SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8)（VS CodeでのSASTスキャン）を参照してください。
<!-- Video published on 2025-02-10 -->

前提要件: 

- GitLab Workflowバージョン5.31.0以降を使用していること。
- [GitLabに対して認証済み](setup.md#authenticate-with-gitlab)であること。
- [**Enable Real-time SAST scan checkbox**（リアルタイムSASTスキャンを有効にする）チェックボックス](setup.md#code-security)をオンにしていること。

VS CodeでファイルのSASTスキャンを実行するには、次の手順に従います:

<!-- markdownlint-disable MD044 -->

1. ファイルを開きます。
1. 次のいずれかの方法でSASTスキャンをトリガーします:
   - ファイルを保存する（[**Enable scanning on file save**（ファイルの保存時にスキャンを有効にする）オプションをオン](setup.md#code-security)にしている場合）。
   - コマンドパレットを使用する:
     1. コマンドパレットを開きます:
        - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
        - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
     1. **GitLab: Run Remote Scan (SAST)**（GitLab: リモートスキャン（SAST）を実行する）を検索し、<kbd>Enter</kbd>キーを押します。
1. SASTスキャンの結果を表示します。
   1. **Primary Side Bar**（プライマリサイドバー）を表示します。
   1. GitLab Workflow（{{< icon name="tanuki">}}）を選択して、拡張機能のサイドバーを表示します。
   1. **GITLAB REMOTE SCAN (SAST)**（GitLabリモートスキャン（SAST））セクションを展開します。

   SASTスキャンの結果は、重大度の降順で一覧表示されます。検出結果の詳細を表示するには、拡張機能のサイドバーの**GITLAB REMOTE SCAN (SAST)**（GitLabリモートスキャン（SAST））セクションで検出結果を選択します。

<!-- markdownlint-enable MD044 -->

## イシューとマージリクエストを検索する {#search-issues-and-merge-requests}

VS Codeからプロジェクトのイシューとマージリクエストを直接検索するには、フィルター検索または[高度な検索](../../integration/advanced_search/elasticsearch.md)を使用します。フィルター検索では、定義済みのトークンを使用して検索結果を絞り込みます。高度な検索では、GitLabインスタンス全体をより高速かつ効率的に検索できます。

前提要件: 

- GitLabプロジェクトのメンバーであること。
- [GitLab Workflow拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)をインストールしていること。
- [GitLabに対して認証する](setup.md#authenticate-with-gitlab)の説明に従って、GitLabインスタンスにサインインしていること。

プロジェクトのタイトルと説明フィールドを検索するには、次の手順に従います:

1. VS Codeでコマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. 目的の検索タイプ（`GitLab: Search project merge requests`（GitLab: プロジェクトのマージリクエストを検索）または`GitLab: Search project issues`（GitLab: プロジェクトのイシューを検索））を選択します。
1. テキストを入力し、必要に応じてフィルタートークンを使用します。
1. 検索テキストを確定するには、<kbd>Enter</kbd>キーを押します。キャンセルするには、<kbd>Escape</kbd>キーを押します。

GitLabがブラウザタブで結果を開きます。

### トークンで検索をフィルタリングする {#filter-searches-with-tokens}

大規模なプロジェクトで検索する際は、フィルターを追加するとより適切な結果が得られます。この拡張機能は、マージリクエストとイシューをフィルタリングするための次のトークンをサポートしています:

| トークン     | 例                                                            | 説明 |
|-----------|--------------------------------------------------------------------|-------------|
| assignee  | `assignee: timzallmann`                                            | 担当者のユーザー名（`@`なし）。 |
| author    | `author: fatihacet`                                                | 作成者のユーザー名（`@`なし）。 |
| label     | `label: frontend`または`label:frontend label: Discussion`            | 1つのラベル。複数回使用でき、同じクエリで`labels`と併用できます。 |
| labels    | `labels: frontend, Discussion, performance`                        | 複数のラベルのカンマ区切りリスト。同じクエリで`label`と併用できます。 |
| milestone | `milestone: 18.1`                                                  | マイルストーンのタイトル（`%`なし）。 |
| scope     | `scope: created-by-me`、`scope: assigned-to-me`、または`scope: all`。 | 指定されたスコープに一致するイシューとマージリクエスト。値: `created-by-me`（デフォルト）、`assigned-to-me`、または`all`。 |
| title     | `title: discussions refactor`                                             | タイトルまたは説明にこれらの単語を含むイシューとマージリクエスト。フレーズを引用符で囲まないでください。 |

トークンの構文とガイドライン:

- 各トークン名の後にはコロン（`:`）が必要です（例: `label:`）。
  - コロンの前にスペースを入れる（`label :`）と無効になり、解析エラーが返されます。
  - トークン名の後のスペースは省略可能です。`label: frontend`と`label:frontend`はいずれも有効です。
- `label`トークンと`labels`トークンは複数回使用でき、また組み合わせて使用することも​​できます。次のクエリはいずれも同じ結果を返します:
  - `labels: frontend discussion label: performance`
  - `label: frontend label: discussion label: performance`
  - `labels: frontend discussion performance`（最終的に得られる結合クエリ）

1つの検索クエリで複数のトークンを組み合わせることができます。次に例を示します: 

```plaintext
title: new merge request widget author: fatihacet assignee: jschatz1 labels: frontend, performance milestone: 17.5
```

この検索クエリは、次の条件に一致するものを探します:

- タイトル: `new merge request widget`
- 作成者: `fatihacet`
- 担当者: `jschatz1`
- ラベル: `frontend`と`performance`
- マイルストーン: `17.5`

## キーボードショートカットをカスタマイズする {#customize-keyboard-shortcuts}

**Accept Inline Suggestion**（インライン提案を受け入れる）、**Accept Next Word Of Inline Suggestion**（インライン提案の次の単語を受け入れる）、または**Accept Next Line Of Inline Suggestion**（インライン提案の次の行を受け入れる）に対して、別のキーボードショートカットを割り当てることができます:

1. VS Codeで`Preferences: Open Keyboard Shortcuts`コマンドを実行します。
1. 編集するショートカットを見つけて、**Change keybinding**（キー割り当てを変更）（{{< icon name="pencil" >}}）を選択します。
1. 使用するショートカットを**Accept Inline Suggestion**インライン提案を受け入れる）、**Accept Next Word Of Inline Suggestion**（インライン提案の次の単語を受け入れる）、または**Accept Next Line Of Inline Suggestion**（インライン提案の次の行を受け入れる）に割り当てます。
1. <kbd>Enter</kbd>キーを押して変更を保存します。

## 拡張機能を更新する {#update-the-extension}

拡張機能を最新バージョンに更新するには、次の手順に従います:

1. Visual Studio Codeで、**設定** > **Extensions**（拡張機能）に移動します。
1. **GitLab (`gitlab.com`)**が発行する**GitLab Workflow**を検索します。
1. **Extension: GitLab Workflow**（拡張機能: GitLab Workflow）で、**Update to {later version}**（{新しいバージョン}に更新）を選択します。
1. オプション。今後の自動更新を有効にするには、**Auto-Update**を選択します。

## ステータスを確認する {#check-status}

1. Visual Studio Codeの下部ステータスバーで、GitLabアイコン（{{< icon name="tanuki">}}）を選択します。
1. VS Codeの検索ボックスの下にメニューが表示され、GitLab Workflow拡張機能のステータスが表示されます。エラーがある場合は**ステータス:**の横に表示されます。

[GitLab Duo Chatのステータス](../../user/gitlab_duo_chat/_index.md#check-the-status-of-chat)も確認できます。

## テレメトリを有効にする {#enable-telemetry}

GitLab Workflow拡張機能は、Visual Studio Codeのテレメトリ設定を使用して、使用状況とエラー情報をGitLabに送信します。Visual Studio Codeでテレメトリを有効化またはカスタマイズするには、次の手順に従います:

1. Visual Studio Codeで、Windows/Linuxの場合は**ファイル** > **設定** > **設定**に移動します。macOSの場合は**コード** > **設定** > **設定**に移動します。
1. 検索ボックスで、`Telemetry`を検索します。
1. 左側のサイドバーで、**Telemetry**（テレメトリ）を選択します。
1. **Telemetry Level**（テレメトリレベル）で、共有するデータを選択します:
   - `all`: 使用状況データ、一般的なエラーテレメトリ、クラッシュレポートを送信します。
   - `error`: 一般的なエラーテレメトリとクラッシュレポートを送信します。
   - `crash`: OSレベルのクラッシュレポートを送信します。
   - `off`: Visual Studio Codeのすべてのテレメトリデータを無効にします。
1. 変更を保存します。

## 関連トピック {#related-topics}

- [VS Code用GitLab Workflow拡張機能のトラブルシューティング](troubleshooting.md)
- [GitLab Workflow拡張機能をダウンロードする](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- 拡張機能の[ソースコード](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [GitLab Duoドキュメント](../../user/project/repository/code_suggestions/_index.md)
- [GitLab言語サーバードキュメント](../language_server/_index.md)
