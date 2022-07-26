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
    A[gitlab-org/gitlab/doc]
    B[gitlab-org/gitlab-runner/docs]
    C[gitlab-org/omnibus-gitlab/doc]
    D[gitlab-org/charts/gitlab/doc]
    E[gitlab-org/cloud-native/gitlab-operator/doc]
    Y[gitlab-org/gitlab-docs]
    A --> Y
    B --> Y
    C --> Y
    D --> Y
    E --> Y
    Y -- Build pipeline --> Z
    Z[docs.gitlab.com]
    M[//ee/]
    N[//runner/]
    O[//omnibus/]
    P[//charts/]
    Q[//operator/]
    Z --> M
    Z --> N
    Z --> O
    Z --> P
    Z --> Q
```

GitLab docs content isn't kept in the `gitlab-docs` repository.
All documentation files are hosted in the respective repository of each
product, and all together are pulled to generate the docs website:

- [GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc)
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/doc)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs)
- [GitLab Chart](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/doc)
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/tree/master/doc)

Learn more about [the docs folder structure](folder_structure.md).

### Documentation in other repositories

If you have code and documentation in a repository other than the [primary repositories](#architecture),
you should keep the documentation with the code in that repository.

Then you can use one of these approaches:

- Recommended. [Add the repository to the list of products](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/development.md#add-a-new-product)
  published at <https://docs.gitlab.com>. The source of the documentation pages remains
  in the external repository, but the resulting pages are indexed and searchable on <https://docs.gitlab.com>.
- Recommended. [Add an entry in the global navigation](global_nav.md#add-a-navigation-entry) for
  <https://docs.gitlab.com> that links directly to the documentation in that external repository.
  The documentation pages are not indexed or searchable on <https://docs.gitlab.com>.
  View [an example](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/fedb6378a3c92274ba3b6031df0d34455594e4cc/content/_data/navigation.yaml#L2944-L2946).
- Create a landing page for the product in the `gitlab` repository, and add the landing page
  [to the global navigation](global_nav.md#add-a-navigation-entry), but keep the rest
  of the documentation in the external repository. The landing page is indexed and
  searchable on <https://docs.gitlab.com>, but the rest of the documentation is not.
  For example, the [GitLab Workflow extension for VS Code](../../../user/project/repository/vscode.md).
  We do not encourage the use of [pages with lists of links](../structure.md#topics-and-resources-pages),
  so only use this option if the recommended options are not feasible.

## Assets

To provide an optimized site structure, design, and a search-engine friendly
website, along with a discoverable documentation, we use a few assets for
the GitLab Documentation website.

### External libraries

GitLab Docs is built with a combination of external:

- [JavaScript libraries](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/package.json).
- [Ruby libraries](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/Gemfile).

### SEO

- [Schema.org](https://schema.org/)
- [Google Analytics](https://marketingplatform.google.com/about/analytics/)
- [Google Tag Manager](https://developers.google.com/tag-platform/tag-manager)

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
located in the [Dockerfiles directory](https://gitlab.com/gitlab-org/gitlab-docs/-/tree/main/dockerfiles).

If you need to rebuild the Docker images immediately (must have maintainer level permissions):

WARNING:
If you change the Dockerfile configuration and rebuild the images, you can break the main
pipeline in the main `gitlab` repository as well as in `gitlab-docs`. Create an image with
a different name first and test it to ensure you do not break the pipelines.

1. In [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs), go to **{rocket}** **CI/CD > Pipelines**.
1. Select **Run pipeline**.
1. See that a new pipeline is running. The jobs that build the images are in the first
   stage, `build-images`. You can select the pipeline number to see the larger pipeline
   graph, or select the first (`build-images`) stage in the mini pipeline graph to
   expose the jobs that build the images.
1. Select the **play** (**{play}**) button next to the images you want to rebuild.
   - Normally, you do not need to rebuild the `image:gitlab-docs-base` image, as it
     rarely changes. If it does need to be rebuilt, be sure to only run `image:docs-lint`
     after it is finished rebuilding.

### Deploy the docs site

Every four hours a scheduled pipeline builds and deploys the docs site. The pipeline
fetches the current docs from the main project's main branch, builds it with Nanoc
and deploys it to <https://docs.gitlab.com>.

To build and deploy the site immediately (must have the Maintainer role):

1. In [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs), go to **{rocket}** **CI/CD > Schedules**.
1. For the `Build docs.gitlab.com every 4 hours` scheduled pipeline, select the **play** (**{play}**) button.

Read more about [documentation deployments](deployment_process.md).

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

## Archived documentation banner

A banner is displayed on archived documentation pages with the text `This is archived documentation for
GitLab. Go to the latest.` when either:

- The version of the documentation displayed is not the first version entry in `online` in
  `content/_data/versions.yaml`.
- The documentation was built from the default branch (`main`).

For example, if the `online` entries for `content/_data/versions.yaml` are:

```yaml
online:
  - "14.4"
  - "14.3"
  - "14.2"
```

In this case, the archived documentation banner isn't displayed:

- For 14.4, the docs built from the `14.4` branch. The branch name is the first entry in `online`.
- For 14.5-pre, the docs built from the default project branch (`main`).

The archived documentation banner is displayed:

- For 14.3.
- For 14.2.
- For any other version.

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
for its search function.

Learn more in <https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/docsearch.md>.

## Monthly release process (versions)

The docs website supports versions and each month we add the latest one to the list.
For more information, read about the [monthly release process](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md).

## Review Apps for documentation merge requests

If you are contributing to GitLab docs read how to [create a Review App with each
merge request](../index.md#previewing-the-changes-live).
