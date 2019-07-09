# GraphQL API (Alpha)

> [Introduced][ce-19008] in GitLab 11.0.

[GraphQL](https://graphql.org/) is a query language for APIs that
allows clients to request exactly the data they need, making it
possible to get all required data in a limited number of requests.

The GraphQL data (fields) can be described in the form of types,
allowing clients to use [clientside GraphQL
libraries](https://graphql.org/code/#graphql-clients) to consume the
API and avoid manual parsing.

Since there's no fixed endpoints and datamodel, new abilities can be
added to the API without creating breaking changes. This allows us to
have a versionless API as described in [the GraphQL
documentation](https://graphql.org/learn/best-practices/#versioning).

## Vision

We want the GraphQL API to be the **primary** means of interacting
programmatically with GitLab. To achieve this, it needs full coverage - anything
possible in the REST API should also be possible in the GraphQL API.

To help us meet this vision, the frontend should use GraphQL in preference to
the REST API for new features, although the alpha status of GraphQL may prevent
this from being a possibility at times.

There are no plans to deprecate the REST API. To reduce the technical burden of
supporting two APIs in parallel, they should share implementations as much as
possible.

## Enabling the GraphQL feature

The GraphQL API itself is currently in Alpha, and therefore hidden behind a
feature flag. You can enable the feature using the [features api][features-api] on a self-hosted instance.

For example:

```shell
curl --data "value=100" --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/features/graphql
```

## Available queries

A first iteration of a GraphQL API includes the following queries

1. `project` : Within a project it is also possible to fetch a `mergeRequest` by IID.
1. `group` : Basic group information and epics **(ULTIMATE)** are currently supported.
1. `namespace` : Within a namespace it is also possible to fetch `projects`.

### Multiplex queries

GitLab supports batching queries into a single request using
[apollo-link-batch-http](https://www.apollographql.com/docs/link/links/batch-http). More
info about multiplexed queries is also available for
[graphql-ruby](https://graphql-ruby.org/queries/multiplex.html) the
library GitLab uses on the backend.

## GraphiQL

The API can be explored by using the GraphiQL IDE, it is available on your
instance on `gitlab.example.com/-/graphql-explorer`.

[ce-19008]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/19008
[features-api]: ../features.md
