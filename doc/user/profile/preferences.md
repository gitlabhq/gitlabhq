---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, howto
---

# Profile preferences **(FREE)**

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252) in GitLab 13.1 as an [Experiment](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252).

Dark mode makes elements on the GitLab UI stand out on a dark background. 

- To turn on Dark mode, Select **Preferences > Color theme > Dark Mode**.

Dark mode works only with the **Dark** Syntax highlighting theme. You can report and view issues, send feedback, and track progress in [epic 2092](https://gitlab.com/groups/gitlab-org/-/epics/2902).

## Change the syntax highlighting theme

> Changing the default syntax highlighting theme for authenticated and unauthenticated users [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25129) in GitLab 15.1.

Syntax highlighting is a feature in code editors and IDEs. The highlighter assigns a color to each type of code, such as strings and comments.

To change the syntax highlighting theme:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Syntax highlighting theme** section, select a theme.
1. Select **Save changes**.

To view the updated syntax highlighting theme, refresh your project's page. 

To customize the syntax highlighting theme, you can also [use the Application settings API](../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls). Use `default_syntax_highlighting_theme` to change the syntax highlighting colors on a more granular level.

If these steps do not work, your programming language might not be supported by the syntax highlighters. 
For more information, view [Rouge Ruby Library](https://github.com/rouge-ruby/rouge) for guidance on code files and Snippets. View [Moncaco Editor](https://microsoft.github.io/monaco-editor/) and [Monarch](https://microsoft.github.io/monaco-editor/monarch.html) for guidance on the Web IDE.  

## Change the diff colors

Diffs use two different background colors to show changes between versions of code. By default, the original file in red and the changes made in green.

To change the diff colors:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. Go to the **Diff colors** section. 
1. Complete the fields.
1. Select **Save changes**.
1. Optional. Type a color code in the fields.

## Behavior

The following settings allow you to customize the behavior of the GitLab layout
and default views of your dashboard and the projects' landing pages.

### Layout width

GitLab can be set up to use different widths depending on your liking. Choose
between the fixed (max. `1280px`) and the fluid (`100%`) application layout.

NOTE:
While `1280px` is the standard max width when using fixed layout, some pages still use 100% width, depending on the content.

### Homepage

This setting changes the behavior of the tanuki icon in the upper-left corner of GitLab.

### Group overview content

The **Group overview content** dropdown list allows you to choose what information is
displayed on a group's home page.

You can choose between 2 options:

- Details (default)
- [Security dashboard](../application_security/security_dashboard/index.md)

### Project overview content

The **Project overview content** setting allows you to choose what content you want to
see on a project's home page.

If **Files and Readme** is selected, you can show or hide the shortcut buttons above the file list on the project overview with the **Show shortcut buttons above files on project overview** setting.

### Tab width

You can set the displayed width of tab characters across various parts of
GitLab, for example, blobs, diffs, and snippets.

NOTE:
Some parts of GitLab do not respect this setting, including the WebIDE, file
editor and Markdown editor.

## Localization

### Language

Select your preferred language from a list of supported languages.

*This feature is experimental and translations are not complete yet.*

### First day of the week

The first day of the week can be customized for calendar views and date pickers.

You can choose one of the following options as the first day of the week:

- Saturday
- Sunday
- Monday

If you select **System Default**, the first day of the week is set to the
[instance default](../../administration/settings/index.md#change-the-default-first-day-of-the-week).

## Time preferences

### Use relative times

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65570) in GitLab 14.1.

You can select your preferred time format for the GitLab user interface:

- Relative times, for example, `30 minutes ago`.
- Absolute times, for example, `May 18, 2021, 3:57 PM`.

The times are formatted depending on your chosen language and browser locale.

To set your time preference:

1. On the **Preferences** page, go to **Time preferences**.
1. Select the **Use relative times** checkbox to use relative times,
   or clear the checkbox to use absolute times.
1. Select **Save changes**.

NOTE:
This feature is experimental, and choosing absolute times might break certain layouts.
Open an issue if you notice that using absolute times breaks a layout.

## User identities in CI job JSON web tokens

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387537) in GitLab 16.0. False by default.

You can select to include the list of your external identities in the JSON Web Token information that is generated for a CI job.
For more information and examples, see [Token Payload](../../ci/secrets/id_token_authentication.md#token-payload).

## Integrations

Configure your preferences with third-party services which provide enhancements to your GitLab experience.

### Sourcegraph

NOTE:
This setting is only visible if Sourcegraph has been enabled by a GitLab administrator.

Manage the availability of integrated code intelligence features powered by
Sourcegraph. View [the Sourcegraph feature documentation](../../integration/sourcegraph.md#enable-sourcegraph-in-user-preferences)
for more information.

### Gitpod

Enable and disable the [GitLab-Gitpod integration](../../integration/gitpod.md). This is only
visible after the integration is configured by a GitLab administrator. View
[the Gitpod feature documentation](../../integration/gitpod.md) for more information.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
