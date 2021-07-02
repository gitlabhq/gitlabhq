---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Documentation site architecture

The [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) project hosts
the repository which is used to generate the GitLab documentation website and
is deployed to <https://docs.gitlab.com>. It uses the [Nanoc](https://nanoc.app/)
static site generator.

## Architecture

While the source of the documentation content is stored in the repositories for
each GitLab product, the source that is used to build the documentation
site _from that content_ is located at <https://gitlab.com/gitlab-org/gitlab-docs>.

The following diagram illustrates the relationship between the repositories
from where content is sourced, the `gitlab-docs` project, and the published output.

```mermaid
  graph LR
    A[gitlab/doc]
    B[gitlab-runner/docs]
    C[omnibus-gitlab/doc]
    D[charts/doc]
    E[gitlab-docs]
    A --> E
    B --> E
    C --> E
    D --> E
    E -- Build pipeline --> F
    F[docs.gitlab.com]
    G[/ce/]
    H[/ee/]
    I[/runner/]
    J[/omnibus/]
    K[/charts/]
    F --> H
    F --> I
    F --> J
    F --> K
    H -- symlink --> G
```

GitLab docs content isn't kept in the `gitlab-docs` repository.
All documentation files are hosted in the respective repository of each
product, and all together are pulled to generate the docs website:

