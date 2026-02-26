---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案の設定。
title: コード提案をセットアップする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

複数の異なるIDEでGitLab Duoコード提案を使用できます。

コード提案を設定するには、IDEの手順に従ってください。

## 前提条件 {#prerequisites}

コード提案を使用するには、以下が必要です。

- GitLab Duo Coreをお持ちの場合は、[IDE機能をオン](../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)にする。
- コード提案が[推奨言語をサポート](supported_extensions.md#supported-languages-by-ide)していることを確認するため。IDEによってサポートされる言語が異なります。

## エディタ拡張機能を設定 {#configure-editor-extension}

コード提案は、エディタ拡張機能の一部です。コード提案を使用するには、以下の手順に従います:

1. IDEに拡張機能をインストールします。
1. IDEからGitLabで認証します。OAuthまたはパーソナルアクセストークンを使用できます。
1. 拡張機能を設定します。

お使いのIDEに合わせて次の手順を実行してください:

- [Visual Studio Code](../../../editor_extensions/visual_studio_code/setup.md)
- [Visual Studio](../../../editor_extensions/visual_studio/setup.md)
- [JetBrains IDE用GitLab Duoプラグイン](../../../editor_extensions/jetbrains_ide/setup.md)
- [`gitlab.vim` Neovim用プラグイン](../../../editor_extensions/neovim/setup.md)
- [Eclipse用GitLab](../../../editor_extensions/eclipse/setup.md)

## コード提案をオンにする {#turn-on-code-suggestions}

コード提案は、[前提条件を満たしている場合](#prerequisites)にオンになります。確認するには、IDEを開き、コード提案が機能するかどうかを確認します。

### VS Code {#vs-code}

VS Codeでコード提案がオンになっていることを確認するには、次の手順に従います:

1. VS Codeで、**設定** > **Extensions** > **GitLab Workflow**に移動します。
1. **管理** ({{< icon name="settings" >}}) を選択します。
1. **GitLab** > **GitLab Duoコード提案であることを確認します: 有効**が選択されています。
1. オプション。**GitLab** > **GitLab Duoコード提案の場合: サポートされている言語を有効にする**、コードの提案または生成に使用する言語を選択します。
1. オプション。**GitLab** > **GitLab Duoコード提案の場合: 追加言語**、使用するその他の言語を追加します。

### Visual Studio {#visual-studio}

Visual Studioでコード提案がオンになっていることを確認するには、次の手順に従います:

1. Visual Studioで、下部のステータスバーでGitLabアイコンをポイントします。
1. コード提案が有効になっている場合、アイコンのツールチップに`GitLab code suggestions are enabled.`と表示されます
1. コード提案が有効になっていない場合は、上部のバーで**Extensions** > **GitLab** > **Toggle Code Suggestions**を選択して有効にします。

### JetBrains IDE {#jetbrains-ides}

JetBrains IDEでコード提案がオンになっていることを確認するには、次の手順に従います:

1. IDEの上部バーで、IDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **機能**セクションで、**Enable Code Suggestions**と**Enable GitLab Duo Chat**が選択されていることを確認します。
1. **OK**または**保存**を選択します。

#### コード提案のカスタム証明書を追加する {#add-a-custom-certificate-for-code-suggestions}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561)GitLab Duo 2.10.0。

{{< /history >}}

GitLab Duoは、こちらで設定しなくても[信頼できるルート証明書](https://www.jetbrains.com/help/idea/ssl-certificates.html)を検出しようとします。必要に応じて、GitLabインスタンスに接続するときに、GitLab DuoプラグインがカスタムSSL証明書を使用できるように、JetBrains IDEを設定します。

カスタムSSL証明書をGitLab Duoで使用するには:

1. IDEの上部バーで、IDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **接続**で、**URL to GitLab instance**を入力します。
1. 接続を検証するには、**Verify setup**を選択します。
1. **OK**または**保存**を選択します。

IDEが信頼されていないSSL証明書を検出した場合:

1. GitLab Duoプラグインに確認ダイアログが表示されます。
1. 表示されているSSL証明書の詳細を確認します。
   - ブラウザでGitLabに接続するときに表示される証明書詳細と証明書詳細が一致することを確認します。
1. 証明書が期待どおりの場合は、**Accept**を選択します。

すでに承認した証明書を確認するには:

1. IDEの上部バーで、IDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **Server Certificates**を選択します。
1. [**Server Certificates**](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html)を選択します。
1. 証明書を選択して表示します。

### Eclipse {#eclipse}

> [!note]
> GitLab Duoコード提案を有効にするには、Eclipseプロジェクトを開きます。単一のファイルを開くと、すべてのファイルタイプでコード提案が無効になります。

Eclipseでコード提案がオンになっていることを確認するには、次の手順に従います:

1. Eclipseで、GitLabプロジェクトを開きます。
1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。

**コード提案**が「Enabled」と表示されます。

### Neovim {#neovim}

コード提案は、組み込みの<kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd>によるオムニ補完キー操作をサポートするためのLSP（Language Server Protocol）サーバーを提供します。

| モード     | キーマッピング                          | 型      | 説明 |
|----------|---------------------------------------|-----------|-------------|
| `INSERT` | <kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd> | ビルトイン | 言語サーバーを介してGitLab Duoコード提案からの補完をリクエストします。 |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>`  | 現在のバッファのコード提案のオン/オフを切替ます。[設定が必要です](../../../editor_extensions/neovim/setup.md#configure-plug-key-mappings)。 |

## コード提案がオンになっていることを確認する {#verify-that-code-suggestions-is-on}

Neovimを除く、GitLabのすべてのエディタ拡張機能は、IDEのステータスバーにアイコンを追加します。たとえば、Visual Studioでは次のようになります:

![Visual Studioのステータスバー。](img/visual_studio_status_bar_v17_4.png)

| アイコン | ステータス | 意味 |
| :--- | :----- | :------ |
| {{< icon name="tanuki-ai" >}} | **準備完了** | GitLab Duoを設定して有効にしており、コード提案をサポートする言語を使用しています。 |
| {{< icon name="tanuki-ai-off" >}} | **Not configured** | パーソナルアクセストークンを入力していないか、コード提案がサポートしていない言語を使用しています。 |
| ![コード提案をフェッチするためのステータスアイコン。](img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duoは、コード提案をフェッチしています。 |
| ![コード提案エラーのステータスアイコン。](img/code_suggestions_error_v17_4.svg) | **エラー** | GitLab Duoでエラーが発生しました。 |

## コード提案をオフにする {#turn-off-code-suggestions}

コード提案をオフにするプロセスは、IDEごとに異なります。

> [!note]
> コード補完とは別にコード生成をオフにすることはできません。

### VS Code {#vs-code-1}

VS Codeでコード提案をオフにするには:

1. **コード** > **設定** > **Extensions**に移動します。
1. **管理** ({{< icon name="settings" >}}) > **設定**を選択します。
1. **GitLab Duoコード提案**チェックボックスをオフにします。

代わりに、[VS Code の`settings.json`ファイルで`gitlab.duoCodeSuggestions.enabled`を `false`に設定できます。](../../../editor_extensions/visual_studio_code/settings.md#extension-settings)

### Visual Studio {#visual-studio-1}

拡張機能をアンインストールせずにコード提案をオンまたはオフにするには、[`GitLab.ToggleCodeSuggestions`カスタムコマンドにキーボードショートカットを割り当てます](../../../editor_extensions/visual_studio/setup.md#configure-the-extension)。

拡張機能を無効にするかアンインストールするには、[拡張機能をアンインストールまたは無効にする方法に関するMicrosoft Visual Studioドキュメント](https://learn.microsoft.com/en-us/visualstudio/ide/finding-and-using-visual-studio-extensions?view=vs-2022#uninstall-or-disable-an-extension)を参照してください。

### JetBrains IDE {#jetbrains-ides-1}

コード提案を含むGitLab Duoを無効にするプロセスは、使用するJetBrains IDEに関係なく同じです。

1. JetBrains IDEで、設定に移動し、プラグインメニューを選択します。
1. インストールされているプラグインで、GitLab Duoプラグインを見つけます。
1. プラグインを無効にします。

詳細については、[JetBrains製品ドキュメント](https://www.jetbrains.com/help/)を参照してください。

### Eclipse {#eclipse-1}

プロジェクトのEclipseコード提案を無効にするには:

1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。
1. **Disable Code Suggestions**を選択して、現在のプロジェクトのコード提案を無効にします。

特定の言語のEclipseコード提案を無効にするには:

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

または、グループ、プロジェクト、またはインスタンス単位で[GitLab Duo（コード提案を含む）を完全に無効](../../gitlab_duo/turn_on_off.md)にすることもできます。
