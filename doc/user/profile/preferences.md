---
stage: none - [facilitated functionality](https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality)
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Profile preferences
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can update your preferences to change the look and feel of GitLab.

## Change the mode

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252) in GitLab 13.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/524846) from experiment to beta in GitLab 17.11.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/470413) from **Appearance** to **Mode** in GitLab 18.1.

{{< /history >}}

You can change the color mode of the interface to be light, dark, or automatically update based on device preferences.

To change the appearance:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. In the **Mode** section, select an option.
1. Select **Save changes**.

<!-- When new navigation is released and feature flag `paneled_view` is removed, change **Navigation** to **Theme** -->

## Change the navigation theme

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/470413) from **Color theme** to **Navigation theme** in GitLab 18.1.
- Themes: Light Indigo, Light Blue, Light Green, and Light Red [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200475) in GitLab 18.4.

{{< /history >}}

You can change the navigation theme of the GitLab UI. These colors are displayed on the left sidebar.
Using individual navigation themes might help you differentiate between your different
GitLab instances.

To change the navigation theme:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. In the **Navigation** section, select a theme.

## Change the syntax highlighting theme

{{< history >}}

- Changing the default syntax highlighting theme for authenticated and unauthenticated users [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25129) in GitLab 15.1.

{{< /history >}}

Syntax highlighting is a feature in code editors and IDEs. The highlighter assigns a color to each type of code, such as strings and comments.

To change the syntax highlighting theme:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. In the **Syntax highlighting** section, select a theme.
1. Select **Save changes**.

To view the updated syntax highlighting theme, refresh your project's page.

