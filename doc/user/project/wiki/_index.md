---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Wiki
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you don't want to keep your documentation in your repository, but you want
to keep it in the same project as your code, you can use the wiki GitLab provides
in each GitLab project. Every wiki is a separate Git repository, so you can create
wiki pages in the web interface, or [locally using Git](#create-or-edit-wiki-pages-locally).

GitLab wikis support Markdown, RDoc, AsciiDoc, and Org for content.
Wiki pages written in Markdown support all [Markdown features](../../markdown.md),
and also provide some [wiki-specific behavior](../../markdown.md#wiki-specific-markdown)
for links.

Wiki pages also display a [sidebar](#sidebar), which [you can customize](#customize-sidebar).

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

The default branch for your wiki repository depends on your version of GitLab:

- *GitLab versions 14.1 and later:* Wikis inherit the
  [default branch name](../repository/branches/default.md) configured for
  your instance or group. If no custom value is configured, GitLab uses `main`.
- *GitLab versions 14.0 and earlier:* GitLab uses `master`.

For any version of GitLab, you can
[rename this default branch](../repository/branches/default.md#update-the-default-branch-name-in-your-repository)
for previously created wikis.

## Create the wiki home page

> - Separation of page title and path [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) in GitLab 17.2 [with flags](../../../administration/feature_flags.md) named `wiki_front_matter` and `wiki_front_matter_title`. Enabled by default.
> - Feature flags `wiki_front_matter` and `wiki_front_matter_title` removed in GitLab 17.3.

When a wiki is created, it is empty. On your first visit, you can create the
home page users see when viewing the wiki. This page requires a specific path
to be used as your wiki's home page. To create it:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Select **Create your first page**.
1. Optional. Change the **Title** of the home page.
1. GitLab requires this first page to have path `home`. The page on this
   path serves as the front page for your wiki.
1. Select a **Format** for styling your text.
1. Add a welcome message for your home page in the **Content** section. You can
   always edit it later.
1. Add a **Commit message**. Git requires a commit message, so GitLab creates one
   if you don't enter one yourself.
1. Select **Create page**.

## Create a new wiki page

> - Separation of page title and path [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) in GitLab 17.2 [with flags](../../../administration/feature_flags.md) named `wiki_front_matter` and `wiki_front_matter_title`. Enabled by default.
> - Feature flags `wiki_front_matter` and `wiki_front_matter_title` removed in GitLab 17.3.

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Select **Wiki actions** (**{ellipsis_v}**), then **New page** on this page, or any other wiki page.
1. Select a content format.
1. Add a **Title** for your new page.
1. Optional. Uncheck **Generate page path from title** and change the **Path** of the page.
   Page paths use [special characters](#special-characters-in-page-paths) for subdirectories and formatting,
   and have [length restrictions](#length-restrictions-for-file-and-directory-names).
1. Optional. Add content to your wiki page.
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
1. Select **Wiki actions** (**{ellipsis_v}**), then **Clone repository**.
1. Follow the on-screen instructions.

Files you add to your wiki locally must use one of the following
supported extensions, depending on the markup language you wish to use.
Files with unsupported extensions don't display when pushed to GitLab:

- Markdown extensions: `.mdown`, `.mkd`, `.mkdn`, `.md`, `.markdown`.
- AsciiDoc extensions: `.adoc`, `.ad`, `.asciidoc`.
- Other markup extensions: `.textile`, `.rdoc`, `.org`, `.creole`, `.wiki`, `.mediawiki`, `.rst`.

### Special characters in page paths

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133521) front matter based titles in GitLab 16.7 [with flags](../../../administration/feature_flags.md) named `wiki_front_matter` and `wiki_front_matter_title`. Disabled by default.
> - Feature flags [`wiki_front_matter`](https://gitlab.com/gitlab-org/gitlab/-/issues/435056) and [`wiki_front_matter_title`](https://gitlab.com/gitlab-org/gitlab/-/issues/428259) enabled by default in GitLab 17.2.
> - Feature flags `wiki_front_matter` and `wiki_front_matter_title` removed in GitLab 17.3.

Wiki pages are stored as files in a Git repository, and by default, the filename of
a page is also its title. Certain characters in the filename have a special meaning:

- Spaces are converted into hyphens when storing a page.
- Hyphens (`-`) are converted back into spaces when displaying a page.
- Slashes (`/`) are used as path separators, and can't be displayed in titles. If you
  create a file with title containing `/` characters, GitLab creates all the subdirectories
  needed to build that path. For example, a title of `docs/my-page` creates a wiki
  page with a path `/wikis/docs/my-page`.

To circumvent these limitations, you can also store the title of a wiki page in a
front matter block before a page's contents. For example:

```yaml
---
title: Page title
---
```

### Length restrictions for file and directory names

Many common file systems have a [limit of 255 bytes](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits)
for file and directory names. Git and GitLab both support paths exceeding
those limits. However, if your file system enforces these limits, you cannot check out a
local copy of a wiki that contains filenames exceeding this limit. To prevent this
problem, the GitLab web interface and API enforce these limits:

- 245 bytes for filenames (reserving 10 bytes for the file extension).
- 255 bytes for directory names.

Non-ASCII characters take up more than one byte.

While you can still create files locally that exceed these limits, your teammates
may not be able to check out the wiki locally afterward.

## Edit a wiki page

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to edit, and either:
   - Use the <kbd>e</kbd> wiki [keyboard shortcut](../../shortcuts.md#wiki-pages).
   - Select **Edit**.
1. Edit the content.
1. Select **Save changes**.

Unsaved changes to a wiki page are preserved in local browser storage to prevent accidental data loss.

### Create a table of contents

> - Table of contents in the wiki sidebar [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/281570) in GitLab 17.2.

Wiki pages with headings in their contents automatically display a table of contents
section in the sidebar.

You can also choose to optionally display a separate table of contents section on the page
itself. To generate a table of contents from a wiki page's subheadings, use the
`[[_TOC_]]` tag. For an example, read [Table of contents](../../markdown.md#table-of-contents).

## Delete a wiki page

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to delete.
1. Select **Wiki actions** (**{ellipsis_v}**), then **Delete page**.
1. Confirm the deletion.

## Move or rename a wiki page

> - Redirects for moved or renamed wiki pages [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/257892) in GitLab 17.1 [with a flag](../../../administration/feature_flags.md) named `wiki_redirection`. Enabled by default.
> - Separation of page title and path [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30758) in GitLab 17.2 [with flags](../../../administration/feature_flags.md) named `wiki_front_matter` and `wiki_front_matter_title`. Enabled by default.
> - Feature flags `wiki_redirection`, `wiki_front_matter` and `wiki_front_matter_title` removed in GitLab 17.3.

In GitLab 17.1 and later, when you move or rename a page, a redirect is
automatically set up from the old page to the new page. A list of redirects
is stored in the `.gitlab/redirects.yml` file in the Wiki repository.

Prerequisites:

- You must have at least the Developer role.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to move or rename.
1. Select **Edit**.
1. To move the page, add the new path to the **Path** field. For example,
   if you have a wiki page called `About` under `Company` and you want to
   move it to the wiki's root, change the **Path** from `About` to `/About`.
1. To rename the page, change the **Path**.
1. Select **Save changes**.

## Export a wiki page

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414691) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `print_wiki`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134251/) in GitLab 16.5.
> - Feature flag `print_wiki` removed in GitLab 16.6.

You can export a wiki page as a PDF file:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to export.
1. On the top right, select **Wiki actions** (**{ellipsis_v}**), then select **Print as PDF**.

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
1. Select **Wiki actions** (**{ellipsis_v}**), then **Templates**.
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

- The revision of the page.
- The page author.
- The commit message.
- The last update.
- Previous revisions, by selecting a revision number in the **Page version** column.

To view the changes for a wiki page:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the page you want to view history for.
1. Select **Wiki actions** (**{ellipsis_v}**), then **Page history**.

### View changes between page versions

You can see the changes made in a version of a wiki page, similar to versioned diff file views:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. Go to the wiki page you're interested in.
1. Select **Wiki actions** (**{ellipsis_v}**), then **Page history** to see all page versions.
1. Select the commit message in the **Diff** column for the version you're interested in.

## Sidebar

> - Searching by title in the sidebar [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156054) in GitLab 17.1.
> - Limit of 15 items in the sidebar [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158084) in GitLab 17.2.

Wiki pages display a sidebar that contains a list of pages in the wiki,
displayed as a nested tree, with sibling pages listed in alphabetical order.

You can quickly find a page by its title in the wiki using the search box in
the sidebar.

For performance reasons, the sidebar is limited to displaying 5000 entries. To
view a list of all pages, select **View All Pages** in the sidebar.

### Customize sidebar

You can manually edit the contents of the sidebar navigation.

Prerequisites:

- You must have at least the Developer role.

This process creates a wiki page named `_sidebar` which fully
replaces the default sidebar navigation:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Plan > Wiki**.
1. In the upper-right corner of the page, select **Add custom sidebar** (**{settings}**).
1. When complete, select **Save changes**.

A `_sidebar` example, formatted with Markdown:

```markdown
### Home

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

## Enable or disable a project wiki

Wikis are enabled by default in GitLab. Project [administrators](../../permissions.md)
can enable or disable a project wiki by following the instructions in
[Sharing and permissions](../settings/_index.md#configure-project-features-and-permissions).

Administrators for GitLab Self-Managed can
[configure additional wiki settings](../../../administration/wikis/_index.md).

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

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/398152) from content editor to rich text editor in GitLab 16.2.

GitLab provides a rich text editing experience for GitLab Flavored Markdown in wikis.

Support includes:

- Formatting text, including using bold, italics, block quotes, headings, and inline code.
- Formatting ordered lists, unordered lists, and checklists.
- Creating and editing table structure.
- Inserting and formatting code blocks with syntax highlighting.
- Previewing Mermaid, PlantUML, and Kroki diagrams.

### Use the rich text editor

1. [Create](#create-a-new-wiki-page) a new wiki page, or [edit](#edit-a-wiki-page) an existing one.
1. Select **Markdown** as your format.
1. Under **Content**, in the lower-left corner, select **Switch to rich text editing**.
1. Customize your page's content using the various formatting options available in the rich text editor.
1. Select **Create page** for a new page, or **Save changes** for an existing page.

To switch back to plain text, select **Switch to plain text editing**.

See also:

- [Rich text editor](../../rich_text_editor.md)

### GitLab Flavored Markdown support

Supporting all GitLab Flavored Markdown content types in the rich text editor is a work in progress.
For the status of the ongoing development for CommonMark and GitLab Flavored Markdown support, read:

- [Basic Markdown formatting extensions](https://gitlab.com/groups/gitlab-org/-/epics/5404) epic.
- [GitLab Flavored Markdown extensions](https://gitlab.com/groups/gitlab-org/-/epics/5438) epic.

## Track wiki events

GitLab tracks wiki creation, deletion, and update events. These events are displayed on the following pages:

- [User profile](../../profile/_index.md#access-your-user-profile).
- Activity pages, depending on the type of wiki:
  - [Group activity](../../group/manage.md#view-group-activity).
  - [Project activity](../working_with_projects.md#view-project-activity).

Commits to wikis are not counted in [repository analytics](../../analytics/repository_analytics.md).

## Troubleshooting

### Page slug rendering with Apache reverse proxy

Page slugs are encoded using the
[`ERB::Util.url_encode`](https://www.rubydoc.info/stdlib/erb/ERB%2FUtil.url_encode) method.
If you use an Apache reverse proxy, you can add a `nocanon` argument to the `ProxyPass`
line of your Apache configuration to ensure your page slugs render correctly.

### Recreate a project wiki with the Rails console

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

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

## Related topics

- [Wiki settings for administrators](../../../administration/wikis/_index.md)
- [Project wikis API](../../../api/wikis.md)
- [Group wikis API](../../../api/group_wikis.md)
- [Group repository storage moves API](../../../api/group_repository_storage_moves.md)
- [Wiki keyboard shortcuts](../../shortcuts.md#wiki-pages)
- [GitLab Flavored Markdown](../../markdown.md)
- [Asciidoc](../../asciidoc.md)
