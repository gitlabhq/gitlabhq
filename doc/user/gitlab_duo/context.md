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

The context available to GitLab Duo Chat depends on:

- Whether you're using [GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md) or [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md).
- Where you're using Chat.

### GitLab Duo Chat (Classic)

The following context is available to GitLab Duo Chat (Classic).

#### Always available

- GitLab documentation.
- General programming knowledge, best practices, and language specifics.
- Content in the file you're viewing or editing, including code before and after your cursor.
- When using Chat in the GitLab UI, the current page title and URL.
- The `/refactor`, `/fix`, `/tests`, and `/explain` slash commands have access to the latest
  Repository X-Ray report from [Code Suggestions](../duo_agent_platform/code_suggestions/repository_xray.md)
  or [Code Suggestions (Classic)](../project/repository/code_suggestions/repository_xray.md).

#### Based on location

When you have any of these resources open, GitLab Duo knows about them.

- Files you've told Chat about, by either:
  - Providing a direct file path.
  - In your IDE, including with the `/include` command.
- Code selected in a file.
- Issues (GitLab Duo Enterprise only).
- Epics (GitLab Duo Enterprise only).
- [Other work item types](../work_items/_index.md#work-item-types) (GitLab Duo Enterprise only).

> [!note]
> In the IDEs, secrets and sensitive values that match known formats are redacted before
> they are sent to GitLab Duo Chat.

In the UI, when you're in a merge request, GitLab Duo also knows about:

- The merge request itself (GitLab Duo Enterprise only).
- Commits in the merge request (GitLab Duo Enterprise only).
- The merge request pipeline's CI/CD jobs (GitLab Duo Enterprise only).

#### When referenced explicitly

All of the resources that are available based on your location
are also available when you refer to them explicitly by their ID or URL.

### GitLab Duo Chat (Agentic)

The following context is available to GitLab Duo Chat (Agentic).

#### Always available

- GitLab documentation.
- General programming knowledge, best practices, and language specifics.
- Your entire project and all of its files that are tracked by Git.
- The GitLab [Search API](../../api/search.md), which Chat uses to find related issues or merge requests.
- When using Chat in the GitLab UI, the current page title and URL.

#### Based on location

- In your IDE, files you have open. You can close those files if you do not want them used for context.
- In the GitLab UI, the current page context (for example, when viewing a merge request or issue).

#### When referenced explicitly

GitLab Duo Chat (Agentic) can autonomously retrieve and use:

- Files (by searching your project or when you provide file paths)
- Epics
- Issues
- Merge requests
- CI/CD pipelines and job logs
- Commits
- Work items

Unlike Classic Chat, Agentic Chat can search for these resources without requiring you to specify exact IDs or URLs. For example, you can ask "Find the merge request about authentication" and Chat searches for relevant merge requests.

#### Extended context in IDEs

When using GitLab Duo Chat (Agentic) in a supported IDE, you can extend Chat's capabilities:

- Use the [Model Context Protocol (MCP)](model_context_protocol/_index.md) to
  connect Chat to external data sources and tools.
- Use a [custom rules](customize_duo/custom_rules.md) or [AGENTS.md](customize_duo/agents_md.md)
  file to provide Chat with project-specific context, coding standards, and team practices.

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
  - Prerequisites:
    - GitLab 17.2 or later for optimal context weighting.
    - Supported IDE extensions. For version requirements, see
      [using open files as context](#using-open-files-as-context).
  - These files provide GitLab Duo with information about the standards and practices in your project.
  - Close files if you do not want them used for context.
  - The most recently opened or changed files are prioritized for context.
  - Code completion is aware of all languages supported by [Code Suggestions](../duo_agent_platform/code_suggestions/supported_extensions.md#supported-languages-by-ide) and [Code Suggestions (Classic)](../project/repository/code_suggestions/supported_extensions.md#supported-languages-by-ide).
  - Code generation is aware of files in these languages only:
    Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files), Vue, and YAML.
- Files imported in the file you're viewing or editing. Optional, and off by default.
  - These files provide GitLab Duo with information about the classes and methods in your file.
  - Supported for JavaScript and TypeScript files, including `.js`, `.jsx`, `.ts`, `.tsx`, and `.vue` file types.
- Code selected in your editor.
- Repository X-Ray files from [Code Suggestions](../duo_agent_platform/code_suggestions/repository_xray.md) or [Code Suggestions (Classic)](../project/repository/code_suggestions/repository_xray.md).

> [!note]
> Secrets and sensitive values that match known formats are redacted before
> they are used to generate code.
> This applies to files added by using `/include`.

For more information about how Code Suggestions uses context in IDEs, see the
[GitLab Language Server documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp#use-open-tabs-as-context).

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
1. Under **GitLab** > **Duo Code Suggestions: Open Tabs Context**,
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
- Feature flag `code_suggestions_include_context_imports` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/536129) in GitLab 18.0.

{{< /history >}}

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

You can control which project content is excluded as context for GitLab Duo.
Use this feature to protect sensitive information, like password and configuration files.

When you exclude content, all GitLab Duo features, with the exception of [GitLab Duo Chat (Classic)](../gitlab_duo_chat/_index.md),
exclude this information as context.

### Manage GitLab Duo context exclusions

To specify content that GitLab Duo excludes:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Under **GitLab Duo**, in the **GitLab Duo context exclusions** section, select **Manage exclusions**.
1. Specify which project files and directories are excluded from GitLab Duo context, and select **Save exclusions**.
1. Optional. To delete an existing exclusion, select **Delete** ({{< icon name="remove" >}}) for the appropriate exclusion.
1. Select **Save changes**.
