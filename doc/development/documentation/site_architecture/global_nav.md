---
description: "Learn how GitLab docs' global navigation works and how to add new items."
---

# Global navigation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/362) in GitLab 11.6.
> - [Updated](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/482) in GitLab 12.1.
> - [Per-project](https://gitlab.com/gitlab-org/gitlab-docs/merge_requests/498) navigation added in GitLab 12.2.

Global navigation (the left-most pane in our three pane documentation) provides:

- A high-level grouped view of product features.
- The ability to discover new features by browsing the menu structure.
- A way to allow the reader to focus on product areas.
- The ability to refine landing pages, so they don't have to do all the work of surfacing
  every page contained within the documentation.

## Adding new items

All new pages need a new navigation item. Without a navigation, the page becomes "orphaned". That
is:

- The navigation shuts when the page is opened, and the reader loses their place.
- The page doesn't belong in a group with other pages.

This means the decision to create a new page is a decision to create new navigation item and vice
versa.

### Where to add

Documentation pages can be said to belong in the following groups:

- GitLab users. This is documentation for day-to-day use of GitLab for users with any level
  of permissions, from Reporter to Owner.
- GitLab administrators. This tends to be documentation for self-managed instances that requires
  access to the underlying infrastructure hosting GitLab.
- Other documentation. This includes documentation for customers outside their day-to-day use of
  GitLab and for contributors. Documentation that doesn't fit in the other groups belongs here.

With these groups in mind, the following are general rules for where new items should be added.

- User documentation for:
  - Group-level features belongs under **Groups**.
  - Project-level features belongs under **Projects**.
  - Features outside a group or project level (sometimes called "instance-level") can be placed at
    the top-level, but care must be taken not to overwhelm that top-level space. If possible, such
    features could be grouped in some way.
  - Outside the above, most other miscellaneous user documentation belongs under **User**.
- Administration documentation belongs under **Administrator**.
- Other documentation belongs at the top-level, but care must be taken to not create an enormously
  long top-level navigation, which defeats the purpose of it.

NOTE: **Note:**
Making all documentation and navigation items adhere to these principles is being progressively
rolled out.

### What to add

Having decided where to add a navigation element, the next step is deciding what to add. The
mechanics of what is required is [documented below](#data-file) but, in principle:

- Navigation item text (that which the reader sees) should:
  - Be as short as possible.
  - Be contextual. It's rare to need to repeat text from a parent item.
  - Avoid jargon or terms of art, unless ubiquitous. For example, **CI** is an acceptable
    substitution for **Continuous Integration**.
- Navigation links must follow the rules documented in the [data file](#data-file).
- EE badging is subject to the following:
  - Required when linking to an EE-only page.
  - Not required when linking to a page that is a mix of CE and EE-only content.
  - Required when all sub-items are EE-only. In this case, no sub-items are EE badged.
  - Not required when sub-items are a mix of CE and EE-only items. In this case, each item is
    badged appropriately.

## How it works

The global nav has 3 components:

- **Section**
  - Category
    - Doc

The available sections are described on the table below:

| Section       | Description                                |
| ------------- | ------------------------------------------ |
| User          | Documentation for the GitLab's user UI.    |
| Administrator | Documentation for the GitLab's Admin Area. |
| Contributor   | Documentation for developing GitLab.       |

The majority of the links available on the nav were added according to the UI.
The match is not perfect, as for some UI nav items the documentation doesn't
apply, and there are also other links to help the new users to discover the
documentation. The docs under **Administration** are ordered alphabetically
for clarity.

To see the improvements planned, check the
[global nav epic](https://gitlab.com/groups/gitlab-com/-/epics/21).

CAUTION: **Attention!**
**Do not** [add items](#adding-new-items) to the global nav without
the consent of one of the technical writers.

## Composition

The global nav is built from two files:

- [Data](#data-file)
- [Layout](#layout-file-logic)

The data file feeds the layout with the links to the docs. The layout organizes
the data among the nav in containers properly [styled](#css-classes).

### Data file

The data file describes the structure of the navigation for the applicable project. All data files
are stored at <https://gitlab.com/gitlab-org/gitlab-docs/blob/master/content/_data/> and comprise
three components:

- Sections
- Categories
- Docs

#### Sections

Each section represents the higher-level nav item. It's composed by
title and URL:

```yaml
sections:
  - section_title: Text
    section_url: 'link'
```

The section can stand alone or contain categories within.

#### Categories

Each category within a section composes the second level of the nav.
It includes the category title and link. It can stand alone in the nav or contain
a third level of sub-items.

Example of section with one stand-alone category:

```yaml
- section_title: Section title
  section_url: 'section-link'
  section_categories:
    - category_title: Category title
      category_url: 'category-link'
```

Example of section with two stand-alone categories:

```yaml
- section_title: Section title
  section_url: 'section-link'
  section_categories:
    - category_title: Category 1 title
      category_url: 'category-1-link'

    - category_title: Category 2 title
      category_url: 'category-2-link'
```

For clarity, **always** add a blank line between categories.

If a category URL is not present in CE (it's an EE-only document), add the
attribute `ee_only: true` below the category link. Example:

```yaml
- category_title: Category title
  category_url: 'category-link'
  ee_only: true
```

If the category links to an external URL, e.g., [GitLab Design System](https://design.gitlab.com),
add the attribute `external_url: true` below the category title. Example:

```yaml
- category_title: GitLab Design System
  category_url: 'https://design.gitlab.com'
  external_url: true
```

#### Docs

Each doc represents the third level of nav links. They must be always
added within a category.

Example with one doc link:

```yaml
- category_title: Category title
  category_url: 'category-link'
  docs:
    - doc_title: Document title
      doc_url: 'doc-link'
```

A category supports as many docs as necessary, but, for clarity, try to not
overpopulate a category.

Example with multiple docs:

```yaml
- category_title: Category title
  category_url: 'category-link'
  docs:
    - doc_title: Document 1 title
      doc_url: 'doc-1-link'
    - doc_title: Document 2 title
      doc_url: 'doc-2-link'
```

Whenever a document is only present in EE, add the attribute `ee-only: true`
below the doc link. Example:

```yaml
- doc_title: Document 2 title
  doc_url: 'doc-2-link'
  ee_only: true
```

If you need to add a document in an external URL, add the attribute `external_url`
below the doc link:

```yaml
- doc_title: Document 2 title
  doc_url: 'doc-2-link'
  external_url: true
```

All nav links are clickable. If the higher-level link does not have a link
of its own, it must link to its first sub-item link, mimicking GitLab's navigation.
This must be avoided so that we don't have duplicated links nor two `.active` links
at the same time.

Example:

```yaml
- category_title: Operations
  category_url: 'user/project/integrations/prometheus_library/'
  # until we have a link to operations, the first doc link is
  # repeated in the category link
  docs:
    - doc_title: Metrics
      doc_url: 'user/project/integrations/prometheus_library/'
```

#### Syntax

For all components (sections, categories, and docs), **respect the indentation**
and the following syntax rules.

##### Titles

- Use sentence case, capitalizing feature names.
- There's no need to wrap the titles, unless there's a special char in it. E.g.,
  in `GitLab CI/CD`, there's a `/` present, therefore, it must be wrapped in quotes.
  As convention, wrap the titles in double quotes: `category_title: "GitLab CI/CD"`.

##### URLs

- As convention, always wrap URLs in single quotes `'url'`.
- Always use relative paths against the home of CE and EE. Examples:
  - For `https://docs.gitlab.com/ee/README.html`, the relative URL is `README.html`.
  - For `https://docs.gitlab.com/ee/user/project/cycle_analytics.html`, the relative
    URL is `user/project/cycle_analytics.html`.
- For `README.html` files, add the complete path `path/to/README.html`.
- For `index.html` files, use the clean (canonical) URL: `path/to/`.
- For EE-only docs, use the same relative path, but add the attribute `ee_only: true` below
  the `doc_url` or `category_url`, as explained above. This displays
  an "info" icon on the nav to make the user aware that the feature is
  EE-only.

DANGER: **Important!**
All links present on the data file must end in `.html`, not `.md`. Do not
start any relative link with a forward slash `/`.

Examples:

```yaml
- category_title: Issues
  category_url: 'user/project/issues/'
  # note that the above URL does not start with a slash and
  # does not include index.html at the end

  docs:
    - doc_title: Service Desk
      doc_url: 'user/project/service_desk.html'
      ee_only: true
      # note that the URL above ends in html and, as the
      # document is EE-only, the attribute ee_only is set to true.
```

### Layout file (logic)

The [layout](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/layouts/global_nav.html)
is fed by the [data file](#data-file), builds the global nav, and is rendered by the
[default](https://gitlab.com/gitlab-org/gitlab-docs/blob/master/layouts/default.html) layout.

There are three main considerations on the logic built for the nav:

- [Path](#path): first-level directories underneath `docs.gitlab.com/`:
  - `https://docs.gitlab.com/ce/`
  - `https://docs.gitlab.com/ee/`
  - `https://docs.gitlab.com/omnibus/`
  - `https://docs.gitlab.com/runner/`
  - `https://docs.gitlab.com/debug/`
  - `https://docs.gitlab.com/*`
- [EE-only](#ee-only-docs): documentation only available in `/ee/`, not on `/ce/`, e.g.:
  - `https://docs.gitlab.com/ee/user/group/epics/`
  - `https://docs.gitlab.com/ee/user/project/security_dashboard.html`
- [Default URL](#default-url): between CE and EE docs, the default is `ee`, therefore, all docs
  should link to `/ee/` unless if on `/ce/` linking internally to `ce`.

#### Path

To use relative paths in the data file, we defined the variable `dir`
from the root's first-child directory, which defines the path to build
all the nav links to other pages:

```html
<% dir = @item.identifier.to_s[%r{(?<=/)[^/]+}] %>
```

For instance, for `https://docs.gitlab.com/ce/user/index.html`,
`dir` == `ce`, and for `https://docs.gitlab.com/omnibus/README.html`,
`dir` == `omnibus`.

#### Default URL

The default and canonical URL for GitLab documentation is
`https://docs.gitlab.com/ee/`, thus, all links
in the docs site should link to `/ee/` except when linking
among `/ce/` docs themselves.

Therefore, if the user is looking at `/ee/`, `/omnibus/`,
`/runner/`, or any other highest-level dir, the nav should
point to `/ee/` docs.

On the other hand, if the user is looking at `/ce/` docs,
all the links in the CE nav should link internally to `/ce/`
files.

```html
<% if dir != 'ce' %>
  <a href="/ee/<%= sec[:section_url] %>">...</a>
  <% else %>
    <a href="/<%= dir %>/<%= sec[:section_url] %>">...</a>
  <% end %>
  ...
<% end %>
```

This also allows the nav to be displayed on other
highest-level dirs (`/omnibus/`, `/runner/`, etc),
linking them back to `/ee/`.

The same logic is applied to all sections (`sec[:section_url]`),
categories (`cat[:category_url]`), and docs (`doc[:doc_url]`) URLs.

#### `ee-only` docs

Docs for features present only in GitLab EE are tagged
in the data file by `ee-only` and an icon is displayed on the nav
link indicating that the `ee-only` feature is not available in CE.

The `ee-only` attribute is available for `categories` (`<% if cat[:ee_only] %>`)
and `docs` (`<% if doc[:ee_only] %>`), but not for `sections`.

### CSS classes

The nav is styled in the general `stylesheet.scss`. To change
its styles, keep them grouped for better development among the team.

The URL components have their unique styles set by the CSS classes `.level-0`,
`.level-1`, and `.level-2`. To adjust the link's font size, padding, color, etc,
use these classes. This way we guarantee that the rules for each link do not conflict
 with other rules in the stylesheets.
