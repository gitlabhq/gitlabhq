---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案は、複数のエディターと言語をサポートしています。
title: サポートされる拡張機能と言語
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コード提案は、以下のエディタ拡張機能および言語で使用できます。

## サポートされているエディタ拡張機能 {#supported-editor-extensions}

コード提案を使用するには、次のエディタ拡張機能のいずれかを使用します:

| IDE                                                             | 拡張機能 |
|-----------------------------------------------------------------|-----------|
| Visual Studio Code（VS Code）                                    | [VS Code用GitLab Workflow拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) |
| [GitLab Web IDE (クラウド内のVS Code)](../../../user/project/web_ide/_index.md) | 設定は不要です。 |
| Microsoft Visual Studio (Windows版2022)                      | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDE                                                  | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) |
| Neovim                                                          | [`gitlab.vim`プラグイン](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) |
| Eclipse                                                          | [GitLab for Eclipse](../../../editor_extensions/eclipse/setup.md) |

VS Code、Visual Studio、Eclipse、Neovimでは、[GitLab言語サーバー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)が使用されています。この言語サーバーにより、より多くのプラットフォームで迅速なイテレーションがサポートされます。また、GitLabが公式サポートを提供していないIDEでコード提案をサポートするように設定することもできます。

他のIDE拡張機能のサポートについては、[このイシュー](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78)で関心を表明できます。

## IDEでサポートされている言語 {#supported-languages-by-ide}

次の表に、コード提案がデフォルトでサポートする言語と、IDEに関する詳細を示します。

