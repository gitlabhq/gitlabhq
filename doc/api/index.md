---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# API Docs **(FREE)**

Use the GitLab APIs to automate GitLab.

## REST API

A REST API is available in GitLab.

For more information and examples, see [REST API](rest/index.md).

For a list of the available resources and their endpoints, see
[REST API resources](api_resources.md).

You can also use a partial [OpenAPI definition](openapi/openapi_interactive.md),
to test the API directly from the GitLab user interface.
Contributions are welcome.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction and basic steps, see
[How to make GitLab API calls](https://www.youtube.com/watch?v=0LsMC3ZiXkA).

## GraphQL API

A GraphQL API is available in GitLab.
For a list of the available resources and their endpoints, see
[GraphQL API resources](graphql/reference/index.md).

With GraphQL, you can make an API request for only what you need,
and it's versioned by default.

GraphQL co-exists with the current v4 REST API. If we have a v5 API, this should
be a compatibility layer on top of GraphQL.

There were some patenting and licensing concerns with GraphQL. However, these
have been resolved to our satisfaction. The reference implementations
were re-licensed under MIT, and the OWF license used for the GraphQL specification.
