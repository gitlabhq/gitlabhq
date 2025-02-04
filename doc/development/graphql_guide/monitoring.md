---
stage: Foundations
group: Import and Integrate
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Reading GraphQL logs
---

We use Kibana to filter GraphQL query logs. Sign in to [Kibana](https://log.gprd.gitlab.net/)
with a `@gitlab.com` email address.

In Kibana we can inspect two kinds of GraphQL logs:

- Logs of each GraphQL query executed within the request.
- Logs of the full request, which due to [query multiplexing](https://graphql-ruby.org/queries/multiplex.html)
  may have executed multiple queries.

## Logs of each GraphQL query

In a [multiplex query](https://graphql-ruby.org/queries/multiplex.html), each individual query
is logged separately. We can use subcomponent filtering to inspect these logs.
[Visit Kibana with this filter enabled](https://log.gprd.gitlab.net/goto/a0da8c9a1e9c1f533a058b7d29d13956)
or set up the subcomponent filter using these steps:

1. Add a filter:
   1. Filter: `json.subcomponent`
   1. Operator: `is`
   1. Value: `graphql_json`
1. Select **Refresh**.

You can select Kibana fields from the **Available fields** section of the sidebar to
add columns to the log table, or [visit this view](https://log.gprd.gitlab.net/goto/5826d3d3affb41cac52e637ffc205905),
which already has a set of Kibana fields selected. Some relevant Kibana fields include:

| Kibana field | Description |
| ---      | ---      |
| `json.operation_name` | The [operation name](https://graphql.org/learn/queries/#operation-name) used by the client. |
| `json.operation_fingerprint`| The [fingerprint](https://graphql-ruby.org/api-doc/1.12.20/GraphQL/Query#fingerprint-instance_method) of the query, used to recognize repeated queries over time. |
| `json.meta.caller_id` | Appears as `graphql:<operation_name>` for queries that came from the GitLab frontend, otherwise as `graphql:unknown`. Can be used to identify internal versus external queries. |
| `json.query_string` | The query string itself. |
| `json.is_mutation` | `true` when a mutation, `false` when not. |
| `json.query_analysis.used_fields` | List of GraphQL fields selected by the query. |
| `json.query_analysis.used_deprecated_fields` | List of deprecated GraphQL fields selected by the query. |
| `json.query_analysis.duration_s` | Duration of query execution in seconds. |
| `json.query_analysis.complexity` | The [complexity](../api_graphql_styleguide.md#max-complexity) score of the query. |

### Useful filters

Combine the [subcomponent filter](#logs-of-each-graphql-query) with the following Kibana filters to further interrogate the query logs.

#### Queries that used a particular field

Filter logs by queries that used a particular field:

1. Add a filter:
   1. Filter: `json.query_analysis.used_fields`
   1. Operator: `is`
   1. Value: `Type.myField`, where `Type.myField` is the type name and field name as it
      appears in [our GraphQL API resources documentation](../../api/graphql/reference/_index.md).
1. Select **Refresh**.

#### Queries that used a deprecated field

Filter logs of queries that used a particular deprecated field by following the
[steps above](#queries-that-used-a-particular-field) but use the `json.graphql.used_deprecated_fields`
filter instead.

## Logs of the full request

The full request logs encompass log data for all [multiplexed queries](https://graphql-ruby.org/queries/multiplex.html)
in the request, as well as data from time spent outside of `GraphQLController#execute`.

To see the full request logs, do **not** apply the `json.subcomponent` [filter](#logs-of-each-graphql-query), and instead:

1. Add a filter:
   1. Filter: `json.meta.caller_id`
   1. Operator: `is`
   1. Value: `GraphqlController#execute`
1. Select **Refresh**.

Some differences from the [query logs](#logs-of-each-graphql-query) described above:

- Some of the [Kibana fields mentioned above](#logs-of-each-graphql-query) are not available to the full request logs.
- The names of filters differ. For example, instead of `json.query_analysis.used_fields` you select `json.graphql.used_fields`.
