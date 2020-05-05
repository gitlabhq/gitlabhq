# Wiki

A separate system for documentation called Wiki, is built right into each
GitLab project. It is enabled by default on all new projects and you can find
it under **Wiki** in your project.

Wikis are very convenient if you don't want to keep your documentation in your
repository, but you do want to keep it in the same project where your code
resides.

You can create Wiki pages in the web interface or
[locally using Git](#adding-and-editing-wiki-pages-locally) since every Wiki is
a separate Git repository.

## First time creating the Home page

The first time you visit a Wiki, you will be directed to create the Home page.
The Home page is necessary to be created since it serves as the landing page
when viewing a Wiki. You only have to fill in the **Content** section and click
**Create page**. You can always edit it later, so go ahead and write a welcome
message.

![New home page](img/wiki_create_home_page.png)

## Creating a new wiki page

NOTE: **Note:**
Requires Developer [permissions](../../permissions.md).

Create a new page by clicking the **New page** button that can be found
in all wiki pages.

You will be asked to fill in a title for your new wiki page.

You can specify a full path for the wiki page by using '/' in the
title to indicate subdirectories. Any missing directories will be created
automatically. For example, a title of `docs/my-page` will create a wiki
page with a path `/wikis/docs/my-page`.

Once you enter the page name, it's time to fill in its content. GitLab wikis
support Markdown, RDoc, AsciiDoc, and Org. For Markdown based pages, all the
[Markdown features](../../markdown.md) are supported and for links there is
some [wiki specific](../../markdown.md#wiki-specific-markdown) behavior.

In the web interface the commit message is optional, but the GitLab Wiki is
based on Git and needs a commit message, so one will be created for you if you
do not enter one.

When you're ready, click the **Create page** and the new page will be created.

![New page](img/wiki_create_new_page.png)

### Attachment storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/33475) in GitLab 11.3.

Starting with GitLab 11.3, any file that is uploaded to the wiki via GitLab's
interface will be stored in the wiki Git repository, and it will be available
if you clone the wiki repository locally. All uploaded files prior to GitLab
11.3 are stored in GitLab itself. If you want them to be part of the wiki's Git
repository, you will have to upload them again.

### Special characters in page titles

Wiki pages are stored as files in a Git repository, so certain characters have a special meaning:

- Spaces are converted into hyphens when storing a page.
- Hyphens (`-`) are converted back into spaces when displaying a page.
- Slashes (`/`) can't be used, because they're used as path separator.

### Length restrictions for file and directory names

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24364) in GitLab 12.8.

Many common file systems have a [limit of 255 bytes for file and directory names](https://en.wikipedia.org/wiki/Comparison_of_file_systems#Limits), and while Git and GitLab both support paths exceeding those limits, the presence of them makes it impossible for users on those file systems to checkout a wiki repository locally.

To avoid this situation, these limits are enforced when editing pages through the GitLab web interface and API:

- 245 bytes for page titles (reserving 10 bytes for the file extension).
- 255 bytes for directory names.

Please note that:

- Non-ASCII characters take up more than one byte.
- It's still possible to create files and directories exceeding those limits locally through Git, but this might break on other people's machines.

## Editing a wiki page

NOTE: **Note:**
Requires Developer [permissions](../../permissions.md).

To edit a page, simply click on the **Edit** button. From there on, you can
change its content. When done, click **Save changes** for the changes to take
effect.

### Adding a table of contents

To generate a table of contents from the headings in a Wiki page, use the `[[_TOC_]]` tag.
For an example, see [Table of contents](../../markdown.md#table-of-contents).

## Deleting a wiki page

NOTE: **Note:**
Requires Maintainer [permissions](../../permissions.md).

You can find the **Delete** button only when editing a page. Click on it and
confirm you want the page to be deleted.

## Moving a wiki page

You can move a wiki page from one directory to another by specifying the full
path in the wiki page title in the [edit](#editing-a-wiki-page) form.

![Moving a page](img/wiki_move_page_1.png)

![After moving a page](img/wiki_move_page_2.png)

In order to move a wiki page to the root directory, the wiki page title must
be preceded by the slash (`/`) character.

## Viewing a list of all created wiki pages

Every wiki has a sidebar from which a short list of the created pages can be
found. The list is ordered alphabetically.

![Wiki sidebar](img/wiki_sidebar.png)

If you have many pages, not all will be listed in the sidebar. Click on
**View All Pages** to see all of them.

## Viewing the history of a wiki page

The changes of a wiki page over time are recorded in the wiki's Git repository,
and you can view them by clicking the **Page history** button.

From the history page you can see the revision of the page (Git commit SHA), its
author, the commit message, when it was last updated, and the page markup format.
To see how a previous version of the page looked like, click on a revision
number.

![Wiki page history](img/wiki_page_history.png)

## Wiki activity records

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14902) in GitLab 12.10.
> - It's deployed behind a feature flag, disabled by default.
> - It's enabled on GitLab.com.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-wiki-events-core-only). **(CORE ONLY)**

Wiki events (creation, deletion, and updates) are tracked by GitLab and
displayed on the [user profile](../../profile/index.md#user-profile),
[group](../../group/index.md#view-group-activity),
and [project](../index.md#project-activity) activity pages.

### Limitations

Only edits made in the browser or through the API have their activity recorded.
Edits made and pushed through Git are not currently listed in the activity list.

### Enable or disable Wiki Events **(CORE ONLY)**

Wiki event activity is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/troubleshooting/navigating_gitlab_via_rails_console.md#starting-a-rails-console-session)
can enable it for your instance. You're welcome to test it, but use it at your
own risk.

To enable it:

```ruby
Feature.enable(:wiki_events)
```

To disable it:

```ruby
Feature.disable(:wiki_events)
```

## Adding and editing wiki pages locally

Since wikis are based on Git repositories, you can clone them locally and edit
them like you would do with every other Git repository.

On the right sidebar, click on **Clone repository** and follow the on-screen
instructions.

## Customizing sidebar

On the project's Wiki page, there is a right side navigation that renders the full Wiki pages list by default, with hierarchy.

To customize the sidebar, you can create a file named `_sidebar` to fully replace the default navigation.

CAUTION: **Warning:**
Unless you link the `_sidebar` file from your custom nav, to edit it you'll have to access it directly
from the browser's address bar by typing: `https://gitlab.com/<namespace>/<project_name>/-/wikis/_sidebar` (for self-managed GitLab instances, replace `gitlab.com` with your instance's URL).

Example for `_sidebar` (using Markdown format):

```markdown
### [Home](home)

- [Hello World](hello)
- [Foo](foo)
- [Bar](bar)

---

- [Sidebar](_sidebar)
```

Support for displaying a generated TOC with a custom side navigation is planned.
