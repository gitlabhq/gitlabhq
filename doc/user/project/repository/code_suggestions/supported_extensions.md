---
stage: AI Coding
group: DAP Repository Flows
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Code Suggestions supports multiple editors and languages.
title: Supported extensions and languages
---

Code Suggestions is available in the following editor extensions and
for the following languages.

## Supported editor extensions

To use Code Suggestions, use one of these editor extensions:

| IDE                                                             | Extension |
|-----------------------------------------------------------------|-----------|
| Visual Studio Code (VS Code)                                    | [GitLab for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) |
| [GitLab Web IDE (VS Code in the Cloud)](../../web_ide/_index.md) | No configuration required. |
| Microsoft Visual Studio (2022 for Windows)                      | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDEs                                                  | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) |
| Neovim                                                          | [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) |
| Eclipse                                                          | [GitLab for Eclipse](../../../../editor_extensions/eclipse/setup.md) |

A [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) is used in VS Code, JetBrains IDEs, Visual Studio, Eclipse, and Neovim. The Language Server supports faster iteration across more platforms. You can also configure it to support Code Suggestions in IDEs where GitLab doesn't provide official support.

You can express interest in other IDE extension support [in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## Supported languages by IDE

In VS Code, Code Suggestions works with all languages that the IDE supports, except plain text.
For some languages, like Kotlin, Scala, or Terraform, you must install a third-party extension to
add support for the language to VS Code.
You can [turn off Code Suggestions for specific languages](#manage-languages-for-code-suggestions).

For the other IDEs, the following table lists the languages Code Suggestions supports by default.
Code Suggestions also works with other languages, but you must [manually add support](#add-support-for-more-languages).

| Language                            | Web IDE     | JetBrains IDEs | Visual Studio 2022 for Windows | Neovim                   | Eclipse |
|-------------------------------------|-------------|----------------|--------------------------------|--------------------------|---------|
| C                                   | {{< yes >}} | {{< no >}}     | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| C++                                 | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| C#                                  | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| CSS                                 | {{< yes >}} | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| Go                                  | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Google SQL                          | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< no >}} |
| HAML                                | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| HTML                                | {{< yes >}} | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| Java                                | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| JavaScript                          | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Kotlin                              | {{< no >}}  | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Markdown                            | {{< yes >}} | {{< no >}}     | {{< no >}}                     | {{< no >}}               | {{< no >}} |
| PHP                                 | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Python                              | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Ruby                                | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Rust                                | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Scala                               | {{< no >}}  | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Shell scripts (`bash` only)         | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Svelte                              | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Swift                               | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| TypeScript (`.ts` and `.tsx` files) | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |
| Terraform                           | {{< no >}}  | {{< yes >}}    | {{< no >}}                     | {{< yes >}}[^requires-third-party] | {{< yes >}} |
| Vue                                 | {{< yes >}} | {{< yes >}}    | {{< yes >}}                    | {{< yes >}}              | {{< yes >}} |

[^requires-third-party]: Neovim requires a third-party extension that provides the `terraform` file type.

> [!note]
> Some languages are not supported in all JetBrains IDEs, or might require additional
> plugin support. Refer to the JetBrains documentation for specifics on your IDE.

## Support for Infrastructure-as-Code (IaC)

Code Suggestions works with infrastructure-as-code interfaces, including:

- Kubernetes Resource Model (KRM)
- Google Cloud CLI
- Terraform

## Manage languages for Code Suggestions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#4210-2024-07-16) in GitLab for VS Code 4.21.0
- Suggestions for all languages [turned on](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.92.0) by default in GitLab for VS Code 6.92.0 during the GitLab 19.5 release.

{{< /history >}}

In VS Code, Code Suggestions is turned on for all languages by default.
You can turn it off for specific languages.

To turn Code Suggestions off or on for the language of the current file:

1. In VS Code, open a file in the language.
1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Select **GitLab: Toggle Code Suggestions for current language**.

You can also select the GitLab Duo icon in the status bar, and then select the option
to turn Code Suggestions off or on for the current language.

To turn off Code Suggestions for more than one language:

1. In VS Code, open the Settings editor:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. Select **Extensions** > **GitLab** > **GitLab Duo**.
1. Under **GitLab › Duo Code Suggestions: Disabled Languages**, select **Add Item**.
1. Enter the [language identifier](https://code.visualstudio.com/docs/languages/identifiers#_known-language-identifiers),
   like `python` or `markdown`.
1. Select **OK**.

Your changes save automatically and take effect immediately.

When you turn off Code Suggestions for a language, the GitLab Duo icon changes to show that suggestions are not available
for this language.

If you turned off languages in the **Enabled Supported Languages** setting of an earlier version
of the extension, it adds them to **Disabled Languages** when you update.

## Add support for more languages

In VS Code, you do not need to add languages. Code Suggestions works with all languages except plain text.

In other IDEs, if your desired language doesn't have Code Suggestions available by default,
you can add support for your language locally.
However, Code Suggestions might not function as expected.

{{< tabs >}}

{{< tab title="JetBrains IDEs" >}}

Prerequisites:

- You have installed and enabled the
  [GitLab Duo plugin for JetBrains IDEs](../../../../editor_extensions/jetbrains_ide/_index.md).
- You have completed the [JetBrains extension setup](../../../../editor_extensions/jetbrains_ide/setup.md)
  instructions, and authorized the extension to access your GitLab account.

To do this:

1. Find your desired language in the list of
   [language identifiers](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem).
   You need the identifier for your languages in a later step.
1. In your IDE, in the top bar, select your IDE name, then select **Settings**.
1. In the left sidebar, select **Tools** > **GitLab Duo**.
1. Under **Code Suggestions Enabled Languages** > **Additional languages**, add the identifier for each language
   you want to support. Identifiers should be in lowercase, like `html`. Separate multiple identifiers with commas,
   like `html,powershell,latex`, and don't add leading periods to each identifier.
1. Select **OK**.

{{< /tab >}}

{{< tab title="Eclipse" >}}

Prerequisites:

- You have installed and enabled the [GitLab for Eclipse plugin](../../../../editor_extensions/eclipse/_index.md).
- You have completed the [Eclipse setup](../../../../editor_extensions/eclipse/setup.md)
  instructions, and authorized the extension to access your GitLab account.

To do this:

1. In the Eclipse bottom toolbar, select the GitLab icon.
1. Select **Show Settings**.
1. Scroll down to the **Code Suggestions Enabled Languages** section.
1. In **Additional Languages**, add a comma-separated list of language identifiers. Don't
   add leading periods to the identifiers. For example, use `html`, `md`, and `powershell`.

{{< /tab >}}

{{< /tabs >}}
