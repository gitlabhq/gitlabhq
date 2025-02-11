---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Profile preferences
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can update your preferences to change the look and feel of GitLab.

## Change the color theme

You can change the color theme of the GitLab UI. These colors are displayed on the left sidebar.
Using individual color themes might help you differentiate between your different
GitLab instances.

To change the color theme:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Color theme** section, select a theme.

### Dark mode

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252) in GitLab 13.1 as an [experiment](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252).

Dark mode makes elements on the GitLab UI stand out on a dark background.

- To turn on Dark mode, Select **Preferences > Color theme > Dark Mode**.

Dark mode works only with the **Dark** Syntax highlighting theme. You can report and view issues, send feedback, and track progress in [epic 2092](https://gitlab.com/groups/gitlab-org/-/epics/2902).

## Change the syntax highlighting theme

> - Changing the default syntax highlighting theme for authenticated and unauthenticated users [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25129) in GitLab 15.1.

Syntax highlighting is a feature in code editors and IDEs. The highlighter assigns a color to each type of code, such as strings and comments.

To change the syntax highlighting theme:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Syntax highlighting theme** section, select a theme.
1. Select **Save changes**.

To view the updated syntax highlighting theme, refresh your project's page.

To customize the syntax highlighting theme, you can also [use the Application settings API](../../api/settings.md#available-settings). Use `default_syntax_highlighting_theme` to change the syntax highlighting colors on a more granular level.

If these steps do not work, your programming language might not be supported by the syntax highlighters.
For more information, view [Rouge Ruby Library](https://github.com/rouge-ruby/rouge) for guidance on code files and Snippets. View [Monaco Editor](https://microsoft.github.io/monaco-editor/) and [Monarch](https://microsoft.github.io/monaco-editor/monarch.html) for guidance on the Web IDE.

## Change the diff colors

Diffs use two different background colors to show changes between versions of code. By default, the original file is in red, and the changes are in green.

To change the diff colors:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Diff colors** section.
1. Select a color or enter a color code.
1. Select **Save changes**.

To change back to the default colors, clear the **Color for removed lines** and **Color for added lines** text boxes and select **Save changes**.

## Behavior

Use the **Behavior** section to customize the behavior of the system layout and default views. You can change your layout width and choose the default content for your homepage, group and project overview pages. You have options to customize appearance and function, like whitespace rendering, file display, and text automation.

### Change the layout width on the UI

You can stretch content on the GitLab UI to fill the entire page. By default, page content is fixed at 1280 pixels wide.

To change the layout width of your UI:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Under **Layout width**, choose **Fixed** or **Fluid**.
1. Select **Save changes**.

### Set the default text editor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423104) in GitLab 17.7.

You can set a default editor for editing content in GitLab.
If you do not choose a default text editor, your last used choice is preserved.

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Under **Default text editor**, select the **Enable default text editor** checkbox.
1. Choose either **Rich text editor** or **Plain text editor** as your default.
1. Select **Save changes**.

### Choose your home organization

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419079) in GitLab 16.6 [with a flag](../../administration/feature_flags.md) named `ui_for_organizations`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag. For more information, see the history.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

If you are a member of two or more [organizations](../organization/_index.md), you can choose a home organization.
This is the organization you are in by default when you first sign in to GitLab.

To choose your home organization:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Home organization** dropdown list, select an option.
1. Select **Save changes**.

### Choose your homepage

> - [Homepage options changed](https://gitlab.com/groups/gitlab-org/-/epics/13066) in GitLab 17.9 [with a flag](../../administration/feature_flags.md) named `your_work_projects_vue`. Disabled by default.

FLAG:
When the `your_work_projects_vue` feature flag is enabled, the **Your Contributed Projects** view becomes the default option, and an additional **Member Projects** option is available in the dropdown list. For more information, see the history.

Control what page you view when you select the GitLab logo (**{tanuki}**). You can set your homepage to be Your Projects (default), Your Groups, Your Activity, and other content.

To choose your homepage view:

1. On the left sidebar, select your avatar.
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

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Group overview content** dropdown list, select an option.
1. Select **Save changes**.

### Customize default content on your project overview page

Your project overview page is the page you view when you select **Project overview** on the left sidebar. You can set your main project overview page to the Activity page, the README file, and other content.

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. From the **Project overview content** dropdown list, select an option.
1. Select **Save changes**.

### Hide shortcut buttons

Shortcut buttons precede the list of files on a project's overview page. These buttons provide links to parts of a project, such as the README file or license agreements.

To hide shortcut buttons on the project overview page:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Clear the **Show shortcut buttons above files on project overview** checkbox.
1. Select **Save changes**.

### Show whitespace characters in the Web IDE

Whitespace characters are any blank characters in a text, such as spaces and indentations. You might use whitespace to structure content in code. If your programming language is sensitive to whitespaces, the Web IDE can detect changes to them.

To render whitespace in the Web IDE:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Render whitespace characters in the Web IDE** checkbox.
1. Select **Save changes**.

You can view changes to whitespace in diffs.

To view diffs on the Web IDE, follow these steps:

1. On the left sidebar, select **Source Control** (**{branch}**).
1. Under the **Changes** tab, select your file.

### Show whitespace changes in diffs

View changes to whitespace in diff files. For more information on whitespaces, view the previous task.

To view changes to whitespace in diffs:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Show whitespace changes in diffs** checkbox.
1. Select **Save changes**.

For more information on diffs, view [Change the diff colors](#change-the-diff-colors).

### Show one file per page in a merge request

The **Changes** tab lets you view all file changes in a merge request on one page.
Instead, you can choose to view one file at a time.

To show one file per page on the **Changes** tab:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Show one file at a time on merge request's Changes tab** checkbox.
1. Select **Save changes**.

Then, to move between files on the **Changes** tab, below each file, select the **Previous** and **Next** buttons.

### Auto-enclose characters

Automatically add the corresponding closing character to text when you type the opening character. For example, you can automatically insert a closing bracket when you type an opening bracket. This setting works only in description and comment boxes and for the following characters: `**"`, `'`, ```, `(`, `[`, `{`, `<`, `*`, `_**`.

To auto-enclose characters in description and comment boxes:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Surround text selection when typing quotes or brackets** checkbox.
1. Select **Save changes**.

In a description or comment box, you can now type a word, highlight it, then type an
opening character. Instead of replacing the text, the closing character is added to the end.

### Automate new list items

Create a new list item when you press <kbd>Enter</kbd> in a list in description and comment boxes.

To add a new list item when you press the <kbd>Enter</kbd> key:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. Select the **Automatically add new list items** checkbox.
1. Select **Save changes**.

### Change the tab width

Change the default size of tabs in diffs, blobs, and snippets. The Web IDE, file editor, and Markdown editor do not support this feature.

To adjust the default tab width:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Scroll to the **Behavior** section.
1. For **Tab width**, enter a value.
1. Select **Save changes**.

## Localization

Change localization settings such as your language, calendar start day, and time preferences.

### Change your display language on the GitLab UI

GitLab supports multiple languages on the UI. To help improve translations or request support for an unlisted language, view [Translating GitLab](../../development/i18n/translation.md).

To choose a language for the GitLab UI:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Localization** section.
1. Under **Language**, select an option.
1. Select **Save changes**.

You might need to refresh your page to view the updated language.

### Customize your contribution calendar start day

Choose which day of the week the contribution calendar starts with. The contribution calendar shows project contributions over the past year. You can view this calendar on each user profile. To access your user profile:

- On the left sidebar, select your avatar > select your name or username.

To change your contribution calendar start day:

1. On the left sidebar, select your avatar.
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

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Time preferences** section.
1. Clear the **Use relative times** checkbox.
1. Select **Save changes**.

### Customize time format

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15206) in GitLab 16.6.

You can customize the format used to display times of activities on your group and project overview pages and user
profiles. You can display times as:

- 12 hour format. For example: `2:34 PM`.
- 24 hour format. For example: `14:34`.

You can also follow your system's setting.

To customize the time format:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Time preferences** section.
1. Under **Time format**, select either the **System**, **12-hour**, or **24-hour** option.
1. Select **Save changes**.

## Disable exact code search

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
> - Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

WARNING:
This feature is in [beta](../../policy/development_stages_support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).

Prerequisites:

- For [GitLab Self-Managed](../../subscriptions/self_managed/_index.md), an administrator must
  [enable exact code search](../../integration/exact_code_search/zoekt.md#enable-exact-code-search).

To disable [exact code search](../search/exact_code_search.md) in user preferences:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Exact code search** section.
1. Clear the **Enable exact code search** checkbox.
1. Select **Save changes**.

## User identities in CI job JSON web tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387537) in GitLab 16.0.

CI/CD jobs generate JSON web tokens, which can include a list of your external identities.
Instead of making separate API calls to get individual accounts, you can find your user identities in a single authentication token.

External identities are not included by default.
To enable including external identities, see [Token payload](../../ci/secrets/id_token_authentication.md#token-payload).

## Control follower engagement

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325558) in GitLab 16.0.

Turn off the ability to follow or be followed by other GitLab users. By default, your user profile, including your name and profile photo, is public in the **Following** tabs of other users. When you deactivate this setting:

- GitLab deletes all of your followers and followed connections.
- GitLab automatically removes your user profile from the pages of each connection.

To remove the ability to be followed by and follow other users:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Clear the **Enable follow users** checkbox.
1. Select **Save changes**.

To access your **Followers** and **Following** tabs:

- On the left sidebar, select your avatar > select your name or username.
- Select **Followers** or **Following**.

## Integrate your GitLab instance with third-party services

Give third-party services access to enhance the GitLab experience.

### Integrate your GitLab instance with Gitpod

Configure your GitLab instance with Gitpod when you want to launch and manage code directly from your GitLab browser. Gitpod automatically prepares and builds development environments for your projects.

To integrate with Gitpod:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Find the **Integrations** section.
1. Select the **Enable Gitpod integration** checkbox.
1. Select **Save changes**.

### Integrate your GitLab instance with Sourcegraph

GitLab supports Sourcegraph integration for all public projects on GitLab.

To integrate with Sourcegraph:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Find the **Integrations** section.
1. Select the **Enable integrated code intelligence on code views** checkbox.
1. Select **Save changes**.

You must be the administrator of the GitLab instance to configure GitLab with Sourcegraph.

### Integrate with the extension marketplace

DETAILS:
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 17.0 [with flags](../../administration/feature_flags.md) named `web_ide_oauth` and `web_ide_extensions_marketplace`. Disabled by default.
> - Feature flag `web_ide_oauth` [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181) and feature flag `web_ide_extensions_marketplace` [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/459028) in GitLab 17.4.
> - Feature flag `web_ide_oauth` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464) in GitLab 17.5.
> - Enabled by default for [workspaces](../workspace/_index.md) in GitLab 17.6. Workspaces do not require any feature flags for the extension marketplace to be available.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

You can use the [extension marketplace](../project/web_ide/_index.md#extension-marketplace) to search and
manage extensions for the [Web IDE](../project/web_ide/_index.md) and [workspaces](../workspace/_index.md).
For third-party extensions, you must enable the marketplace in user preferences.

To enable the extension marketplace for the Web IDE and workspaces:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Integrations** section.
1. Select the **Enable extension marketplace** checkbox.
1. In the third-party extension acknowledgement, select **I understand**.
1. Select **Save changes**.

NOTE:
This preferences checkbox will always be available, even if the feature flags are disabled.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
