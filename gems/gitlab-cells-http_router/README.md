# Gitlab::Cells::HttpRouter

Ruby-side support for the [Cells HTTP Router](https://gitlab.com/gitlab-org/cells/http-router).

GitLab is the source of truth for how the router must classify requests, so the artifacts the
router consumes are generated here rather than in the router repository. That keeps the two from
drifting apart, which could route requests to the wrong cell.

Anything that needs a booted Rails application stays in the monolith. See
`lib/tasks/gitlab/cells/routes.rake` in the GitLab monorepo for the caller.

## RoutesSnapshot

Reduces every Rails and Grape route to a `template` paired with a concrete `example` URL. The
router downloads the generated file and replays each example against its own routing table.

```ruby
snapshot = Gitlab::Cells::HttpRouter::RoutesSnapshot.new(
  path_specs: Rails.application.routes.routes.map { |route| route.path.spec.to_s } +
    API::API.routes.map { |route| route.path.to_s }
)

snapshot.routes         # => [#<struct Route template: "/groups/:id", example: "/groups/foo">, ...]
snapshot.to_json_string # => the snapshot as pretty-printed JSON
snapshot.write!(Rails.root.join('config/routing/gitlab_routes.json'))
```

Given the path spec `/groups/*group_id/-/milestones/:id(.:format)`, it produces the template
`/groups/*group_id/-/milestones/:id` and the example `/groups/foo/bar/-/milestones/foo`.

Templates are deduplicated and sorted. Routes that only exist under `RAILS_ENV=test` are dropped,
because each template also becomes a reserved-word guard on the router side. See
`RoutesSnapshot::TEST_ONLY_TEMPLATES`.

To build a single example without a full snapshot:

```ruby
Gitlab::Cells::HttpRouter::RoutesSnapshot.example_for('/api/:version/groups/:id/access_requests')
# => "/api/v4/groups/foo/access_requests"
```

## Development

Follow the GitLab [gems development guidelines](../../doc/development/gems.md).
