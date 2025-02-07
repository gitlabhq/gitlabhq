---
stage: Foundations
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Advanced search
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

You can use advanced search for faster, more efficient search across the entire GitLab
instance. Advanced search is based on Elasticsearch, a purpose-built full-text search
engine you can horizontally scale to get results in up to a second in most cases.

You can find code you want to update in all projects at once to save
maintenance time and promote innersourcing.

You can use advanced search in:

- Projects
- Issues
- Merge requests
- Milestones
- Users
- Epics
- Code
- Comments
- Commits
- Project and group wikis

## Enable advanced search

- For [GitLab.com](../../subscriptions/gitlab_com/_index.md) and [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md),
  advanced search is enabled in paid subscriptions.
- For [GitLab Self-Managed](../../subscriptions/self_managed/_index.md), an administrator must
  [enable advanced search](../../integration/advanced_search/elasticsearch.md#enable-advanced-search).

## Syntax

<!-- Remember to also update the tables in `doc/drawers/advanced_search_syntax.md` -->

> - Refining user search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388409) in GitLab 15.10.

Advanced search uses [`simple_query_string`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html),
which supports both exact and fuzzy queries.

When you search for a user, the [`fuzzy`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-fuzzy-query.html) query is used by default.
You can refine user search with `simple_query_string`.

| Syntax              | Description      | Example |
|---------------------|------------------|---------|
| `"`                 | Exact search     | [`"gem sidekiq"`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=%22gem+sidekiq%22) |
| `~`                 | Fuzzy search     | [`J~ Doe`](https://gitlab.com/search?scope=users&search=j%7E+doe) |
| <code>&#124;</code> | Or               | [<code>display &#124; banner</code>](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+%7C+banner) |
| `+`                 | And              | [`display +banner`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=display+%2Bbanner&snippets=) |
| `-`                 | Exclude          | [`display -banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+-banner) |
| `*`                 | Partial          | [`bug error 50*`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=bug+error+50%2A&snippets=) |
| <code>&#92;</code>  | Escape           | [`\*md`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=%5C*md&group_id=9970&project_id=278964) |
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
| [<code>bug &#124; (display +banner)</code>](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964) | Returns `bug` or both `display` and `banner`. |
| [<code>helper -extension:yml -extension:js</code>](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=helper+-extension%3Ayml+-extension%3Ajs&snippets=) | Returns `helper` in all files except files with a `.yml` or `.js` extension. |
| [<code>helper path:lib/git</code>](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=helper+path%3Alib%2Fgit) | Returns `helper` in all files with a `lib/git*` path (for example, `spec/lib/gitlab`). |

<!-- markdownlint-enable MD044 -->

## Known issues

- You can only search files smaller than 1 MB.
  For more information, see [issue 195764](https://gitlab.com/gitlab-org/gitlab/-/issues/195764).
  For GitLab Self-Managed, an administrator can
  [configure the **Maximum file size indexed** setting](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration).
- You can use advanced search on the default branch of a project only.
  For more information, see [issue 229966](https://gitlab.com/gitlab-org/gitlab/-/issues/229966).
- The search query must not contain any of the following characters:

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | < > ( ) { } [ ] @
  ```

  For more information, see [issue 325234](https://gitlab.com/gitlab-org/gitlab/-/issues/325234).
- Search results show only the first match in a file.
  For more information, see [issue 668](https://gitlab.com/gitlab-org/gitlab/-/issues/668).
