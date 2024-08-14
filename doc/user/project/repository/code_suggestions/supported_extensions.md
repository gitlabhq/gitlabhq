---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Code suggestions supports multiple editors and languages."
---

# Supported extensions and languages

DETAILS:
**Tier:** Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code suggestions are available in the following editor extensions and
for the following languages.

## Supported editor extensions

To use code suggestions, use one of these editor extensions:

| IDE                                                                        | Extension                                                                                                                   |
|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Visual Studio Code (VS Code)                                               | [GitLab Workflow for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)             |
| [GitLab Web IDE (VS Code in the Cloud)](../../../project/web_ide/index.md) | No configuration required.                                                                                                  |
| Microsoft Visual Studio (2022 for Windows)                                 | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDEs                                                             | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)                                    |
| Neovim                                                                     | [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)                                           |

A [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) is used in VS Code, Visual Studio, and Neovim. The Language Server supports faster iteration across more platforms. You can also configure it to support code suggestions in IDEs where GitLab doesn't provide official support.

You can express interest in other IDE extension support [in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## Supported languages

Code suggestions are aware of common popular programming languages, concepts, and
infrastructure-as-code interfaces, like Kubernetes Resource Model (KRM),
Google Cloud CLI, and Terraform.

Code suggestions support these languages:

| Language                     | Web IDE                    | VS Code                                                                                    | JetBrains IDEs         | Visual Studio 2022 for Windows | Neovim                                                                                                |
|-------------------------------|----------------------------|---------------------------------------------------------------------------------------------|-----------------------|--------------------------------|--------------------------------------------------------------------------------------------------------|
| C                             | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{dotted-circle}** No | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| C++                           | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| C#                            | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| CSS                           | **{check-circle}** Yes     | **{dotted-circle}** No                                                                     | **{dotted-circle}** No | **{dotted-circle}** No         | **{dotted-circle}** No                                                                                 |
| Go                            | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Google SQL                    | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| HAML                          | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| HTML                          | **{check-circle}** Yes     | **{dotted-circle}** No                                                                     | **{dotted-circle}** No | **{dotted-circle}** No         | **{dotted-circle}** No                                                                                 |
| Java                          | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| JavaScript                    | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Kotlin                        | **{dotted-circle}** No     | **{check-circle}** Yes <br><br>(Requires third-party extension providing Kotlin support) | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Markdown                      | **{check-circle}** Yes     |**{dotted-circle}** No                                                                     | **{dotted-circle}** No | **{dotted-circle}** No         | **{dotted-circle}** No                                                                                 |
| PHP                           | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Python                        | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Ruby                          | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Rust                          | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Scala                         | **{dotted-circle}** No     | **{check-circle}** Yes <br><br>(Requires third-party extension providing Scala support) | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Shell scripts (`bash` only)   | **{check-circle}** Yes     | **{dotted-circle}** No                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Svelte                        | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Swift                         | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| TypeScript                    | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |
| Terraform                     | **{dotted-circle}** No     | **{check-circle}** Yes <br><br>(Requires third-party extension providing Terraform support) | **{check-circle}** Yes | **{dotted-circle}** No         | **{check-circle}** Yes <br><br>(Requires third-party extension providing the `terraform` file type) |
| Vue                           | **{check-circle}** Yes     | **{check-circle}** Yes                                                                     | **{check-circle}** Yes | **{check-circle}** Yes         | **{check-circle}** Yes                                                                                 |

NOTE:
Some languages are not supported in all JetBrains IDEs, or might require additional
plugin support. Refer to the JetBrains documentation for specifics on your IDE.

Locally, you can add [more languages](#add-support-for-more-languages). For languages not listed in the table,
code suggestions might not function as expected.

## Manage languages for code suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#4210-2024-07-16) in GitLab Workflow for VS Code 4.21.0

You can customize your coding experience in VS Code by enabling or disabling code suggestions for specific supported languages.
You can do this by editing your `settings.json` file directly, or from the VS Code user interface:

1. In VS Code, open the extension settings for **GitLab Workflow**:
   1. On the top bar, go to **Code > Settings > Extensions**.
   1. Search for **GitLab Workflow** in the list, and select **Manage** (**{settings}**).
   1. Select **Extension Settings**.
1. In your **User** settings, find the section titled **AI Assisted Code Suggestions: Enabled Supported Languages**.
1. You will see a list of all supported languages with checkboxes next to each language.
1. To enable code suggestions for a language, ensure its checkbox is checked.
1. To disable code suggestions for a language, uncheck its checkbox.
1. Your changes are automatically saved and will take effect immediately.

When you disable code suggestions for a language, the Duo icon changes to show that suggestions are disabled
for this language. On hover, it shows **Code Suggestions are disabled for this language**.

### Add support for more languages

If your desired language doesn't have code suggestions available by default,
you can add support for your language locally.

::Tabs

:::TabTitle Visual Studio Code

Prerequisites:

- You have installed and enabled the
  [GitLab Workflow extension for VS Code](../../../../editor_extensions/visual_studio_code/index.md).
- You have completed the [VS Code extension setup](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup)
    instructions, and authorized the extension to access your GitLab account.

To do this:

1. Find your desired language in the list of
   [language identifiers](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem).
   You need the **Identifier** for your languages in a later step.
1. In VS Code, open the extension settings for **GitLab Workflow**:
   1. On the top bar, go to **Code > Settings > Extensions**.
   1. Search for **GitLab Workflow** in the list, and select **Manage** (**{settings}**).
   1. Select **Extension Settings**.
   1. In your **User** settings, find
      **GitLab › Ai Assisted Code Suggestions: Additional Languages** and select **Add Item**.
1. In **Item**, add the language identifier, and select **OK**.

:::TabTitle JetBrains IDEs

Prerequisites:

- You have installed and enabled the
  [GitLab plugin for JetBrains IDEs](../../../../editor_extensions/jetbrains_ide/index.md).
- You have completed the [Jetbrains extension setup](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup)
    instructions, and authorized the extension to access your GitLab account.

To do this:

1. Find your desired language in the list of
   [language identifiers](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem).
   You need the **Identifier** for your languages in a later step.
1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Code Suggestions Enabled Languages > Additional languages** add the language identifiers, separated by comma (`,`).
1. Select **OK**.

::EndTabs

## View multiple code suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325) in GitLab 17.1.

For a code completion suggestion in VS Code, multiple suggestion options
might be available. To view all available suggestions:

1. Hover over the code completion suggestion.
1. Scroll through the alternatives. Either:
   - Use keyboard shortcuts:
     - On a Mac, press <kbd>Option</kbd> + <kbd>]</kbd> to view the
       next suggestion, and <kbd>Option</kbd> + <kbd>&#91;</kbd> to view the previous
       suggestions.
     - On Windows, press <kbd>Alt</kbd> + <kbd>]</kbd> to view the
       next suggestion, and <kbd>Alt</kbd> + <kbd>&#91;</kbd> to view the previous
       suggestions.
   - On the dialog that's displayed, select the right or left arrow to see next or previous options.
1. Press <kbd>Tab</kbd> to apply the suggestion you prefer.
