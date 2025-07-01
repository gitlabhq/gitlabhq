---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Documentation site architecture
---

The [`docs-gitlab-com`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com) project hosts
the repository used to generate the GitLab documentation website and
is deployed to <https://docs.gitlab.com>. It uses the [Hugo](https://gohugo.io/)
static site generator.

For more information, see the [Docs site architecture](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/architecture.md)
page.

## Source files

The documentation source files are in the same repositories as the product code.

| Project | Path |
| --- | --- |
| [GitLab](https://gitlab.com/gitlab-org/gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/) | [`/docs`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs) |
| [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc) |
| [Charts](https://gitlab.com/gitlab-org/charts/gitlab) | [`/doc`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/doc) |
| [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator) | [`/doc`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/tree/master/doc) |

Documentation issues and merge requests are part of their respective repositories and all have the label `Documentation`.

## Publication

Documentation for GitLab, GitLab Runner, GitLab Operator, Omnibus GitLab, and Charts is published to <https://docs.gitlab.com>.

The same documentation is included in the application. To view the in-product help,
go to the URL and add `/help` at the end.
Only help for your current edition and version is included.

Help for other versions is available at <https://docs.gitlab.com/archives/>.

## Updating older versions

If you need to add or edit documentation for a GitLab version that has already been
released, follow the [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md).

## Documentation in other repositories

If you have code and documentation in a repository other than the [primary repositories](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/architecture.md),
you should keep the documentation with the code in that repository.

Then you can use one of these approaches:

- Recommended. [Add the repository to the list of products](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/development.md#add-a-new-product)
  published at <https://docs.gitlab.com>. The source of the documentation pages remains
  in the external repository, but the resulting pages are indexed and searchable on <https://docs.gitlab.com>.
- Recommended. [Add an entry in the global navigation](global_nav.md#add-a-navigation-entry) for
  <https://docs.gitlab.com> that links directly to the documentation in that external repository.
  The documentation pages are not indexed or searchable on <https://docs.gitlab.com>.
- Create a landing page for the product in the `gitlab` repository, and add the landing page
  [to the global navigation](global_nav.md#add-a-navigation-entry), but keep the rest
  of the documentation in the external repository. The landing page is indexed and
  searchable on <https://docs.gitlab.com>, but the rest of the documentation is not.
  For example, the [GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/_index.md).
  We do not encourage the use of [pages with lists of links](../topic_types/_index.md#pages-and-topics-to-avoid),
  so only use this option if the recommended options are not feasible.

## Documentation in other languages

Translations of GitLab documentation are done through a semi-autonomous process.
The [English files](#source-files) are the canonical source files, and the translations
are in language-specific subdirectories under `doc-locale` or similar. For example, Japanese translations
are in `/doc-locale/ja-jp/`.

| Project         | Path |
|-----------------|------|
| GitLab          | [`/doc-locale`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc-locale) |
| GitLab Runner   | [`/docs-locale`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs-locale) |
| Omnibus GitLab  | [`/doc-locale`](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc-locale) |
| Charts          | [`/doc-locale`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/doc-locale) |
| GitLab Operator | [`/doc-locale`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/tree/master/doc-locale) |

Development documentation under `doc/development` or similar is not translated.

You can contribute to the English source files only. The translated files are updated by automation.

## Monthly release process (versions)

The docs website supports versions and each month we add the latest one to the list.
For more information, read about the [monthly release process](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/releases.md).

## Danger Bot

GitLab uses [Danger](https://github.com/danger/danger) to automate code review processes.
When documentation files in `/doc` are modified in a merge request,
Danger Bot automatically comments with documentation-related guidelines.
This automation is configured in the [`Dangerfile`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/danger/documentation/Dangerfile).

## Request a documentation survey banner

To reach to a wider audience, you can request
[a survey banner](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/maintenance.md#survey-banner).

Only one banner can exist at any given time. Priority is given based on who
asked for the banner first.

To request a survey banner:

1. [Open an issue](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/issues/new?issue[title]=Survey%20banner%20request&issuable_template=Survey%20banner%20request)
   in the `docs-gitlab-com` project and use the "Survey banner request" template.
1. Fill in the details in the issue description.
1. Create the issue and someone from the Technical Writing team will handle your request.
1. When you no longer need the banner, ping the person assigned to the issue and ask them to remove it.
