---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: Profile preferences
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Tabs [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257460) in GitLab 19.6 [with a flag](../../administration/feature_flags/_index.md) named `preferences_tabs`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of the tabbed layout is controlled by a feature flag.
> For more information, see the history.
> Without tabs, the same sections appear on one page.

You can update your preferences to change the look and feel of GitLab.

The preferences page is organized into tabs:

- **Appearance**: Color mode, theme, layout width, syntax highlighting, and diff colors.
- **Behavior**: Default views, keyboard shortcuts, diffs, and following users.
- **Editing**: The text editor, Markdown behavior, and code display.
- **Localization**: Language, calendar, and time preferences.
- **AI assistance**: Your default group for GitLab Duo and your GitLab Orbit settings.
  This tab is shown only when these settings are available to you.
- **Integrations**: Third-party services enabled by your administrator.
  This tab is shown only when an integration is available.

To open your preferences:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.

## Appearance

Use the **Appearance** tab to change how GitLab looks.

### Change the mode

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252) in GitLab 13.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/524846) from experiment to beta in GitLab 17.11.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/470413) from **Appearance** to **Mode** in GitLab 18.1.

{{< /history >}}

You can change the color mode of the interface to be light, dark, or automatically update based on device preferences.

To change the appearance:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Appearance** tab, in the **Color mode** section, select an option.
1. Select **Save changes**.

### Change the navigation theme

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/470413) from **Color theme** to **Navigation theme** in GitLab 18.1.
- Themes: Light Indigo, Light Blue, Light Green, and Light Red [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200475) in GitLab 18.4.

{{< /history >}}

You can change the navigation theme of the GitLab UI. These colors are displayed in the left sidebar.
Using individual navigation themes might help you differentiate between your different
GitLab instances.

To change the navigation theme:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Appearance** tab, in the **Theme** section, select a theme.

### Change the layout width on the UI

You can stretch content on the GitLab UI to fill the entire page. By default, page content is fixed at 1280 pixels wide.

To change the layout width of your UI:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Appearance** tab, in the **Layout** section, choose **Fixed** or **Fluid**.
1. Select **Save changes**.

### Change the syntax highlighting theme

Syntax highlighting is a feature in code editors and IDEs. The highlighter assigns a color to each type of code, such as strings and comments.

To change the syntax highlighting theme:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Appearance** tab, in the **Syntax highlighting** section, select a theme.
1. Select **Save changes**.

To view the updated syntax highlighting theme, refresh your project's page.

