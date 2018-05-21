# GraphQL API (Beta)

> [Introduced][ce-19008] in GitLab 11.0.

## Enabling the GraphQL feature

The GraphQL API itself is currently in Beta, and therefore hidden behind a
feature flag. To enable it on your selfhosted instance, run
`Feature.enable(:graphql)`.

Start the console by running

```bash
sudo gitlab-rails console
```

Then enable the feature by running

```ruby
Feature.enable(:graphql)
```

## Available queries

A first iteration of a GraphQL API inlcudes only 2 queries: `project` and
`merge_request` and only returns scalar fields, or fields of the type `Project`
or `MergeRequest`.

## GraphiQL

The API can be explored by using the GraphiQL IDE, it is available on your
instance on `gitlab.example.com/api/graphiql`.

[ce-19008]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/19008
