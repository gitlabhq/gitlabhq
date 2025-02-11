---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Hugo migration reference for writers
---

We are moving GitLab Docs from Nanoc to Hugo. This guide outlines the formatting
requirements for documentation after the migration.

While existing content will be automatically updated, any new or modified documentation must follow these guidelines to ensure proper building with Hugo.

For the latest migration status, see [this issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/44).

## Formatting changes

### Page titles

Page titles move from `h1` tags to `title` front matter attributes.

For example, on Nanoc, a title is added as an `h1`, like this:

```markdown
---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Cloud Connector: Configuration

A GitLab Rails instance accesses...
```

For Hugo, move the title into the page's front matter:

```markdown
---
stage: Systems
group: Cloud Connector
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 'Cloud Connector: Configuration'
---

A GitLab Rails instance accesses...
```

**Why:** Hugo can generate automated listings of pages. For these to work, Hugo needs the page title to be handled more like data than regular content.
We are not using these initially, but may do so in the future.

**When:** Currently in-progress. See [this issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/82) for details.

**Testing:** Error-level Vale rule ([`FrontMatter.yml`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/master/doc/.vale/gitlab_docs/FrontMatter.yml?ref_type=heads)).

### Shortcodes

Custom Markdown elements are now marked up using Hugo's shortcode syntax.

Our custom elements are:

- Alert boxes
- History details
- Feature availability details (tier, offering, status)
- GitLab SVG icons
- Tabs

For example, before:

```markdown
WARNING:
Don't delete your gitlabs!
```

And after:

```markdown
{{< alert type="warning" >}}

Don't delete your gitlabs!

{{< /alert >}}
```

