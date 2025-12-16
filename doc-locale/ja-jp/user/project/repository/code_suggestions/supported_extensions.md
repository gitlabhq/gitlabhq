---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案は、複数のエディタと言語をサポートしています。
title: サポートされる拡張機能と言語
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

コード提案は、以下のエディタ拡張機能と言語で利用できます。

## サポートされているエディタ拡張機能 {#supported-editor-extensions}

コード提案を使用するには、次のいずれかのエディタ拡張機能を使用します:

| IDE                                                             | 拡張機能 |
|-----------------------------------------------------------------|-----------|
| Visual Studio Code（VS Code）                                    | [VS Code用GitLab Workflow拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) |
| [GitLab Web IDE](../../web_ide/_index.md)（クラウド上のVS Code） | 必要な設定はありません。 |
| Microsoft Visual Studio（Windows版2022）                      | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDE                                                  | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) |
| Neovim                                                          | [`gitlab.vim`プラグイン](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) |
| Eclipse                                                          | [GitLab for Eclipse](../../../../editor_extensions/eclipse/setup.md) |

[GitLab言語サーバー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)が、VS Code、Visual Studio、Eclipse、Neovimで使用されています。この言語サーバーは、より多くのプラットフォームでより高速なイテレーションをサポートします。公式サポートがGitLabから提供されていないIDEでコード提案をサポートするように設定することもできます。

他のIDE拡張機能のサポートについては、[このイシュー](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78)で関心を示すことができます。

## IDE別のサポート対象言語 {#supported-languages-by-ide}

次の表では、コード提案がデフォルトでサポートする言語とIDEについて詳しく説明します。

