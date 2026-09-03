---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code navigation
description: Find where symbols are defined and called, using the knowledge graph from GitLab Orbit.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234404) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 19.0 [with a feature flag](../../administration/feature_flags/_index.md) named `orbit_code_intelligence`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Code navigation helps you understand unfamiliar code and how it connects to the rest of the
project.

Code navigation reads the knowledge graph that
[GitLab Orbit](https://docs.gitlab.com/orbit/indexed-data/) builds from your code and updates
as you push changes.
From that graph it reads the files in your project, the classes, modules, methods, and
functions they define, and which of those symbols call each other.
It doesn't need an indexer or a CI/CD job.

For a selected symbol, code navigation shows the following:

- References: The places in the project that call this symbol, also shown as a caller count.
- Calls: The symbols that this symbol calls.
- Definition: A link to the file and line where the symbol is defined.

## View code navigation for a file

Prerequisites:

- The Reporter, Developer, Maintainer, or Owner role for the project.
- [GitLab Orbit turned on](https://docs.gitlab.com/orbit/remote/getting-started/) for the
  project's top-level group.
- A file on the default branch of the project. GitLab Orbit doesn't index other branches.

To view code navigation for a file:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Repository**.
1. Select a file on the default branch.
1. In the upper-right corner of the file, select **Code navigation** ({{< icon name="code" >}}).

If you turned on GitLab Orbit for your top-level group recently,
[indexing](https://docs.gitlab.com/orbit/remote/indexing/) might still be in progress.
The panel lists symbols when indexing is complete.

To see where a symbol is used:

1. In the panel, select a symbol.
1. Select **References** to see the symbols that call it, or **Calls** to see the symbols it
   calls.
1. Select a result to open that file at the matching line.

To return to the full list of symbols, select **Back to symbols**.

## Supported languages

Code navigation covers the languages that GitLab Orbit indexes.
For the current list, see the [GitLab Orbit](https://docs.gitlab.com/orbit/) documentation.
