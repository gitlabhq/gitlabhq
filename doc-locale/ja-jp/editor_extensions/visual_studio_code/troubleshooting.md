---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab for VS Code拡張機能のトラブルシューティング
---

GitLab for VS Codeを使用する場合、次のイシューが発生する可能性があります。

問題が以下に記載されていない場合は、[サポートに必要な情報](#required-information-for-support)を収集し、[`gitlab-vscode-extension`イシュートラッカー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues)でバグを報告してください。

## ログ {#logs}

GitLab for VS Code拡張機能と、この拡張機能を強化するGitLab言語サーバーの両方が、トラブルシューティングを行うのに役立つログを提供します。

### デバッグログを有効にする {#enable-debug-logs}

デバッグロギングを有効にするには:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **Extensions** > **GitLab** > **その他**を選択します。
1. **GitLab: Debug**で、チェックボックスを選択してデバッグモードをオンにします。
1. ウィンドウをリロードして拡張機能を再起動します。
   1. コマンドパレットを開きます。
      - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
      - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   1. `Developer: Reload Window`と入力して<kbd>Enter</kbd>キーを押します。

### デバッグログを表示する {#view-debug-logs}

デバッグログを表示するには:

1. VS Codeで、**View** > **Output**を選択します。
1. 出力パネルの右上隅にあるドロップダウンリストで、**GitLab**または**GitLab Language Server**ログをフィルターします。
1. エラー、警告、接続の問題、または認証の問題がないか確認します。

## 認証 {#authentication}

次の認証エラーが発生する可能性があります。

### エラー: `...can't access the OS Keychain` {#error-cant-access-the-os-keychain}

macOSおよびUbuntuでは、拡張機能がOSキーチェーンにアクセスして認証することができない場合にエラーが発生することがあります。

例: 

```plaintext
The GitLab extension can't access the OS Keychain.
If you use Ubuntu, see this existing issue.
```

```plaintext
Error: Cannot get password
at I.$getPassword (vscode-file://vscode-app/snap/code/97/usr/share/code/resources/app/out/vs/workbench/workbench.desktop.main.js:1712:49592)
```

お使いのオペレーティングシステムに合わせて、以下の回避策を実行してください。

このエラーの詳細については、以下を参照してください:

- [拡張イシュー580](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/580)
- [アップストリーム`microsoft/vscode`イシュー147515](https://github.com/microsoft/vscode/issues/147515)

#### macOSの回避策 {#macos-workaround}

macOSでこのエラーを回避するには:

1. お使いのコンピューターで**Keychain Access**を開き、`vscodegitlab.gitlab-workflow`を検索します。
1. キーチェーンから`vscodegitlab.gitlab-workflow`を削除します。
1. <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押してコマンドパレットを開きます。
1. `GitLab: Remove Account from VS Code`と入力し、<kbd>Enter</kbd>を押して破損したアカウントをVS Codeから削除します。
1. 再度コマンドパレットを開き、`GitLab: Authenticate`を実行してアカウントを再度追加します。

#### Ubuntuの回避策 {#ubuntu-workaround}

Ubuntu 20.04および22.04で`snap`を使用してVS Codeをインストールする場合、VS CodeはOSキーチェーンからパスワードを読み取ることができません。拡張機能バージョン3.44.0以降では、安全なトークンストレージにOSキーチェーンを使用します。

VS Codeバージョン1.68.0以前を使用している場合は、次のいずれかの回避策を試してください:

- GitLab for VS Code拡張機能をバージョン3.43.1にダウングレードします。
- `snap`ではなく、`.deb`パッケージからVS Codeをインストールします:
  1. `snap` VS Codeをアンインストールします。
  1. [`.deb`パッケージ](https://code.visualstudio.com/Download)からVS Codeをインストールします。
  1. Ubuntuの**Password & Keys**に移動し、`vscodegitlab.workflow/gitlab-tokens`エントリを見つけて削除します。
  1. VS Codeで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押してコマンドパレットを開きます。
  1. `Gitlab: Remove Your Account`と入力し、<kbd>Enter</kbd>を押して、不足している認証情報を持つアカウントを削除します。
  1. 再度コマンドパレットを開き、`GitLab: Authenticate`を実行してアカウントを再度追加します。

VS Codeバージョン1.68.0以降を使用している場合は、再認証を試してください:

1. Ubuntuの**Password & Keys**に移動し、`vscodegitlab.workflow/gitlab-tokens`エントリを見つけて削除します。
1. VS Codeで、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押してコマンドパレットを開きます。
1. `Gitlab: Remove Your Account`と入力し、<kbd>Enter</kbd>を押して、不足している認証情報を持つアカウントを削除します。
1. 再度コマンドパレットを開き、`GitLab: Authenticate`を実行してアカウントを再度追加します。

### GDK使用時の接続および認可エラー {#connection-and-authorization-error-when-using-gdk}

VS CodeをGDKとともに使用している場合、システムがlocalhostで実行されているGitLabインスタンスへの安全なTLS接続を確立できないというエラーが表示されることがあります。

例えば、`127.0.0.1:3000`をGitLabサーバーとして使用している場合:

```plaintext
Request to https://127.0.0.1:3000/api/v4/version failed, reason: Client network
socket disconnected before secure TLS connection was established
```

このイシューは、GDKを`http`で実行しており、GitLabインスタンスが`https`でホストされている場合に発生します。

これを解決するには:

1. コマンドパレットを開きます。
   - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
   - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
1. `GitLab: Authenticate`と入力して<kbd>Enter</kbd>キーを押します。
1. 手動でインスタンスの`http` URLを入力するオプションを選択し、<kbd>Enter</kbd>を押します。
1. 残りのプロンプトに従って認証してください。

## プロジェクト設定 {#project-configuration}

次のプロジェクト設定エラーが発生する可能性があります。

### アカウントとプロジェクトの設定エラー {#account-and-project-configuration-errors}

VS Codeでプロジェクトを開くと、**GitLab**（{{< icon name="tanuki" >}}）タブのプロジェクト名の横にエラーメッセージが表示されることがあります。または、ステータスバーに複数のアカウントまたはプロジェクトに関する警告メッセージが表示される場合があります。

これらのメッセージは、拡張機能が使用するリポジトリ、アカウント、またはプロジェクトを特定できない場合に表示されます。

これらのエラーを解決するには:

- リモートが定義されていないか、複数のリモートが設定されている場合は、[あなたのリポジトリに接続する](setup.md#connect-to-your-repository)を参照してください。
- ステータスバーに**Multiple GitLab Accounts**が表示される場合は、[アカウントを切り替える](setup.md#switch-accounts)を選択します。
- ステータスバーに **（multiple projects）** が表示される場合は、[プロジェクトを選択する](setup.md#select-a-project)を選択します。

VS CodeでGitを初めて使用する場合は、[VS Codeのソース管理](https://code.visualstudio.com/docs/sourcecontrol/overview)を参照して、リポジトリとVS Codeワークスペースの初期化に関する情報を確認してください。これらはGitLab拡張機能の外部で実行されます。

#### SSHカスタムエイリアスを使用したGitリモート {#git-remote-with-ssh-custom-alias}

リポジトリのリモートがSSHカスタムエイリアスを使用している場合、拡張機能がリポジトリをGitLabプロジェクトに正しく照合できない可能性があります。例えば、リモートが`git@gitlab.com:group/project.git`の代わりに`git@my-work-gitlab:group/project.git`を使用している場合です。

この問題を解決するには、次の操作を実行します:

- リモートをHTTPを使用するように変更するか、カスタムエイリアスなしでSSHを使用するように変更します。
- 拡張機能でデフォルトのGitLab Duoネームスペースを設定します。

デフォルトのネームスペースを設定するには:

1. [プロジェクトが属するネームスペースを特定します](../../user/namespace/_index.md#determine-which-type-of-namespace-youre-in)。
1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
1. **GitLab › Duo Agent Platform: デフォルトネームスペース**に、ネームスペースを入力します。

### HTTPSプロジェクトのクローンは機能するが、SSHクローンは失敗する {#https-project-cloning-works-but-ssh-cloning-fails}

HTTPSクローンは機能するのに、SSHクローンエラーが発生することがあります。これは、SSH URLホストまたはパスがHTTPSパスと異なる場合に発生します。

GitLab for VS Code拡張機能は以下を使用します:

- 設定したアカウントに一致するホスト。
- ネームスペースとプロジェクト名を取得するためのパス。

例えば、VS Code拡張機能プロジェクトのURLは次のとおりです:

- SSH: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- HTTPS: `https://gitlab.com/gitlab-org/gitlab-vscode-extension.git`

両方とも`gitlab.com`ホストと`gitlab-org/gitlab-vscode-extension`パスを持っています。

このエラーを解決するには:

1. お使いのSSH URLが別のホストにあるか、パスに余分なセグメントが含まれているかを確認します。
1. どちらかに該当する場合は、GitリポジトリをGitLabプロジェクトに手動で割り当てます:
   1. VS Codeの左サイドバーで、**GitLab**（{{< icon name="tanuki" >}}）を選択します。
   1. `(no GitLab project)`とマークされたプロジェクトを選択し、**Manually assign GitLab project**を選択します: ![GitLabプロジェクトを手動で割り当てる](img/manually_assign_v15_3.png)
   1. リストから正しいプロジェクトを選択します。

このプロセスを簡素化する方法の詳細については、`gitlab-vscode-extension`プロジェクトの[イシュー577](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/577)を参照してください。

## ネットワークと接続性 {#network-and-connectivity}

次のネットワークおよび接続エラーが発生する可能性があります。

### エラー: プロキシによる`407 Access Denied`失敗 {#error-407-access-denied-failure-with-a-proxy}

認証済みプロキシを使用している場合、`407 Access Denied (authentication_failed)`エラーが発生することがあります。

例: 

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

このエラーを解決するには、GitLab言語サーバーの[プロキシ認証を有効にします](../language_server/_index.md#enable-proxy-authentication)。

### カスタム証明書に関するエラー {#errors-with-custom-certificates}

自己署名証明書など、カスタム証明書を使用してGitLabインスタンスに接続する場合、エラーが発生することがあります。

これらのエラーは、証明書が次の設定を使用している場合に発生することがあります:

| 設定名                     | 情報 |
|----------------------------------|-------------|
| `gitlab.ca`                      | 非推奨。自己署名CAのセットアップ方法の詳細については、[SSLセットアップガイド](ssl.md)を参照してください。|
| `gitlab.cert`                    | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。 |
| `gitlab.certKey`                 | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。 |
| `gitlab.ignoreCertificateErrors` | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。 |

解決するには、[カスタム認証局向けに拡張機能を設定する](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/user/custom-certificates.md)を参照してください。

### 期限切れのSSL証明書 {#expired-ssl-certificate}

誤った期限切れのSSL証明書エラーが発生することがあります。例: 

`API request failed - Error: certificate has expired`。

このエラーを解決するには、システム証明書を無効にします:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. **ユーザー**設定タブで、**アプリケーション** > **Proxy**を選択します。
1. **Proxy Strict SSL**および**System Certificates**の設定を無効にします。

## GitLab Duo {#gitlab-duo}

VS CodeでGitLab Duoを使用すると、次のイシューが発生することがあります。

### GitLab Duo機能が利用できない {#gitlab-duo-features-are-unavailable}

VS CodeでのGitLab Duoエラーをトラブルシューティングを行うには:

1. [前提条件](setup.md#configure-gitlab-duo)を満たし、必要な設定がオンになっていることを確認してください。
1. [管理者モードが無効になっている](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)ことを確認してください。
1. 診断出力を確認します:
   1. VS Codeでコマンドパレットを開きます。
      - macOSの場合、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します
      - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します
   1. `GitLab: Diagnostics`コマンドを実行し、失敗したチェックがないか出力を確認します。
1. 診断で機能がオンになっていないと示されている場合:
   1. VS Codeで、設定エディタを開きます:
      - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
      - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
   1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
   1. 不足している機能の**GitLab** › セクションを見つけ、チェックボックスを選択してオンにします。
1. 診断でAgentic Chatが現在のプロジェクトでサポートされていないと示されている場合は、[デフォルトのGitLab Duoネームスペース](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)を設定します。
1. 診断で、すべてのAgentic Chatのチェックがパスしているにもかかわらずパネルが表示されない場合は、[カスタムVS Codeレイアウト](https://code.visualstudio.com/docs/configure/custom-layout)に隠されている可能性があります。
   1. VS Codeでコマンドパレットを開きます。
      - macOSの場合、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します
      - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します
   1. `View: Show GitLab Duo Agent Platform`または`View: Toggle GitLab Duo Agent Platform`コマンドを実行します。

コード提案のサポートについては、[コード提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md#vs-code-troubleshooting)を参照してください。

### GitLab DuoがWebSocketエンドポイントの代わりに`HTTP/1.1`応答を返す {#gitlab-duo-returns-http11-responses-instead-of-websocket-endpoints}

ログにGitLab Duoからの`HTTP/1.1`応答が`/-/cable` WebSocketエンドポイントの代わりに表示されることがあります。

これは、GitLabインスタンスがWebSocket接続をブロックする場合に発生します。

このエラーを解決するには、ネットワーク管理者にGitLabインスタンスを変更して、[IDEクライアントからの受信WebSocket接続を許可する](../../administration/gitlab_duo/configure/_index.md#allow-inbound-connections-from-clients-to-the-gitlab-instance)ように依頼してください。

GitLab Duo Agent Platformへの接続がWebSocketエラー`1006`または`404`で失敗した場合は、[WebSocketエラー`1006`または`404`で接続が失敗する](../../user/duo_agent_platform/troubleshooting.md#connection-fails-with-websocket-error-1006-or-404)を参照してください。

### GitLab Duo Chatがリモート環境で初期化に失敗する {#gitlab-duo-chat-fails-to-initialize-in-remote-environments}

リモート開発環境（ブラウザベースのVS CodeやリモートSSH接続など）でGitLab Duo Chatを使用している場合、次のような初期化の失敗が発生することがあります:

- 空白または読み込まれないチャットパネル。
- ログ内のエラー。例えば`The webview didn't initialize in 10000ms`。
- 拡張機能がアクセスできないローカルURLに接続しようとします。

これらのエラーを解決するには:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押します。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押します。
1. 右上隅で **Open Settings（JSON）** を選択して、`settings.json`ファイルを編集します。
1. この設定を追加または変更します:

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. 変更を保存し、ウィンドウをリロードします:
   1. コマンドパレットを開きます。
      - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
      - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   1. `Developer: Reload Window`と入力して<kbd>Enter</kbd>キーを押します。

永続的な解決策の更新については、[イシュー #1944](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1944)および[イシュー #1943](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1943)を参照してください。

### GitLab Duoコマンドが失敗するか、無期限に実行される {#gitlab-duo-commands-fail-or-run-indefinitely}

IDEでGitLab Duo Agentic Chatまたはソフトウェア開発フローを使用すると、GitLab Duoがループにはまったり、コマンドの実行に問題が発生したりする可能性があります。

このイシューは、`Oh My ZSH!`や`powerlevel10k`などのShellテーマまたはインテグレーションを使用している場合に発生する可能性があります。GitLab Duoエージェントがターミナルを作成すると、Shellテーマまたはインテグレーションによってコマンドが正しく実行されないことがあります。

回避策として、以下に示す手順に従って、エージェントによって送信されるコマンドにシンプルなテーマを使用してください。

修正の詳細については、[イシュー2116](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2116)を参照してください。

#### `.zshrc`ファイルを編集する {#edit-your-zshrc-file}

VS Codeで、`Oh My ZSH!`または`powerlevel10k`を設定して、エージェントによって送信されるコマンドにシンプルなテーマを使用するようにします。IDEによって公開された環境変数を使用して、これらの値を設定できます。

`~/.zshrc`ファイルを編集し、次のコードを追加します:

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"
else
  # Oh My ZSH
  source $ZSH/oh-my-zsh.sh
  # Theme: Powerlevel10k
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # Other integrations like syntax highlighting
fi

# Other setup, like PATH variables
```

#### Bash Shellを編集する {#edit-your-bash-shell}

VS Codeで、Bashの高度なプロンプトをオフにすることができます。

`~/.bashrc`ファイルまたは`~/.bash_profile`ファイルを編集し、次のコードを追加します:

```shell
# ~/.bashrc or ~/.bash_profile

# Decide whether to load a full terminal environment,
# or keep it minimal for Agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"

  # Keep only essential settings for agents
  export PS1='\$ '  # Minimal prompt

else
  # Load full Bash environment

  # Custom prompt (e.g., Starship, custom PS1)
  if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  else
    # ... Add your own PS1 variable
  fi

  # Load additional integrations
fi

# Always load essential environment variables and aliases
```

## サポートに必要な情報 {#required-information-for-support}

サポートに連絡する前に、最新のGitLab for VS Code拡張機能がインストールされていることを確認してください。

最新のリリースは、[VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)の**Version History**タブで確認できます。

影響を受けるユーザーから次の情報を収集し、バグレポートに含めてください:

1. ユーザーに表示されたエラーメッセージ。
1. **GitLab**と**GitLab Language Server**の[ログ](#logs)。
1. 診断出力。
   1. コマンドパレットを開きます。
      - macOSの場合は、<kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>キーを押します。
      - WindowsまたはLinuxの場合、<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を押します。
   1. `GitLab: Diagnostics`と入力して<kbd>Enter</kbd>キーを押します。
   1. 拡張機能のバージョンをメモします。
1. システム詳細:
   - VS Codeで、**OS**の詳細:
     - macOSの場合、**コード** > **About Visual Studio Code**に移動し、**OS**を見つけます。
     - WindowsまたはLinuxの場合、**ヘルプ** > **GitLabについて**に移動し、**OS**を見つけます。
   - マシン仕様（CPU, RAM）: これらはお使いのマシンから提供してください。これらはIDEからはアクセスできません。
1. 影響のスコープを説明してください。何人のユーザーが影響を受けていますか？
1. エラーを再現する方法を説明してください。可能であれば、画面録画を含めてください。
1. 他のGitLab Duo機能がどのように影響を受けているか説明してください:
   - GitLab Quick Chatは機能していますか？
   - コード提案は機能していますか？
   - Web IDEのGitLab Duo Chatは応答を返しますか？
1. [GitLab for VS Code拡張機能の分離ガイド](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/814#step-2-extension-isolation-testing)で説明されているように、拡張機能の分離テストを実行します。他のすべての拡張機能を無効にする（またはアンインストールする）ことで、別の拡張機能がこのイシューを引き起こしているかどうかを判断してください。
