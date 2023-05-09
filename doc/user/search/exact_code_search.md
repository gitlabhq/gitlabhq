---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Exact Code Search **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) named `index_code_with_zoekt` for indexing and `search_code_with_zoekt` for searching. Both are disabled by default.

WARNING:
We are still actively making changes to the Exact Code Search feature. GitLab will dogfood it first, and roll it out only to specific customers on GitLab.com who request access to it. We will make an announcement when it's available for GitLab.com customers to tryout. You can follow our development progress by checking [the Exact Code Search feature roadmap](https://gitlab.com/groups/gitlab-org/-/epics/9404).
On self-managed GitLab, it is technically possible to enable this feature, however, GitLab does not provide support or documentation at this stage of development and it has not been widely tested at scale. There are also many known limitations.

## Usage

When performing any Code search in GitLab it will choose to use "Exact Code
Search" powered by [Zoekt](https://github.com/sourcegraph/zoekt) if the project
is part of an enabled Group.

The main differences between Zoekt and [advanced search](advanced_search.md)
are that Zoekt provides exact substring matching as well as allows you to
search for regular expressions. Since it allows searching for regular
expressions, certain special characters will require escaping. Backslash can
escape special characters and wrapping in double quotes can be used for phrase
searches.

## Syntax

To understand the possible filtering options, see the
[Zoekt query syntax](https://github.com/sourcegraph/zoekt/blob/main/doc/query_syntax.md).
