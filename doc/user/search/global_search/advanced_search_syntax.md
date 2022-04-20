---
stage: Enablement
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Advanced Search syntax **(PREMIUM)**

With [Advanced Search](../advanced_search.md), you can perform a thorough
search through your entire GitLab instance.

The Advanced Search syntax supports fuzzy or exact search queries with prefixes,
boolean operators, and much more. Advanced Search uses
[Elasticsearch's syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html#simple-query-string-syntax).

WARNING:
Advanced Search searches projects' default branches only.

See query examples on the tables below and their respective expected output.
The examples link to a search on GitLab.com to help you visualize the output.

## General search

| Query example | Expected output |
|---|---|
[`“display bug”`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%22display+bug%22&group_id=9970&project_id=278964) | Returns the **exact phrase** _display bug_ (stemming still applies). |
[`bug -display`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+-display&group_id=9970&project_id=278964) | Results include _bug_, and **exclude** _display_. |
[<code>bug &#124; display</code>](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+banner&group_id=9970&project_id=278964) | Results include _bug_ **or** _display_. |
[<code>bug &#124; (display +banner)</code>](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964) | Results include _bug_ **or** _display_ **and** _banner_. |
| [`bug error 50*`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+error+50*&group_id=9970&project_id=278964) | `*` finds **partial matches**. Results include _bug_, _error_, and the partial _50_ (looking for any 500 errors, for example). |
| [`bug \-display`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=argument+%5C-last&group_id=9970&project_id=278964) | `\` **scapes symbols**. Results include _bug_ **and** _-display_. |

## Code Search

| Query example | Expected output | Notes |
|---|---|---|
| [`filename:*spec.rb`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=filename%3A*spec.rb&group_id=9970&project_id=278964) | Returns the specified filename. | Use `*` for fuzzy matching. |
| [`path:spec/controllers/`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=path%3Aspec%2Fcontrollers%2F&snippets=) | Returns the specified path location of the repository. | Use `*` for fuzzy matching. |
| [`extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=extension%3Ajs&snippets=) | Returns the specified file extension. | **Do not** include a leading dot. This only works with exact matches for the extension. |
| [`blob:998707b421c89b*`](https://gitlab.com/search?snippets=false&scope=blobs&repository_ref=&search=blob%3A998707b421c89b*&group_id=9970) | Returns the specified Git object ID. | This only works with exact matches. |

## Excluding filters

Filters can also be inverted to filter out results from the result set by prefixing the filter name with a `-` (hyphen) character.

| Query example | Expected output |
|---|---|
| [`rails -filename:gemfile.lock`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=rails+-filename%3Agemfile.lock&snippets=) | Results include _`rails`_ in all files except the _`gemfile.lock`_ file. |
