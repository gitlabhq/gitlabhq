---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: お使いのIDEでコード提案を設定します。
title: コード提案をセットアップする
---

複数の異なるIDEでGitLab Duoコード提案を使用できます。

コード提案を設定するには、IDEの手順に従ってください。

## 前提条件 {#prerequisites}

コード提案を使用するには、以下を行う必要があります:

- GitLab Duo Coreをお持ちの場合は、[IDE機能をオン](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)にする。
- コード提案が[目的の言語をサポート](supported_extensions.md#supported-languages-by-ide)していることを確認する。IDEによってサポートされる言語が異なります。

## エディタ拡張機能を設定する {#configure-editor-extension}

コード提案はエディタ拡張機能の一部です。コード提案を使用するには、以下の手順に従います:

1. IDEに拡張機能をインストールします。
1. IDEからGitLabに対して認証します。OAuthまたはパーソナルアクセストークンを使用できます。
1. 拡張機能を設定します。

お使いのIDEに合わせて次の手順を実行してください:

- [Visual Studio Code](../../../../editor_extensions/visual_studio_code/setup.md)
- [Visual Studio](../../../../editor_extensions/visual_studio/setup.md)
- [JetBrains IDE用GitLab Duoプラグイン](../../../../editor_extensions/jetbrains_ide/setup.md)
- [`gitlab.vim` Neovim用プラグイン](../../../../editor_extensions/neovim/setup.md)
- [GitLab for Eclipse](../../../../editor_extensions/eclipse/setup.md)

## コード提案をオンにする {#turn-on-code-suggestions}

コード提案は、[前提条件を満たしている場合](#prerequisites)にオンになります。IDEを開き、コード提案が機能するかどうかを確認してください。

### VS Code {#vs-code}

VS Codeでコード提案がオンになっていることを確認するには、次の手順に従います:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押してください。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押してください。
1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
1. **GitLab › GitLab Duoコード提案: の下のチェックボックスがオンになっていることを確認します: Enabled**が選択されていることを確認します。
1. オプション。**GitLab › Duo Code Suggestions: Enabled Supported Languages**で、コードの提案または生成の対象とする言語を選択します。
1. オプション。**GitLab › Duo Code Suggestions: Additional Languages**で、使用するその他の言語を追加します。

### Visual Studio {#visual-studio}

Visual Studioでコード提案がオンになっていることを確認するには、次の手順に従います:

1. Visual Studioで、下部のステータスバーでGitLabアイコンをポイントします。
1. アイコンのツールチップを確認し、機能が有効になっていることを確認します。
1. コード提案が有効になっていない場合、トップバーで**Extensions** > **GitLab** > **Toggle Code Suggestions**を選択して有効にします。

### JetBrains IDE {#jetbrains-ides}

JetBrains IDEでコード提案がオンになっていることを確認するには、次の手順に従います:

1. お使いのIDEで、トップバーにあるIDEの名前を選択し、次に**設定**を選択します。
1. 左サイドバーで**ツール**を展開し、**GitLab Duo**を選択します。
1. **Features**セクションで、**Enable Code Suggestions**と**Enable GitLab Duo Chat**が選択されていることを確認します。
1. **OK**または**Save**を選択します。

#### コード提案のカスタム証明書を追加する {#add-a-custom-certificate-for-code-suggestions}

{{< history >}}

- GitLab Duo 2.10.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561)されました。

{{< /history >}}

GitLab Duoは、ユーザーが設定しなくても[信頼できるルート証明書](https://www.jetbrains.com/help/idea/ssl-certificates.html)を検出しようとします。必要に応じて、GitLabインスタンスに接続するときに、GitLab DuoプラグインがカスタムSSL証明書を使用できるように、JetBrains IDEを設定します。

カスタムSSL証明書をGitLab Duoで使用するには、次の手順に従います:

1. お使いのIDEで、トップバーにあるIDEの名前を選択し、次に**設定**を選択します。
1. 左サイドバーで**ツール**を展開し、**GitLab Duo**を選択します。
1. **Connection**で、**URL to GitLab instance**を入力します。
1. 接続を検証するには、**Verify setup**を選択します。
1. **OK**または**Save**を選択します。

IDEが信頼されていないSSL証明書を検出した場合:

1. GitLab Duoプラグインに確認ダイアログが表示されます。
1. 表示されているSSL証明書の詳細を確認します。
   - その証明書の詳細が、ブラウザでGitLabに接続するときに表示される証明書と一致することを確認します。
1. 証明書が想定どおりの場合は、**Accept**を選択します。

すでに承認した証明書を確認するには、次の手順に従います:

1. お使いのIDEで、トップバーにあるIDEの名前を選択し、次に**設定**を選択します。
1. 左サイドバーで**ツール** > **Server Certificates**を選択します。
1. [**Server Certificates**](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html)を選択します。
1. 証明書を選択して表示します。

### Eclipse {#eclipse}

> [!note]
> GitLab Duoコード提案を有効にするには、Eclipseプロジェクトを開きます。単一のファイルを開くと、すべてのファイルタイプでコード提案が無効になります。

Eclipseでコード提案がオンになっていることを確認するには、次の手順に従います:

1. Eclipseで、GitLabプロジェクトを開きます。
1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。

**Code Suggestions**に「Enabled」と表示されます。

### Neovim {#neovim}

コード提案は、組み込みの<kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd>によるオムニ補完キーマッピングをサポートするため、LSP（Language Server Protocol）サーバーを提供します:

| モード     | キーマッピング                          | 種類      | 説明 |
|----------|---------------------------------------|-----------|-------------|
| `INSERT` | <kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd> | ビルトイン | 言語サーバーを介してGitLab Duoコード提案からの補完をリクエストします。 |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>`  | 現在のバッファに対してコード提案のオン/オフを切り替えます。[設定](../../../../editor_extensions/neovim/setup.md#configure-plug-key-mappings)が必要です。 |

## コード提案がオンになっていることを確認する {#verify-that-code-suggestions-is-on}

Neovimを除く、GitLabのすべてのエディタ拡張機能は、IDEのステータスバーにアイコンを追加します。たとえば、Visual Studioでは次のようになります:

![Visual Studioのステータスバー。](img/visual_studio_status_bar_v17_4.png)

| アイコン | ステータス | 意味 |
| :--- | :----- | :------ |
| {{< icon name="tanuki-ai" >}} | **Ready** | GitLab Duoを設定して有効にしており、コード提案をサポートする言語を使用しています。 |
| {{< icon name="tanuki-ai-off" >}} | **Not configured** | パーソナルアクセストークンを入力していないか、コード提案がサポートしていない言語を使用しています。 |
| ![コード提案のフェッチ中を示すステータスアイコン。](img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duoがコード提案をフェッチしています。 |
| ![コード提案エラーを示すステータスアイコン。](img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duoでエラーが発生しました。 |

## コード提案をオフにする {#turn-off-code-suggestions}

コード提案をオフにするプロセスは、IDEごとに異なります。

> [!note]
> コード生成とコード補完を個別にオフにすることはできません。

### VS Code {#vs-code-1}

VS Codeでコード提案をオフにするには、次の手順に従います:

1. VS Codeで、設定エディタを開きます:
   - macOSでは、<kbd>Command</kbd>+<kbd>,</kbd>を押してください。
   - WindowsまたはLinuxでは、<kbd>Control</kbd>+<kbd>,</kbd>を押してください。
1. **Extensions** > **GitLab** > **GitLab Duo**を選択します。
1. **GitLab › Duo Code Suggestions: Enabled**のチェックボックスをオフにします。

代わりに、[VS Codeの`settings.json`ファイルで`gitlab.duoCodeSuggestions.enabled`を`false`に設定することもできます。](../../../../editor_extensions/visual_studio_code/settings.md#extension-settings)

### Visual Studio {#visual-studio-1}

拡張機能をアンインストールせずにコード提案をオンまたはオフにするには、[`GitLab.ToggleCodeSuggestions`カスタムコマンドにキーボードショートカットを割り当てます](../../../../editor_extensions/visual_studio/setup.md#configure-the-extension)。

拡張機能を無効にするかアンインストールするには、[拡張機能のアンインストールまたは無効化に関するMicrosoft Visual Studioドキュメント](https://learn.microsoft.com/en-us/visualstudio/ide/finding-and-using-visual-studio-extensions?view=vs-2022#uninstall-or-disable-an-extension)を参照してください。

### JetBrains IDE {#jetbrains-ides-1}

コード提案を含むGitLab Duoを無効にするプロセスは、使用するJetBrains IDEに関係なく同じです。

1. JetBrains IDEで、設定に移動し、プラグインメニューを選択します。
1. インストールされているプラグインの中からGitLab Duoプラグインを見つけます。
1. プラグインを無効にします。

詳細については、[JetBrains製品ドキュメント](https://www.jetbrains.com/help/)を参照してください。

### Eclipse {#eclipse-1}

プロジェクトのEclipseコード提案を無効にするには、次の手順に従います:

1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。
1. **Disable Code Suggestions**を選択して、現在のプロジェクトのコード提案を無効にします。

特定の言語のEclipseコード提案を無効にするには、次の手順に従います:

1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。
1. **Show Settings**を選択します。
1. **Code Suggestions Enabled Languages**セクションまでスクロールし、無効にする言語のチェックボックスをオフにします。

### Neovim {#neovim-1}

1. [Neovim `defaults.lua`設定ファイル](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua)に移動します。
1. `code_suggestions`で、`enabled =`フラグを`false`に変更します:

   ```lua
   code_suggestions = {
   ...
    enabled = false,
   ```

### GitLab Duoをオフにする {#turn-off-gitlab-duo}

または、グループ、プロジェクト、またはインスタンス単位で[GitLab Duo（コード提案を含む）を完全に無効](../../../gitlab_duo/turn_on_off.md)にすることもできます。
