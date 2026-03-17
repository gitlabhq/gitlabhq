---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab for VS Code拡張機能を使用して、IDEでGitLabプロジェクトを直接操作します。
title: VS Codeでプロジェクトを操作する
---

GitLab for VS Code拡張機能を使用して、GitLabプロジェクトを操作します:

- イシューで作業を計画し追跡する。
- GitLab DuoをAIネイティブな計画とコーディングに利用します。
- マージリクエストの変更点をレビューし、議論します。
- ブランチを比較し、GitLabでファイルを表示します。
- コードをスニペットで保存共有します。

この拡張機能を使用すると、これらのタスクの多くをVS Codeで直接完了できます。その他の場合、拡張機能はブラウザでGitLabを開きます。

## 前提条件 {#prerequisites}

- 拡張機能を[認証する](setup.md#connect-to-gitlab)。GitLab上のリポジトリに接続します。
- GitLab Duoについては、[設定要件](setup.md#configure-gitlab-duo)を確認してください。

## 作業中にGitLab Duoを使用する {#use-gitlab-duo-as-you-work}

GitLab for VS Code拡張機能を使用すると、プロジェクトでの作業中にGitLab Duo Agent PlatformとGitLab Duo (Classic) にアクセスできます。

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

GitLab Duo Chat (エージェント型)、エージェント、およびフローを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}) を選択します。
1. GitLab Duo Chatと対話するには、チャットタブを選択し、プロンプトを入力します。
1. エージェントと連携するには、チャットタブを選択し、**New chat** ({{< icon name="duo-chat-new" >}}) ドロップダウンリストを使用して、基本的なエージェントまたはカスタムエージェントを選択します。
1. ソフトウェア開発フローを使用するには、フロータブを選択し、プロンプトを入力します。

GitLab Duoのコード提案を使用するには:

1. 下部のステータスバーで、**Duo** ({{< icon name="tanuki-ai" >}}) を選択して機能のステータスを確認します。
1. コードを作成する際に、インラインコード提案をレビューして受け入れます。

### GitLab Duo（クラシック） {#gitlab-duo-classic}

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo Chat (Classic) を使用するには:

1. 左側のサイドバーで、**GitLab Duo Chat** ({{< icon name="duo-chat" >}}) を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

GitLab Duoのコード提案 (Classic) を使用するには:

1. 下部のステータスバーで、**Duo** ({{< icon name="tanuki-ai" >}}) を選択して機能のステータスを確認します。
1. コードを作成する際に、インラインコード提案をレビューして受け入れます。

## イシューを作成する {#create-an-issue}

現在のプロジェクトでイシューを作成するには:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Create New Issue on Current Project**と入力し、<kbd>Enter</kbd>を押します。

GitLabは、デフォルトのブラウザで**新規イシュー**ページを開きます。

## マージリクエストを作成する {#create-a-merge-request}

現在のプロジェクトでマージリクエストを作成するには、下部のステータスバーで**Create MR** ({{< icon name="merge-request-open" >}}) を選択します。

または、コマンドパレットを使用することもできます:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Create New Merge Request on Current Project**と入力し、<kbd>Enter</kbd>を押します。

GitLabは、デフォルトのブラウザで**新しいマージリクエスト**ページを開きます。

## イシューとマージリクエストを表示する {#view-issues-and-merge-requests}

特定のプロジェクトのイシューとマージリクエストを表示するには、次の手順に従います。

1. VS Codeの左側のサイドバーで、**GitLab** ({{< icon name="tanuki" >}}) を選択します。
1. イシューおよびマージリクエストセクションを展開する。
1. プロジェクトを選択して展開する。
1. 項目の一覧をレビューするには、以下のいずれかのオプションを選択します:
   - **Issues assigned to me（自分に割り当てられたイシュー）**
   - **Issues created by me（自分が作成したイシュー）**
   - **Merge requests assigned to me（自分に割り当てられたマージリクエスト）**
   - **Merge requests I'm reviewing（自分がレビュー中のマージリクエスト）**
   - **Merge requests created by me（自分が作成したマージリクエスト）**
   - **All project merge requests（プロジェクトのすべてのマージリクエスト）**
   - Your custom queries（自分の[カスタムクエリ](custom_queries.md)）
1. イシューまたはマージリクエストを選択すると、新しいVS Codeタブで開きます。

## イシューとマージリクエストを検索する {#search-issues-and-merge-requests}