コード提案は他の言語でも動作しますが、[手動でサポートを追加](#add-support-for-more-languages)する必要があります。

| 言語                            | Web IDE                                     | VS Code                                                                                                          | JetBrains IDE                              | Visual Studio 2022 for Windows              | Neovim                                                                                                                   | Eclipse |
|-------------------------------------|---------------------------------------------|------------------------------------------------------------------------------------------------------------------|---------------------------------------------|---------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|---------|
| C                                   | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| C++                                 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| C#                                  | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| CSS                                 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応                                                                               | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応                                                                                       | {{< icon name="dash-circle" >}}非対応 |
| Go                                  | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Google SQL                          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="dash-circle" >}}非対応 |
| HAML                                | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| \`\`\`html                                | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応                                                                               | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応                                                                                       | {{< icon name="dash-circle" >}}非対応 |
| Java                                | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| JavaScript                          | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Kotlin                              | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 <br><br>（Kotlinサポートを提供するサードパーティ製拡張機能が必要です）    | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Markdown                            | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応                                                                               | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応          | {{< icon name="dash-circle" >}}非対応                                                                                       | {{< icon name="dash-circle" >}}非対応 |
| PHP                                 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Python                              | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Ruby                                | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Rust                                | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Scala                               | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 <br><br>（Scalaサポートを提供するサードパーティ製拡張機能が必要です）     | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| シェルスクリプト（`bash`のみ）         | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応                                                                               | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Svelte                              | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Swift                               | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| TypeScript(`.ts`および`.tsx`ファイル) | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |
| Terraform                           | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 <br><br>（Terraformサポートを提供するサードパーティ製拡張機能が必要です） | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="dash-circle" >}}非対応          | {{< icon name="check-circle-filled" >}}対応 <br><br>（`terraform`ファイルタイプを提供するサードパーティ製拡張機能が必要です） | {{< icon name="check-circle-filled" >}}対応 |
| Vue                                 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                      | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応 | {{< icon name="check-circle-filled" >}}対応                                                                              | {{< icon name="check-circle-filled" >}}対応 |

{{< alert type="note" >}}

一部の言語は、すべてのJetBrains IDEでサポートされていません。または、追加のプラグインサポートが必要な場合があります。お使いのIDEの具体的な内容については、JetBrainsのドキュメントを参照してください。

{{< /alert >}}

## Infrastructure as Code（IaC）のサポート {#support-for-infrastructure-as-code-iac}

コード提案は、次のものを含むInfrastructure as Codeのインターフェースで動作します:

- Kubernetesリソースモデル（KRM）
- Google Cloud CLI
- Terraform

## コード提案の言語を管理する {#manage-languages-for-code-suggestions}

{{< history >}}

- VS Code用GitLab Workflow 4.21.0で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#4210-2024-07-16)されました。

{{< /history >}}

特定のサポートされている言語に対してコード提案を有効または無効にすることで、VS Codeでのコーディングエクスペリエンスをカスタマイズできます。これは、`settings.json`ファイルを直接編集するか、VS Codeユーザーインターフェースから行うことができます:

1. VS Codeで、**GitLab Workflow**の拡張機能設定を開きます:
   1. 上部のバーで、**コード** > **設定** > **Extensions**（拡張機能）に移動します。
   1. リストで**GitLab Workflow**を検索し、**管理** ({{< icon name="settings" >}}) を選択します。
   1. **Extension Settings**を選択します。
1. **ユーザー**の設定で、**AIアシストコード提案: サポートされている言語を有効にする**というセクションを見つけます。
1. 言語のコード提案を有効にするには、そのチェックボックスをオンにします。
1. 言語のコード提案を無効にするには、そのチェックボックスをオフにします。
1. 変更は自動的に保存され、すぐに有効になります。

言語のコード提案を無効にすると、Duoアイコンが変わり、この言語では提案が無効になっていることが示されます。カーソルを合わせると、**Code Suggestions are disabled for this language**（この言語ではコード提案が無効になっている）と表示されます。

## より多くの言語のサポートを追加 {#add-support-for-more-languages}

目的の言語でコード提案がデフォルトで使用できない場合は、ローカルで言語のサポートを追加できます。ただし、コード提案が期待どおりに機能しない可能性があります。

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

前提要件: 

- [VS Code用GitLab Workflow拡張機能](../../../../editor_extensions/visual_studio_code/_index.md)をインストールして有効にしました。
- [VS Code拡張機能の設定](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. [言語識別子](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem)のリストで、目的の言語を見つけます。後の手順で言語の**識別子**が必要です。
1. VS Codeで、**GitLab Workflow**の拡張機能設定を開きます:
   1. 上部のバーで、**コード** > **設定** > **Extensions**（拡張機能）に移動します。
   1. リストで**GitLab Workflow**を検索し、**管理** ({{< icon name="settings" >}}) を選択します。
   1. **Extension Settings**を選択します。
   1. **ユーザー**の設定で、**GitLab › AIアシストコード提案を見つけます: 追加の言語**を選択し、**Add Item**（項目の追加）を選択します。
1. 「**Item**（項目）」で、サポートする各言語の識別子を追加します。識別子は、`html`や`powershell`のように小文字にする必要があります。各識別子にファイルサフィックスから先頭のピリオドを追加しないでください。
1. **OK**を選択します。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

前提要件: 

- [JetBrains IDE用GitLabプラグイン](../../../../editor_extensions/jetbrains_ide/_index.md)をインストールして有効にしました。
- [Jetbrains拡張機能設定](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. [言語識別子](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem)のリストで、目的の言語を見つけます。後の手順で言語の識別子が必要です。
1. IDEの上部バーでIDE名を選択し、次に**設定**を選択します。
1. 左側のサイドバーで、**ツール** > **GitLab Duo**を選択します。
1. **Code Suggestions Enabled Languages**（コード提案が有効になっている言語） > **Additional languages**（追加の言語）で、サポートする各言語の識別子を追加します。識別子は、`html`のように小文字にする必要があります。複数の識別子をコンマで区切ります（`html,powershell,latex`など）。また、各識別子に先頭のピリオドを追加しないでください。
1. **OK**を選択します。

{{< /tab >}}

{{< tab title="Eclipse" >}}

前提要件: 

- [GitLab for Eclipseプラグイン](../../../../editor_extensions/eclipse/_index.md)をインストールして有効にしました。
- [Eclipse設定](../../../../editor_extensions/eclipse/setup.md)の手順を完了し、GitLabアカウントにアクセスするための拡張機能を承認しました。

これを行うには、次の手順を実行します:

1. Eclipseの下部メニューで、GitLabアイコンを選択します。
1. **Show Settings**（設定を表示）を選択します。
1. **Code Suggestions Enabled Languages**（コード提案が有効になっている言語）セクションまでスクロールダウンします。
1. **Additional Languages**（追加の言語）で、言語識別子のコンマ区切りリストを追加します。識別子に先頭のピリオドを追加しないでください。たとえば、`html`、`md`、および`powershell`を使用します。

{{< /tab >}}

{{< /tabs >}}
