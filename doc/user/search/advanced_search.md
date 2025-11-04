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

Use advanced search to find exactly what you need across your entire GitLab instance.

With advanced search:

- Identify code patterns across all projects to refactor shared components more efficiently.
- Locate security vulnerabilities across your entire organization's codebase and dependencies.
- Track usage of deprecated functions or libraries throughout all repositories.
- Find discussions buried in issues, merge requests, or comments.
- Discover existing solutions instead of reinventing functionality that already exists.

Advanced search works in projects, issues, merge requests, milestones,
users, epics, code, comments, commits, and wikis.

## Use advanced search

Prerequisites:

- Advanced search must be enabled:
  - For GitLab.com and GitLab Dedicated, advanced search is
    enabled by default in paid subscriptions.
  - For GitLab Self-Managed, an administrator must
    [enable advanced search](../../integration/advanced_search/elasticsearch.md#enable-advanced-search).

To use advanced search:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the search box, enter your search term.

You can also use advanced search in a project or group.

## Available scopes

Scopes describe the type of data you're searching.
The following scopes are available for advanced search:

| Scope          | Global <sup>1</sup> <sup>2</sup>            | Group                                       | Project |
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
1. On GitLab.com, global search is not enabled for code, commits, and wikis.

## Syntax

<!-- Remember to also update the tables in `doc/drawers/advanced_search_syntax.md` -->

Advanced search uses [`simple_query_string`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html),
which supports both exact and fuzzy queries.

When you search for a user, the [`fuzzy`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html) query is used by default.
You can refine user search with `simple_query_string`.

| Syntax | Description      | Example |
|--------|------------------|---------|
| `"`    | Exact search     | `"gem sidekiq"` |
| `~`    | Fuzzy search     | `J~ Doe` |
| `\|`   | Or               | `display \| banner` |
| `+`    | And              | `display +banner` |
| `-`    | Exclude          | `display -banner` |
| `*`    | Partial          | `bug error 50*` |
| ` \ `  | Escape           | `\*md`  |
| `#`    | Issue ID         | `#23456` |
| `!`    | Merge request ID | `!23456` |

### Code search

| Syntax       | Description                                     | Example |
|--------------|-------------------------------------------------|---------|
| `filename:`  | Filename                                        | `filename:*spec.rb` |
| `path:`      | Repository location (full or partial matches)   | `path:spec/workers/` |
| `extension:` | File extension without `.` (exact matches only) | `extension:js` |
| `blob:`      | Git object ID (exact matches only)              | `blob:998707*` |

### Examples

<!-- markdownlint-disable MD044 -->

| Query                                 | Description |
|---------------------------------------|-------------|
| `rails -filename:gemfile.lock`        | Returns `rails` in all files except the `gemfile.lock` file. |
| `RSpec.describe Resolvers -*builder`  | Returns `RSpec.describe Resolvers` that does not start with `builder`. |
| `bug \| (display +banner)`            | Returns `bug` or both `display` and `banner`. |
| `helper -extension:yml -extension:js` | Returns `helper` in all files except files with a `.yml` or `.js` extension. |
| `helper path:lib/git`                 | Returns `helper` in all files with a `lib/git*` path (for example, `spec/lib/gitlab`). |

<!-- markdownlint-enable MD044 -->

## Known issues

- You can search only files smaller than 1 MB.
  For GitLab Self-Managed, an administrator can set a limit on the
  [maximum file size indexed](../../administration/instance_limits.md#maximum-file-size-indexed).
- You can use advanced search only on the default branch of a project.
  For more information, see [issue 229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966).
- The search query must not contain any of the following characters:

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

- Search results show only the first match in a file.