フィルタリングされた検索または[高度な検索](../../integration/advanced_search/elasticsearch.md)を使用して、VS Codeからプロジェクトのイシューおよびマージリクエストを直接検索します。フィルター検索では、定義済みのトークンを使用して検索結果を絞り込みます。高度な検索により、GitLabインスタンス全体でより高速かつ効率的な検索が可能です。

前提条件: 

- GitLabプロジェクトのメンバーであること。

プロジェクトを検索するには:

1. VS Codeでコマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. 希望する検索タイプを選択します:
   - **GitLab: Search Project Issues (Supports Filters)**
   - **GitLab: Search Project Merge Requests (Supports Filters)**
   - **GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)**
1. プロンプトに従って検索値を入力し、検索を絞り込みます。

GitLabがブラウザタブで結果を開きます。

### 検索結果をフィルタリングするためのトークン {#tokens-to-filter-search-results}

大規模なプロジェクトで検索する際は、フィルターを追加するとより適切な結果が得られます。この拡張機能は、マージリクエストとイシューをフィルタリングするための次のトークンをサポートしています。

| トークン     | 例                                                 | 説明 |
|-----------|---------------------------------------------------------|-------------|
| assignee  | `assignee: sjones`                                      | 担当者のユーザー名（`@`なし）。 |
| author    | `author: zwei`                                          | 作成者のユーザー名（`@`なし）。 |
| label     | `label: frontend`または`label:frontend label: Discussion` | 1つのラベル。複数回使用でき、同じクエリで`labels`と併用できます。 |
| labels    | `labels: frontend, Discussion, performance`             | 複数のラベルのカンマ区切りリスト。同じクエリで`label`と併用できます。 |
| milestone | `milestone: 18.1`                                       | マイルストーンのタイトル（`%`なし）。 |
| scope     | `scope: created-by-me`                                  | イシューまたはマージリクエストのスコープ。値: `created-by-me`（デフォルト）、`assigned-to-me`、または`all`。 |
| title     | `title: discussions refactor`                           | タイトルまたは説明で一致する単語。フレーズの周りに引用符を追加しないでください。 |

トークンの構文とガイドライン:

- 各トークン名の後にはコロン（`:`）が必要です（例: `label:`）。
  - コロンの前にスペースを入れる（`label :`）と無効になり、解析エラーが返されます。
  - トークン名の後のスペースは省略可能です。`label: frontend`と`label:frontend`はいずれも有効です。
- `label`トークンと`labels`トークンは複数回使用でき、また組み合わせて使用することも​​できます。次のクエリはいずれも同じ結果を返します。
  - `labels: frontend discussion label: performance`
  - `label: frontend label: discussion label: performance`
  - `labels: frontend discussion performance`（最終的に得られる結合クエリ）

1つの検索クエリで複数のトークンを組み合わせることができます。例: 

```plaintext
title: new merge request widget author: zwei assignee: sjones labels: frontend, performance milestone: 17.5
```

この検索クエリは、次の条件に一致するものを探します。

- タイトル: `new merge request widget`
- 作成者: `zwei`
- 担当者: `sjones`
- ラベル: `frontend`と`performance`
- マイルストーン: `17.5`

## マージリクエストをレビューする {#review-a-merge-request}

VS Codeでマージリクエストをレビューし、コメントし、承認するには:

1. 左側のサイドバーで、**GitLab** ({{< icon name="tanuki" >}}) を選択します。
1. イシューおよびマージリクエストセクションを展開し、プロジェクトを選択します。
1. レビューするマージリクエストを選択します。
1. マージリクエストの番号とタイトルの下にある**概要**を選択して、マージリクエストの詳細を確認します。
1. 提案されたファイルの変更をレビューするには、リストからファイルを選択してVS Codeタブに表示します。GitLabは、差分コメントをタブ内にインライン表示します。リストでは、削除されたファイルは赤色で表示されます。

   ![このマージリクエストで変更されたファイルと変更タイプのアルファベット順リスト](img/vscode_view_changed_file_v17_6.png)

差分を使用して次の操作を行います。

- ディスカッションをレビューおよび作成する。
- ディスカッションを解決および再オープンする。
- 個々のコメントを削除および編集する。

## クイックアクションを使用する {#use-quick-actions}

イシューおよびマージリクエストで[GitLabクイックアクション](../../user/project/quick_actions.md)を使用するには:

