---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: VS Code用GitLab Workflow拡張機能のトラブルシューティング
---

GitLab Workflow拡張機能（VS Code用）で問題が発生した場合、または機能リクエストがある場合は、以下をお試しください:

1. 既知のイシューと解決策については、[拡張機能のドキュメント](_index.md)を確認してください。
1. バグの報告や機能のリクエストは、[`gitlab-vscode-extension`イシュートラッカー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues)で行ってください。[サポートに必要な情報](#required-information-for-support)を提供してください。

VS Code向けGitLab Duoコード提案のトラブルシューティングについては、[VS Code向けコード提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md#vs-code-troubleshooting)を参照してください。

## デバッグログを有効にする {#enable-debug-logs}

VS Code拡張機能とGitLab言語サーバーはどちらも、トラブルシューティングに役立つログファイルを提供します。デバッグログを有効にするには、次の手順に従います:

1. VS Codeで、上部のバーにある**コード** > **設定** > **設定**に移動します。
1. 右上隅で、**Open Settings (JSON)**（設定を開く（JSON））を選択して、`settings.json`ファイルを編集します。
1. この行を追加するか、すでに存在する場合は編集します:

   ```json
   "gitlab.debug": true,
   ```

1. 変更を保存します。

### ログファイルを表示する {#view-log-files}

VS Code拡張機能またはGitLab言語サーバーからデバッグログを表示するには:

1. コマンド`GitLab: Show Extension Logs`を使用して、出力パネルを表示します。
1. 出力パネルの右上隅にあるドロップダウンリストから、**GitLab Workflow**（GitLab Workflow）または**GitLab Language Server**（GitLab言語サーバー）のいずれかを選択します。

## エラー: プロキシを使用した`407 Access Denied`の失敗 {#error-407-access-denied-failure-with-a-proxy}

認証済みプロキシを使用している場合は、`407 Access Denied (authentication_failed)`のようなエラーが発生する可能性があります:

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

GitLab言語サーバーの[プロキシ認証を有効にする](../language_server/_index.md#enable-proxy-authentication)必要があります。

## 自己署名証明書の設定 {#configure-self-signed-certificates}

自己署名認証局を使用してGitLabインスタンスに接続するには、これらの設定を使用して設定します。GitLabチームはパブリック認証局を使用しているため、これらの設定はコミュニティのコントリビュートです。どのフィールドも必須ではありません。

前提要件: 

- VS Codeで[`http.proxy`設定](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support)を使用していません。詳細については、[issue 314](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/314)を参照してください。

| 設定名 | デフォルト | 情報 |
| ------------ | :-----: | ----------- |
| `gitlab.ca`  | null    | 非推奨。自己署名認証局を設定する方法の詳細については、[SSL設定ガイド](ssl.md)を参照してください。 |
| `gitlab.cert`| null    | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。GitLab Self-Managedでカスタム証明書またはキーペアが必要な場合は、証明書ファイルを指すようにこのオプションを設定します。`gitlab.certKey`を参照してください。 |
| `gitlab.certKey`| null    | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。GitLab Self-Managedでカスタム証明書またはキーペアが必要な場合は、証明書キーファイルを指すようにこのオプションを設定します。`gitlab.cert`を参照してください。 |
| `gitlab.ignoreCertificateErrors` | いいえ   | サポートされていません。[エピック6244](https://gitlab.com/groups/gitlab-org/-/epics/6244)を参照してください。SSL証明書なしでGitLab Self-Managedを使用する場合、または拡張機能の使用を妨げる証明書の問題がある場合は、このオプションを`true`に設定して証明書エラーを無視します。 |

## SSL証明書の期限切れ {#expired-ssl-certificate}

場合によっては、証明書が誤って期限切れとして分類されることがあります。これにより、エラー`API request failed - Error: certificate has expired`が発生する可能性があります。この問題が発生した場合は、システム証明書のVS Codeサポートを無効にできます。

システム証明書を無効にするには:

1. VS Codeで、上部のバーにある**コード** > **設定** > **設定**に移動します。
1. **ユーザー**設定タブで、**Application**（アプリケーション） > **Proxy**（プロキシ）を選択します。
1. **Proxy Strict SSL**（プロキシ厳密SSL）と**System Certificates**（システム証明書）の設定を無効にします。

## HTTPSプロジェクトのクローン作成は機能するが、SSHのクローン作成は失敗する {#https-project-cloning-works-but-ssh-cloning-fails}

この問題は、SSH URLのホストまたはパスがHTTPSパスと異なる場合にVS Codeで発生します。GitLab Workflow拡張機能では、以下を使用します:

- 設定したアカウントと一致するホスト。
- ネームスペースとプロジェクト名を取得するパス。

たとえば、VS Code拡張機能のURLは次のとおりです:

- SSH: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- HTTPS: `https://gitlab.com/gitlab-org/gitlab-vscode-extension.git`

どちらも`gitlab.com`と`gitlab-org/gitlab-vscode-extension`のパスを持ちます。

この問題を解決するには、SSH URLが別のホスト上にあるかどうか、またはパスに追加のセグメントがあるかどうかを確認してください。どちらかが当てはまる場合は、GitリポジトリをGitLabプロジェクトに手動で割り当てできます:

1. VS Codeの左側のサイドバーで、**GitLab Workflow**（GitLab Workflow）（{{< icon name="tanuki" >}}）を選択します。
1. `(no GitLab project)`とマークされたプロジェクトを選択し、**Manually assign GitLab project**（GitLabプロジェクトを手動で割り当て）を選択します: ![GitLabプロジェクトを手動で割り当て](img/manually_assign_v15_3.png)
1. リストから正しいプロジェクトを選択します。

このプロセスを簡素化する方法の詳細については、`gitlab-vscode-extension`プロジェクトの[イシュー577](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/577)を参照してください。

## 既知のイシュー: リモート環境でGitLab Duoチャットが初期化に失敗する {#known-issue-gitlab-duo-chat-fails-to-initialize-in-remote-environments}

リモート開発環境（ブラウザベースのVS CodeやリモートSSH接続など）でGitLab Duoチャットを使用すると、次のような初期化の失敗が発生する可能性があります:

- 空白またはロードされないチャットパネル。
- ログファイルのエラー: `The webview didn't initialize in 10000ms`。
- 拡張機能がアクセスできないローカルURLに接続しようとしています。

これらの問題を解決するには:

1. VS Codeで、上部のバーにある**コード** > **設定** > **設定**に移動します。
1. 右上隅で、**Open Settings (JSON)**（設定を開く（JSON））を選択して、`settings.json`ファイルを編集します。
   - または、<kbd>F1</kbd>キーを押し、**環境設定を入力します: 設定を開く（JSON）**を選択します。
1. この設定を追加または変更します:

   ```json
   "gitlab.featureFlags.languageServerWebviews": false
   ```

1. 変更を保存して、VS Codeをリロードします。

恒久的な解決策の更新については、[イシュー #1944](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1944)と[イシュー #1943](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1943)を参照してください

## エラー: `can't access the OS Keychain` {#error-cant-access-the-os-keychain}

このようなエラーメッセージは、macOSとUbuntuの両方で発生する可能性があります:

```plaintext
GitLab Workflow can't access the OS Keychain.
If you use Ubuntu, see this existing issue.
```

```plaintext
Error: Cannot get password
at I.$getPassword (vscode-file://vscode-app/snap/code/97/usr/share/code/resources/app/out/vs/workbench/workbench.desktop.main.js:1712:49592)
```

これらのエラーの詳細については、以下を参照してください:

- [拡張機能のイシュー580](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/580)
- [アップストリーム`microsoft/vscode`イシュー147515](https://github.com/microsoft/vscode/issues/147515)

### macOS回避策 {#macos-workaround}

macOSの回避策が存在します:

1. マシンで、**Keychain Access**（キーチェーンアクセス）を開き、`vscodegitlab.gitlab-workflow`を検索します。
1. キーチェーンから`vscodegitlab.gitlab-workflow`を削除します。
1. `GitLab: Remove Account from VS Code`コマンドを使用して、破損したアカウントをVS Codeから削除します。
1. アカウントを再度追加するには、`Gitlab: Add Account to VS Code`または`GitLab: Authenticate to GitLab.com`を実行します。

### Ubuntu回避策 {#ubuntu-workaround}

Ubuntu 20.04および22.04で`snap`を使用してVS Codeをインストールすると、VS CodeはOSキーチェーンからパスワードを読み取ることができません。拡張機能バージョン3.44.0以降では、安全なトークンストレージにOSキーチェーンを使用します。VS Codeのバージョン1.68.0より前のバージョンを使用するUbuntuユーザーには、回避策が存在します:

- GitLab Workflow拡張機能をバージョン3.43.1にダウングレードできます。
- `snap`ではなく、`.deb`パッケージからVS Codeをインストールできます:
  1. `snap` VS Codeをアンインストールします。
  1. [`.deb`パッケージ](https://code.visualstudio.com/Download)からVS Codeをインストールします。
  1. Ubuntuの**Password & Keys**（パスワードとキー）に移動し、`vscodegitlab.workflow/gitlab-tokens`エントリを見つけて削除します。
  1. VS Codeで、`Gitlab: Remove Your Account`を実行して、認証情報がないアカウントを削除します。
  1. アカウントを再度追加するには、`GitLab: Authenticate`を実行します。

VS Codeバージョン1.68.0以降を使用している場合、再インストールはできない可能性があります。ただし、最後の3つの手順を実行して再度認証することができます。

## 環境変数でトークンを設定する {#set-token-with-environment-variables}

Gitpodコンテナなど、VS Codeストレージを頻繁に削除する場合は、VS Codeを起動する前に環境変数を設定します。[VS Code環境変数](https://code.visualstudio.com/docs/editor/variables-reference#_environment-variables)でトークンを設定すると、VS Codeストレージを削除するたびにパーソナルアクセストークンを設定する必要はありません。これらの変数を設定します:

- `GITLAB_WORKFLOW_INSTANCE_URL`: `https://gitlab.com`のようなGitLabインスタンスのURL。
- `GITLAB_WORKFLOW_TOKEN`: [GitLabで認証するとき](setup.md#authenticate-with-gitlab)に作成したパーソナルアクセストークン。

環境変数で設定されたトークンは、拡張機能で同じGitLabインスタンスのトークンを設定するとオーバーライドされます。

### GDKの使用時の接続と認可のエラー {#connection-and-authorization-error-when-using-gdk}

VS CodeをGDKで使用する場合、localhostで実行されているGitLabインスタンスへの安全なTLS接続をシステムが確立できないというエラーが発生する可能性があります。

たとえば、GitLabサーバーとして`127.0.0.1:3000`を使用している場合:

```plaintext
Request to https://127.0.0.1:3000/api/v4/version failed, reason: Client network
socket disconnected before secure TLS connection was established
```

この問題は、`http`でGDKを実行していて、GitLabインスタンスが`https`でホストされている場合に発生します。

これを解決するには、`GitLab: Authenticate`コマンドを実行するときに、インスタンスの`http` URLを手動で入力します。

## サポートに必要な情報 {#required-information-for-support}

サポートに問い合わせる前に、最新のGitLab Workflow拡張機能がインストールされていることを確認してください。すべてのリリースは、[VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)の**Version History**（バージョン履歴）タブにあります。

影響を受けるユーザーからこの情報を収集し、バグレポートで提供してください:

1. ユーザーに表示されるエラーメッセージ。
1. ワークフローと言語サーバーのログファイル:
   1. [デバッグログを有効にする](#enable-debug-logs)。
   1. 拡張機能と言語サーバーの[ログファイルを取得する](#view-log-files)。
1. 診断出力。
   1. <kbd>コマンド</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>または<kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>を使用してコマンドパレットを開きます
   1. コマンド`GitLab: Diagnostics`を実行し、拡張機能のバージョンをメモします。
1. システム詳細:
   - VS Codeで、**コード** > **About Visual Studio Code**（Visual Studio Codeについて）に移動し、**OS**を見つけます。
   - マシンの仕様（CPU、RAM）: マシンからこれらを提供します。これらはWeb IDEではアクセスできません。
1. 影響のスコープを記述します。影響を受けるユーザーの数は？
1. エラーの再現方法を説明します。可能であれば、画面録画を含めます。
1. 他のGitLab Duo機能がどのように影響を受けているかを記述します:
   - GitLabクイックチャットは機能していますか？
   - コード提案は機能していますか？
   - Web IDE Duoチャットは応答を返しますか？
1. [GitLab Workflow拡張機能分離ガイド](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/814#step-2-extension-isolation-testing)の説明に従って、拡張機能の分離テストを実行します。他のすべての拡張機能を無効にする（またはアンインストールする）ことを試して、別の拡張機能が問題の原因になっているかどうかを判断します。これにより、問題が当社の拡張機能にあるのか、外部ソースからのものなのかを判断できます。
