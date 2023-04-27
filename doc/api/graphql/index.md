---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GraphQL API **(FREE)**

> Enabled and [made generally available](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30444) in GitLab 12.1. [Feature flag `graphql`](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30444) removed.

[GraphQL](https://graphql.org/) is a query language for APIs. You can use it to
request the exact data you need, and therefore limit the number of requests you need.

GraphQL data is arranged in types, so your client can use
[client-side GraphQL libraries](https://graphql.org/code/#graphql-clients)
to consume the API and avoid manual parsing.

There are no fixed endpoints and no data model, so you can add
to the API without creating [breaking changes](../../development/deprecation_guidelines/index.md).
This enables us to have a [versionless API](https://graphql.org/learn/best-practices/#versioning).

## Vision

We want the GraphQL API to be the **primary** means of interacting
programmatically with GitLab. To achieve this, it needs full coverage - anything
possible in the REST API should also be possible in the GraphQL API.

To help us meet this vision, the frontend should use GraphQL in preference to
the REST API for new features.

There are no plans to deprecate the REST API. To reduce the technical burden of
supporting two APIs in parallel, they should share implementations as much as
possible.

## Work with GraphQL

If you're new to the GitLab GraphQL API, see [Get started with GitLab GraphQL API](getting_started.md).

You can view the available resources in the [GraphQL API reference](reference/index.md).
The reference is automatically generated from the GitLab GraphQL schema and
written to a Markdown file.

The GitLab GraphQL API endpoint is located at `/api/graphql`.

### GraphiQL

Explore the GraphQL API using the interactive [GraphiQL explorer](https://gitlab.com/-/graphql-explorer),
or on your self-managed GitLab instance on
`https://<your-gitlab-site.com>/-/graphql-explorer`.

For more information, see [GraphiQL](getting_started.md#graphiql).

### View GraphQL examples

You can work with sample queries that pull data from public projects on GitLab.com:

- [Create an audit report](audit_report.md)
- [Identify issue boards](sample_issue_boards.md)
- [Query users](users_example.md)
- [Use custom emojis](custom_emoji.md)

The [get started](getting_started.md) page includes different methods to customize GraphQL queries.

## Breaking changes

The GitLab GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning) and changes to the API are primarily backward-compatible.

However, GitLab sometimes changes the GraphQL API in a way that is not backward-compatible. These changes are considered breaking changes, and
can include removing or renaming fields, arguments, or other parts of the schema.
When creating a breaking change, GitLab follows a [deprecation and removal process](#deprecation-and-removal-process).

To avoid having a breaking change affect your integrations, you should
familiarize yourself with the [deprecation and removal process](#deprecation-and-removal-process) and
frequently [verify your API calls against the future breaking-change schema](#verify-against-the-future-breaking-change-schema).

Fields behind a feature flag and disabled by default do not follow the deprecation and removal process, and can be removed at any time without notice.

For more information, see [Deprecating GitLab features](../../development/deprecation_guidelines/index.md).

WARNING:
GitLab makes all attempts to follow the [deprecation and removal process](#deprecation-and-removal-process).
On rare occasions, GitLab might make immediate breaking changes to the GraphQL
API to patch critical security or performance concerns if the deprecation
process would pose significant risk.

### Verify against the future breaking-change schema

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353642) in GitLab 15.6.

You can make calls against the GraphQL API as if all deprecated items were already removed.
This way, you can verify API calls ahead of a [breaking-change release](#deprecation-and-removal-process)
before the items are actually removed from the schema.

To make these calls, add a
`remove_deprecated=true` query parameter to the GitLab GraphQL API endpoint (for example,
`https://gitlab.com/api/graphql?remove_deprecated=true` for GitLab SaaS GraphQL).

### Deprecation and removal process

The deprecation and removal process for the GitLab GraphQL API aligns with the wider GitLab
[deprecation process](https://about.gitlab.com/handbook/product/gitlab-the-product/#deprecations-removals-and-breaking-changes).

Parts of the schema marked for removal from the GitLab GraphQL API are first
[deprecated](https://about.gitlab.com/handbook/product/gitlab-the-product/#deprecation)
but still available for at least six releases. They are then [removed](https://about.gitlab.com/handbook/product/gitlab-the-product/#removal)
entirely during the next `XX.0` major release.

Items are marked as deprecated in:

- The [schema](https://spec.graphql.org/October2021/#sec--deprecated).
- The [GraphQL API reference](reference/index.md).
- The [deprecation feature removal schedule](../../update/deprecations.md), which is linked from release posts.
- Introspection queries of the GraphQL API.

The deprecation message provides an alternative for the deprecated schema item,
if applicable.

NOTE:
If you use the GraphQL API, we recommend you remove the deprecated schema from your GraphQL
API calls as soon as possible to avoid experiencing breaking changes.
You should [verify your API calls against the schema without the deprecated schema items](#verify-against-the-future-breaking-change-schema).

#### Deprecation example

The following fields are deprecated in different minor releases, but both
removed in GitLab 14.0:

| Field deprecated in | Reason |
| ------------------- | ---    |
| 12.7                | GitLab traditionally has 12 minor releases per major release. To ensure the field is available for 6 more releases, it is removed in the 14.0 major release (and not 13.0). |
| 13.6                | The removal in 14.0 allows for 6 months of availability. |

### List of removed items

View the [list of items removed](removed_items.md) in previous releases.

## Available queries

The GraphQL API includes the following queries at the root level:

Query         | Description
--------------|------------
`project`     | Project information and many of its associations, such as issues and merge requests.
`group`       | Basic group information and epics.
`user`        | Information about a particular user.
`namespace`   | The namespace and the `projects` in it.
`currentUser` | Information about the authenticated user.
`users`       | Information about a collection of users.
`metaData`    | Metadata about GitLab and the GraphQL API.
`snippets`    | Snippets visible to the authenticated user.

New associations and root level objects are regularly added.
See the [GraphQL API Reference](reference/index.md) for up-to-date information.

Root-level queries are defined in
[`app/graphql/types/query_type.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/graphql/types/query_type.rb).

### Multiplex queries

GitLab supports batching queries into a single request using
[`@apollo/client/link/batch-http`](https://www.apollographql.com/docs/react/api/link/apollo-link-batch-http/). More
information about multiplexed queries is also available for
[GraphQL Ruby](https://graphql-ruby.org/queries/multiplex.html), the
library GitLab uses on the backend.

## Limits

The following limits apply to the GitLab GraphQL API.

Limit                | Default
---------------------|---------------------------------------------------------------------
Max page size        | 100 records (nodes) per page. Applies to most connections in the API. Particular connections may have different max page size limits that are higher or lower.
[Max query complexity](#max-query-complexity) | `200` for unauthenticated requests and `250` for authenticated requests.
Request timeout      | 30 seconds.
Max query size       | 10,000 characters per query or mutation. If this limit is reached, use [variables](https://graphql.org/learn/queries/#variables) and [fragments](https://graphql.org/learn/queries/#fragments) to reduce the query or mutation size. Remove white spaces as last resort.

### Max query complexity

The GitLab GraphQL API scores the _complexity_ of a query. Generally, larger
queries have a higher complexity score. This limit is designed to protect
the API from performing queries that could negatively impact its overall performance.

You can [query](getting_started.md#query-complexity) the complexity score of a query
and the limit for the request.

If a query exceeds the complexity limit, an error message response is
returned.

In general, each field in a query adds `1` to the complexity score, although
this can be higher or lower for particular fields. Sometimes, adding
certain arguments may also increase the complexity of a query.

NOTE:
The complexity limits may be revised in future, and additionally, the complexity
of a query may be altered.

## Resolve mutations detected as spam

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327360) in GitLab 13.11.

GraphQL mutations can be detected as spam. If a mutation is detected as spam and:

- A CAPTCHA service is not configured, a
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

- A CAPTCHA service is configured, you receive a response with:
  - `needsCaptchaResponse` set to `true`.
  - The `spamLogId` and `captchaSiteKey` fields set.

  For example:

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

- Use the `captchaSiteKey` to obtain a CAPTCHA response value using the appropriate CAPTCHA API.
  Only [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) is supported.
- Resubmit the request with the `X-GitLab-Captcha-Response` and `X-GitLab-Spam-Log-Id` headers set.

NOTE:
The GitLab GraphiQL implementation doesn't permit passing of headers, so we must write
this as a cURL query. `--data-binary` is used to properly handle escaped double quotes
in the JSON-embedded query.

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --header "Authorization: Bearer $PRIVATE_TOKEN" --header "Content-Type: application/json" --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" --request POST --data-binary '{"query": "mutation {createSnippet(input: {title: \"Title\" visibilityLevel: public blobActions: [ { action: create filePath: \"BlobPath\" content: \"BlobContent\" } ] }) { snippet { id title } errors }}"}' "https://gitlab.example.com/api/graphql"
```
