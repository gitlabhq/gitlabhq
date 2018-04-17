# Advanced Syntax Search **[STARTER]**

>**Notes:**
- Introduced in [GitLab Enterprise Starter][ee] 9.2
- This is the user documentation. To install and configure Elasticsearch,
  visit the [admin docs](../../integration/elasticsearch.md).

Use advanced queries for more targeted search results.

## Overview

The Advanced Syntax Search is a subset of the
[Advanced Global Search](advanced_global_search.md), which you can use if you
want to have more specific search results.

## Use cases

Let's say for example that the product you develop relies on the code of another
product that's hosted under some other group.

Since under your GitLab instance there are hosted hundreds of different projects,
you need the search results to be as efficient as possible. You have a feeling
of what you want to find (e.g., a function name), but at the same you're also
not so sure.

In that case, using the advanced search syntax in your query will yield much
better results.

## Using the Advanced Syntax Search

The Advanced Syntax Search supports fuzzy or exact search queries with prefixes,
boolean operators, and much more.

Full details can be found in the [Elasticsearch documentation][elastic], but
here's a quick guide:

* Searches look for all the words in a query, in any order - e.g.: searching
  issues for `display bug` will return all issues matching both those words, in any order.
* To find the exact term, use double quotes: `"display bug"`
* To find bugs not mentioning display, use `-`: `bug -display`
* To find a bug in display or sound, use `|`: `bug display | sound`
* To group terms together, use parentheses: `bug | (display +sound)`
* To match a partial word, use `*`: `bug find_by_*`
* To find a term containing one of these symbols, use `\`: `argument \-last`

[ee]: https://about.gitlab.com/products/
[elastic]: https://www.elastic.co/guide/en/elasticsearch/reference/5.3/query-dsl-simple-query-string-query.html#_simple_query_string_syntax
