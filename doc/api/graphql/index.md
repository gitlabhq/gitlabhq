---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19008) in GitLab 11.0 (enabled by feature flag `graphql`).
> - [Always enabled](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30444) in GitLab 12.1.

## Getting Started

For those new to the GitLab GraphQL API, see
[Getting started with GitLab GraphQL API](getting_started.md).

### Quick Reference

- GitLab's GraphQL API endpoint is located at `/api/graphql`.
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
added to the API without creating breaking changes. This allows us to
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

### Deprecation process

Fields marked for removal from the GitLab GraphQL API are first **deprecated** but still available
for at least six releases, and then **removed entirely**.
Removals occur at X.0 and X.6 releases.

For example, a field can be marked as deprecated (but still usable) in %12.7, but can be used until its removal in %13.6.
When marked as deprecated, an alternative should be provided if there is one.
That gives consumers of the GraphQL API a minimum of six months to update their GraphQL queries.

The process is as follows:

1. The field is listed as deprecated in [GraphQL API Reference](reference/index.md).
1. Removals are announced at least one release prior in the Deprecation Warnings section of the
   release post (at or prior to X.11 and X.5 releases).
1. Fields meeting criteria are removed in X.0 or X.6.

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
[`app/graphql/types/query_type.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/graphql/types/query_type.rb).

### Multiplex queries

GitLab supports batching queries into a single request using
[apollo-link-batch-http](https://www.apollographql.com/docs/link/links/batch-http/). More
information about multiplexed queries is also available for
[GraphQL Ruby](https://graphql-ruby.org/queries/multiplex.html), the
library GitLab uses on the backend.

## Reference

GitLab's GraphQL reference [is available](reference/index.md).

It is automatically generated from GitLab's GraphQL schema and embedded in a Markdown file.

Machine-readable versions are also available:

- [JSON format](reference/gitlab_schema.json)
- [IDL format](reference/gitlab_schema.graphql)

## Generate updates for documentation

If you've changed the GraphQL schema, you should set up an MR to gain approval of your changes.
To generate the required documentation and schema, follow the instructions given in the
[Rake tasks for developers](../../development/rake_tasks.md#update-graphql-documentation-and-schema-definitions) page.

Be sure to run these commands using the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit/).