To customize the syntax highlighting theme, you can also [use the Application settings API](../../api/settings.md#available-settings). Use `default_syntax_highlighting_theme` and `default_dark_syntax_highlighting_theme` to change the syntax highlighting colors on a more
granular level.

If these steps do not work, your programming language might not be supported by the syntax highlighters.
For more information, view [Rouge Ruby Library](https://github.com/rouge-ruby/rouge) for guidance on code files and Snippets. View [Monaco Editor](https://microsoft.github.io/monaco-editor/) and [Monarch](https://microsoft.github.io/monaco-editor/monarch.html) for guidance on the Web IDE.

### Change the diff colors

Diffs use two different background colors to show changes between versions of code. By default, the original file is in red, and the changes are in green.

To change the diff colors:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Appearance** tab, go to the **Diff colors** section.
1. Select a color or enter a color code.
1. Select **Save changes**.

To change back to the default colors, clear the **Color for removed lines** and **Color for added lines** text boxes and select **Save changes**.

## Behavior

Use the **Behavior** tab to choose the default content for your homepage, group, and project overview pages, and to customize keyboard shortcuts, diffs, and following users.

### Choose your homepage

{{< history >}}

- [Homepage options changed](https://gitlab.com/groups/gitlab-org/-/work_items/13066) in GitLab 17.9 [with a feature flag](../../administration/feature_flags/_index.md) named `your_work_projects_vue`. Disabled by default.
- [Homepage option changes generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.
- [Personal homepage introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/546151) in GitLab 18.1 [with a feature flag](../../administration/feature_flags/_index.md) named `personal_homepage`. Disabled by default.
- [Personal homepage enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/554048) in GitLab 18.4 for a subset of users.
- [Personal homepage enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/work_items/17932) in GitLab 18.5.
- [Personal homepage generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/561388) in GitLab 19.4. Feature flag `personal_homepage` removed.

{{< /history >}}

Control what page you view when you select the GitLab logo ({{< icon name="tanuki" >}}). You can set your homepage to be Personal homepage (default), Your Contributed Projects, Your Groups, Your Activity, and other content.

To choose your homepage view:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Default views** section, from the **Homepage** dropdown list, select an option.
1. Select **Save changes**.

### Customize default content on your group overview page

You can change the main content on your group overview page. Your group overview page is the page that shows when you select **Groups** in the left sidebar. You can customize the default content for your group overview page to the:

- Details Dashboard (default), which includes an overview of group activities and projects.
- Security Dashboard, which might include group security policies and other security topics.

For more information, view [Groups](../group/_index.md).

To change the default content on your group overview page:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Default views** section, from the **Group overview content** dropdown list, select an option.
1. Select **Save changes**.

### Customize default content on your project overview page

Your project overview page is the page you view when you select **Project overview** in the left sidebar. You can set your main project overview page to the Activity page, the README file, and other content.

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Default views** section, from the **Project overview content** dropdown list, select an option.
1. Select **Save changes**.

### Hide shortcut buttons

Shortcut buttons precede the list of files on a project's overview page. These buttons provide links to parts of a project, such as the README file or license agreements.

To hide shortcut buttons on the project overview page:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Default views** section, clear the **Show shortcut buttons above files on project overview** checkbox.
1. Select **Save changes**.

### Turn off keyboard shortcuts

By default, you can use [keyboard shortcuts](../shortcuts.md) to navigate GitLab.

To turn off keyboard shortcuts:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Keyboard shortcuts** section, clear the **Enable keyboard shortcuts** checkbox.
1. Select **Save changes**.

### Show whitespace changes in diffs

View changes to whitespace in diff files. For more information on whitespaces, view [Show whitespace characters in the Web IDE](#show-whitespace-characters-in-the-web-ide).

To view changes to whitespace in diffs:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Diffs** section, select the **Show whitespace changes in diffs** checkbox.
1. Select **Save changes**.

For more information on diffs, view [Change the diff colors](#change-the-diff-colors).

### Show one file per page in a merge request

The **Changes** tab lets you view all file changes in a merge request on one page.
Instead, you can choose to view one file at a time.

To show one file per page on the **Changes** tab:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Diffs** section, select the **Show one file at a time on merge request's Changes tab** checkbox.
1. Select **Save changes**.

Then, to move between files on the **Changes** tab, below each file, select the **Previous** and **Next** buttons.

### Control follower engagement

Turn off the ability to follow or be followed by other GitLab users. By default, your user profile, including your name and profile photo, is public in the **Following** tabs of other users. When you deactivate this setting:

- GitLab deletes all of your followers and followed connections.
- GitLab automatically removes your user profile from the pages of each connection.

To remove the ability to be followed by and follow other users:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Behavior** tab, in the **Follow users** section, clear the **Enable follow users** checkbox.
1. Select **Save changes**.

To access your **Followers** and **Following** tabs:

- In the upper-right corner, select your avatar.
- Select **Followers** or **Following**.

## Editing

Use the **Editing** tab to choose your default text editor and customize how Markdown and code behave.

### Set the default text editor

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423104) in GitLab 17.7.
- Default for new users [set to rich text editor](https://gitlab.com/gitlab-org/gitlab/-/issues/536611) in 18.2.

{{< /history >}}

By default, all new users see the **Rich text editor** when editing content.
You can change the default editor for editing content in GitLab.

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Text editor** section, ensure the **Enable default text editor** checkbox is selected.
1. Choose either **Rich text editor** or **Plain text editor** as your default.
1. Select **Save changes**.

### Auto-enclose characters

Automatically add the corresponding closing character to text when you type the opening character. For example, you can automatically insert a closing bracket when you type an opening bracket. This setting works only in description and comment boxes and for the following characters: `**"`, `'`, ```, `(`, `[`, `{`, `<`, `*`, `_**`.

To auto-enclose characters in description and comment boxes:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Markdown** section, select the **Surround text selection when typing quotes or brackets** checkbox.
1. Select **Save changes**.

In a description or comment box, you can now type a word, highlight it, then type an
opening character. Instead of replacing the text, the closing character is added to the end.

### Automate new list items

Create a new list item when you press <kbd>Enter</kbd> in a list in description and comment boxes.

To add a new list item when you press the <kbd>Enter</kbd> key:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Markdown** section, select the **Automatically add new list items** checkbox.
1. Select **Save changes**.

### Maintain cursor indentation

Maintain the indentation when you press <kbd>Enter</kbd>. The cursor on the new line is automatically indented the same as the previous line. This setting works only in description and comment boxes.

To maintain the indentation when you press the <kbd>Enter</kbd> key:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Markdown** section, select the **Maintain indentation** checkbox.
1. Select **Save changes**.

### Turn off emoji autocomplete

By default, when you type a colon (`:`) in a description or comment box, GitLab suggests
matching emoji. If you type colons for other reasons, such as in languages that put a space
before a colon, you can turn off these suggestions. When turned off, you can still insert emoji
by other means, such as copy and paste.

To turn off emoji autocomplete:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Markdown** section, clear the **Enable emoji autocomplete** checkbox.
1. Select **Save changes**.

### Show whitespace characters in the Web IDE

Whitespace characters are any blank characters in a text, such as spaces and indentations. You might use whitespace to structure content in code. If your programming language is sensitive to whitespaces, the Web IDE can detect changes to them.

To render whitespace in the Web IDE:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Code** section, select the **Render whitespace characters in the Web IDE** checkbox.
1. Select **Save changes**.

You can view changes to whitespace in diffs.

To view diffs on the Web IDE, follow these steps:

1. In the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Under the **Changes** tab, select your file.

### Change the tab width

Change the default size of tabs in diffs, blobs, and snippets. The Web IDE, file editor, and Markdown editor do not support this feature.

To adjust the default tab width:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Editing** tab, in the **Code** section, for **Tab width**, enter a value.
1. Select **Save changes**.

## Localization

Use the **Localization** tab to change your language, calendar start day, and time preferences.

### Change your display language on the GitLab UI

GitLab supports multiple languages on the UI.

To choose a language for the GitLab UI:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Localization** tab, in the **Language and region** section, under **Language**, select an option.
1. Select **Save changes**.

You might need to refresh your page to view the updated language.

### Customize your contribution calendar start day

Choose which day of the week the contribution calendar starts with. The contribution calendar shows project contributions over the past year. You can view this calendar on each user profile. To access your user profile:

- In the upper-right corner, select your avatar, and select your name or username.

To change your contribution calendar start day:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Localization** tab, in the **Language and region** section, under **First day of the week**, select an option.
1. Select **Save changes**.

After you change your calendar start day, refresh your user profile page.

### Show exact times instead of relative times

Customize the format used to display times of activities on your group and project overview pages and user profiles. You can display times in a:

- Relative format, for example `30 minutes ago`.
- Absolute format, for example `September 3, 2022, 3:57 PM`.

To use exact times on the GitLab UI:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Localization** tab, in the **Time preferences** section, clear the **Use relative times** checkbox.
1. Select **Save changes**.

### Customize time format

You can customize the format used to display times of activities on your group and project overview pages and user
profiles. You can display times as:

- 12 hour format. For example: `2:34 PM`.
- 24 hour format. For example: `14:34`.

You can also follow your system's setting.

To customize the time format:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Localization** tab, in the **Time preferences** section, under **Time format**, select either the **System**, **12-hour**, or **24-hour** option.
1. Select **Save changes**.

## AI assistance

Use the **AI assistance** tab to configure GitLab Duo and GitLab Orbit for your account.

### Set a default GitLab Duo namespace

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/552081) in GitLab 18.3 with a [flag](../../administration/feature_flags/_index.md) named `ai_user_default_duo_namespace`. Disabled by default.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/560319) in GitLab 18.4.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/569140) `ai_user_default_duo_namespace` feature flag in GitLab 18.7.

{{< /history >}}

Set a default GitLab Duo namespace to ensure GitLab Duo is available to use with your project.
Your default GitLab Duo namespace determines your available [AI models](../gitlab_duo/model_selection.md)
and GitLab Duo features, and your consumption of [GitLab Credits](../../subscriptions/gitlab_credits.md).

Your default GitLab Duo namespace determines feature availability and credit consumption in the following scenarios:

- You're not a member of the project you're working in.
- You belong to multiple GitLab Duo namespaces.
- You work in your IDE with a project that does not have a GitLab remote configured.
- You use GitLab Duo in the CLI.

When you work in a project or group where you're a direct or inherited member, the top-level group
of that project or group is used instead for feature availability and credit consumption:

- If you use GitLab Duo features in a project you're a member of,
  usage is billed to the top-level group of that project.
- If you use GitLab Duo features outside a project (for example, in your IDE without
  an open project or in the CLI), usage is billed to your default namespace.
- If you use GitLab Duo features in a project you're not a member of,
  usage is billed to your default namespace.

If you do not set a default namespace, GitLab Duo Agentic Chat and the GitLab Duo Agent Platform are disabled.

To set a default GitLab Duo namespace:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **AI assistance** tab, in the **GitLab Duo** section, from the **Default group** dropdown list, select the group you want to set as your default.
1. Select **Save changes**.

#### Namespace resolution in your local environment

{{< history >}}

- Access to user default namespaces for IDEs [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2043) in GitLab 18.10.
- Access to user default namespaces introduced in GitLab for VS Code 6.71.7.
- Access to user default namespaces introduced in GitLab Duo CLI 8.76.0.
- Default namespace setting in editor extensions [removed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2369) in GitLab 19.4.
  - [Removed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.46.0) in GitLab Duo plugin for JetBrains IDEs 3.46.0.
  - [Removed](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.90.0) in GitLab for VS Code 6.90.0.

{{< /history >}}

When you use GitLab Duo in an IDE or the CLI, the first available namespace determines feature
availability and credit consumption. Along with the other Agent Platform requirements, the project
you work on must be in a [group namespace](../namespace/_index.md).

GitLab Duo checks for a namespace in this order:

1. The project namespace, if your project is linked to a remote repository in GitLab.
1. The default namespace set in your user preferences.

If the first namespace identified does not have access to the requested feature or available credits,
the feature is not available. GitLab Duo does not fall back to the next namespace in the list.

If your project is not linked to a remote repository in GitLab, you must
[set a default GitLab Duo namespace](#set-a-default-gitlab-duo-namespace) in your user preferences.

### Choose which GitLab Duo features use Orbit

{{< details >}}

- Status: Beta

{{< /details >}}

When Orbit in GitLab Duo is on for you, you can choose which GitLab Duo features use Orbit.
Orbit in GitLab Duo is on for members of a top-level group with Orbit on, or when an administrator turns it on for the instance.

To choose which features use Orbit:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **AI assistance** tab, in the **GitLab Orbit** section, select or clear the checkboxes:
   - **Agentic Chat**
   - **Orbit Agent**
   - **Other Foundational Agents**
   - **Custom Agents**
1. Optional. If you belong to more than one top-level group with GitLab Orbit, from the **Default group** dropdown list, select the group to assign usage from MCP and API calls to.
1. Select **Save changes**.

## Integrate your GitLab instance with third-party services

Give third-party services access to enhance the GitLab experience.
Use the **Integrations** tab.

### Integrate your GitLab instance with Ona

Configure your GitLab instance with Ona when you want to launch and manage code directly from your GitLab browser. Ona automatically prepares and builds development environments for your projects.

To integrate with Ona:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Integrations** tab, select the **Enable Ona integration** checkbox.
1. Select **Save changes**.

### Integrate your GitLab instance with Sourcegraph

GitLab supports Sourcegraph integration for all public projects on GitLab.

To integrate with Sourcegraph:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Integrations** tab, select the **Enable integrated code intelligence on code views** checkbox.
1. Select **Save changes**.

You must be the administrator of the GitLab instance to configure GitLab with Sourcegraph.

### Integrate with the extension marketplace

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 17.0 [with feature flags](../../administration/feature_flags/_index.md) named `web_ide_oauth` and `web_ide_extensions_marketplace`. Disabled by default.
- `web_ide_oauth` [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181) in GitLab 17.4.
- `web_ide_extensions_marketplace` [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/459028) in GitLab 17.4.
- `web_ide_oauth` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464) in GitLab 17.5.
- Enabled by default for [workspaces](../workspace/_index.md) in GitLab 17.6. Workspaces do not require any feature flags for the extension marketplace to be available.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/508996) the `vscode_extension_marketplace_settings` [feature flag](../../administration/feature_flags/_index.md) in GitLab 17.10. Disabled by default.
- `web_ide_extensions_marketplace` [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662), and `vscode_extension_marketplace_settings` [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662) in GitLab 17.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192659) in GitLab 18.1. Feature flags `web_ide_extensions_marketplace` and `vscode_extension_marketplace_settings` removed.

{{< /history >}}

The VS Code Extension Marketplace provides access to extensions that enhance the functionality of the
Web IDE and workspaces.

Prerequisites:

- For GitLab Self-Managed and GitLab Dedicated, a GitLab administrator must [enable the extension registry](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry).
- For enterprise users, a group Owner must [enable the Extension Marketplace](../enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users)
  for the associated group.

To integrate with the Extension Marketplace:

1. In the upper-right corner, select your avatar.
1. Select **Preferences**.
1. On the **Integrations** tab, select the **Enable extension marketplace** checkbox.
1. In the third-party extension acknowledgment, select **I understand**.
1. Select **Save changes**.

## User identities in CI job JSON web tokens

CI/CD jobs generate JSON web tokens, which can include a list of your external identities.
Instead of making separate API calls to get individual accounts, you can find your user identities in a single authentication token.

External identities are not included by default.
To enable including external identities, see [Token payload](../../ci/secrets/id_token_authentication.md#token-payload).
