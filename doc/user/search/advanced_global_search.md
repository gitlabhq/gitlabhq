---
stage: Enablement
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Advanced Search **(STARTER)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/109) in GitLab [Starter](https://about.gitlab.com/pricing/) 8.4.

NOTE: **GitLab.com availability:**
Advanced Search (powered by Elasticsearch) is enabled for Bronze and above on GitLab.com since 2020-07-10.

Leverage Elasticsearch for faster, more advanced code search across your entire
GitLab instance.

This is the user documentation. To install and configure Elasticsearch,
visit the [administrator documentation](../../integration/elasticsearch.md).

## Overview

The Advanced Search in GitLab is a powerful search service that saves
you time. Instead of creating duplicate code and wasting time, you can
now search for code within other projects that can help your own project.

GitLab leverages the search capabilities of [Elasticsearch](https://www.elastic.co/elasticsearch/) and enables it when
searching in:

- Projects
- Issues
- Merge requests
- Milestones
- Comments
- Code
- Commits
- Wiki
- Users

## Use cases

The Advanced Search can be useful in various scenarios.

### Faster searches

If you are dealing with huge amount of data and want to keep GitLab's search
fast, Advanced Search will help you achieve that.

NOTE: **Note:**
Between versions 12.10 and 13.4, Advanced Search response times have improved by 80%.

### Promote innersourcing

Your company may consist of many different developer teams each of which has
their own group where the various projects are hosted. Some of your applications
may be connected to each other, so your developers need to instantly search
throughout the GitLab instance and find the code they search for.

## Searching globally

Just use the search as before and GitLab will show you matching code from each
project you have access to.

![Advanced Search](img/advanced_global_search.png)

You can also use the [Advanced Search Syntax](advanced_search_syntax.md) which
provides some useful queries.

NOTE: **Note:**
Elasticsearch has only data for the default branch. That means that if you go
to the repository tree and switch the branch from the default to something else,
then the "Code" tab in the search result page will be served by the basic
search even if Elasticsearch is enabled.
