---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code用GitLab Workflow拡張機能の設定とコマンド。
title: GitLab Workflow拡張機能の設定とコマンド
---

VS Code用GitLab Workflow拡張機能は、VS Codeのコマンドパレットと統合し、既存のVS CodeとGitのインテグレーションを拡張し、設定オプションを提供します。

## コマンドパレットコマンド {#command-palette-commands}

この拡張機能は、[コマンドパレット](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)でトリガーできる一連のコマンドを提供します:

### プロジェクトとコードの管理 {#manage-projects-and-code}

- `GitLab: Authenticate`
- [`GitLab: Compare Current Branch with Default Branch`](_index.md#compare-with-default-branch): ブランチをリポジトリのデフォルトブランチと比較し、GitLabで変更を表示します。
- `GitLab: Open Current Project on GitLab`
- [`GitLab: Open Remote Repository`](remote_urls.md): リモートのGitLabリポジトリをブラウズします。
- `GitLab: Pipeline Actions - View, Create, Retry, or Cancel`
- `GitLab: Remove Account from VS Code`
- `GitLab: Validate GitLab Accounts`

### イシューとマージリクエストを管理する {#manage-issues-and-merge-requests}

- [`GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)`](_index.md#search-issues-and-merge-requests)
- `GitLab: Copy Link to Active File on GitLab`
- `GitLab: Create New Issue on Current Project`
- `GitLab: Create New Merge Request on Current Project`: マージリクエストページを開いて、マージリクエストを作成します。
- [`GitLab: Open Active File on GitLab`](_index.md#open-current-file-in-gitlab-ui) - GitLab上のアクティブなファイルを表示し、アクティブな行番号と選択されたテキストブロックを強調表示します。
- `GitLab: Open Merge Request for Current Branch`
- [`GitLab: Search Project Issues (Supports Filters)`](_index.md#search-issues-and-merge-requests)。
- [`GitLab: Search Project Merge Requests (Supports Filters)`](_index.md#search-issues-and-merge-requests)。
- `GitLab: Show Issues Assigned to Me`: GitLabであなたに割り当てられたイシューを開きます。
- `GitLab: Show Merge Requests Assigned to Me`: GitLabであなたに割り当てられたマージリクエストを開きます。

### CI/CDパイプラインの管理 {#manage-cicd-pipelines}

- [`GitLab: Show Merged GitLab CI/CD Configuration`](cicd.md#show-merged-gitlab-cicd-configuration): すべてのincludeが解決されたGitLab CI/CD設定ファイル`.gitlab-ci.yml`のプレビューを表示します。
- [`GitLab: Validate GitLab CI/CD Configuration`](cicd.md#test-gitlab-cicd-configuration): `.gitlab-ci.yml`のGitLab CI/CDの設定ファイルをテストします。

### AI機能 {#ai-assisted-features}

- `GitLab: Restart GitLab Language Server`
- `GitLab: Show Duo Workflow`
- `GitLab: Toggle Code Suggestions`
- `GitLab: Toggle Code Suggestions for current language`

### その他の機能 {#other-features}

- `GitLab: Apply Snippet Patch`
- `GitLab: Clone Wiki`
- [`GitLab: Create Snippet`](_index.md#create-a-snippet): ファイル全体または選択範囲から、公開、内部、またはプライベートスニペットを作成します。
- [`GitLab: Create Snippet Patch`](_index.md#create-a-patch-file): ファイル全体または選択範囲から、`.patch`ファイルを作成します。
- [`GitLab: Insert Snippet`](_index.md#insert-a-snippet): シングルファイルまたはマルチファイルプロジェクトスニペットを挿入します。
- `GitLab: Publish Workspace to GitLab`
- `GitLab: Refresh Sidebar`
- `GitLab: Show Extension Logs`
- `GitLab: View Security Finding Details`
- `GitLab Workflow: Focus on For current branch View`
- `GitLab Workflow: Focus on Issues and Merge Requests View`
- `GitLab: Diagnostics`: GitLab Workflow拡張機能の詳細設定ページを開きます。

## コマンドインテグレーション {#command-integrations}

この拡張機能は、VS Codeによって提供されるいくつかのコマンドとも統合されています:

- `Git: Clone`: セットアップしたすべてのGitLabインスタンスのプロジェクトを検索してクローンします。詳細については、以下を参照してください:
  - [GitLabプロジェクトをクローンする](remote_urls.md#clone-a-git-project)拡張機能ドキュメント。
  - [リポジトリのクローン](https://code.visualstudio.com/docs/sourcecontrol/overview#_cloning-a-repository) VS Codeドキュメント。
- `Git: Add Remote...`: セットアップしたすべてのGitLabインスタンスから、既存のプロジェクトをリモートとして追加します。

## 拡張機能設定 {#extension-settings}

VS Codeで設定を変更する方法については、[ユーザーとワークスペースの設定](https://code.visualstudio.com/docs/configure/settings)に関するVS Codeドキュメントを参照してください。

自己署名証明書を使用してGitLabインスタンスに接続する場合は、コミュニティがコントリビュートした[自己署名証明書の設定](troubleshooting.md#configure-self-signed-certificates)をお読みください。

| 設定 | デフォルト | 情報 |
| ------- | ------- | ----------- |
| `gitlab.customQueries` | 該当なし | GitLabパネルに表示される項目を取得する検索クエリを定義します。詳細については、[カスタムクエリドキュメント](custom_queries.md)を参照してください。 |
| `gitlab.authentication.oauthClientIds` | 該当なし | [セットアップ](setup.md#authenticate-with-gitlab)時に(GitLabインスタンスURL別)に使用するOAuthクライアントID。 |
| `gitlab.debug` | いいえ | `true`の場合、デバッグモードが有効になります。拡張機能はソースマップを使用して縮小されたコードを理解するため、デバッグモードではエラースタックトレースが改善されます。デバッグモードでは、[拡張機能ログ](troubleshooting.md#view-log-files)にもデバッグログメッセージが表示されます。 |
| `gitlab.duo.enabledWithoutGitlabProject` | はい | `true`の場合、拡張機能がプロジェクトの`duoFeaturesEnabledForProject`設定を取得できない場合、GitLab Duo機能は有効のままになります。`false`の場合、拡張機能がプロジェクトの`duoFeaturesEnabledForProject`設定を取得できない場合、すべてのGitLab Duo機能は無効になります。[`duoFeaturesEnabledForProject`設定](#duofeaturesenabledforproject)を参照してください。 |
| `gitlab.duoAgentPlatform.defaultNamespace` | 該当なし | 拡張機能がGitLabプロジェクトの詳細を取得できない場合のGitLab Duoエージェントプラットフォームのデフォルトのグループまたはネームスペースパス。 |
| `gitlab.duoCodeSuggestions.additionalLanguages` | 該当なし | （試験運用）。コード提案の[正式にサポートされている言語](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages-by-ide)のリストを展開するには、[言語識別子](https://code.visualstudio.com/docs/languages/identifiers#_known-language-identifiers)の配列を指定します。追加された言語のコード提案の品質は最適ではない可能性があります。 |
| `gitlab.duoCodeSuggestions.enabled` | はい | `true`の場合、AIコード提案が有効になります。 |
| `gitlab.duoCodeSuggestions.enabledSupportedLanguages` | 該当なし | コード提案を有効にする[サポートされている言語](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages-by-ide)。デフォルトでは、サポートされているすべての言語が有効になっています。 |
| `gitlab.duoCodeSuggestions.openTabsContext` | はい | `true`の場合、コード提案を改善するために、開いているタブ間でコンテキストの送信が有効になります。 |
| `gitlab.keybindingHints.enabled` | はい | GitLab Duoのキーバインドヒントを有効にします。 |
| `gitlab.pipelineGitRemoteName` | null | パイプラインを含むGitLabリポジトリに対応するGitリモート名の名前。`null`または空の場合、拡張機能は非パイプライン機能と同じリモートを使用します。 |
| `gitlab.showPipelineUpdateNotifications` | いいえ | `true`の場合、パイプラインが完了するとアラートが表示されます。 |

### `duoFeaturesEnabledForProject` {#duofeaturesenabledforproject}

次の場合、`duoFeaturesEnabledForProject`設定は利用できません:

- プロジェクトが拡張機能でセットアップされていません。
- プロジェクトが現在のアカウントとは異なるGitLabインスタンスにあります。
- 作業しているファイルまたはフォルダーは、アクセスできるGitLabプロジェクトの一部ではありません。
