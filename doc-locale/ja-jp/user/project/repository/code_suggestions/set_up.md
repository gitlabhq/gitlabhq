---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案をセットアップします。
title: コード提案をセットアップする
---

{{< history >}}

- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

複数の異なるIDEでコード提案を使用できます。コード提案を設定するには、お使いのIDEの手順に従ってください。

## 前提要件 {#prerequisites}

コード提案を使用するには、以下が必要です:

- GitLab Duo Core、Pro、またはEnterpriseアドオン。
- PremiumまたはUltimateサブスクリプション。
- GitLab Duo ProまたはEnterpriseをお持ちの場合は、割り当て済みのシート。
- GitLab Duo Coreをお持ちの場合は、[IDE機能をオン](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)にする。
- コード提案が、[お好みの言語をサポート](supported_extensions.md#supported-languages-by-ide)しているか確認するため。IDEが異なると、サポートされる言語も異なります。

## エディタ拡張機能を設定する {#configure-editor-extension}

コード提案はエディタ拡張機能の一部です。コード提案を使用するには、以下の手順に従います:

1. IDEに拡張機能をインストールします。
1. IDEからGitLabで認証します。OAuthまたはパーソナルアクセストークンを使用できます。
1. 拡張機能を設定します。

お使いのIDEに合わせて、次の手順に従ってください:

- [Visual Studio Code](../../../../editor_extensions/visual_studio_code/setup.md)
- [Visual Studio](../../../../editor_extensions/visual_studio/setup.md)
- [JetBrains IDE用GitLab Duoプラグイン](../../../../editor_extensions/jetbrains_ide/setup.md)
- [`gitlab.vim` Neovim用プラグイン](../../../../editor_extensions/neovim/setup.md)
- [Eclipse用GitLab](../../../../editor_extensions/eclipse/setup.md)

## コード提案をオンにする。 {#turn-on-code-suggestions}

コード提案は、[前提条件を満たしている場合](#prerequisites)にオンになります。確認するには、IDEを開き、コード提案が動作するかどうかを確認します。

### VS Code {#vs-code}

コード提案がVS Codeでオンになっていることを確認するには、次のようにします:

1. VS Codeで、**設定** > **Extensions**（拡張機能） > **GitLab Workflow**に移動します。
1. **管理** ({{< icon name="settings" >}})を選択します。
1. **GitLab › GitLab Duoコード提案: 有効**が選択されていることを確認してください。
1. オプション。**GitLab › Duoコード提案: 有効Supported Languages**で、コードを提案または生成する言語を選択します。
1. オプション。**GitLab › Duoコード提案: Additional Languages**に、使用するその他の言語を追加します。

### Visual Studio {#visual-studio}

コード提案がVisual Studioでオンになっていることを確認するには、次のようにします:

1. Visual Studioの下部のステータスバーで、GitLabアイコンをポイントします。
1. コード提案が有効になっている場合、アイコンのツールチップに`GitLab code suggestions are enabled.`と表示されます。
1. コード提案が有効になっていない場合は、上部のバーで**Extensions**（拡張機能） > **GitLab** > **Toggle Code Suggestions**（コード提案）を選択して有効にします。

### JetBrains IDE {#jetbrains-ides}

コード提案がJetBrains IDEでオンになっていることを確認するには、次のようにします:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. **機能**セクションで、**Enable Code Suggestions**（コード提案）と**Enable GitLab Duo Chat**（GitLab Duo Chat）が選択されていることを確認します。
1. **OK**または**保存**を選択します。

#### コード提案用のカスタム証明書を追加 {#add-a-custom-certificate-for-code-suggestions}

{{< history >}}

- GitLab Duo 2.10.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561)。

{{< /history >}}

GitLab Duoは、[信頼できるルート証明書](https://www.jetbrains.com/help/idea/ssl-certificates.html)を自動的に検出します。必要に応じて、JetBrains IDEを設定し、GitLab DuoプラグインがGitLabインスタンスに接続する際に、カスタムSSL証明書を使用できるようにします。

カスタムSSL証明書をGitLab Duoで使用するには、次のようにします:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール**を展開し、**GitLab Duo**を選択します。
1. **接続**で、**URL to GitLab instance**（GitLabインスタンスへのURL）を入力します。
1. 接続を検証するには、**Verify setup**（設定の確認）を選択します。
1. **OK**または**保存**を選択します。

IDEが信頼されていないSSL証明書を検出した場合:

1. GitLab Duoプラグインに確認ダイアログが表示されます。
1. 表示されているSSL証明書の詳細を確認します。
   - 証明書の詳細が、ブラウザでGitLabに接続したときに表示される証明書と一致することを確認します。
1. 証明書が予想と一致する場合は、**Accept**を選択します。

すでに承認した証明書を確認するには、次のようにします:

1. IDEの上部のバーで、IDEの名前を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **Server Certificates**（サーバー証明書）を選択します。
1. [**Server Certificates**（サーバー証明書）](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html)を選択します。
1. 証明書を選択して表示します。

### Eclipse {#eclipse}

{{< alert type="note" >}}

GitLab Duoコード提案を有効にするには、Eclipseプロジェクトを開きます。単一のファイルを開くと、すべてのファイルタイプでコード提案が無効になります。

{{< /alert >}}

コード提案がEclipseでオンになっていることを確認するには、次のようにします:

1. Eclipseで、GitLabプロジェクトを開きます。
1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。

**コード提案**は「Enabled」と表示されます。

### Neovim {#neovim}

コード提案はLSP（言語サーバープロトコル）サーバーを提供し、組み込みの<kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd> Omni Completionキーマッピングをサポートします:

| モード     | キーマッピング                          | 型      | 説明 |
|----------|---------------------------------------|-----------|-------------|
| `INSERT` | <kbd>Control</kbd>+<kbd>x</kbd>、<kbd>Control</kbd>+<kbd>o</kbd> | 内蔵 | 言語サーバーを介してGitLab Duoコード提案から補完をリクエストします。 |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>`  | 現在のバッファのコード提案のオン/オフを切り替えます。[設定](../../../../editor_extensions/neovim/setup.md#configure-plug-key-mappings)が必要です。 |

## コード提案がオンになっていることを確認 {#verify-that-code-suggestions-is-on}

Neovimを除く、GitLabのすべてのエディタ拡張機能は、IDEのステータスバーにアイコンを追加します。たとえば、Visual Studioでは次のようになります:

![Visual Studioのステータスバー。](img/visual_studio_status_bar_v17_4.png)

| アイコン | ステータス | 意味 |
| :--- | :----- | :------ |
| {{< icon name="tanuki-ai" >}} | **準備完了** | コード提案をサポートする言語を使用しており、GitLab Duoを設定して有効にしました。 |
| {{< icon name="tanuki-ai-off" >}} | **Not configured**（未設定） | パーソナルアクセストークンを入力していないか、コード提案がサポートしていない言語を使用しています。 |
| ![コード提案をフェッチするためのステータスアイコン。](img/code_suggestions_loading_v17_4.svg) | **Loading suggestion**（提案をロードしています） | GitLab Duoがコード提案をフェッチしています。 |
| ![コード提案エラーのステータスアイコン。](img/code_suggestions_error_v17_4.svg) | **エラー**: | GitLab Duoでエラーが発生しました。 |

## コード提案をオフにする {#turn-off-code-suggestions}

コード提案をオフにするプロセスは、IDEごとに異なります。

{{< alert type="note" >}}

コード生成とコード補完を個別にオフにすることはできません。

{{< /alert >}}

### VS Code {#vs-code-1}

VS Codeでコード提案をオフにするには、次のようにします:

1. **コード** > **設定** > **Extensions**（拡張機能）に移動します。
1. **管理** ({{< icon name="settings" >}}) > **設定**を選択します。
1. **GitLab Duoコード提案**チェックボックスをオフにします。

代わりに、[VS Codeの`settings.json`ファイルで`gitlab.duoCodeSuggestions.enabled`を`false`に設定できます](../../../../editor_extensions/visual_studio_code/settings.md#extension-settings)。

### Visual Studio {#visual-studio-1}

拡張機能をアンインストールせずにコード提案をオン/オフにするには、[`GitLab.ToggleCodeSuggestions`カスタムコマンドにキーボードショートカットを割り当て](../../../../editor_extensions/visual_studio/setup.md#configure-the-extension)ます。

拡張機能を無効にするかアンインストールするには、[拡張機能のアンインストールまたは無効化に関するMicrosoft Visual Studioドキュメント](https://learn.microsoft.com/en-us/visualstudio/ide/finding-and-using-visual-studio-extensions?view=vs-2022#uninstall-or-disable-an-extension)を参照してください。

### JetBrains IDE {#jetbrains-ides-1}

コード提案を含むGitLab Duoを無効にするプロセスは、使用するJetBrains IDEに関係なく同じです。

1. JetBrains IDEで、設定に移動し、プラグインメニューを選択します。
1. インストールされているプラグインで、GitLab Duoプラグインを見つけます。
1. プラグインを無効にします。

詳しくは、[JetBrains製品ドキュメント](https://www.jetbrains.com/help/)をご覧ください。

### Eclipse {#eclipse-1}

プロジェクトのEclipseコード提案を無効にするには、次のようにします:

1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。
1. **Disable Code Suggestions**（コード提案を無効）を選択して、現在のプロジェクトのコード提案を無効にします。

特定の言語のEclipseコード提案を無効にするには、次のようにします:

1. Eclipseの下部ツールバーで、GitLabアイコンを選択します。
1. **Show Settings**（設定）を選択します。
1. **Code Suggestions Enabled Languages**（コード提案が有効な言語）」セクションまでスクロールし、無効にする言語のチェックボックスをオフにします。

### Neovim {#neovim-1}

1. [Neovim `defaults.lua`設定ファイル](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua)に移動します。
1. `code_suggestions`で、`enabled =`フラグを`false`に変更します:

   ```lua
   code_suggestions = {
   ...
    enabled = false,
   ```

### GitLab Duoをオフにする {#turn-off-gitlab-duo}

または、グループ、プロジェクト、またはインスタンスのGitLab Duo（コード提案を含む）を完全に[オフにすることができます](../../../gitlab_duo/turn_on_off.md)。
