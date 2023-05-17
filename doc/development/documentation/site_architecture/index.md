---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Documentation site architecture

The [`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) project hosts
the repository which is used to generate the GitLab documentation website and
is deployed to <https://docs.gitlab.com>. It uses the [Nanoc](https://nanoc.app/)
static site generator.

View the [`gitlab-docs` architecture page](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/architecture.md)
for more information.

## Documentation in other repositories

If you have code and documentation in a repository other than the [primary repositories](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/architecture.md),
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
  We do not encourage the use of [pages with lists of links](../topic_types/index.md#pages-and-topics-to-avoid),
  so only use this option if the recommended options are not feasible.

## Monthly release process (versions)

The docs website supports versions and each month we add the latest one to the list.
For more information, read about the [monthly release process](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/releases.md).

## Review Apps for documentation merge requests

If you are contributing to GitLab docs read how to
[create a Review App with each merge request](../index.md#previewing-the-changes-live).
