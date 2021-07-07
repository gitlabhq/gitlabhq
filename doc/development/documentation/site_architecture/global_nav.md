---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: "Learn how GitLab docs' global navigation works and how to add new items."
---

# Global navigation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/362) in GitLab 11.6.
> - [Updated](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/482) in GitLab 12.1.
> - [Per-project](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/498) navigation added in GitLab 12.2.
> - [Unified global navigation](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/1482) added in GitLab 13.11.

Global navigation is the left-most pane in the documentation. You can use the
"global nav" to browse the content.

Research shows that people use Google to search for GitLab product documentation. When they land on a result,
we want them to find topics nearby that are related to the content they're reading. The global nav provides this information.

At the highest level, our global nav is workflow-based. Navigation needs to help users build a mental model of how to use GitLab.
The levels under each of the higher workflow-based topics are the names of features.
For example:

**Use GitLab** (_workflow_) **> Build your application** (_workflow_) **> CI/CD** (_feature_) **> Pipelines** (_feature)

## Choose the right words for your navigation entry

Before you add an item to the left nav, choose the parts of speech you want to use.

The nav entry should match the page title. However, if the title is too long,
when you shorten the phrase, use either:

- A noun, like **Merge requests**.
- An active verb, like **Install GitLab** or **Get started with runners**.

Use a phrase that clearly indicates what the page is for. For example, **Get started** is not
as helpful as **Get started with runners**.

## Add a navigation entry

All topics should be included in the left nav.

To add a topic to the global nav, edit
[`navigation.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/content/_data/navigation.yaml)
and add your item.

All new pages need a navigation item. Without a navigation, the page becomes "orphaned." That
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

## How it works

The global nav has five levels:

- **Section**
  - Category
    - Doc
      - Doc
        - Doc

The majority of the links available on the nav were added according to the UI.
The match is not perfect, as for some UI nav items the documentation doesn't
apply, and there are also other links to help the new users to discover the
documentation. The docs under **Administration** are ordered alphabetically
for clarity.

To see the improvements planned, check the
[global nav epic](https://gitlab.com/groups/gitlab-org/-/epics/1599).

**Do not** [add items](#add-a-navigation-entry) to the global nav without
the consent of one of the technical writers.

## Composition

The global nav is built from two files:

- [Data](#data-file)
- [Layout](#layout-file-logic)

The data file feeds the layout with the links to the docs. The layout organizes
the data among the nav in containers properly [styled](#css-classes).

### Data file

The data file describes the structure of the navigation for the applicable project.
It is stored at <https://gitlab.com/gitlab-org/gitlab-docs/blob/main/content/_data/navigation.yaml>
and comprises of three main components:

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

#### Docs

Each doc represents the third, fourth, and fifth level of nav links. They must be always
added within a category.

Example with three doc links, one at each level:

```yaml
- category_title: Category title
  category_url: 'category-link'
  docs:
    - doc_title: Document title
      doc_url: 'doc-link'
      docs:
      - doc_title: Document title
        doc_url: 'doc-link'
        docs:
        - doc_title: Document title
          doc_url: 'doc-link'
```

A category supports as many docs as necessary, but, for clarity, try to not
overpopulate a category. Also, do not use more than three levels of docs, it
is not supported.

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

If you need to add a document in an external URL, add the attribute `external_url`
below the doc link:

```yaml
- doc_title: Document 2 title
  doc_url: 'doc-2-link'
  external_url: true
```

All nav links are clickable. If the higher-level link does not have a link
of its own, it must link to its first sub-item link, mimicking the navigation in GitLab.
This must be avoided so that we don't have duplicated links nor two `.active` links
at the same time.

Example:

```yaml
- category_title: Operations
  category_url: 'ee/user/project/integrations/prometheus_library/'
  # until we have a link to operations, the first doc link is
  # repeated in the category link
  docs:
    - doc_title: Metrics
      doc_url: 'ee/user/project/integrations/prometheus_library/'
```

#### Syntax

For all components (sections, categories, and docs), **respect the indentation**
and the following syntax rules.

##### Titles

- Use sentence case, capitalizing feature names.
- There's no need to wrap the titles, unless there's a special char in it. For example,
  in `GitLab CI/CD`, there's a `/` present, therefore, it must be wrapped in quotes.
  As convention, wrap the titles in double quotes: `category_title: "GitLab CI/CD"`.

##### URLs

URLs can be either relative or external, and the following apply:

- All links in the data file must end with `.html` (with the exception
  of `index.html` files), and not `.md`.
- For `index.html` files, use the clean (canonical) URL: `path/to/`. For example, `https://docs.gitlab.com/ee/install/index.html` becomes `ee/install/`.
- Do not start any relative link with a forward slash `/`.
- As convention, always wrap URLs in single quotes `'url'`.
- Always use the project prefix depending on which project the link you add
  lives in. To find the global nav link, from the full URL remove `https://docs.gitlab.com/`.
- If a URL links to an external URL, like the [GitLab Design System](https://design.gitlab.com),
  add the attribute `external_url: true`, for example:

  ```yaml
  - category_title: GitLab Design System
    category_url: 'https://design.gitlab.com'
    external_url: true
  ```

Examples of relative URLs:

| Full URL                                                       | Global nav URL                        |
| -------------------------------------------------------------- | ------------------------------------- |
| `https://docs.gitlab.com/ee/api/avatar.html`                   | `ee/api/avatar.html`                  |
| `https://docs.gitlab.com/ee/install/index.html`                | `ee/install/`                         |
| `https://docs.gitlab.com/omnibus/settings/database.html`       | `omnibus/settings/database.html`      |
| `https://docs.gitlab.com/charts/installation/deployment.html`  | `charts/installation/deployment.html` |
| `https://docs.gitlab.com/runner/install/docker.html`           | `runner/install/docker.html`          |

### Layout file (logic)

The [layout](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/layouts/global_nav.html)
is fed by the [data file](#data-file), builds the global nav, and is rendered by the
[default](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/layouts/default.html) layout.

The global nav contains links from all [four upstream projects](index.md#architecture).
The [global nav URL](#urls) has a different prefix depending on the documentation file you change.

| Repository                                                     | Link prefix | Final URL                          |
|----------------------------------------------------------------|-------------|------------------------------------|
| <https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc>         | `ee/`       | `https://docs.gitlab.com/ee/`      |
| <https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc> | `omnibus/`  | `https://docs.gitlab.com/omnibus/` |
| <https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs> | `runner/`   | `https://docs.gitlab.com/runner/`  |
| <https://gitlab.com/charts/gitlab/tree/master/doc>             | `charts/`   | `https://docs.gitlab.com/charts/`  |

### CSS classes

The nav is styled in the general `stylesheet.scss`. To change
its styles, keep them grouped for better development among the team.

The URL components have their unique styles set by the CSS classes `.level-0`,
`.level-1`, and `.level-2`. To adjust the link's font size, padding, color, etc,
use these classes. This way we guarantee that the rules for each link do not conflict
 with other rules in the stylesheets.
