---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19008) in GitLab 11.0 (enabled by feature flag `graphql`).
> - [Always enabled](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30444) in GitLab 12.1.

## Getting Started

For those new to the GitLab GraphQL API, see
[Getting started with GitLab GraphQL API](getting_started.md).

### Quick Reference

- The GitLab GraphQL API endpoint is located at `/api/graphql`.
- Get an [introduction to GraphQL from graphql.org](https://graphql.org/).
- GitLab supports a wide range of resources, listed in the [GraphQL API Reference](reference/index.md).

### Examples

To work with sample queries that pull data from public projects on GitLab.com,
see the menu options in the left-hand
documentation menu, under API > GraphQL at `https://docs.gitlab.com/ee/api/graphql/`.

The [Getting started](getting_started.md) page includes different methods to customize GraphQL queries.

### GraphiQL

Explore the GraphQL API using the interactive [GraphiQL explorer](https://gitlab.com/-/graphql-explorer),
or on your self-managed GitLab instance on
`https://<your-gitlab-site.com>/-/graphql-explorer`.

See the [GitLab GraphQL overview](getting_started.md#graphiql) for more information about the GraphiQL Explorer.

## What is GraphQL?

[GraphQL](https://graphql.org/) is a query language for APIs that
allows clients to request exactly the data they need, making it
possible to get all required data in a limited number of requests.

The GraphQL data (fields) can be described in the form of types,
allowing clients to use [client-side GraphQL
libraries](https://graphql.org/code/#graphql-clients) to consume the
API and avoid manual parsing.

Since there's no fixed endpoints and data model, new abilities can be
added to the API without creating [breaking changes](../../development/contributing/#breaking-changes). This allows us to
have a versionless API as described in [the GraphQL
documentation](https://graphql.org/learn/best-practices/#versioning).

## Vision

We want the GraphQL API to be the **primary** means of interacting
programmatically with GitLab. To achieve this, it needs full coverage - anything
possible in the REST API should also be possible in the GraphQL API.

To help us meet this vision, the frontend should use GraphQL in preference to
the REST API for new features.

There are no plans to deprecate the REST API. To reduce the technical burden of
supporting two APIs in parallel, they should share implementations as much as
possible.

## Breaking changes

The GitLab GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning) and
changes are made to the API in a way that maintains backwards-compatibility.

Occasionally GitLab needs to change the GraphQL API in a way that is not backwards-compatible.
These changes include the removal or renaming of fields, arguments or other parts of the schema.

In these situations, GitLab follows a [Deprecation and removal process](#deprecation-and-removal-process)
where the deprecated part of the schema is supported for a period of time before being removed.

Clients should familiarize themselves with the process to avoid breaking changes affecting their integrations.

WARNING:
While GitLab will make all attempts to follow the [deprecation and removal process](#deprecation-and-removal-process),
GitLab may on very rare occasions need to make immediate breaking changes to the GraphQL API to patch critical security or performance
concerns and where the deprecation process would be considered to pose significant risk.

NOTE:
Fields behind a feature flag and disabled by default are exempt from the deprecation process,
and can be removed at any time without notice.

### Deprecation and Removal process

Parts of the schema marked for removal from the GitLab GraphQL API are first **deprecated** but still available
for at least six releases, and then **removed entirely**.
Removals occur at `X.0` and `X.6` releases.

The process is as follows:

1. The item is marked as deprecated in the schema. It will be displayed as deprecated in the
   [GraphQL API Reference](reference/index.md) and in introspection queries.
1. Removals are announced at least one release prior in the [Deprecations](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations)
   section of the release post (at or prior to `X.11` and `X.5` releases).
1. Items meeting criteria are removed in `X.0` or `X.6` and added to:

   - The [Removals](https://about.gitlab.com/handbook/marketing/blog/release-posts/#removals) section of the Release Post.
   - The [Removed items page](removed_items.md).

This gives consumers of the GraphQL API a minimum of six months to update their GraphQL queries.

When an item is deprecated or removed, an alternative is provided if available.

**Example:**

A field marked as deprecated in `12.7` can be used until its removal in `13.6`.

### List of removed items

View the [fields, enums, and other items we removed](removed_items.md) from the GraphQL API.

## Available queries

The GraphQL API includes the following queries at the root level:

1. `project` : Project information, with many of its associations such as issues and merge requests.
1. `group` : Basic group information and epics **(ULTIMATE)** are currently supported.
1. `user` : Information about a particular user.
1. `namespace` : Within a namespace it is also possible to fetch `projects`.
1. `currentUser`: Information about the currently logged in user.
1. `users`: Information about a collection of users.
1. `metaData`: Metadata about GitLab and the GraphQL API.
1. `snippets`: Snippets visible to the currently logged in user.

New associations and root level objects are constantly being added.
See the [GraphQL API Reference](reference/index.md) for up-to-date information.

Root-level queries are defined in
[`app/graphql/types/query_type.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/types/query_type.rb).

### Multiplex queries

GitLab supports batching queries into a single request using
[apollo-link-batch-http](https://www.apollographql.com/docs/link/links/batch-http/). More
information about multiplexed queries is also available for
[GraphQL Ruby](https://graphql-ruby.org/queries/multiplex.html), the
library GitLab uses on the backend.

## Limits

The following limits apply to the GitLab GraphQL API.

### Max page size

By default, connections return at most `100` records ("nodes") per page,
and this limit applies to most connections in the API. Particular connections
may have different max page size limits that are higher or lower.

### Max query complexity

The GitLab GraphQL API scores the _complexity_ of a query. Generally, larger
queries will have a higher complexity score. This limit is designed to protect
the API from performing queries that could negatively impact its overall performance.

The complexity of a single query is limited to a maximum of:

- `200` for unauthenticated requests.
- `250` for authenticated requests.

There is no way to discover the complexity of a query except by exceeding the limit.

If a query exceeds the complexity limit an error message response will
be returned.

In general, each field in a query will add `1` to the complexity score, although
this can be higher or lower for particular fields. Sometimes the addition of
certain arguments may also increase the complexity of a query.

NOTE:
The complexity limits may be revised in future, and additionally, the complexity
of a query may be altered.

### Request timeout

Requests time out at 30 seconds.

### Spam

GraphQL mutations can be detected as spam. If this happens, a
[GraphQL top-level error](https://spec.graphql.org/June2018/#sec-Errors) is raised. For example:

```json
{
  "errors": [
    {
      "message": "Request denied. Spam detected",
      "locations": [ { "line": 6, "column": 7 } ],
      "path": [ "updateSnippet" ],
      "extensions": {
        "spam": true
      }
    }
  ],
  "data": {
    "updateSnippet": {
      "snippet": null
    }
  }
}
```

If mutation is detected as potential spam and a CAPTCHA service is configured:

- The `captchaSiteKey` should be used to obtain a CAPTCHA response value using the appropriate CAPTCHA API.
  Only [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) is supported.
- The request can be resubmitted with the `X-GitLab-Captcha-Response` and `X-GitLab-Spam-Log-Id` headers set.

```json
{
  "errors": [
    {
      "message": "Request denied. Solve CAPTCHA challenge and retry",
      "locations": [ { "line": 6, "column": 7 } ],
      "path": [ "updateSnippet" ],
      "extensions": {
        "needsCaptchaResponse": true,
        "captchaSiteKey": "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI",
        "spamLogId": 67
      }
    }
  ],
  "data": {
    "updateSnippet": {
      "snippet": null,
    }
  }
}
```

## Reference

The GitLab GraphQL reference [is available](reference/index.md).

It is automatically generated from the GitLab GraphQL schema and embedded in a Markdown file.

## Generate updates for documentation

If you've changed the GraphQL schema, you should set up an MR to gain approval of your changes.
To generate the required documentation and schema, follow the instructions given in the
[Rake tasks for developers](../../development/rake_tasks.md#update-graphql-documentation-and-schema-definitions) page.

Be sure to run these commands using the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/).
