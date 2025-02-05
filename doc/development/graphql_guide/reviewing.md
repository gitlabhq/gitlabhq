---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GraphQL API merge request checklist
---

The GitLab GraphQL API has a fair degree of complexity so it's important that merge requests containing GraphQL changes be reviewed by someone familiar with GraphQL.
You can ping one via the `@gitlab-org/graphql-experts` group in a MR or in the [`#f_graphql` channel](https://gitlab.slack.com/archives/C6MLS3XEU) in Slack (available to GitLab team members only).

GraphQL queries need to be reviewed for:

- breaking changes
- authorization
- performance

## Review criteria

This is not an exhaustive list.

### Description with sample query

Ensure that the description includes a sample query with setup instructions.
Try running the query in [GraphiQL](../api_graphql_styleguide.md#graphiql) on your local GDK instance.

### No breaking changes (unless after full deprecation cycle)

Check the MR for any [breaking changes](../api_graphql_styleguide.md#breaking-changes).

If a feature is marked as an [experiment](../api_graphql_styleguide.md#mark-schema-items-as-experiments), you can make breaking changes immediately, with no deprecation period.

For more information, see [deprecation and removal process](../../api/graphql/_index.md#deprecation-and-removal-process).

### Multiversion compatibility

Ensure that multi-version compatibility is guaranteed.
This generally means frontend and backend code for the same GraphQL feature can't be shipped in the same release.

For details, see [multiple version compatibility](../multi_version_compatibility.md).

### Technical writing review

Changes to the generated API docs require a technical writer review.

### Changelog

Public-facing changes that are not marked as an [experiment](../api_graphql_styleguide.md#mark-schema-items-as-experiments) require a [changelog entry](../changelog.md).

### Use the framework

GraphQL is a framework with many moving parts. It's important that the framework is followed.

- Do not manually invoke framework bits. For example, do not instantiate resolvers during execution and instead let the framework do that.
- You can subclass resolvers, as in `MyResolver.single` (see [deriving resolvers](../api_graphql_styleguide.md#deriving-resolvers)).
- Use the `ready?` method for more complex argument logic (see [correct use of resolver#ready](../api_graphql_styleguide.md#correct-use-of-resolverready)).
- Use the `prepare` method for more complex argument validation (see [Preprocessing](https://graphql-ruby.org/fields/arguments.html#preprocessing)).

For details, see [resolver guide](../api_graphql_styleguide.md#writing-resolvers).

### Authorization

Ensure proper authorization is followed and that `authorize :some_ability` is tested in the specs.

For details, see [authorization guide](authorization.md).

### Performance

Ensure:

- You have [checked for N+1s](../api_graphql_styleguide.md#how-to-see-n1-problems-in-development) and
  used [optimizations](../api_graphql_styleguide.md#optimizations) to remove N+1s whenever possible.
- You use [laziness](../api_graphql_styleguide.md#laziness) appropriately.

### Use appropriate types

For example:

- [`TimeType`](../api_graphql_styleguide.md#typestimetype) for Ruby `Time` and `DateTime` objects.
- Global IDs for `id` fields

For details, see [types](../api_graphql_styleguide.md#types).

### Appropriate complexity

Query complexity is a way of quantifying how expensive a query is likely to be. Query complexity limits are defined as constants in the schema.
When a resolver or type is expensive to call we need to ensure that the query complexity reflects that.

For details, see [max complexity](../api_graphql_styleguide.md#max-complexity), [field complexity](../api_graphql_styleguide.md#field-complexity) and [query limits](../api_graphql_styleguide.md#query-limits).

### Testing

- Resolver (unit) specs are deprecated in favour of request (integration) specs.
- Many aspects of our framework are outside the `resolve` method and a request spec is the only way to ensure they behave properly.
- Every GraphQL change MR should ideally have changes to API specs.

For details, see [testing guide](../api_graphql_styleguide.md#testing).
