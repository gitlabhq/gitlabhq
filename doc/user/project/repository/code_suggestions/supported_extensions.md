---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Code Suggestions supports multiple editors and languages."
---

# Supported extensions and languages

DETAILS:
**Tier:** Premium or Ultimate with [GitLab Duo Pro](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Suggestions is available in the following editor extensions and
for the following languages.

## Supported editor extensions

To use Code Suggestions, use one of these editor extensions:

| IDE                                                                        | Extension                                                                                                                   |
|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| Visual Studio Code (VS Code)                                               | [VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)             |
| [GitLab Web IDE (VS Code in the Cloud)](../../../project/web_ide/index.md) | No configuration required.                                                                                                  |
| Microsoft Visual Studio (2022 for Windows)                                 | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDEs                                                             | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)                                    |
| Neovim                                                                     | [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)                                           |

A [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) is used in VS Code, Visual Studio, and Neovim. The Language Server supports faster iteration across more platforms. You can also configure it to support Code Suggestions in IDEs where GitLab doesn't provide official support.

You can express interest in other IDE extension support [in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## Supported languages

Code Suggestions is aware of common popular programming languages, concepts, and
infrastructure-as-code interfaces, like Kubernetes Resource Model (KRM),
Google Cloud CLI, and Terraform.

Code Suggestions supports these languages:

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

For languages not listed in the table, Code Suggestions might not function as expected.

## Use open tabs as context

> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206) in GitLab 17.2.

To enhance the accuracy and relevance of GitLab Duo Code Suggestions, enable the use of
open tabs as context in your IDE settings. This feature uses the contents of files most recently
opened or changed in your IDE to provide more tailored code suggestions, within certain truncation limits.
This extra context gives you:

- More accurate and relevant code suggestions
- Better alignment with your project's standards and practices
- Improved context for new file creation

Open tabs as context supports these languages:

- Code Completion: All configured languages.
- Code Generation: Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files),
  Vue, and YAML.

## Enable open tabs as context

Prerequisites:

- Requires GitLab 17.1 or later.
- For GitLab self-managed instances, enable the `code_suggestions_context`and the
  `advanced_context_resolver` [feature flags](../../../feature_flags.md).
- GitLab Duo Code Suggestions enabled for your project
- For Visual Studio Code, requires the GitLab Workflow extension, version 4.14.2 or later.

::Tabs

:::TabTitle Visual Studio Code

1. Install the [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
   from the Visual Studio Marketplace.
1. Configure the extension following the
   [setup instructions](https://gitlab.com/gitlab-org/gitlab-vscode-extension#extension-settings).
1. Enable the feature by toggling the `gitlab.aiAssistedCodeSuggestions.enabledSupportedLanguages` setting.

:::TabTitle JetBrains IDEs

For installation instructions for JetBrains IDEs, see the
[GitLab JetBrains Plugin documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#toggle-sending-open-tabs-as-context).

::EndTabs

When you're ready to start coding:

1. Open relevant files, including configuration files, to provide better context.
1. Close any files you don't want to be used as context.

## View Multiple Code Suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325) in GitLab 17.1.

For a code completion suggestion in VS Code, multiple suggestion options
might be available. To view all available suggestions:

1. Hover over the code completion suggestion.
1. Scroll through the alternatives. Either:
   - Use keyboard shortcuts. Press <kbd>Option</kbd> + <kbd>`]`</kbd> to view the
     next suggestion, and <kbd>Option</kbd> + <kbd>`[`</kbd> to view the previous
     suggestions.
   - Select the right or left arrow to see next or previous options.
1. Press <kbd>Tab</kbd> to apply the suggestion you prefer.

## Add additional languages for Code Suggestions

If your desired language isn't [enabled by default](#supported-languages) for Code Suggestions,
you can add support for it locally.

Prerequisites:

- You have installed and enabled the
  [GitLab Workflow extension for VS Code](../../../../editor_extensions/visual_studio_code/index.md#download-the-extension).
- You have completed the [extension setup](https://gitlab.com/gitlab-org/gitlab-vscode-extension/#setup)
  instructions, and authorized the extension to access your GitLab account.

To do this:

1. Find your desired language in the list of
   [language identifiers](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocumentItem)
   for VS Code. You need the **Identifier** for a later step.
1. In VS Code, open the extension settings for **GitLab Workflow**:
   1. On the top bar, go to **Code > Settings > Extensions**.
   1. Search for **GitLab Workflow** in the list, and select **Manage** (**{settings}**).
   1. Select **Extension Settings**.
   1. In your **User** settings, find
      **GitLab › Ai Assisted Code Suggestions: Additional Languages** and select **Add Item**.
1. In **Item**, add the language identifier, and select **OK**.
