---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Advanced search
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Moved to GitLab Premium in 13.9.

{{< /history >}}

Use advanced search to find exactly what you need across your entire GitLab instance.

With advanced search:

- Identify code patterns across all projects to refactor shared components more efficiently.
- Locate security vulnerabilities across your entire organization's codebase and dependencies using [advanced vulnerability management](../application_security/vulnerability_report/_index.md#advanced-vulnerability-management).
- Track usage of deprecated functions or libraries throughout all repositories.
- Find discussions buried in issues, merge requests, or comments.
- Discover existing solutions instead of reinventing functionality that already exists.

Advanced search works in projects, issues, merge requests, milestones,
users, epics, code, comments, commits, and wikis.

## Enable advanced search

- For [GitLab.com](../../subscriptions/gitlab_com/_index.md) and [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md),
  advanced search is enabled in paid subscriptions.
- For [GitLab Self-Managed](../../subscriptions/self_managed/_index.md), an administrator must
  [enable advanced search](../../integration/advanced_search/elasticsearch.md#enable-advanced-search).

## Available scopes

Scopes describe the type of data you're searching.
The following scopes are available for advanced search:

| Scope          | Global <sup>1</sup>                         | Group                                       | Project |
|----------------|:-------------------------------------------:|:-------------------------------------------:|:-------:|
| Code           | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Comments       | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Commits        | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Epics          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| Issues         | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Merge requests | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Milestones     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Projects       | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| Users          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Wikis          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |

**Footnotes**:

1. An administrator can [disable global search scopes](_index.md#disable-global-search-scopes).
   On GitLab Self-Managed, global search is not available when limited indexing is enabled by default.
   An administrator can [enable global search for limited indexing](../../integration/advanced_search/elasticsearch.md#indexed-namespaces).

## Syntax

<!-- Remember to also update the tables in `doc/drawers/advanced_search_syntax.md` -->

{{< history >}}

- Refining user search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388409) in GitLab 15.10.

{{< /history >}}

Advanced search uses [`simple_query_string`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html),
which supports both exact and fuzzy queries.

When you search for a user, the [`fuzzy`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html) query is used by default.
You can refine user search with `simple_query_string`.

| Syntax              | Description      | Example |
|---------------------|------------------|---------|
| `"`                 | Exact search     | [`"gem sidekiq"`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=%22gem+sidekiq%22) |
| `~`                 | Fuzzy search     | [`J~ Doe`](https://gitlab.com/search?scope=users&search=j%7E+doe) |
| `\|`                | Or               | [`display \| banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+%7C+banner) |
| `+`                 | And              | [`display +banner`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=display+%2Bbanner&snippets=) |
| `-`                 | Exclude          | [`display -banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+-banner) |
| `*`                 | Partial          | [`bug error 50*`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=bug+error+50%2A&snippets=) |
| ` \ `               | Escape           | [`\*md`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=%5C*md&group_id=9970&project_id=278964) |
| `#`                 | Issue ID         | [`#23456`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%2323456&group_id=9970&project_id=278964) |
| `!`                 | Merge request ID | [`!23456`](https://gitlab.com/search?snippets=&scope=merge_requests&repository_ref=&search=%2123456&group_id=9970&project_id=278964) |

### Code search

| Syntax       | Description                                     | Example |
|--------------|-------------------------------------------------|---------|
| `filename:`  | Filename                                        | [`filename:*spec.rb`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=filename%3A*spec.rb&group_id=9970&project_id=278964) |
| `path:`      | Repository location (full or partial matches)   | [`path:spec/workers/`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=path%3Aspec%2Fworkers&snippets=) |
| `extension:` | File extension without `.` (exact matches only) | [`extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=extension%3Ajs&snippets=) |
| `blob:`      | Git object ID (exact matches only)              | [`blob:998707*`](https://gitlab.com/search?snippets=false&scope=blobs&repository_ref=&search=blob%3A998707*&group_id=9970) |

### Examples

<!-- markdownlint-disable MD044 -->

| Query                                              | Description |
|----------------------------------------------------|-------------|
| [`rails -filename:gemfile.lock`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=rails+-filename%3Agemfile.lock&snippets=) | Returns `rails` in all files except the `gemfile.lock` file. |
| [`RSpec.describe Resolvers -*builder`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=RSpec.describe+Resolvers+-*builder) | Returns `RSpec.describe Resolvers` that does not start with `builder`. |
| [`bug \| (display +banner)`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964) | Returns `bug` or both `display` and `banner`. |
| [`helper -extension:yml -extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=helper+-extension%3Ayml+-extension%3Ajs&snippets=) | Returns `helper` in all files except files with a `.yml` or `.js` extension. |
| [`helper path:lib/git`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=helper+path%3Alib%2Fgit) | Returns `helper` in all files with a `lib/git*` path (for example, `spec/lib/gitlab`). |

<!-- markdownlint-enable MD044 -->

## Known issues

- You can search only files smaller than 1 MB.
  For more information, see [issue 195764](https://gitlab.com/gitlab-org/gitlab/-/issues/195764).
  For GitLab Self-Managed, an administrator can
  [configure the **Maximum file size indexed** setting](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration).
- You can use advanced search only on the default branch of a project.
  For more information, see [issue 229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966).
- The search query must not contain any of the following characters:

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

  For more information, see [issue 325234](https://gitlab.com/gitlab-org/gitlab/-/issues/325234).
- Search results show only the first match in a file.
  For more information, see [issue 668](https://gitlab.com/gitlab-org/gitlab/-/issues/668).
