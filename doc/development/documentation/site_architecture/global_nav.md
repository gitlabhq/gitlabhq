---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how GitLab docs' global navigation works and how to add new items.
title: Global navigation
---

Global navigation (global nav) is the left-most pane in the documentation. You can use the
global nav to browse the content.

Research shows that people use Google to search for GitLab product documentation. When they land on a result,
we want them to find topics nearby that are related to the content they're reading. The global nav provides this information.

At the highest level, our global nav is **workflow-based**. Navigation needs to help users build a mental model of how to use GitLab.
The levels under each of the higher workflow-based topics are the names of features. For example:

**Use GitLab** (_workflow_) > **Build your application** (_workflow_) > **Get started** (_feature_) > **CI/CD** (_feature_) > **Pipelines** (_feature_)

While some older sections of the nav are alphabetical, the nav should primarily be workflow-based.

Without a navigation entry:

- The navigation closes when the page is opened, and the reader loses their place.
- The page isn't visible in a group with other pages.

## Choose the right words for your navigation entry

Before you add an item to the left nav, choose the parts of speech you want to use.

The nav entry should match the page title. However, if the title is too long,
when you shorten the phrase, use either:

- A noun, like **Merge requests**.
- An active verb, like **Install GitLab** or **Get started with runners**.

Use a phrase that clearly indicates what the page is for. For example, **Get started** is not
as helpful as **Get started with runners**.

## Add a navigation entry

The global nav is stored in the `gitlab-org/technical-writing/docs-gitlab-com` project, in the
`data/en-us/navigation.yaml` file. The documentation website at `docs.gitlab.com` is built using Hugo and assembles documentation
content from several projects (including `charts`, `gitlab`, `gitlab-runner`, and `omnibus-gitlab`).

**Do not** add items to the global nav without
the consent of one of the technical writers.

To add a topic to the global navigation:

1. Check that the topic is published on <https://docs.gitlab.com>.
1. In the [`navigation.yaml`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/en-us/navigation.yaml)
   file, add the item.
1. Assign the MR to a technical writer for review and merge.

### Where to add

Documentation pages can be said to belong in the following groups:

- GitLab users. This documentation is for day-to-day use of GitLab for users with any level
  of permissions, from Reporter to Owner.
- GitLab administrators. This tends to be documentation for GitLab Self-Managed instances that requires
  access to the underlying infrastructure hosting GitLab.
- Other documentation. This includes documentation for customers outside their day-to-day use of
  GitLab and for contributors. Documentation that doesn't fit in the other groups belongs here.

With these groups in mind, the following are general rules for where new items should be added.

- User documentation belongs in **Use GitLab**.
- Administration documentation belongs under **Administer**. This documentation often includes sections that mention:

  - Changing the `gitlab.rb` or `gitlab.yml` files.
  - Accessing the rails console or running Rake tasks.
  - Doing things in the **Admin** area.
  - Tasks that can only be done by an instance administrator.

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

### Pages you don't need to add

Exclude these pages from the global nav:

- Legal notices.
- Pages in the `user/application_security/dast/checks/` directory.

The following pages should probably be in the global nav, but the technical writers
do not actively work to add them:

- Pages in the `/development` directory.
- Pages authored by the support team, which are under the `doc/administration/troubleshooting` directory.

Sometimes a feature page must be excluded from the global navigation. For example,
pages for deprecated features might not be in the global nav, depending on how long ago the feature was deprecated.
To make it clear these pages are excluded from the global navigation on purpose,
add the following code to the page's front matter:

```yaml
ignore_in_report: true
```

All other pages should be in the global nav.

The technical writing team runs a report to determine which pages are not in the nav.
This report skips pages with `ignore_in_report: true` in the front matter.
The team reviews this list each month.

### Use GitLab section

In addition to feature documentation, each category in the **Use GitLab** section should contain:

- A [top-level page](../topic_types/top_level_page.md).
- A [Get started page](../topic_types/get_started.md).

This ensures a repeatable pattern that familiarizes users with how to navigate the documentation.