- [GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs)
- [GitLab Chart](https://gitlab.com/charts/gitlab/tree/master/doc)

NOTE:
In September 2019, we [moved towards a single codebase](https://gitlab.com/gitlab-org/gitlab/-/issues/2952),
as such the docs for CE and EE are now identical. For historical reasons and
in order not to break any existing links throughout the internet, we still
maintain the CE docs (`https://docs.gitlab.com/ce/`), although it is hidden
from the website, and is now a symlink to the EE docs. When
[Pages supports redirects](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/24),
we can remove this completely.

## Assets

To provide an optimized site structure, design, and a search-engine friendly
website, along with a discoverable documentation, we use a few assets for
the GitLab Documentation website.

### Libraries

- [Bootstrap 4.3.1 components](https://getbootstrap.com/docs/4.3/components/)
- [Bootstrap 4.3.1 JS](https://getbootstrap.com/docs/4.3/getting-started/javascript/)
- [jQuery](https://jquery.com/) 3.3.1
- [Clipboard JS](https://clipboardjs.com/)
- [Font Awesome 4.7.0](https://fontawesome.com/v4.7.0/icons/)

### SEO

- [Schema.org](https://schema.org/)
- [Google Analytics](https://marketingplatform.google.com/about/analytics/)
- [Google Tag Manager](https://developers.google.com/tag-manager/)

## Global navigation

Read through [the global navigation documentation](global_nav.md) to understand:

- How the global navigation is built.
- How to add new navigation items.

<!--
## Helpers

TBA
-->

## Pipelines

The pipeline in the `gitlab-docs` project:

- Tests changes to the docs site code.
- Builds the Docker images used in various pipeline jobs.
- Builds and deploys the docs site itself.
- Generates the review apps when the `review-docs-deploy` job is triggered.

### Rebuild the docs site Docker images

Once a week on Mondays, a scheduled pipeline runs and rebuilds the Docker images
used in various pipeline jobs, like `docs-lint`. The Docker image configuration files are
located in the [Dockerfiles directory](https://gitlab.com/gitlab-org/gitlab-docs/-/tree/master/dockerfiles).

If you need to rebuild the Docker images immediately (must have maintainer level permissions):

WARNING:
If you change the Dockerfile configuration and rebuild the images, you can break the main
pipeline in the main `gitlab` repository as well as in `gitlab-docs`. Create an image with
a different name first and test it to ensure you do not break the pipelines.

1. In [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs), go to **{rocket}** **CI/CD > Pipelines**.
1. Click the **Run pipeline** button.
1. See that a new pipeline is running. The jobs that build the images are in the first
   stage, `build-images`. You can click the pipeline number to see the larger pipeline
   graph, or click the first (`build-images`) stage in the mini pipeline graph to
   expose the jobs that build the images.
1. Click the **play** (**{play}**) button next to the images you want to rebuild.
   - Normally, you do not need to rebuild the `image:gitlab-docs-base` image, as it
     rarely changes. If it does need to be rebuilt, be sure to only run `image:docs-lint`
     after it is finished rebuilding.

### Deploy the docs site

Every four hours a scheduled pipeline builds and deploys the docs site. The pipeline
fetches the current docs from the main project's main branch, builds it with Nanoc
and deploys it to <https://docs.gitlab.com>.

If you need to build and deploy the site immediately (must have maintainer level permissions):

1. In [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs), go to **{rocket}** **CI/CD > Schedules**.
1. For the `Build docs.gitlab.com every 4 hours` scheduled pipeline, click the **play** (**{play}**) button.

Read more about the [deployment process](deployment_process.md).

## Using YAML data files

The easiest way to achieve something similar to
[Jekyll's data files](https://jekyllrb.com/docs/datafiles/) in Nanoc is by
using the [`@items`](https://nanoc.app/doc/reference/variables/#items-and-layouts)
variable.

The data file must be placed inside the `content/` directory and then it can
be referenced in an ERB template.

Suppose we have the `content/_data/versions.yaml` file with the content:

```yaml
versions:
  - 10.6
  - 10.5
  - 10.4
```

We can then loop over the `versions` array with something like:

```erb
<% @items['/_data/versions.yaml'][:versions].each do | version | %>

<h3><%= version %></h3>

<% end &>
```

Note that the data file must have the `yaml` extension (not `yml`) and that
we reference the array with a symbol (`:versions`).

## Bumping versions of CSS and JavaScript

Whenever the custom CSS and JavaScript files under `content/assets/` change,
make sure to bump their version in the front matter. This method guarantees that
your changes take effect by clearing the cache of previous files.

Always use Nanoc's way of including those files, do not hardcode them in the
layouts. For example use:

```erb
<script async type="application/javascript" src="<%= @items['/assets/javascripts/badges.*'].path %>"></script>

<link rel="stylesheet" href="<%= @items['/assets/stylesheets/toc.*'].path %>">
```

The links pointing to the files should be similar to:

```erb
<%= @items['/path/to/assets/file.*'].path %>
```

Nanoc then builds and renders those links correctly according with what's
defined in [`Rules`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/Rules).

## Linking to source files

A helper called [`edit_on_gitlab`](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/lib/helpers/edit_on_gitlab.rb) can be used
to link to a page's source file. We can link to both the simple editor and the
web IDE. Here's how you can use it in a Nanoc layout:

- Default editor: `<a href="<%= edit_on_gitlab(@item, editor: :simple) %>">Simple editor</a>`
- Web IDE: `<a href="<%= edit_on_gitlab(@item, editor: :webide) %>">Web IDE</a>`

If you don't specify `editor:`, the simple one is used by default.

## Algolia search engine

The docs site uses [Algolia DocSearch](https://community.algolia.com/docsearch/)
for its search function. This is how it works:

1. GitLab is a member of the [DocSearch program](https://community.algolia.com/docsearch/#join-docsearch-program),
   which is the free tier of [Algolia](https://www.algolia.com/).
1. Algolia hosts a [DocSearch configuration](https://github.com/algolia/docsearch-configs/blob/master/configs/gitlab.json)
   for the GitLab docs site, and we've worked together to refine it.
1. That [configuration](https://community.algolia.com/docsearch/config-file.html) is
   parsed by their [crawler](https://community.algolia.com/docsearch/crawler-overview.html)
   every 24h and [stores](https://community.algolia.com/docsearch/inside-the-engine.html)
   the [DocSearch index](https://community.algolia.com/docsearch/how-do-we-build-an-index.html)
   on [Algolia's servers](https://community.algolia.com/docsearch/faq.html#where-is-my-data-hosted%3F).
1. On the docs side, we use a [DocSearch layout](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/layouts/docsearch.html) which
   is present on pretty much every page except <https://docs.gitlab.com/search/>,
   which uses its [own layout](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/layouts/instantsearch.html). In those layouts,
   there's a JavaScript snippet which initiates DocSearch by using an API key
   and an index name (`gitlab`) that are needed for Algolia to show the results.

### Algolia notes for GitLab team members

If you're a GitLab team member, find credentials for the Algolia dashboard
in the shared [GitLab 1Password account](https://about.gitlab.com/handbook/security/#1password-for-teams).
To receive weekly reports of the search usage, search the Google doc with
title `Email, Slack, and GitLab Groups and Aliases`, search for `docsearch`,
and add a comment with your email to be added to the alias that gets the weekly
reports.

## Monthly release process (versions)

The docs website supports versions and each month we add the latest one to the list.
For more information, read about the [monthly release process](release_process.md).

## Review Apps for documentation merge requests

If you are contributing to GitLab docs read how to [create a Review App with each
merge request](../index.md#previewing-the-changes-live).
