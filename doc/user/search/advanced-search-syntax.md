## Advanced search syntax

If your site administrator has enabled [Elasticsearch integration](../../integration/elasticsearch.md)
then some advanced search functionality is available.

Full details can be found in the
[Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html#_simple_query_string_syntax)
but here's a quick guide:

* Searches look for all the words in a query, in any order - e.g.: searching
  issues for `display bug` will return all issues matching both those words, in any order.
* To find the exact term, use double quotes: `"display bug"`
* To find bugs not mentioning display, use `-`: `bug -display`
* To find a bug in display or sound, use `|`: `bug display | sound`
* To group terms together, use parentheses: `bug | (display +sound)`
* To match a partial word, use `*`: `bug find_by_*`
* To find a term containing one of these symbols, use `\`: `argument \-last`