To customize the syntax highlighting theme, you can also [use the Application settings API](../../api/settings.md#available-settings). Use `default_syntax_highlighting_theme` and `default_dark_syntax_highlighting_theme` to change the syntax highlighting colors on a more
granular level.

If these steps do not work, your programming language might not be supported by the syntax highlighters.
For more information, view [Rouge Ruby Library](https://github.com/rouge-ruby/rouge) for guidance on code files and Snippets. View [Monaco Editor](https://microsoft.github.io/monaco-editor/) and [Monarch](https://microsoft.github.io/monaco-editor/monarch.html) for guidance on the Web IDE.

## Change the diff colors

Diffs use two different background colors to show changes between versions of code. By default, the original file is in red, and the changes are in green.

To change the diff colors:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Diffs** section.
1. Select a color or enter a color code.
1. Select **Save changes**.

To change back to the default colors, clear the **Color for removed lines** and **Color for added lines** text boxes and select **Save changes**.

## Behavior

Use the **Behavior** section to customize the behavior of the system layout and default views. You can change your layout width and choose the default content for your homepage, group and project overview pages. You have options to customize appearance and function, like whitespace rendering, file display, and text automation.

### Change the layout width on the UI

You can stretch content on the GitLab UI to fill the entire page. By default, page content is fixed at 1280 pixels wide.

To change the layout width of your UI:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Under **Layout width**, choose **Fixed** or **Fluid**.
1. Select **Save changes**.

### Set the default text editor

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423104) in GitLab 17.7.
- Default for new users [set to rich text editor](https://gitlab.com/gitlab-org/gitlab/-/issues/536611) in 18.2.

{{< /history >}}

By default, all new users see the **Rich text editor** when editing content.
You can change the default editor for editing content in GitLab.

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Under **Default text editor**, ensure the **Enable default text editor** checkbox is selected.
1. Choose either **Rich text editor** or **Plain text editor** as your default.
1. Select **Save changes**.

### Choose your homepage

{{< history >}}

- [Homepage options changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `your_work_projects_vue`. Disabled by default.
- [Homepage option changes generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/465889) in GitLab 17.10. Feature flag `your_work_projects_vue` removed.
- [Personal homepage introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/546151) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `personal_homepage`. Disabled by default.
- [Personal homepage enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/554048) in GitLab 18.4 for a subset of users.
- [Personal homepage enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/17932) in GitLab 18.5.

{{< /history >}}

Control what page you view when you select the GitLab logo ({{< icon name="tanuki" >}}). You can set your homepage to be Personal homepage (default), Your Contributed Projects, Your Groups, Your Activity, and other content.

To choose your homepage view:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Homepage** dropdown list, select an option.
1. Select **Save changes**.

### Customize default content on your group overview page

You can change the main content on your group overview page. Your group overview page is the page that shows when you select **Groups** on the left sidebar. You can customize the default content for your group overview page to the:

- Details Dashboard (default), which includes an overview of group activities and projects.
- Security Dashboard, which might include group security policies and other security topics.

For more information, view [Groups](../group/_index.md).

To change the default content on your group overview page:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Group overview content** dropdown list, select an option.
1. Select **Save changes**.

### Customize default content on your project overview page

Your project overview page is the page you view when you select **Project overview** on the left sidebar. You can set your main project overview page to the Activity page, the README file, and other content.

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Project overview content** dropdown list, select an option.
1. Select **Save changes**.

### Hide shortcut buttons

Shortcut buttons precede the list of files on a project's overview page. These buttons provide links to parts of a project, such as the README file or license agreements.

To hide shortcut buttons on the project overview page:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Clear the **Show shortcut buttons above files on project overview** checkbox.
1. Select **Save changes**.

### Show whitespace characters in the Web IDE

Whitespace characters are any blank characters in a text, such as spaces and indentations. You might use whitespace to structure content in code. If your programming language is sensitive to whitespaces, the Web IDE can detect changes to them.

To render whitespace in the Web IDE:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Render whitespace characters in the Web IDE** checkbox.
1. Select **Save changes**.

You can view changes to whitespace in diffs.

To view diffs on the Web IDE, follow these steps:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Under the **Changes** tab, select your file.

### Show whitespace changes in diffs

View changes to whitespace in diff files. For more information on whitespaces, view the previous task.

To view changes to whitespace in diffs:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Show whitespace changes in diffs** checkbox.
1. Select **Save changes**.

For more information on diffs, view [Change the diff colors](#change-the-diff-colors).

### Show one file per page in a merge request

The **Changes** tab lets you view all file changes in a merge request on one page.
Instead, you can choose to view one file at a time.

To show one file per page on the **Changes** tab:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Show one file at a time on merge request's Changes tab** checkbox.
1. Select **Save changes**.

Then, to move between files on the **Changes** tab, below each file, select the **Previous** and **Next** buttons.

### Auto-enclose characters

Automatically add the corresponding closing character to text when you type the opening character. For example, you can automatically insert a closing bracket when you type an opening bracket. This setting works only in description and comment boxes and for the following characters: `**"`, `'`, ```, `(`, `[`, `{`, `<`, `*`, `_**`.

To auto-enclose characters in description and comment boxes:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Surround text selection when typing quotes or brackets** checkbox.
1. Select **Save changes**.

In a description or comment box, you can now type a word, highlight it, then type an
opening character. Instead of replacing the text, the closing character is added to the end.

### Automate new list items

Create a new list item when you press <kbd>Enter</kbd> in a list in description and comment boxes.

To add a new list item when you press the <kbd>Enter</kbd> key:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Automatically add new list items** checkbox.
1. Select **Save changes**.

### Maintain cursor indentation

Maintain the indentation when you press <kbd>Enter</kbd>. The cursor on the new line is automatically indented the same as the previous line. This setting works only in description and comment boxes.

To add a new list item when you press the <kbd>Enter</kbd> key:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Maintain cursor indentation** checkbox.
1. Select **Save changes**.

### Change the tab width

Change the default size of tabs in diffs, blobs, and snippets. The Web IDE, file editor, and Markdown editor do not support this feature.

To adjust the default tab width:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. For **Tab width**, enter a value.
1. Select **Save changes**.

## Localization

Change localization settings such as your language, calendar start day, and time preferences.

### Change your display language on the GitLab UI

GitLab supports multiple languages on the UI.

To choose a language for the GitLab UI:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Localization** section.
1. Under **Language**, select an option.
1. Select **Save changes**.

You might need to refresh your page to view the updated language.

### Customize your contribution calendar start day

Choose which day of the week the contribution calendar starts with. The contribution calendar shows project contributions over the past year. You can view this calendar on each user profile. To access your user profile:

- On the left sidebar, select your avatar > select your name or username. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.

To change your contribution calendar start day:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Localization** section.
1. Under **First day of the week**, select an option.
1. Select **Save changes**.

After you change your calendar start day, refresh your user profile page.

### Show exact times instead of relative times

Customize the format used to display times of activities on your group and project overview pages and user profiles. You can display times in a:

- Relative format, for example `30 minutes ago`.
- Absolute format, for example `September 3, 2022, 3:57 PM`.

To use exact times on the GitLab UI:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Time preferences** section.
1. Clear the **Use relative times** checkbox.
1. Select **Save changes**.

### Customize time format

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15206) in GitLab 16.6.

{{< /history >}}

You can customize the format used to display times of activities on your group and project overview pages and user
profiles. You can display times as:

- 12 hour format. For example: `2:34 PM`.
- 24 hour format. For example: `14:34`.

You can also follow your system's setting.

To customize the time format:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Time preferences** section.
1. Under **Time format**, select either the **System**, **12-hour**, or **24-hour** option.
1. Select **Save changes**.

<!--- start_remove The following content will be removed on remove_date: '2026-02-20' -->

## Disable exact code search (deprecated)

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags/_index.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
- Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

{{< /history >}}

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/554933) in GitLab 18.3
and is planned for removal in 18.6.

{{< /alert >}}

Prerequisites:

- For [GitLab Self-Managed](../../subscriptions/self_managed/_index.md), an administrator must
  [enable exact code search](../../integration/zoekt/_index.md#enable-exact-code-search).

To disable [exact code search](../search/exact_code_search.md) in user preferences:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Exact code search** section.
1. Clear the **Enable exact code search** checkbox.
1. Select **Save changes**.

<!--- end_remove -->

## User identities in CI job JSON web tokens

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387537) in GitLab 16.0.

{{< /history >}}

CI/CD jobs generate JSON web tokens, which can include a list of your external identities.
Instead of making separate API calls to get individual accounts, you can find your user identities in a single authentication token.

External identities are not included by default.
To enable including external identities, see [Token payload](../../ci/secrets/id_token_authentication.md#token-payload).

## Control follower engagement

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325558) in GitLab 16.0.

{{< /history >}}

Turn off the ability to follow or be followed by other GitLab users. By default, your user profile, including your name and profile photo, is public in the **Following** tabs of other users. When you deactivate this setting:

- GitLab deletes all of your followers and followed connections.
- GitLab automatically removes your user profile from the pages of each connection.

To remove the ability to be followed by and follow other users:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Clear the **Enable follow users** checkbox.
1. Select **Save changes**.

To access your **Followers** and **Following** tabs:

- On the left sidebar, select your avatar > select your name or username. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
- Select **Followers** or **Following**.

## Integrate your GitLab instance with third-party services

Give third-party services access to enhance the GitLab experience.

### Integrate your GitLab instance with Ona

Configure your GitLab instance with Ona when you want to launch and manage code directly from your GitLab browser. Ona automatically prepares and builds development environments for your projects.

To integrate with Ona:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Find the **Integrations** section.
1. Select the **Enable Ona integration** checkbox.
1. Select **Save changes**.

### Integrate your GitLab instance with Sourcegraph

GitLab supports Sourcegraph integration for all public projects on GitLab.

To integrate with Sourcegraph:

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Find the **Integrations** section.
1. Select the **Enable integrated code intelligence on code views** checkbox.
1. Select **Save changes**.

You must be the administrator of the GitLab instance to configure GitLab with Sourcegraph.

### Integrate with the extension marketplace

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 17.0 [with flags](../../administration/feature_flags/_index.md) named `web_ide_oauth` and `web_ide_extensions_marketplace`. Disabled by default.
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

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Preferences**.
1. Go to the **Integrations** section.
1. Select the **Enable extension marketplace** checkbox.
1. In the third-party extension acknowledgment, select **I understand**.
1. Select **Save changes**.
