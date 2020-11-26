---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Profile preferences

A user's profile preferences page allows the user to customize various aspects
of GitLab to their liking.

To navigate to your profile's preferences:

1. Click your avatar.
1. Select **Settings**.
1. Click **Preferences** in the sidebar.

## Navigation theme

The GitLab navigation theme setting allows you to personalize your GitLab experience.
You can choose from several color themes that add unique colors to the top navigation
and left side navigation.
Using individual color themes might help you differentiate between your different
GitLab instances.

The default theme is Indigo. You can choose between 10 themes:

- Indigo
- Light Indigo
- Blue
- Light Blue
- Green
- Light Green
- Red
- Light Red
- Dark
- Light

![Profile preferences navigation themes](img/profil-preferences-navigation-theme.png)

## Dark mode

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28252) in GitLab 13.1 as an Alpha release.

GitLab has started work on dark mode! The dark mode Alpha release is available in the
spirit of iteration and the lower expectations of
[Alpha versions](https://about.gitlab.com/handbook/product/#alpha).

Progress on dark mode is tracked in the [Dark theme epic](https://gitlab.com/groups/gitlab-org/-/epics/2902). See the epic for:

- A list of known issues.
- Our planned direction and next steps.

If you find an issue that isn’t listed, please leave a comment on the epic or create a
new issue.

Dark mode is available as a navigation theme, for MVC and compatibility reasons. In
the future, we plan to make it configurable in its own section along with support for
[different navigation themes](https://gitlab.com/gitlab-org/gitlab/-/issues/219512).

NOTE: **Note:**
Dark theme currently only works with the 'Dark' syntax highlighting.

## Syntax highlighting theme

NOTE: **Note:**
GitLab uses the [rouge Ruby library](http://rouge.jneen.net/ "Rouge website")
for syntax highlighting outside of any Editor context. The WebIDE (like Snippets)
uses [Monaco Editor](https://microsoft.github.io/monaco-editor/) and it's provided [Monarch](https://microsoft.github.io/monaco-editor/monarch.html) library for
syntax highlighting. For a list of supported languages, visit the documentation of
the respective libraries.

Changing this setting allows you to customize the color theme when viewing any
syntax highlighted code on GitLab.

The default syntax theme is White, and you can choose among 5 different themes:

- White
- Dark
- Solarized light
- Solarized dark
- Monokai

![Profile preferences syntax highlighting themes](img/profile-preferences-syntax-themes.png)

[Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2389) in 13.0, the theme
you choose also applies to the [Web IDE](../project/web_ide/index.md)'s code editor and [Snippets](../snippets.md).
The themes are available only in the Web IDE file editor, except for the [dark theme](https://gitlab.com/gitlab-org/gitlab/-/issues/209808) and
the [Solarized dark theme](https://gitlab.com/gitlab-org/gitlab/-/issues/219228),
which apply to the entire Web IDE screen.

## Behavior

The following settings allow you to customize the behavior of GitLab's layout
and default views of your dashboard and the projects' landing pages.

### Layout width

GitLab can be set up to use different widths depending on your liking. Choose
between the fixed (max. `1280px`) and the fluid (`100%`) application layout.

NOTE: **Note:**
While `1280px` is the standard max width when using fixed layout, some pages still use 100% width, depending on the content.

### Default dashboard

For users who have access to a large number of projects but only keep up with a
select few, the amount of activity on the default Dashboard page can be
overwhelming. Changing this setting allows you to redefine your default
dashboard.

You have 8 options here that you can use for your default dashboard view:

- Your projects (default)
- Starred projects
- Your projects' activity
- Starred projects' activity
- Your groups
- Your [to-dos](../todos.md)
- Assigned Issues
- Assigned Merge Requests
- Operations Dashboard **(PREMIUM)**

### Group overview content

The **Group overview content** dropdown allows you to choose what information is
displayed on a group’s home page.

You can choose between 2 options:

- Details (default)
- [Security dashboard](../application_security/security_dashboard/index.md) **(ULTIMATE)**

### Project overview content

The **Project overview content** setting allows you to choose what content you want to
see on a project’s home page.

### Tab width

You can set the displayed width of tab characters across various parts of
GitLab, for example, blobs, diffs, and snippets.

NOTE: **Note:**
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

If you select **System Default**, the system-wide default setting is used.

## Integrations

Configure your preferences with third-party services which provide enhancements to your GitLab experience.

### Sourcegraph

NOTE: **Note:**
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

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