コード提案は他の言語でも動作しますが、[手動でサポートを追加](#add-support-for-more-languages)する必要があります。

| 言語                            | Web IDE     | VS Code                  | JetBrains IDE | Windows版Visual Studio 2022 | Neovim                   | Eclipse |
|-------------------------------------|-------------|--------------------------|----------------|--------------------------------|--------------------------|---------|
| C                                   | {{< yes >}} | {{< yes >}}              | {{< no >}}     | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| C++                                 | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| C#                                  | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| CSS                                 | {{< yes >}} | {{< no >}}               | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| Go                                  | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Google SQL                          | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< no >}} |
| HAML                                | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| HTML                                | {{< yes >}} | {{< no >}}               | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| Java                                | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| JavaScript                          | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Kotlin                              | {{< no >}}  | {{< yes >}} <sup>1</sup> | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Markdown                            | {{< yes >}} | {{< no >}}               | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| PHP                                 | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Python                              | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Ruby                                | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Rust                                | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Scala                               | {{< no >}}  | {{< yes >}} <sup>2</sup> | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Shellスクリプト（`bash`のみ）         | {{< yes >}} | {{< no >}}               | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Svelte                              | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Swift                               | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| TypeScript(`.ts`および`.tsx`ファイル) | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Terraform                           | {{< no >}}  | {{< yes >}} <sup>3</sup> | {{< yes >}}    | {{< no >}}                     | {{< yes >}} <sup>4</sup> | {{< yes >}} |
| Vue                                 | {{< yes >}} | {{< yes >}}              | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |

**脚注**: 

1. VS Codeでは、Kotlinをサポートするサードパーティ製の拡張機能が必要です。
1. VS Codeでは、Scalaをサポートするサードパーティ製の拡張機能が必要です。
1. VS Codeでは、Terraformをサポートするサードパーティ製の拡張機能が必要です。
1. Neovimでは、`terraform`ファイルタイプを提供するサードパーティ製の拡張機能が必要です。

> [!note]
> 一部の言語は、すべてのJetBrains IDEでサポートされているわけではありません。また、追加のプラグインサポートが必要な場合があります。お使いのIDEの具体的な内容については、JetBrainsのドキュメントを参照してください。

## Infrastructure as Code（IaC）のサポート {#support-for-infrastructure-as-code-iac}

コード提案は、次のものを含むinfrastructure-as-codeインターフェースで動作します:

- Kubernetesリソースモデル（KRM）
- Google Cloud CLI
- Terraform

## コード提案の言語を管理 {#manage-languages-for-code-suggestions}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#4210-2024-07-16)：VS Code用GitLab Workflow拡張機能4.21.0

{{< /history >}}

VS Codeでのコーディングエクスペリエンスは、サポートされている特定の言語に対してコード提案を有効または無効にすることでカスタマイズできます。これを行うには、`settings.json`ファイルを直接編集するか、VS Codeのユーザーインターフェースから行います:

1. VS Codeで、**GitLab Workflow**の設定を開きます:
   1. 上部のバーで、**Code** > **Settings** > **Extensions**に移動します。
   1. リストで**GitLab Workflow**を検索し、**管理**（{{< icon name="settings" >}}）を選択します。
   1. **Extension Settings**を選択します。
1. **ユーザー**設定で、**AIアシストコード提案というタイトルのセクションを探します: 有効なサポート対象言語**.
1. 言語のコード提案を有効にするには、そのチェックボックスをオンにします。
1. 言語のコード提案を無効にするには、そのチェックボックスをオフにします。
1. 変更は自動的に保存され、すぐに有効になります。

言語のコード提案を無効にすると、この言語では提案が無効になっていることを示すようにGitLab Duoアイコンが変化します。カーソルを合わせると、**Code Suggestions are disabled for this language**と表示されます。

## 他の言語のサポートを追加 {#add-support-for-more-languages}

ご希望の言語でコード提案がデフォルトで使用できない場合は、ローカルで言語のサポートを追加できます。ただし、コード提案は期待どおりに機能しない可能性があります。

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

前提条件: 

- [VS Code用GitLab Workflow拡張機能](../../../editor_extensions/visual_studio_code/_index.md)をインストールして有効にしました。
- [VS Code拡張機能の設定](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. [language identifier](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem)のリストで、目的の言語を見つけます。後の手順で、言語の**識別子**が必要です。
1. VS Codeで、**GitLab Workflow**の設定を開きます:
   1. 上部のバーで、**Code** > **Settings** > **Extensions**に移動します。
   1. リストで**GitLab Workflow**を検索し、**管理**（{{< icon name="settings" >}}）を選択します。
   1. **Extension Settings**を選択します。
   1. **ユーザー**設定で、**GitLab › AIアシストコード提案を探します: 追加の言語**を選択し、**Add Item**を選択します。
1. **Item**で、サポートする各言語の識別子を追加します。識別子は、`html`や`powershell`のように小文字にする必要があります。ファイルサフィックスから各識別子に先頭のピリオドを追加しないでください。
1. **OK**を選択します。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

前提条件: 

- [JetBrains IDE用GitLabプラグイン](../../../editor_extensions/jetbrains_ide/_index.md)をインストールして有効にしました。
- [JetBrains拡張機能の設定](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. [language identifier](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem)のリストで、目的の言語を見つけます。後の手順で、言語の識別子が必要です。
1. IDEの上部バーで、IDE名を選択し、**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **Code Suggestions Enabled Languages** > **Additional languages**で、サポートする各言語の識別子を追加します。識別子は、`html`のように小文字にする必要があります。複数の識別子をコンマで区切ります（例：`html,powershell,latex`）。また、各識別子に先頭のピリオドを追加しないでください。
1. **OK**を選択します。

{{< /tab >}}

{{< tab title="Eclipse" >}}

前提条件: 

- [GitLab for Eclipse plugin](../../../editor_extensions/eclipse/_index.md)をインストールして有効にしました。
- [Eclipse設定](../../../editor_extensions/eclipse/setup.md)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. Eclipseの下部メニューで、GitLabアイコンを選択します。
1. **Show Settings**を選択します。
1. **Code Suggestions Enabled Languages**セクションまでスクロールダウンします。
1. **Additional Languages**に、コンマで区切られた言語識別子のリストを追加します。識別子に先頭のピリオドを追加しないでください。たとえば、`html`、`md`、`powershell`を使用します。

{{< /tab >}}

{{< /tabs >}}
