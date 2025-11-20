---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code用GitLab Workflow拡張機能を使用すると、一般的なGitLabタスクをVS Codeで直接処理できます。
title: VS Code用のGitLab Workflow extension for VS Codeをインストールして設定する
---

をインストールするには、次のようにします:

- [Visual Studio Marketplaceに移動](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)して、拡張機能をインストールして有効にします。
- VS Codeの非公式バージョンを使用している場合は、[Open VSXレジストリ](https://open-vsx.org/extension/GitLab/gitlab-workflow)から拡張機能をインストールします。

## GitLabに接続する {#connect-to-gitlab}

拡張機能をダウンロードしてインストールしたら、GitLabアカウントに接続します。

### GitLabに対して認証する {#authenticate-with-gitlab}

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. `GitLab: Authenticate`と入力して<kbd>Enter</kbd>キーを押します。
1. オプションからGitLabインスタンスのURLを選択するか、手動で入力します。
   - 手動で入力する場合は、**URL to GitLab instance**（GitLabインスタンスのURL）に、`http://`または`https://`を含む完全なURLを貼り付けます。確認するには、<kbd>Enter</kbd>を押します。
1. 以下を使用してGitLabに対して認証します:
   - [認証の設定](#authentication)後のOAuthログイン。
   - 新規[パーソナルアクセストークン](#create-a-personal-access-token)。

この拡張機能は、GitリポジトリのリモートURLを、トークンに指定したGitLabインスタンスURLと照合します。複数のアカウントまたはプロジェクトがある場合は、使用するアカウントまたはプロジェクトを選択できます。詳細については、[VS CodeでGitLabアカウントを切り替える](_index.md#switch-gitlab-accounts-in-vs-code)を参照してください。

### リポジトリに接続 {#connect-to-your-repository}

VS CodeからGitLabリポジトリに接続するには、次の手順を実行します:

1. VS Codeの上部メニューで、**ターミナル** > **New Terminal**（新しいターミナル）を選択します。
1. リポジトリをクローンします: `git clone <repository>`。
1. リポジトリがクローンされたディレクトリに変更し、ブランチをチェックアウトします: `git checkout <branch_name>`。
1. プロジェクトが選択されていることを確認します:
   1. 左側のサイドバーで、**GitLab Workflow**（GitLab Workflow） ({{< icon name="tanuki" >}})を選択します。
   1. プロジェクト名を選択します。複数のプロジェクトがある場合は、作業するプロジェクトを1つ選択します。
1. ターミナルで、リポジトリがリモートで設定されていることを確認します: `git remote -v`。結果は次のようになります:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   リモートが定義されていない場合、または複数のリモートがある場合:

   1. 左側のサイドバーで、**Source Control**（ソース管理）（{{< icon name="branch" >}}）を選択します。
   1. [ソース管理] **Source Control**（ソース管理） ラベルで右クリックし、**リポジトリ**を選択します。
   1. リポジトリの横にある省略記号({{< icon name=ellipsis_h >}})を選択し、次に**リモート** > **Add Remote**（リモートの追加） を選択します。
   1. **Add remote from GitLab**（GitLabからリモートを追加）を選択します。
   1. リモートを選択します。

次の両方の場合、拡張機能はVS Codeステータスバーに情報を表示します:

- プロジェクトに最後のコミットのパイプラインがある。
- 現在のブランチがマージリクエストに関連付けられている。

## 拡張機能を設定する {#configure-the-extension}

設定を構成するには、**設定** > **Extensions**（拡張機能） > **GitLab Workflow**に移動します。設定は、ユーザーまたはワークスペースレベルで構成できます。

デフォルトでは、コード提案とGitLab Duoチャットが有効になっているため、GitLab Duoアドオンがあり、シートが割り当てられている場合は、アクセスできるはずです。

### 認証 {#authentication}

personal access tokenを使用するか、OAuthアプリケーションを介してログインして認証します。

#### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

GitLab Self-ManagedまたはGitLab Dedicatedを使用している場合は、personal access tokenを作成してください。

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. 名前、説明、有効期限を入力します。
1. `api`スコープを選択します。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

#### OAuthアプリケーションを使用する {#use-an-oauth-application}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab Workflow 6.47.0で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2738)。

{{< /history >}}

OAuth認証を使用するには、次のいずれかのクライアントIDを知っている必要があります:

- インスタンスの管理者が管理するインスタンス全体のOAuthアプリケーション。
- グループオーナーが管理するグループ全体のOAuthアプリケーション。
- 自身で管理するユーザーOAuthアプリケーション。

OAuthアプリケーションログインを構成するには:

1. コマンドパレットを開きます:
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合は、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
1. `Preferences: Open User Settings`と入力して<kbd>Enter</kbd>キーを押します。
1. **設定** > **Extensions**（拡張機能） > **GitLab Workflow** > **認証**を選択します。
1. **OAuth Client IDs**（OAuthクライアントID）で、**Add Item**（項目の追加）を選択します。
1. **キー**を選択し、GitLabインスタンスのURLを入力します。
1. **値**を選択し、OAuthアプリケーションのクライアントIDを入力します。

### コードセキュリティ {#code-security}

コードセキュリティ設定を構成するには、**設定** > **Extensions**（拡張機能） > **GitLab Workflow** > **Code Security**（コードセキュリティ）に移動します。

- アクティブなファイルの静的アプリケーションセキュリティテストスキャンを有効にするには、**Enable Real-time SAST scan**（リアルタイム静的アプリケーションセキュリティテストスキャンを有効にする）チェックボックスを選択します。
- オプション。保存時にアクティブなファイルの静的アプリケーションセキュリティテストスキャンを有効にするには、**Enable scanning on file save**（ファイル保存時にスキャンを有効にする）チェックボックスを選択します。

### 拡張機能のプレリリース版をインストールする {#install-pre-release-versions-of-the-extension}

GitLabは、拡張機能のプレリリースビルドをVS Code Extension Marketplaceに公開しています。

プレリリースビルドをインストールするには:

1. VS Codeを開きます。
1. **Extensions**（拡張機能） > **GitLab Workflow**で、**Switch to Pre-release Version**（プレリリースバージョンに切り替える）を選択します。
1. **Restart Extensions**（拡張機能を再起動）を選択します。
   1. または、**Reload Window**（ウィンドウを更新）して、更新後に古くなったWebビューを更新します。
