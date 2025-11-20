---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabリモートURLの形式
---

VS Codeでは、Gitリポジトリをクローンしたり、読み取り専用モードで参照したりできます。

GitLabリモートリポジトリのURLには、次のパラメータが必要です:

- `instanceUrl`: `https://`または`http://`を含まないGitLabインスタンスURL。
  - GitLabインスタンスが[相対URLを使用している](../../install/relative_url.md)場合は、URLに相対URLを含めます。
  - たとえば、インスタンス`example.com/gitlab`上のプロジェクト`templates/ui`の`main`ブランチのURLは、`gitlab-remote://example.com/gitlab/<label>?project=templates/ui&ref=main`です。
- `label`: Visual Studio Codeがこのワークスペースフォルダーの名前として使用するテキスト:
  - これは、インスタンスURLの直後に表示される必要があります。
  - `/`や`?`などのエスケープされていないURLコンポーネントを含めることはできません。
  - `https://gitlab.com`など、ドメインルートにインストールされたインスタンスの場合、ラベルは最初のパス要素である必要があります。
  - リポジトリのルートを参照するURLの場合、ラベルは最後のパス要素である必要があります。
  - VS Codeは、ラベルの後に表示されるすべてのパス要素を、リポジトリ内のパスとして扱います。たとえば、`gitlab-remote://gitlab.com/GitLab/app?project=gitlab-org/gitlab&ref=master`は、GitLab.com上の`gitlab-org/gitlab`リポジトリの`app`ディレクトリを参照します。
- `projectId`: プロジェクトの数値ID（`5261717`など）またはネームスペース（`gitlab-org/gitlab-vscode-extension`）のいずれかです。インスタンスがリバースプロキシを使用している場合は、数値IDで`projectId`を指定します。詳細については、[issue 18775](https://gitlab.com/gitlab-org/gitlab/-/issues/18775)を参照してください。
- `gitReference`: リポジトリのブランチまたはコミットSHA。

パラメータは、次の順序でまとめられます:

```plaintext
gitlab-remote://<instanceUrl>/<label>?project=<projectId>&ref=<gitReference>
```

たとえば、main GitLabプロジェクトの`projectID`は`278964`なので、main GitLabプロジェクトのリモートURLは次のようになります:

```plaintext
gitlab-remote://gitlab.com/<label>?project=278964&ref=master
```

## Gitプロジェクトをクローンする {#clone-a-git-project}

GitLabワークフローは、`Git: Clone`コマンドパレットコマンドを拡張します。GitLabプロジェクトの場合、HTTPSまたはGit URLのいずれかを使用したクローンをサポートしています。

前提要件: 

- GitLabインスタンスから検索結果を返すには、そのGitLabインスタンスに[アクセストークンを追加](setup.md#authenticate-with-gitlab)する必要があります。
- 検索結果として返すには、プロジェクトのメンバーである必要があります。

GitLabプロジェクトを検索してからクローンするには:

1. コマンドパレットを押し開いてください:
   - MacOSの場合: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>。
   - Windows: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>。
1. **Git: Clone**コマンドを実行します。
1. リポジトリソースとしてGitHubまたはGitLabのいずれかを選択します。
1. **リポジトリ名**を検索して選択します。
1. リポジトリをクローンするローカルフォルダーを選択します。
1. GitLabリポジトリをクローンする場合は、クローン方法を選択します:
   - Gitでクローンするには、`user@hostname.com`で始まるURLを選択します。
   - HTTPSでクローンするには、`https://`で始まるURLを選択します。このメソッドは、アクセストークンを使用してリポジトリのクローンを作成し、コミットをフェッチし、コミットをプッシュします。
1. クローンされたリポジトリを開くか、現在のワークスペースに追加するかを選択します。

## 読み取り専用モードでリポジトリを参照する {#browse-a-repository-in-read-only-mode}

この拡張機能を使用すると、クローンを作成せずに、読み取り専用モードでGitLabリポジトリを参照できます。

前提要件: 

- そのGitLabインスタンスの[アクセストークンを登録](setup.md#authenticate-with-gitlab)しました。

読み取り専用モードでGitLabリポジトリを参照するには:

1. コマンドパレットを押し開いてください:
   - MacOSの場合: <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>。
   - Windows: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>。
1. **GitLab: Open Remoteリポジトリ**コマンドを実行します。
1. **Open in current window**（現在のウィンドウで開く）、**Open in new window**（新しいウィンドウで開く）、または**Add to workspace**（ワークスペースに追加） を選択します。
1. リポジトリを追加するには、`Enter gitlab-remote URL`を選択し、目的のプロジェクトの`gitlab-remote://` URLを入力します。
1. 既に追加したリポジトリを表示するには、**プロジェクトを選択する**を選択し、ドロップダウンリストから目的のプロジェクトを選択します。
1. ドロップダウンリストで、表示するGitブランチを選択し、<kbd>Enter</kbd>を押して確定します。

ワークスペースファイルに`gitlab-remote` URLを追加するには、VS Codeドキュメントの[ワークスペースファイル](https://code.visualstudio.com/docs/editor/multi-root-workspaces#_workspace-file)を参照してください。
