---
description: "Learn how GitLab docs' global navigation works and how to add new items."
---

# Global navigation

> - [Introduced](https://gitlab.com/gitlab-com/gitlab-docs/merge_requests/362)
in GitLab 11.6.
> - [Updated](https://gitlab.com/gitlab-com/gitlab-docs/merge_requests/482) in GitLab 12.1.

The global nav adds to the left sidebar the ability to
navigate and explore the contents of GitLab's documentation.

The global nav should be maintained consistent through time to allow the
users to locate their most-visited links easily to facilitate navigation.
Therefore, any updates must be carefully considered by the technical writers.

## Adding new items to the global nav

To add a new doc to the nav, first and foremost, check with the technical writing team:

- If it's applicable
- What's the exact position the doc will be added to the nav

Once you get their approval and their guidance in regards to the position on the nav,
read trhough this page to understand how it works, and submit a merge request to the
docs site, adding the doc you wish to include in the nav into the
[global nav data file](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/content/_data/global-nav.yaml).

Don't forget to ask a technical writer to review your changes before merging.

## How it works

The global nav has 3 components:

- **Section**
  - Category
    - Doc

The available sections are described on the table below:

| Section       | Description                                |
| ------------- | ------------------------------------------ |
| User          | Documentation for the GitLab's user UI.    |
| Administrator | Documentation for the GitLab's admin area. |
| Contributor   | Documentation for developing GitLab.       |

The majority of the links available on the nav were added according to the UI.
The match is not perfect, as for some UI nav items the documentation doesn't
apply, and there are also other links to help the new users to discover the
documentation. The docs under **Administration** are ordered alphabetically
for clarity.

To see the improvements planned, check the
[global nav epic](https://gitlab.com/groups/gitlab-com/-/epics/21).

CAUTION: **Attention!**
**Do not** [add items](#adding-new-items-to-the-global-nav) to the global nav without
the consent of one of the technical writers.

## Composition

The global nav is built from two files:

- [Data](#data-file)
- [Layout](#layout-file-logic)

The data file feeds the layout with the links to the docs. The layout organizes
the data among the nav in containers properly [styled](#css-classes).

### Data file

The [data file](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/content/_data/global-nav.yaml)
is structured in three components: sections, categories, and docs.

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

The [layout](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/layouts/global_nav.html)
is fed by the [data file](#data-file), builds the global nav, and is rendered by the
[default](https://gitlab.com/gitlab-com/gitlab-docs/blob/master/layouts/default.html) layout.

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
