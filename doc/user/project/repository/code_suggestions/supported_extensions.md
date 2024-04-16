---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Supported extensions and languages

DETAILS:
**Tier:** Premium or Ultimate with GitLab Duo Pro
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Code Suggestions is available in the following editor extensions and
for the following languages.

## Supported editor extensions

To use Code Suggestions, use one of these editor extensions:

| IDE              | Extension              |
|------------------|------------------------|
| VSCode           | [VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)|
| [GitLab WebIDE (VS Code in the Cloud)](../../../project/web_ide/index.md)  | No configuration required. |
| Microsoft Visual Studio | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
| JetBrains IDEs  | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) |
| Neovim           | [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) |

A [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) is used in VS Code, Visual Studio, and Neovim. The Language Server supports faster iteration across more platforms. You can also configure it to support Code Suggestions in IDEs where GitLab doesn't provide official support. 

You can express interest in other IDE extension support [in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## Supported languages

Code Suggestions is aware of common popular programming languages, concepts, and
infrastructure-as-code interfaces, like Kubernetes Resource Model (KRM),
Google Cloud CLI, and Terraform.

The following languages are supported:

| Language         | VS Code                | JetBrains IDEs         | Visual Studio          | Neovim |
|------------------|------------------------|------------------------|------------------------|--------|
| C                | **{check-circle}** Yes | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes |
| C++              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| C#               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| CSS              | **{dotted-circle}** No  | **{check-circle}** Yes | **{check-circle}** Yes  | **{check-circle}** Yes  |
| Go               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Google SQL       | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| HTML             | **{dotted-circle}** No  | **{check-circle}** Yes | **{check-circle}** Yes  | **{check-circle}** Yes  |
| Java             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| JavaScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Kotlin           | **{check-circle}** Yes <br><br>(Requires third-party extension providing Kotlin support) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| PHP              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Python           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Ruby             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Rust             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Scala            | **{check-circle}** Yes <br><br>(Requires third-party extension providing Scala support) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Shell scripts (`bash` only) | **{dotted-circle}** No  | **{check-circle}** Yes | **{check-circle}** Yes  | **{check-circle}** Yes  |
| Swift            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| TypeScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Terraform        | **{check-circle}** Yes <br><br>(Requires third-party extension providing Terraform support) | **{check-circle}** Yes | **{dotted-circle}** No | **{check-circle}** Yes <br><br>(Requires third-party extension providing the `terraform` file type) |

NOTE:
Some languages are not supported in all JetBrains IDEs, or might require additional
plugin support. Refer to the JetBrains documentation for specifics on your IDE.

For languages not listed in the table, Code Suggestions might not function as expected.
