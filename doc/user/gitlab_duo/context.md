---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo contextual awareness
---

Depending on which GitLab Duo feature you are using and where you are using it,
different information is available to help GitLab Duo make decisions and offer suggestions.

Information can be available:

- Always.
- Based on your location (the context changes when you navigate).
- When referenced explicitly. For example, you mention the information by URL, ID, or file path.

## GitLab Duo Chat

{{< history >}}

- Current page title and URL [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209186) in GitLab 18.6.

{{< /history >}}

The following context is available to GitLab Duo Chat.

### Always available

- GitLab documentation.
- General programming knowledge, best practices, and language specifics.
- Content in the file you're viewing or editing, including code before and after your cursor.
- When using Chat in the GitLab UI, the current page title and URL.
- The `/refactor`, `/fix`, and `/tests` slash commands have access to the latest
  [Repository X-Ray report](../project/repository/code_suggestions/repository_xray.md).

### Based on location

When you have any of these resources open, GitLab Duo knows about them.

- Files (included with the `/include` command)
- Code selected in a file
- Issues (GitLab Duo Enterprise only)
- Epics (GitLab Duo Enterprise only)
- [Other work item types](../work_items/_index.md#work-item-types) (GitLab Duo Enterprise only)

{{< alert type="note" >}}

In the IDEs, secrets and sensitive values that match known formats are redacted before
they are sent to GitLab Duo Chat.

{{< /alert >}}

In the UI, when you're in a merge request, GitLab Duo also knows about:

- The merge request itself (GitLab Duo Enterprise only).
- Commits in the merge request (GitLab Duo Enterprise only).
- The merge request pipeline's CI/CD jobs (GitLab Duo Enterprise only).

### When referenced explicitly

All of the resources that are available based on your location
are also available when you refer to them explicitly by their ID or URL.

## Software development flow

The following context is available to the software development flow in GitLab Duo Agent Platform.

### Always available

- General programming knowledge, best practices, and language specifics.
- Your entire project and all of its files that are tracked by Git.
- The GitLab [Search API](../../api/search.md), which is used to find related issues or merge requests.

### Based on location

- Files you have open in the IDE (close files if you do not want them used for context).

### When referenced explicitly

- Files
- Epics
- Issues
- Merge requests
- The merge request's pipelines

## Code Suggestions

The following context is available to Code Suggestions.

### Always available

- General programming knowledge, best practices, and language specifics.
- The name, extension, and content of the file you're viewing or editing,
  including content before and after your cursor.

### Based on location

- Files you have open in tabs in the IDE. Optional, but on by default.
  - These files provide GitLab Duo with information about the standards and practices in your project.
  - Close files if you do not want them used for context.
  - Code completion is aware of all [supported languages](../project/repository/code_suggestions/supported_extensions.md#supported-languages-by-ide).
  - Code generation is aware of files in these languages only:
    Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files), Vue, and YAML.
- Files imported in the file you're viewing or editing. Optional, and off by default.
  - These files provide GitLab Duo with information about the classes and methods in your file.
- Code selected in your editor.
- [Repository X-Ray files](../project/repository/code_suggestions/repository_xray.md).

{{< alert type="note" >}}

Secrets and sensitive values that match known formats are redacted before
they are used to generate code.
This applies to files added by using `/include`.

{{< /alert >}}

#### Change what Code Suggestions uses for context

You can change whether or not Code Suggestions uses other files as context.

##### Using open files as context

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464767) in GitLab 17.1 [with a flag](../../administration/feature_flags/_index.md) named `advanced_context_resolver`. Disabled by default.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 17.1 [with a flag](../../administration/feature_flags/_index.md) named `code_suggestions_context`. Disabled by default.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276) in GitLab Workflow for VS Code 4.20.0.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462) in GitLab Duo for JetBrains 2.7.0.
- [Added](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152) to the GitLab Neovim plugin on July 16, 2024.
- Feature flags `advanced_context_resolver` and `code_suggestions_context` enabled on GitLab.com in GitLab 17.2 and on GitLab Self-Managed in GitLab 17.4.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 18.6. Feature flag `code_suggestions_context` removed.

{{< /history >}}

By default, Code Suggestions uses the open files in your IDE for context when making suggestions.
However, you can turn this setting off.

Prerequisites:

- GitLab 17.2 or later. Earlier GitLab versions that support Code Suggestions
  cannot weigh the content of open tabs more heavily than other files in your project.
- A supported extension:
  - GitLab Workflow extension for VS Code 6.2.2 or later.
  - GitLab plugin for JetBrains IDEs 3.6.5 or later.
  - GitLab plugin for Neovim 1.1.0 or later.
  - GitLab extension for Visual Studio 0.51.0 or later.

To change open files being used as context:

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. On the top bar, go to **Code** > **Settings** > **Extensions**.
1. Search for GitLab Workflow in the list, and select the gear icon.
1. Select **Settings**.
1. In your **User** settings, search for `open tabs`.
1. Under **GitLab › Duo Code Suggestions: Open Tabs Context**,
   select or clear **Use the contents of open tabs as context**.

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Below **Additional languages**, select or clear **Send open tabs as context**.
1. Select **Apply** or **Save**.

{{< /tab >}}

{{< /tabs >}}

##### Using imported files as context

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/514124) in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `code_suggestions_include_context_imports`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/514124) in GitLab 17.11.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use the imported files in your IDE to provide context about your code project. Imported file context is supported for JavaScript and TypeScript files, including `.js`, `.jsx`, `.ts`, `.tsx`, and `.vue` file types.

## Exclude context from GitLab Duo

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Pro or Enterprise

{{< /details >}}
{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17124) in GitLab 18.2 [with a flag](../../administration/feature_flags/_index.md) named `use_duo_context_exclusion`. Disabled by default.
- Changed to beta in GitLab 18.4.
- Enabled by default in GitLab 18.5.

{{< /history >}}

You can control which project content is excluded as context for GitLab Duo. Use this to protect sensitive information such as password files and configuration files.

For Duo Chat, excluded context is enforced within [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md). Excluded context is not enforced within [GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md).

### Manage GitLab Duo context exclusions

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **General**.
1. Under **GitLab Duo**, in the **GitLab Duo context exclusions** section, select **Manage exclusions**.
1. Specify which project files and directories are excluded from GitLab Duo context, and select **Save exclusions**.
1. Optional. To delete an existing exclusion, select **Delete** ({{< icon name="remove" >}}) for the appropriate exclusion.
1. Select **Save changes**.