1. VS Codeでイシューまたはマージリクエストを表示するための手順に従います。
1. コメントセクションを見つけるには、下にスクロールします。
1. 新しいコメントにクイックアクションを入力し、<kbd>Enter</kbd>を押します。たとえば、イシューに`bug`ラベルを追加するには、`/label bug`と入力します。

## デフォルトブランチと比較する {#compare-with-default-branch}

マージリクエストを作成せずに、自分のブランチをプロジェクトのデフォルトブランチと比較するには、次の手順に従います。

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Compare Current Branch with Default Branch**と入力し、<kbd>Enter</kbd>を押します。

拡張機能が新しいブラウザタブを開き、自分のブランチの最新コミットと、プロジェクトのデフォルトブランチの最新コミットの差分を表示します。

## GitLab UIで現在のファイルを開く {#open-current-file-in-gitlab-ui}

現在のGitLabプロジェクトのファイルをGitLab UIで開き、特定の行を強調表示するには、次の手順に従います。

1. VS Codeで目的のファイルを開きます。
1. 強調表示する行を選択します。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Open Active File on GitLab**と入力し、<kbd>Enter</kbd>を押します。

## スニペットを作成する {#create-a-snippet}

[スニペット](../../user/snippets.md)を作成して、コードやテキストの一部を保存し、他のユーザーと共有できます。スニペットは、選択範囲またはファイル全体を指定して作成できます。

VS Codeでスニペットを作成するには、次の手順に従います。

1. スニペットの内容を選択します。
   - ファイル全体を使用してスニペットを作成するには、ファイルを開きます。
   - ファイルの一部の選択範囲を使用してスニペットを作成するには、ファイルを開き、含める行を選択します。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Create Snippet**と入力し、<kbd>Enter</kbd>を押します。
1. スニペットのプライバシーレベルを選択します。
   - **Private**（非公開）スニペットは、プロジェクトメンバーのみに表示されます。
   - **Public**（公開）スニペットは、すべてのユーザーに表示されます。
1. スニペットのスコープを選択します。
   - **Snippet from file**（ファイルからスニペット）を作成する場合は、アクティブなファイル全体の内容を使用します。
   - **Snippet from selection**（選択範囲からスニペット）を作成する場合は、アクティブなファイルで選択した行を使用します。

GitLabは、新しいブラウザタブで新しいスニペットのページを開きます。

### パッチファイルを作成する {#create-a-patch-file}

マージリクエストをレビューするとき、複数のファイルにわたる変更を提案する場合は、スニペットパッチを作成します。

1. ローカルマシンで、変更を提案するブランチをチェックアウトします。
1. VS Codeで、変更するすべてのファイルを編集します。変更をコミットしないでください。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. コマンドパレットで**GitLab: Command PaletteでGitLab: Create Snippet Patch**と入力し、<kbd>Enter</kbd>を押します。このコマンドは`git diff`コマンドを実行し、プロジェクト内にGitLabスニペットを作成します。
1. **Patch name**（パッチ名）を入力し、<kbd>Enter</kbd>キーを押します。GitLabはこの名前をスニペットのタイトルとして使用し、拡張子`.patch`が付加されたファイル名に変換します。
1. スニペットのプライバシーレベルを選択します。
   - **Private**（非公開）スニペットは、プロジェクトメンバーのみに表示されます。
   - **Public**（公開）スニペットは、すべてのユーザーに表示されます。

VS Codeは、新しいブラウザタブでスニペットパッチを開きます。スニペットパッチの説明には、パッチを適用する手順が記載されています。

### スニペットを挿入する {#insert-a-snippet}

メンバーになっているプロジェクトから既存の単一ファイルまたは[複数ファイル](../../user/snippets.md#add-or-remove-multiple-files)のスニペットを挿入するには、次の手順に従います。

1. スニペットを挿入する位置にカーソルを置きます。
1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. **GitLab: Command PaletteでGitLab: Insert Snippet**と入力し、<kbd>Enter</kbd>を押します。
1. スニペットを含むプロジェクトを選択します。
1. 適用するスニペットを選択します。
1. 複数ファイルのスニペットの場合は、適用するファイルを選択します。

## 関連トピック {#related-topics}

- [VS Code拡張機能のCI/CDパイプライン](cicd.md)
- [VS Code向けGitLabでアプリケーションを保護する](security_scanning.md)
- [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)
- [GitLab Duo（クラシック）](../../user/gitlab_duo/feature_summary.md)