The structure for the **Use GitLab** section is:

- Use GitLab
  - Top-level page
    - Get started page
    - Feature
    - Feature

## Composition

The global nav is built from two files:

- [Data](#data-file)
- [Layout](#layout-file-logic)

The data file feeds the layout with the links to the documentation.
The layout organizes the data among the nav in containers properly [styled](#css-classes).

### Data file

The data file describes the structure of the navigation for the applicable project.
It is stored at <https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/en-us/navigation.yaml>.

Each entry comprises of three main components:

- `title`
- `url`
- `submenu` (optional)

For example:

```yaml
- title: Getting started
  url: 'user/get_started/'
- title: Tutorials
  url: 'tutorials/'
  submenu:
    - title: Find your way around GitLab
      url: 'tutorials/gitlab_navigation/'
      submenu:
        - title: 'Tutorial: Use the left sidebar to navigate GitLab'
          url: 'tutorials/left_sidebar/'
```

Each entry can stand alone or contain nested pages, under `submenu`.
New components are indented two spaces.

All nav links:

- Are selectable.
- Must refer to unique pages.
- Must not point to an anchor in a page, for example: `path/to/page/#anchor-link`.

This must be followed so that we don't have duplicated links nor two `.active` links
at the same time.

#### Syntax

For all components, **respect the indentation** and the following syntax rules.

##### Titles

- Use sentence case, capitalizing feature names.
- There's no need to wrap the titles, unless there's a special character in it. For example,
  in `GitLab CI/CD`, there's a `/` present, therefore, it must be wrapped in quotes.
  As convention, wrap the titles in double quotes: `title: "GitLab CI/CD"`.

##### URLs

URLs must be relative. In addition:

- End each URL with a trailing `/` (not `.html` or `.md`).
- Do not start any relative link with a forward slash `/`.
- Match the path you see on the website.
- As convention, always wrap URLs in single quotes `'url'`.
  To find the global nav link, from the full URL remove `https://docs.gitlab.com/`.
- Do not link to external URLs. Leaving the documentation site by clicking the left navigation is a confusing user experience.

Examples of relative URLs:

| Full URL                                                  | Global nav URL |
| --------------------------------------------------------- | -------------- |
| `https://docs.gitlab.com/api/avatar/`                     | `api/avatar/`  |
| `https://docs.gitlab.com/charts/installation/deployment/` | `charts/installation/deployment/` |
| `https://docs.gitlab.com/install/`                        | `install/`     |
| `https://docs.gitlab.com/omnibus/settings/database/`      | `omnibus/settings/database/` |
| `https://docs.gitlab.com/operator/installation/`          | `operator/installation/` |
| `https://docs.gitlab.com/runner/install/docker/`          | `runner/install/docker/` |

### Layout file (logic)

The navigation Vue.js component [`sidebar_menu.vue`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/themes/gitlab-docs/src/components/sidebar_menu.vue)
is fed by the [data file](#data-file) and builds the global nav.

The global nav contains links from all [five upstream projects](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/architecture.md).
The [global nav URL](#urls) has a different prefix depending on the documentation file you change.

| Repository                                                                     | Link prefix | Final URL |
| ------------------------------------------------------------------------------ | ----------- | --------- |
| <https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc>                       | None        | `https://docs.gitlab.com/` |
| <https://gitlab.com/charts/gitlab/tree/master/doc>                             | `charts/`   | `https://docs.gitlab.com/charts/` |
| <https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc>                 | `omnibus/`  | `https://docs.gitlab.com/omnibus/` |
| <https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/tree/master/doc> | `operator`  | `https://docs.gitlab.com/operator/` |
| <https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs>                 | `runner/`   | `https://docs.gitlab.com/runner/` |

### CSS classes

The nav is styled in the general `main.css` file. To change
its styles, keep them grouped for better development among the team.

## Testing

We run various checks on `navigation.yaml` in
[`check-navigation.sh`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/scripts/check-navigation.sh),
which runs as a pipeline job when the YAML file is updated.
