---
stage: Enablement
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Advanced Search Syntax **(STARTER)**

> - Introduced in [GitLab Enterprise Starter](https://about.gitlab.com/pricing/) 9.2

NOTE: **GitLab.com availability:**
Advanced Search (powered by Elasticsearch) is enabled for Bronze and above on GitLab.com since 2020-07-10.

Use advanced queries for more targeted search results.

This is the user documentation. To install and configure Elasticsearch,
visit the [administrator documentation](../../integration/elasticsearch.md).

## Overview

The Advanced Search Syntax is a subset of the
[Advanced Search](advanced_global_search.md), which you can use if you
want to have more specific search results.

Advanced Search only supports searching the [default branch](../project/repository/branches/index.md#default-branch).

## Use cases

Let's say for example that the product you develop relies on the code of another
product that's hosted under some other group.

Since under your GitLab instance there are hosted hundreds of different projects,
you need the search results to be as efficient as possible. You have a feeling
of what you want to find (e.g., a function name), but at the same you're also
not so sure.

In that case, using the advanced search syntax in your query will yield much
better results.

## Using the Advanced Search Syntax

The Advanced Search Syntax supports fuzzy or exact search queries with prefixes,
boolean operators, and much more.

Full details can be found in the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/5.3/query-dsl-simple-query-string-query.html#_simple_query_string_syntax), but
here's a quick guide:

- Searches look for all the words in a query, in any order - e.g.: searching
  issues for [`display bug`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=display+bug&group_id=9970&project_id=278964) and [`bug display`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=bug+Display&group_id=9970&project_id=278964) will return the same results.
- To find the exact phrase (stemming still applies), use double quotes: [`"display bug"`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=%22display+bug%22&group_id=9970&project_id=278964)
- To find bugs not mentioning display, use `-`: [`bug -display`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=bug+-display&group_id=9970&project_id=278964)
- To find a bug in display or banner, use `|`: [`bug display | banner`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=bug+display+%7C+banner&group_id=9970&project_id=278964)
- To group terms together, use parentheses: [`bug | (display +banner)`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964)
- To match a partial word, use `*`. In this example, I want to find bugs with any 500 errors. : [`bug error 50*`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=issues&repository_ref=&search=bug+error+50*&group_id=9970&project_id=278964)
- To use one of symbols above literally, escape the symbol with a preceding `\`: [`argument \-last`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=argument+%5C-last&group_id=9970&project_id=278964)

### Syntax search filters

The Advanced Search Syntax also supports the use of filters. The available filters are:

- filename: Filters by filename. You can use the glob (`*`) operator for fuzzy matching.
- path: Filters by path. You can use the glob (`*`) operator for fuzzy matching.
- extension: Filters by extension in the filename. Please write the extension without a leading dot. Exact match only.
- blob: Filters by Git `object ID`. Exact match only.

To use them, add them to your keyword in the format `<filter_name>:<value>` without
any spaces between the colon (`:`) and the value. A keyword or an asterisk (`*`) is required for filter searches and has to be added in front of the filter separated by a space.

Examples:

- Finding a file with any content named `search_results.rb`: [`* filename:search_results.rb`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=*+filename%3Asearch_results.rb&group_id=9970&project_id=278964)
- Finding a file named `found_blob_spec.rb` with the text `CHANGELOG` inside of it: [`CHANGELOG filename:found_blob_spec.rb](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=CHANGELOG+filename%3Afound_blob_spec.rb&group_id=9970&project_id=278964)
- Finding the text `EpicLinks` inside files with the `.rb` extension: [`EpicLinks extension:rb`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=EpicLinks+extension%3Arb&group_id=9970&project_id=278964)
- Finding the text `Sidekiq` in a file, when that file is in a path that includes `elastic`: [`Sidekiq path:elastic`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=Sidekiq+path%3Aelastic&group_id=9970&project_id=278964)
- Finding the files represented by the Git object ID `998707b421c89bd9a3063333f9f728ef3e43d101`: [`* blob:998707b421c89bd9a3063333f9f728ef3e43d101`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=false&scope=blobs&repository_ref=&search=*+blob%3A998707b421c89bd9a3063333f9f728ef3e43d101&group_id=9970)
- Syntax filters can be combined for complex filtering. Finding any file starting with `search` containing `eventHub` and with the `.js` extension: [`eventHub filename:search* extension:js`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=eventHub+filename%3Asearch*+extension%3Ajs&group_id=9970&project_id=278964)

#### Excluding filters

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31684) in GitLab Starter 13.3.

Filters can be inverted to **filter out** results from the result set, by prefixing the filter name with a `-` (hyphen) character, such as:

- `-filename`
- `-path`
- `-extension`
- `-blob`

Examples:

- Finding `rails` in all files but `Gemfile.lock`: [`rails -filename:Gemfile.lock`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=rails+-filename%3AGemfile.lock&group_id=9970&project_id=278964)
- Finding `success` in all files excluding `.po|pot` files: [`success -filename:*.po*`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=success+-filename%3A*.po*&group_id=9970&project_id=278964)
- Finding `import` excluding minified JavaScript (`.min.js`) files: [`import -extension:min.js`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=import+-extension%3Amin.js&group_id=9970&project_id=278964)
- Finding `docs` for all files outside the `docs/` folder: [`docs -path:docs/`](https://gitlab.com/search?utf8=%E2%9C%93&snippets=&scope=blobs&repository_ref=&search=docs+-path%3Adocs%2F&group_id=9970&project_id=278964)