See the [Shortcodes reference](https://new.docs.gitlab.com/shortcodes) for syntax and examples.

**Why:** Shortcodes are the standard Hugo method for creating custom templated
bits of content.

**When:** After launch.

**Testing:** Shortcodes will be validated on docs pipelines (see [implementation issue](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/issues/161)).

#### Shortcodes in `/help`

Shortcodes, like our existing custom Markdown elements, will not render in `/help`.
`/help` is a built-in set of documentation pages available in GitLab Self-Managed instances
([learn more](help.md)).

Shortcodes have more verbose syntax, so we've modified `/help` to hide these
tags and show simplified plain text fallbacks for elements like tabs and alert boxes.

**Why:** `/help` only renders plain Markdown. It is not a static site generator with
functionality to transform content or render templated frontend code.

**When:** After launch.

### Kramdown

Kramdown is no longer supported on the website.

A few example Kramdown tags that exist on the site right now:

```plaintext
{::options parse_block_html="true" /}

{: .alert .alert-warning}
```

With Hugo, these will no longer have any effect. They will render as plain text.

**Why:** Hugo uses the Goldmark Markdown rendering engine, not Kramdown.

**When:** After launch.

**Testing:** We are running an audit job on the CI pipeline for Kramdown tags ([example](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/jobs/8885163533)).
These tags will be manually removed as part of launch.

### Menu entries in `navigation.yaml`

1. We have simplified the structure of the `navigation.yaml` file. The valid
property names are now `title`, `url`, and `submenu` rather than using different property
names at each level of the hierarchy.

    For example, the Nanoc site menu data looks like this:

    ```yaml
    sections:
    - section_title: Tutorials
        section_url: 'ee/tutorials/'
        section_categories:
        - category_title: Find your way around GitLab
            category_url: 'ee/tutorials/gitlab_navigation.html'
            docs:
            - doc_title: 'Tutorial: Use the left sidebar to navigate GitLab'
                doc_url: 'ee/tutorials/left_sidebar/'
    ```

    For Hugo, it looks like this:

    ```yaml
    - title: Tutorials
      url: 'tutorials/'
      submenu:
        - title: Find your way around GitLab
          url: 'tutorials/gitlab_navigation/'
          submenu:
            - title: 'Tutorial: Use the left sidebar to navigate GitLab'
              url: 'tutorials/left_sidebar/'
    ```

    **Why:** Using the same property names at each level of the hierarchy significantly
    simplifies everything we do programmatically with the menu. It also simplifies
    menu edits for contributors.

1. As part of the change to `prettyURLs`, page paths should no longer
include a `.html` extension. End each URL with a trailing `/`.

    For example:

    ```plaintext
    # Before
    - category_title: Find your way around GitLab
      category_url: 'ee/tutorials/gitlab_navigation.html'

    # After
    - title: Find your way around GitLab
      url: 'tutorials/gitlab_navigation/'
    ```

**When:** Post-launch.

**Testing:** We various checks on `navigation.yaml` in [this script](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/blob/main/scripts/check-navigation.sh?ref_type=heads),
which runs as a pipeline job when the YAML file is updated.

## File naming

### Index file names

All files previously named `index.md` need to be named `_index.md`. For example:

```plaintext
Before:
doc/
├── user/
│   ├── index.md           # Must be renamed
│   └── feature/
│       └── index.md       # Must be renamed
└── admin/
    └── index.md           # Must be renamed

After:
doc/
├── user/
│   ├── _index.md         # Renamed
│   └── feature/
│       └── _index.md     # Renamed
└── admin/
    └── _index.md         # Renamed
```

**Why:** Hugo requires this specific naming convention for section index pages (pages that serve as the main page for a directory).
See Hugo's documentation on [Page bundles](https://gohugo.io/content-management/page-bundles/) for more information.

**When:** Currently in-progress. See [this issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/82) for details.

**Testing:** We will test for this on the pipeline and prevent merges that include an `index.md` file (see [this issue](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/issues/161) for details).

### Clashing file names

Hugo is configured to use PrettyURLs, which drop the `.html` extension from page URLs.

A _path clash_ occurs when two files would render at the same URL, making one of them
inaccessible.

```plaintext
# Example 1
- doc/development/project_templates.md
- doc/development/project_templates/index.md
# Resulting URL for both: /development/project_templates/

# Example 2
- doc/user/gitlab_duo_chat.md
- doc/user/gitlab_duo_chat/index.md
# Resulting URL for both: /user/gitlab_duo_chat/

# Example 3
- doc/administration/dedicated/configure_instance.md
- doc/administration/dedicated/configure_instance/index.md
# Resulting URL for both: /administration/dedicated/configure_instance/
```

**Why:** Hugo's options for URL paths are `prettyURLs` and `uglyURLs`. Both of these produce
somewhat different paths than the Nanoc website does. We've opted for `prettyURLs` because it's
Hugo's default, and Hugo's pattern for `uglyURLs` is different from most other static site generators.

**When:** Try to start avoiding these now because each one requires a manual fix: a rename and a redirect.

**Testing:** After launch, Hugo will throw an error on docs pipelines if it detects a new path clash.

## Processes

### Cutting a release

Cutting a release no longer requires updating `latest.Dockerfile`. This file no longer exists in
the project, and the release template has been updated accordingly.

**Why:** We've refactored versioning to use the [Parallel Deployments](../../user/project/pages/_index.md#parallel-deployments) feature.
You can review the new release process [here](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/.gitlab/issue_templates/release.md).

**When:** First new release after launch.

### Monthly technical writing tasks

The [Docs project maintenance tasks rotation](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments) will pause when we launch on Hugo.

For February 2025, run the checks for broken external links and `start_remove` content before Wednesday, February 12. Other tasks are fine to skip for now. From March onwards, the monthly maintenance task will be on hold until further notice.

NOTE:
This does not impact the release post [structural check](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#structural-check) or [monthly documentation release](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md) tasks. The assigned Technical Writer should continue to do these tasks as previously scheduled.

**Why:** Some Ruby scripts need to be rewritten in Go, and the maintenance tasks are
low-priority enough that we can launch without them. There may be more opportunity
post-launch to share more of these scripts with the Handbook project.

**Testing:** Because we will pause on removing old redirects temporarily,
we've added a [test script](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/blob/main/scripts/redirect-threshold-check.sh?ref_type=heads) to warn if we get near the Pages redirect limit.

**When:** Post-launch.

## User-facing changes

These changes take effect when we launch the new site.
They are viewable at [https://new.docs.gitlab.com](https://new.docs.gitlab.com).

### Page URLs

- `ee` prefix: We dropped the `ee` prefix from paths to pages
that come from the GitLab project.
The prefix was an artifact leftover from when pages were split
between `ce` and `ee`, and has been a source of confusion
for site visitors.
- Pretty URLs: Pages no longer have a `.html` extension in the URL.
A file located at `/foo/bar/baz.html` is available at `/foo/bar/baz`.

We have redirects in place at Cloudflare to redirect all URLs to their
new formats. See the [redirects documentation](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/blob/main/doc/redirects.md?ref_type=heads#cloudflare) in the Hugo project for more information.

### Layout changes

We implemented the layout changes proposed in [this issue](https://gitlab.com/gitlab-org/gitlab-docs/-/issues/673), which aim to improve
readability.

The primary changes are:

- Main content column has a maximum width.
- Main content column (which includes the table of contents) is
centered, with extra space on either side of it, when the site
is viewed on a large screen.

## Timeline for all changes

| Change           |  When     | Action needed |
| ---------------- | --------- | --------- |
| Path clashes     | Now | Avoid creating new clashing paths. If possible, remove and redirect [existing clashing paths](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/snippets/4797439) for pages in your groups. |
| Kramdown         | Now | Do not add new Kramdown tags to page content. |
| Page titles<sup>1</sup>      | Now (in-progress) | Use new format in projects where this change is complete. See [this issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/82) for current status. |
| Index file names<sup>1</sup> | Now (in-progress) | Use new format in projects where this change is complete. See [this issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/82) for current status. |
| Shortcodes<sup>1</sup>       | Post-launch | None |
| Release process  | Post-launch | None |
| Chores process   | Post-launch | None |

**Footnotes:**

1. Timing for these changes on [automated pages](site_architecture/automation.md) will
differ from standard pages, as they require a more
complex set of steps to migrate. See [this issue](https://gitlab.com/gitlab-org/technical-writing-group/gitlab-docs-hugo/-/issues/168)
for details.
