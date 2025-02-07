---
stage: Foundations
group: Import and Integrate
description: Programmatic interaction with GitLab.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQL API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[GraphQL](https://graphql.org/) is a query language for APIs. You can use it to
request the exact data you need, and therefore limit the number of requests you need.

GraphQL data is arranged in types, so your client can use
[client-side GraphQL libraries](https://graphql.org/community/tools-and-libraries/)
to consume the API and avoid manual parsing.

The GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning).

## Getting started

If you're new to the GitLab GraphQL API, see [Get started with GitLab GraphQL API](getting_started.md).

You can view the available resources in the [GraphQL API reference](reference/_index.md).

The GitLab GraphQL API endpoint is located at `/api/graphql`.

### Interactive GraphQL explorer

Explore the GraphQL API using the interactive GraphQL explorer, either:

- [On GitLab.com](https://gitlab.com/-/graphql-explorer).
- On GitLab Self-Managed on `https://<your-gitlab-site.com>/-/graphql-explorer`.

For more information, see [GraphiQL](getting_started.md#graphiql).

### View GraphQL examples

You can work with sample queries that pull data from public projects on GitLab.com:

- [Create an audit report](audit_report.md)
- [Identify issue boards](sample_issue_boards.md)
- [Query users](users_example.md)
- [Use custom emoji](custom_emoji.md)

The [get started](getting_started.md) page includes different methods to customize GraphQL queries.

### Authentication

You can access some queries without authentication, but others require authentication. Mutations always require
authentication.

You can authenticate by using either a:

- [Token](#token-authentication)
- [Session cookie](#session-cookie-authentication)

If the authentication information is not valid, GitLab returns an error message with a status code of `401`:

```json
{"errors":[{"message":"Invalid token"}]}
```

#### Token authentication

Use any of the following tokens to authenticate with the GraphQL API:

- [OAuth 2.0 tokens](../oauth2.md)
- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Project access tokens](../../user/project/settings/project_access_tokens.md)
- [Group access tokens](../../user/group/settings/group_access_tokens.md)

Authenticate with a token by passing it through in a [request header](#header-authentication) or as a [parameter](#parameter-authentication).

Tokens require the correct [scope](#token-scopes).

##### Header authentication

Example of token authentication using an `Authorization: Bearer <token>` request header:

```shell
curl "https://gitlab.com/api/graphql" --header "Authorization: Bearer <token>" \
     --header "Content-Type: application/json" --request POST \
     --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### Parameter authentication

Example of using an OAuth 2.0 token in the `access_token` parameter:

```shell
curl "https://gitlab.com/api/graphql?access_token=<oauth_token>" \
     --header "Content-Type: application/json" --request POST \
     --data "{\"query\": \"query {currentUser {name}}\"}"
```

You can pass in personal, project, or group access tokens using the `private_token` parameter:

```shell
curl "https://gitlab.com/api/graphql?private_token=<access_token>" \
     --header "Content-Type: application/json" --request POST \
     --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### Token scopes

Tokens must have the correct scope to access the GraphQL API, either:

| Scope      | Access  |
|------------|---------|
| `read_api` | Grants read access to the API. Sufficient for queries. |
| `api`      | Grants read and write access to the API. Required by mutations. |

#### Session cookie authentication

Signing in to the main GitLab application sets a `_gitlab_session` session cookie.

The [interactive GraphQL explorer](#interactive-graphql-explorer) and the web frontend of
GitLab itself use this method of authentication.

## Object identifiers

The GitLab GraphQL API uses a mix of identifiers.

[Global IDs](#global-ids), full paths, and internal IDs (IIDs) are all used as arguments in the GitLab
GraphQL API, but often a particular part of schema does not accept all of these at the same time.

Although the GitLab GraphQL API has historically not been consistent on this, in general you can expect:

- If the object is a project, group, or namespace, you use the object's full path.
- If an object has an IID, you use a combination of full path and IID.
- For other objects, you use a [Global ID](#global-ids).

For example, finding a project by its full path `"gitlab-org/gitlab"`:

```graphql
{
  project(fullPath: "gitlab-org/gitlab") {
    id
    fullPath
  }
}
```

Another example, locking an issue by its project's full path `"gitlab-org/gitlab"` and the issue's IID `"1"`":

```graphql
mutation {
  issueSetLocked(input: { projectPath: "gitlab-org/gitlab", iid: "1", locked: true }) {
    issue {
      id
      iid
    }
  }
}
```

An example of finding a CI runner by its Global ID:

```graphql
{
  runner(id: "gid://gitlab/Ci::Runner/1") {
    id
  }
}
```

Historically, the GitLab GraphQL API has been inconsistent with typing of full path and
IID fields and arguments, but generally:

- Full path fields and arguments are a GraphQL `ID` type .
- IID fields and arguments are a GraphQL `String` type.

### Global IDs

In the GitLab GraphQL API, a field or argument named `id` is nearly always a [Global ID](https://graphql.org/learn/global-object-identification/)
and never a database primary key ID. A Global ID in the GitLab GraphQL API
begins with `"gid://gitlab/"`. For example, `"gid://gitlab/Issue/123"`.

Global IDs are a convention used for caching and fetching in some client-side libraries.

GitLab Global IDs are subject to change. If changed, the use of the old Global ID as an argument is deprecated and supported according to the [deprecation and breaking change](#breaking-changes) process.
You should not expect that a cached Global ID will be valid beyond the time of a GitLab GraphQL deprecation cycle.

## Available top-level queries

The top-level entry points for all queries are defined in the [`Query` type](reference/_index.md#query-type) in the
GraphQL reference.

### Multiplex queries

GitLab supports batching queries into a single request. For more information, see
[Multiplex](https://graphql-ruby.org/queries/multiplex.html).

## Breaking changes

The GitLab GraphQL API is [versionless](https://graphql.org/learn/best-practices/#versioning) and changes to the API are
primarily backward-compatible.

However, GitLab sometimes changes the GraphQL API in a way that is not backward-compatible. These changes are considered breaking changes, and
can include removing or renaming fields, arguments, or other parts of the schema.
When creating a breaking change, GitLab follows a [deprecation and removal process](#deprecation-and-removal-process).

To avoid having a breaking change affect your integrations, you should:

- Familiarize yourself with the [deprecation and removal process](#deprecation-and-removal-process).
- Frequently [verify your API calls against the future breaking-change schema](#verify-against-the-future-breaking-change-schema).

For more information, see [Deprecating GitLab features](../../development/deprecation_guidelines/_index.md).

For GitLab Self-Managed, [downgrading](../../downgrade_ee_to_ce/_index.md) from an EE instance to CE causes breaking changes.

### Breaking change exemptions

Schema items labeled as experiments in the [GraphQL API reference](reference/_index.md)
are exempt from the deprecation process. These items can be removed or changed at any
time without notice.

Fields behind a feature flag and disabled by default do not follow the
deprecation and removal process. These fields can be removed at any time without notice.

WARNING:
GitLab makes all attempts to follow the [deprecation and removal process](#deprecation-and-removal-process).
GitLab might make immediate breaking changes to the GraphQL
API to patch critical security or performance concerns if the deprecation
process would pose significant risk.

### Verify against the future breaking-change schema

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353642) in GitLab 15.6.

You can make calls against the GraphQL API as if all deprecated items were already removed.
This way, you can verify API calls ahead of a [breaking-change release](#deprecation-and-removal-process)
before the items are actually removed from the schema.

To make these calls, add a
`remove_deprecated=true` query parameter to the GraphQL API endpoint. For example,
`https://gitlab.com/api/graphql?remove_deprecated=true` for GraphQL on GitLab.com.

### Deprecation and removal process

Parts of the schema marked for removal from the GitLab GraphQL API are first
deprecated but still available for at least six releases. They are then
removed entirely during the next `XX.0` major release.

Items are marked as deprecated in:

- The [schema](https://spec.graphql.org/October2021/#sec--deprecated).
- The [GraphQL API reference](reference/_index.md).
- The [deprecation feature removal schedule](../../update/deprecations.md), which is linked from release posts.
- Introspection queries of the GraphQL API.

The deprecation message provides an alternative for the deprecated schema item,
if applicable.

To avoid experiencing breaking changes, you should remove the deprecated schema from your GraphQL API calls as soon as
possible. You should [verify your API calls against the schema without the deprecated schema items](#verify-against-the-future-breaking-change-schema).

#### Deprecation example

The following fields are deprecated in different minor releases, but both
removed in GitLab 17.0:

| Field deprecated in | Reason |
|:--------------------|:-------|
| 15.7                | GitLab traditionally has 12 minor releases per major release. To ensure the field is available for 6 more releases, it is removed in the 17.0 major release (and not 16.0). |
| 16.6                | The removal in 17.0 allows for 6 months of availability. |

### List of removed items

View the [list of items removed](removed_items.md) in previous releases.

## Limits

The following limits apply to the GitLab GraphQL API.

| Limit                                                 | Default |
|:------------------------------------------------------|:--------|
| Maximum page size                                     | 100 records (nodes) per page. Applies to most connections in the API. Particular connections may have different max page size limits that are higher or lower. |
| [Maximum query complexity](#maximum-query-complexity) | 200 for unauthenticated requests and 250 for authenticated requests. |
| Maximum query size                                    | 10,000 characters per query or mutation. If this limit is reached, use [variables](https://graphql.org/learn/queries/#variables) and [fragments](https://graphql.org/learn/queries/#fragments) to reduce the query or mutation size. Remove white spaces as last resort. |
| Rate limits | For GitLab.com, see [GitLab.com-specific rate limits](../../user/gitlab_com/_index.md#gitlabcom-specific-rate-limits). |
| Request timeout                                       | 30 seconds. |

### Maximum query complexity

The GitLab GraphQL API scores the _complexity_ of a query. Generally, larger
queries have a higher complexity score. This limit is designed to protecting
the API from performing queries that could negatively impact its overall performance.

You can [query](getting_started.md#query-complexity) the complexity score of a query
and the limit for the request.

If a query exceeds the complexity limit, an error message response is
returned.

In general, each field in a query adds `1` to the complexity score, although
this can be higher or lower for particular fields. Sometimes, adding
certain arguments may also increase the complexity of a query.

## Resolve mutations detected as spam

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
