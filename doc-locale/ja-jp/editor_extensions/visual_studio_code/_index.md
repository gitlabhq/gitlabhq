---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the GitLab Workflow extension for VS Code to handle common GitLab tasks directly in VS Code.
title: VS Code用GitLabワークフロー拡張機能
---

Visual Studio Code用[GitLabワークフロー拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)は、GitLab Duoやその他のGitLabの機能をIDEに直接統合します。GitLabワークフローパネルがVS Codeのサイドバーに追加されます。このパネルでは、イシュー、マージリクエスト、パイプラインを表示し、[カスタムクエリ](custom_queries.md)で表示を拡張することができます。

最初に[拡張機能をインストールして設定](setup.md)します。

設定が完了すると、この拡張機能により、日常的に使用するGitLabの機能がVS Code環境に直接取り込まれます。

- [イシューとマージリクエストを表示](#view-issues-and-merge-requests)する。
- Visual Studio Codeコマンドパレットから[一般的なコマンドを実行](settings.md#command-palette-commands)する。
- マージリクエストを作成して[レビュー](#review-a-merge-request)する。
- [GitLab CI/CDの設定をテスト](cicd.md#test-gitlab-cicd-configuration)する。
- [パイプラインのステータス](cicd.md)と[ジョブの出力](cicd.md#view-cicd-job-output)を表示する。
- スニペットを[作成](#create-a-snippet)および管理する。
- リポジトリをクローンせずに[参照](remote_urls.md#browse-a-repository-in-read-only-mode)する。
- [セキュリティ検出を表示](#view-security-findings)する。
- [SASTスキャンを実行](#perform-sast-scanning)する。

GitLabワークフロー拡張機能はまた、AIアシスト機能によってVS Codeワークフローを効率化します。

- [GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-vs-code):VS CodeでAIアシスタントと直接やり取りします。
- [GitLab Duoコード提案](../../user/project/repository/code_suggestions/_index.md#use-code-suggestions):現在のコード行の補完を提案するか、またはより実質的な提案を得るために自然言語のコードコメントを作成します。

VS CodeでGitLabプロジェクトを表示すると、この拡張機能により現在のブランチに関する情報が表示されます。

- ブランチの最新のCI/CDパイプラインのステータス。
- このブランチのマージリクエストへのリンク。
- マージリクエストに[イシューのクローズパターン](../../user/project/issues/managing_issues.md#closing-issues-automatically)が含まれている場合は、イシューへのリンク。

## VS CodeでGitLabアカウントを切り替える

GitLabワークフロー拡張機能は、[VS Codeワークスペース](https://code.visualstudio.com/docs/editor/workspaces)（ウィンドウ）ごとに1つのアカウントを使用します。この拡張機能は、次の場合にアカウントを自動的に選択します。

- 拡張機能にGitLabアカウントを1つだけ追加した場合。
- VS Codeウィンドウ内のすべてのワークスペースが、`git remote`の設定に基づいて同じGitLabアカウントを使用している場合。

それ以外の場合は、アクティブなVS CodeウィンドウのGitLabアカウントを選択する必要があります。

アカウントの選択を変更するには、次の手順に従います。

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンド`GitLab: Select Account for this Workspace`を実行します。
1. リストから使用するアカウントを選択します。

GitLabアカウントのステータスバー項目を選択して、アカウントを変更することもできます。

## GitLabプロジェクトを選択する

Gitリポジトリが複数のGitLabプロジェクトに関連付けられている場合、拡張機能は使用するアカウントを判断できません。これは、次のように複数のremoteがある場合に発生する可能性があります。

- `origin`: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork`: `git@gitlab.com:myusername/gitlab-vscode-extension.git`

このような場合、拡張機能は**（複数のプロジェクト）**ラベルを追加して、アカウントを選択する必要があることを示します。

アカウントを選択するには、次の手順に従います。

1. 縦のメニューバーで**GitLabワークフロー**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. **イシューとマージリクエスト**を展開します。
1. **（複数のプロジェクト）**を含む行を選択して、アカウントのリストを展開します。
1. 目的のプロジェクトを選択します。![プロジェクトとアカウントの組み合わせを選択](../img/select-project-account_v17_7.png)

**イシューとマージリクエスト**リストが、選択したプロジェクトの情報で更新されます。

### 選択内容を変更する

プロジェクトの選択を変更するには、次の手順に従います。

1. 縦のメニューバーで**GitLabワークフロー**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. **イシューとマージリクエスト**を展開して、プロジェクトリストを表示します。
1. プロジェクトの名前を右クリックします。
1. **選択したプロジェクトをクリアする**を選択します。

## スラッシュ(/) コマンドを使用する

イシューとマージリクエストでは、VS Codeでアクションを直接実行できるように、[GitLabのスラッシュ(/) コマンド](../../user/project/integrations/gitlab_slack_application.md#slash-commands)がサポートされています。

## スニペットを作成する

[スニペット](../../user/snippets.md)を作成して、コードのビット数とテキストを保存し、他のユーザーと共有します。スニペットは、選択範囲またはファイル全体にすることができます。

VS Codeでスニペットを作成するには、次の手順に従います。

1. スニペットのコンテンツを選択します。
   - **ファイルからスニペット**を作成する場合は、ファイルを開きます。
   - **選択範囲からスニペット**を作成する場合は、ファイルを開き、含める行を選択します。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで、コマンド`GitLab: Create Snippet`を実行します。
1. スニペットのプライバシーレベルを選択します。
   - **プライベート**スニペットは、プロジェクトメンバーのみに表示されます。
   - **パブリック**スニペットは、すべてのユーザーに表示されます。
1. スニペットのスコープを選択します。
   - **ファイルからスニペット**を作成する場合は、アクティブなファイルの内容全体を使用します。
   - **選択範囲からスニペット**を作成する場合は、アクティブなファイルで選択した行を使用します。

GitLabは、新しいブラウザータブで新しいスニペットのページを開きます。

### パッチファイルを作成する

マージリクエストをレビューするときに、複数のファイルの変更を提案する場合は、スニペットパッチを作成します。

1. ローカルマシンで、変更を提案するブランチをチェックアウトします。
1. VS Codeで、変更するすべてのファイルを編集します。変更をコミットしないでください。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで、`GitLab: Create snippet patch`と入力してこれを選択します。このコマンドは`git diff`コマンドを実行し、プロジェクトにGitLabスニペットを作成します。
1. **パッチ名**を入力し、<kbd>Enter</kbd>キーを押します。GitLabはこの名前をスニペットのタイトルとして使用し、`.patch`が付加されたファイル名に変換します。
1. スニペットのプライバシーレベルを選択します。
   - **プライベート**スニペットは、プロジェクトメンバーのみに表示されます。
   - **パブリック**スニペットは、すべてのユーザーに表示されます。

VS Codeは、新しいブラウザータブでスニペットパッチを開きます。スニペットパッチの説明には、パッチの適用方法に関する指示が含まれています。

### スニペットを挿入する

メンバーになっているプロジェクトから既存の1つのファイルまたは[複数ファイル](../../user/snippets.md#add-or-remove-multiple-files)のスニペットを挿入するには、次の手順に従います。

1. スニペットを挿入する場所にカーソルを置きます。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. `GitLab: Insert Snippet`と入力してこれを選択します。
1. スニペットを含むプロジェクトを選択します。
1. 適用するスニペットを選択します。
1. 複数ファイルのスニペットの場合は、適用するファイルを選択します。

## イシューとマージリクエストを表示する

特定のプロジェクトのイシューとマージリクエストを表示するには、次の手順に従います。

1. メニューバーで**GitLabワークフロー**（{{< icon name="tanuki" >}}）を選択して、拡張機能サイドバーを表示します。
1. サイドバーで**イシューとマージリクエスト**を展開します。
1. 目的のプロジェクトを選択して展開します。
1. 次のいずれかの結果タイプを選択します。
   - 自分に割り当てられたイシュー
   - 自分が作成したイシュー
   - 自分に割り当てられたマージリクエスト
   - 自分がレビュー中のマージリクエスト
   - 自分が作成したマージリクエスト
   - すべてのプロジェクトマージリクエスト
   - あなたの[カスタムクエリ](custom_queries.md)

イシューまたはマージリクエストを選択して、新しいVS Codeタブで開きます。

## マージリクエストをレビューする

この拡張機能を使用して、VS Codeを離れることなく、マージリクエストをレビュー、コメント、承認できます。

1. VS Codeで[イシューとマージリクエスト](#view-issues-and-merge-requests)を表示して、レビューするマージリクエストを選択します。そのサイドバーエントリが展開され、詳細情報が表示されます。
1. マージリクエストの番号とタイトルの下にある**説明**を選択して、マージリクエストの詳細を読みます。
1. ファイルに対する提案された変更をレビューするには、リストからファイルを選択してVS Codeタブに表示します。GitLabは、タブに差分コメントをインラインで表示します。リストでは、削除されたファイルは赤色でマークされています。

   ![このマージリクエストで変更されたファイルのアルファベット順リスト（変更タイプを含む）。](../img/vscode_view_changed_file_v17_6.png)

次の作業に差分を使用します。

- ディスカッションをレビューおよび作成する。
- これらのディスカッションを解決および未解決にする。
- 個々のコメントを削除および編集する。

### デフォルトブランチと比較する

<!-- vale gitlab_base.InclusiveLanguage = NO -->

マージリクエストを作成せずに、ブランチをプロジェクトのデフォルトブランチと比較するには、次の手順に従います。

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab:現在のブランチをマスターと比較する**を検索し、<kbd>Enter</kbd>キーを押します。

拡張機能が新しいブラウザータブを開きます。ブランチの最新コミットと、プロジェクトのデフォルトブランチの最新コミットの差分が表示されます。

<!-- vale gitlab_base.InclusiveLanguage = YES -->

### GitLab UIで現在のファイルを開く

GitLab UIで現在のGitLabプロジェクトのファイルを開き、特定の行を強調表示するには、次の手順に従います。

1. VS Codeで目的のファイルを開きます。
1. 強調表示する行を選択します。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. コマンドパレットで**GitLab:GitLabでアクティブなファイルを開く**を選択し、<kbd>Enter</kbd>キーを押します。

## セキュリティ検出を表示する

{{< details >}}

- プラン:Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- GitLabワークフローバージョン3.74.0以降を使用していること。
- プロジェクトに、静的アプリケーションセキュリティテスト（SAST）、動的アプリケーションセキュリティテスト（DAST）、コンテナスキャン、依存関係スキャンなどの[セキュリティリスク管理](https://about.gitlab.com/features/?stage=secure)機能が含まれていること。
- [セキュリティリスク管理](../../user/application_security/secure_your_application.md)機能を設定していること。

セキュリティ検出を表示するには、次の手順に従います。

1. 縦のメニューバーで**GitLabワークフロー**（{{< icon name="tanuki" >}}）を選択して、拡張機能のサイドバーを表示します。
1. サイドバーで**セキュリティスキャン**を展開します。
1. **新しい検出**または**修正された検出**のいずれかを選択します。
1. 目的の重大度レベルを選択します。
1. 検出を選択して、VS Codeタブで開きます。

## SASTスキャンを実行する

{{< details >}}

- プラン:Ultimate
- 提供形態:GitLab.com
- ステータス:実験

{{< /details >}}

{{< history >}}

- VS Code拡張機能バージョン5.31で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1675)されました。

{{< /history >}}

VS Codeの静的アプリケーションセキュリティテスト （SAST）は、アクティブなファイルの脆弱性を検出します。早期に検出することで、変更をデフォルトブランチにマージする前に脆弱性を修正できます。

SASTスキャンをトリガーすると、アクティブなファイルの内容がGitLabに渡され、SAST脆弱性ルールに照らしてチェックされます。GitLabは、プライマリサイドバーにスキャン結果を表示します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>SASTスキャンのセットアップについては、GitLab Unfilteredの[SAST scanning in VS Code](https://www.youtube.com/watch?v=s-qOSQO0i-8)を参照してください。
<!-- Video published on 2025-02-10 -->

前提要件:

- GitLabワークフローバージョン5.31.0以降を使用していること。
- [GitLabで認証](setup.md#authenticate-with-gitlab)していること。
- [**リアルタイムSASTスキャンを有効にするチェックボックス**](setup.md#code-security)を選択していること。

VS CodeでファイルのSASTスキャンを実行するには、次の手順に従います。

<!-- markdownlint-disable MD044 -->

1. ファイルを開きます。
1. 次のいずれかの方法でSASTスキャンをトリガーします。
   - ファイルを保存する（[**ファイル保存時にスキャンを有効にする**オプションを選択した場合](setup.md#code-security)）。
   - コマンドパレットを使用する。
     1. コマンドパレットを開きます。
        - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
        - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
     1. **GitLab:リモートスキャン（SAST）を実行する**を検索し、<kbd>Enter</kbd>キーを押します。
1. SASTスキャンの結果を表示します。
   1. **プライマリサイドバー**を表示します。
   1. GitLabワークフロー（{tanuki}）を選択して、拡張機能サイドバーを表示します。
   1. **GitLabリモートスキャン（SAST）**セクションを展開します。

   SASTスキャンの結果は、重大度順に降順でリストされています。検出の詳細を表示するには、拡張機能のサイドバーの**GitLabリモートスキャン（SAST）**セクションで検出を選択します。

<!-- markdownlint-enable MD044 -->

## イシューとマージリクエストを検索する

VS Codeからプロジェクトのイシューとマージリクエストを直接検索するには、フィルター検索または[高度な検索](../../integration/advanced_search/elasticsearch.md)を使用します。フィルター検索では、定義済みのトークンを使用して検索結果を絞り込みます。高度な検索では、GitLabインスタンス全体でより高速で効率的な検索を実行できます。

前提要件:

- GitLabプロジェクトのメンバーであること。
- [GitLabワークフロー拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)をインストールしていること。
- [GitLabで認証する](setup.md#authenticate-with-gitlab)の説明に従って、GitLabインスタンスにサインインしていること。

プロジェクトのタイトルと説明フィールドを検索するには、次の手順に従います。

1. VS Codeでコマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. 目的の検索タイプ（`GitLab: Search project merge requests`または`GitLab: Search project issues`）を選択します。
1. 必要に応じて[フィルタートークン](#filter-searches-with-tokens)を使用して、テキストを入力します。
1. 検索テキストを確定するには、<kbd>Enter</kbd>キーを押します。キャンセルするには、<kbd>Escape</kbd>キーを押します。

GitLabはブラウザータブで結果を開きます。

### トークンで検索をフィルタリングする

大規模なプロジェクトでの検索でフィルターを追加すると、より良い結果が得られます。この拡張機能では、マージリクエストとイシューをフィルタリングするための以下のトークンをサポートしています。

| トークン     | 例                                                            | 説明 |
|-----------|--------------------------------------------------------------------|-------------|
| assignee  | `assignee: timzallmann`                                            | 担当者のユーザー名（`@`なし）。 |
| author    | `author: fatihacet`                                                | 作成者のユーザー名（`@`なし）。 |
| label     | `label: frontend`または`label:frontend label: Discussion`            | 1つのラベル。複数回使用でき、`labels`と同じクエリで使用できます。 |
| labels    | `labels: frontend, Discussion, performance`                        | 複数のラベルをカンマで区切ったリスト。`label`と同じクエリで使用できます。 |
| milestone | `milestone: 18.1`                                                  | マイルストーンのタイトル（`%`なし）。 |
| scope     | `scope: created-by-me`、`scope: assigned-to-me`、または`scope: all`。 | 指定されたスコープに一致するイシューとマージリクエスト。値: `created-by-me`（デフォルト）、`assigned-to-me`、または`all`。 |
| title     | `title: discussions refactor`                                             | これらの単語に一致するタイトルまたは説明を持つイシューとマージリクエスト。フレーズを引用符で囲まないでください。 |

トークンの構文とガイドライン:

- 各トークン名の後にはコロン（`:`）が必要です（`label:`など）
  - コロンの前のスペース（`label :`）は無効であり、解析エラーが返されます。
  - トークン名の後のスペースはオプションです。`label: frontend`と`label:frontend`はいずれも有効です。
- `label`トークンと`labels`トークンは複数回使用でき、また組み合わせて使用​​できます。次のクエリは同じ結果を返します。
  - `labels: frontend discussion label: performance`
  - `label: frontend label: discussion label: performance`
  - `labels: frontend discussion performance`（結果として得られる結合クエリ）

1つの検索クエリで複数のトークンを組み合わせることができます。次に例を示します。

```plaintext
title: new merge request widget author: fatihacet assignee: jschatz1 labels: frontend, performance milestone: 17.5
```

この検索クエリは、以下を検索します。

- タイトル: `new merge request widget`
- 作成者: `fatihacet`
- 担当者: `jschatz1`
- ラベル: `frontend`と`performance`
- マイルストーン: `17.5`

## キーボードショートカットをカスタマイズする

**Accept Inline Suggestion**、**Accept Next Word Of Inline Suggestion**、または**Accept Next Line Of Inline Suggestion**に、別のキーボードショートカットを割り当てることができます。

1. VS Codeで`Preferences: Open Keyboard Shortcuts`コマンドを実行します。
1. 編集するショートカットを見つけ、**Change keybinding**（{{< icon name="pencil" >}}）を選択します。
1. 使用するショートカットを**Accept Inline Suggestion**、**Accept Next Word Of Inline Suggestion**、または**Accept Next Line Of Inline Suggestion**に割り当てます。
1. <kbd>Enter</kbd>キーを押して変更を保存します。

## 関連トピック

- [VS Code用GitLabワークフロー拡張機能のトラブルシューティング](troubleshooting.md)
- [GitLabワークフロー拡張機能をダウンロードする](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- 拡張機能の[ソースコード](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [GitLab Duoドキュメント](../../user/project/repository/code_suggestions/_index.md)
- [GitLab言語サーバーのドキュメント](../language_server/_index.md)
