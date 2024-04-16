---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Wiki

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Page loading [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/336792) to asynchronous in GitLab 14.9.
> - Page slug encoding method [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71753) to `ERB::Util.url_encode` in GitLab 14.9.

If you don't want to keep your documentation in your repository, but you want
to keep it in the same project as your code, you can use the wiki GitLab provides
in each GitLab project. Every wiki is a separate Git repository, so you can create
wiki pages in the web interface, or [locally using Git](#create-or-edit-wiki-pages-locally).

GitLab wikis support Markdown, Rdoc, AsciiDoc, and Org for content.
Wiki pages written in Markdown support all [Markdown features](../../markdown.md),
and also provide some [wiki-specific behavior](../../markdown.md#wiki-specific-markdown)
for links.

In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/17673/),
wiki pages display a sidebar, which you [can customize](#customize-sidebar). This
sidebar contains a partial list of pages in the wiki, displayed as a nested tree,
with sibling pages listed in alphabetical order. To view a list of all pages, select
**View All Pages** in the sidebar:

![Wiki sidebar](img/wiki_sidebar_v13_5.png)

## View a project wiki

To access a project wiki:

1. On the left sidebar, select **Search or go to** and find your project.
1. To display the wiki, either:
   - On the left sidebar, select **Plan > Wiki**.
   - On any page in the project, use the <kbd>g</kbd> + <kbd>w</kbd>
     [wiki keyboard shortcut](../../shortcuts.md).

If **Plan > Wiki** is not listed in the left sidebar of your project, a project administrator
has [disabled it](#enable-or-disable-a-project-wiki).

## Configure a default branch for your wiki

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221159) in GitLab 14.1.

The default branch for your wiki repository depends on your version of GitLab:

- *GitLab versions 14.1 and later:* Wikis inherit the
  [default branch name](../repository/branches/default.md) configured for
  your instance or group. If no custom value is configured, GitLab uses `main`.
- *GitLab versions 14.0 and earlier:* GitLab uses `master`.

For any version of GitLab, you can
[rename this default branch](../repository/branches/default.md#update-the-default-branch-name-in-your-repository)
for previously created wikis.

## Create the wiki home page

When a wiki is created, it is empty. On your first visit, you can create the
home page users see when viewing the wiki. This page requires a specific title
to be used as your wiki's home page. To create it:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Select **Create your first page**.
1. GitLab requires this first page be titled `home`. The page with this
   title serves as the front page for your wiki.
1. Select a **Format** for styling your text.
1. Add a welcome message for your home page in the **Content** section. You can
   always edit it later.
1. Add a **Commit message**. Git requires a commit message, so GitLab creates one
   if you don't enter one yourself.
1. Select **Create page**.

## Create a new wiki page

Users with at least the Developer role can create new wiki pages:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Select **New page** on this page, or any other wiki page.
1. Select a content format.
1. Add a title for your new page. Page titles use
   [special characters](#special-characters-in-page-titles) for subdirectories and formatting,
   and have [length restrictions](#length-restrictions-for-file-and-directory-names).
1. Add content to your wiki page.
1. Optional. Attach a file, and GitLab stores it in the wiki's Git repository.
1. Add a **Commit message**. Git requires a commit message, so GitLab creates one
   if you don't enter one yourself.
1. Select **Create page**.

### Create or edit wiki pages locally

Wikis are based on Git repositories, so you can clone them locally and edit
them like you would do with every other Git repository. To clone a wiki repository
locally:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. On the right sidebar, select **Clone repository**.
1. Follow the on-screen instructions.

Files you add to your wiki locally must use one of the following
supported extensions, depending on the markup language you wish to use.
Files with unsupported extensions don't display when pushed to GitLab:

- Markdown extensions: `.mdown`, `.mkd`, `.mkdn`, `.md`, `.markdown`.
- AsciiDoc extensions: `.adoc`, `.ad`, `.asciidoc`.
- Other markup extensions: `.textile`, `.rdoc`, `.org`, `.creole`, `.wiki`, `.mediawiki`, `.rst`.

### Special characters in page titles

Wiki pages are stored as files in a Git repository, so certain characters have a special meaning:

- Spaces are converted into hyphens when storing a page.
- Hyphens (`-`) are converted back into spaces when displaying a page.
- Slashes (`/`) are used as path separators, and can't be displayed in titles. If you
  create a title containing `/` characters, GitLab creates all the subdirectories
  needed to build that path. For example, a title of `docs/my-page` creates a wiki
  page with a path `/wikis/docs/my-page`.

### Length restrictions for file and directory names

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24364) in GitLab 12.8.

Many common file systems have a [limit of 255 bytes](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits)
for file and directory names. Git and GitLab both support paths exceeding
those limits. However, if your file system enforces these limits, you cannot check out a
local copy of a wiki that contains filenames exceeding this limit. To prevent this
problem, the GitLab web interface and API enforce these limits:

- 245 bytes for page titles (reserving 10 bytes for the file extension).
- 255 bytes for directory names.

Non-ASCII characters take up more than one byte.

While you can still create files locally that exceed these limits, your teammates
may not be able to check out the wiki locally afterward.

## Edit a wiki page

You need at least the Developer role to edit a wiki page:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to edit, and either:
   - Use the <kbd>e</kbd> wiki [keyboard shortcut](../../shortcuts.md#wiki-pages).
   - Select the edit icon (**{pencil}**).
1. Edit the content.
1. Select **Save changes**.

Unsaved changes to a wiki page are preserved in local browser storage to prevent accidental data loss.

### Create a table of contents

To generate a table of contents from a wiki page's subheadings, use the `[[_TOC_]]` tag.
For an example, read [Table of contents](../../markdown.md#table-of-contents).

## Delete a wiki page

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to delete.
1. Select the edit icon (**{pencil}**).
1. Select **Delete page**.
1. Confirm the deletion.

## Move a wiki page

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to move.
1. Select the edit icon (**{pencil}**).
1. Add the new path to the **Title** field. For example, if you have a wiki page
   called `about` under `company` and you want to move it to the wiki's root,
   change the **Title** from `about` to `/about`.
1. Select **Save changes**.

## Export a wiki page

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414691) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `print_wiki`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134251/) in GitLab 16.5.
> - Feature flag `print_wiki` removed in GitLab 16.6.

You can export a wiki page as a PDF file:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to export.
1. Select the vertical ellipsis (**{ellipsis_v}**), and then select **Print as PDF**.

A PDF of the wiki page is created.

## Wiki page templates

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442228) in GitLab 16.10.

You can create templates to use when creating new pages, or to apply
to existing pages. Templates are wiki pages that are stored in the `templates/`
directory in the wiki repository.

### Create a template

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. On the right sidebar, select **Templates**.
1. Select **New Template**.
1. Enter template title, format and content, as if creating a regular wiki page.

Templates of a particular format can only be applied to pages of the same format.
For example, Markdown templates only apply to Markdown pages.

### Apply a template

When you are [creating](#create-a-new-wiki-page) or [editing](#edit-a-wiki-page) a wiki page,
you can apply a template.

Prerequisites:

- You must have [created](#create-a-template) at least one template already.

1. In the **Content** section, select the **Choose a template** dropdown list.
1. Select a template from the list. If the page already has some content, a warning displays
   indicating that the existing content will be overridden.
1. Select **Apply template**.

## View history of a wiki page

The changes of a wiki page over time are recorded in the wiki's Git repository.
The history page shows:

![Wiki page history](img/wiki_page_history.png)

- The revision (Git commit SHA) of the page.
- The page author.
- The commit message.
- The last update.
- Previous revisions, by selecting a revision number in the **Page version** column.

To view the changes for a wiki page:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to view history for.
1. Select **Page history**.

### View changes between page versions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15242) in GitLab 13.2.

You can see the changes made in a version of a wiki page, similar to versioned diff file views:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the wiki page you're interested in.
1. Select **Page history** to see all page versions.
1. Select the commit message in the **Changes** column for the version you're interested in.

   ![Wiki page changes](img/wiki_page_diffs_v13_2.png)

## Track wiki events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14902) in GitLab 12.10.
> - Git events were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216014) in GitLab 13.0.
> - [Feature flag for Git events was removed](https://gitlab.com/gitlab-org/gitlab/-/issues/258665) in GitLab 13.5.

GitLab tracks wiki creation, deletion, and update events. These events are displayed on these pages:

- [User profile](../../profile/index.md#access-your-user-profile).
- Activity pages, depending on the type of wiki:
  - [Group activity](../../group/manage.md#view-group-activity).
  - [Project activity](../working_with_projects.md#view-project-activity).

Commits to wikis are not counted in [repository analytics](../../analytics/repository_analytics.md).

## Customize sidebar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23109) in GitLab 13.8, the sidebar can be customized by selecting the **Edit sidebar** button.

Prerequisites:

- You must have at least the Developer role.

This process creates a wiki page named `_sidebar` which fully
replaces the default sidebar navigation:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. In the upper-right corner of the page, select **Edit sidebar**.
1. When complete, select **Save changes**.

A `_sidebar` example, formatted with Markdown:

```markdown
### [Home](home)

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

## Enable or disable a project wiki

Wikis are enabled by default in GitLab. Project [administrators](../../permissions.md)
can enable or disable a project wiki by following the instructions in
[Sharing and permissions](../settings/index.md#configure-project-features-and-permissions).

Administrators for self-managed GitLab installs can
[configure additional wiki settings](../../../administration/wikis/index.md).

You can disable group wikis from the [group settings](group.md#configure-group-wiki-visibility)

## Link an external wiki

To add a link to an external wiki from a project's left sidebar:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **External wiki**.
1. Add the URL to your external wiki.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

You can now see the **External wiki** option from your project's
left sidebar.

When you enable this integration, the link to the external
wiki doesn't replace the link to the internal wiki.
To hide the internal wiki from the sidebar, [disable the project's wiki](#disable-the-projects-wiki).

To hide the link to an external wiki:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **External wiki**.
1. Under **Enable integration**, clear the **Active** checkbox.
1. Select **Save changes**.

## Disable the project's wiki

To disable a project's internal wiki:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Scroll down to find and turn off the **Wiki** toggle (in gray).
1. Select **Save changes**.

The internal wiki is now disabled, and users and project members:

- Cannot find the link to the wiki from the project's sidebar.
- Cannot add, delete, or edit wiki pages.
- Cannot view any wiki page.

Previously added wiki pages are preserved in case you
want to re-enable the wiki. To re-enable it, repeat the process
to disable the wiki but toggle it on (in blue).

## Rich text editor

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5643) in GitLab 14.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345398) switching between editing experiences in GitLab 14.7 [with a flag](../../../administration/feature_flags.md) named `wiki_switch_between_content_editor_raw_markdown`. Enabled by default.
> - Switching between editing experiences generally available in GitLab 14.10. [Feature flag `wiki_switch_between_content_editor_raw_markdown`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83760) removed.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/398152) from content editor to rich text editor in GitLab 16.2.

GitLab provides a WYSIWYG editing experience for GitLab Flavored Markdown in wikis.

Support includes:

- Formatting text, including using bold, italics, block quotes, headings, and inline code.
- Formatting ordered lists, unordered lists, and checklists.
- Creating and editing table structure.
- Inserting and formatting code blocks with syntax highlighting.
- Previewing Mermaid, PlantUML, and Kroki diagrams ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86701) in GitLab 15.2).
- Creating and editing HTML comments ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104084) in GitLab 15.7).

### Use the rich text editor

1. [Create](#create-a-new-wiki-page) a new wiki page, or [edit](#edit-a-wiki-page) an existing one.
1. Select **Markdown** as your format.
1. Above **Content**, select **Edit rich text**.
1. Customize your page's content using the various formatting options available in the rich text editor.
1. Select **Create page** for a new page, or **Save changes** for an existing page.

The rich text editing mode remains the default until you switch back to
[edit the raw source](#switch-back-to-the-old-editor).

### Switch back to the old editor

1. *If you're editing the page in the rich text editor,* scroll to **Content**.
1. Select **Edit source**.

### GitLab Flavored Markdown support

Supporting all GitLab Flavored Markdown content types in the rich text editor is a work in progress.
For the status of the ongoing development for CommonMark and GitLab Flavored Markdown support, read:

- [Basic Markdown formatting extensions](https://gitlab.com/groups/gitlab-org/-/epics/5404) epic.
- [GitLab Flavored Markdown extensions](https://gitlab.com/groups/gitlab-org/-/epics/5438) epic.

## Related topics

- [Wiki settings for administrators](../../../administration/wikis/index.md)
- [Project wikis API](../../../api/wikis.md)
- [Group repository storage moves API](../../../api/group_repository_storage_moves.md)
- [Group wikis API](../../../api/group_wikis.md)
- [Wiki keyboard shortcuts](../../shortcuts.md#wiki-pages)

## Troubleshooting

### Page slug rendering with Apache reverse proxy

In GitLab 14.9 and later, page slugs are now encoded using the
[`ERB::Util.url_encode`](https://www.rubydoc.info/stdlib/erb/ERB%2FUtil.url_encode) method.
If you use an Apache reverse proxy, you can add a `nocanon` argument to the `ProxyPass`
line of your Apache configuration to ensure your page slugs render correctly.

### Recreate a project wiki with the Rails console

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

WARNING:
This operation deletes all data in the wiki.

WARNING:
Any command that changes data directly could be damaging if not run correctly, or under the
right conditions. We highly recommend running them in a test environment with a backup of the
instance ready to be restored, just in case.

To clear all data from a project wiki and recreate it in a blank state:

1. [Start a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run these commands:

   ```ruby
   # Enter your project's path
   p = Project.find_by_full_path('<username-or-group>/<project-name>')

   # This command deletes the wiki project from the filesystem.
   p.wiki.repository.remove

   # Refresh the wiki repository state.
   p.wiki.repository.expire_exists_cache
   ```

All data from the wiki has been cleared, and the wiki is ready for use.
