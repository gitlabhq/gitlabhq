---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Advanced Search syntax **(PREMIUM)**

With [Advanced Search](../advanced_search.md), you can perform a thorough
search of your entire GitLab instance.

The Advanced Search syntax supports fuzzy or exact search queries with prefixes,
boolean operators, and more. Advanced Search uses
[Elasticsearch's syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html#simple-query-string-syntax).

WARNING:
Advanced Search searches default project branches only.

## General search

<!-- markdownlint-disable -->

| Use | Description  | Example                                                                                                                                        |
|-----|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `"` | Exact search | [`"gem sidekiq"`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=%22gem+sidekiq%22)                   |
| <code>&#124;</code> | Or | [<code>display &#124; banner</code>](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+%7C+banner)          |
| `+` | And          | [`display +banner`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=display+%2Bbanner&snippets=) |
| `-` | Exclude      | [`display -banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+-banner)                              |
| `*` | Partial      | [`bug error 50*`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=bug+error+50%2A&snippets=)       |
| `\` | Escape       | [`\*md`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=%5C*md&group_id=9970&project_id=278964)         |

## Code search

| Use          | Description                     | Example                                                                                                                                              |
|--------------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `filename:`  | Filename                        | [`filename:*spec.rb`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=filename%3A*spec.rb&group_id=9970&project_id=278964)    |
| `path:`      | Repository location             | [`path:spec/workers/`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=path%3Aspec%2Fworkers&snippets=) |
| `extension:` | File extension, without the `.` | [`extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=extension%3Ajs&snippets=)              |
| `blob:`      | Git object ID                   | [`blob:998707*`](https://gitlab.com/search?snippets=false&scope=blobs&repository_ref=&search=blob%3A998707*&group_id=9970)                           |

`extension` and `blob` return exact matches only.

## Examples

| Example                                                                                                                                                                              | Description                                                          |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| [`rails -filename:gemfile.lock`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=rails+-filename%3Agemfile.lock&snippets=)              | Show _rails_ in all files except the _`gemfile.lock`_ file.          |
| [`RSpec.describe Resolvers -*builder`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=RSpec.describe+Resolvers+-*builder)                              | Show all _RSpec.describe Resolvers_ that don't start with _builder_. |
| [<code>bug &#124; (display +banner)</code>](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964)  | Show _bug_ **or** _display_ **and** _banner_.                        |

<!-- markdownlint-enable -->
