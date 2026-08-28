---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content.
  For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: HTTP Router
---

## HTTP Router

HTTP Router is the service that determines which cell should serve the incoming requests inside the cluster.
This is generally determined by the resources the request is asking for.

For example, a request looking for a project inside `cell-2` will be routed to `cell-2`.

To learn more about HTTP Router, check out the
[design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/http_routing_service/) and
the [project repository](https://gitlab.com/gitlab-org/cells/http-router).

## Routing Rules

Routing rules define how to decode requests and make routing decisions.

Rules are organized in rulesets (e.g. [session_token](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/config/ruleset/session_token.json)).
Rules are static and selected (by ruleset) prior to the HTTP Router deployment.

Routing decision is evaluated from top to bottom. It short circuits upon first match.

For more in-depth explanation of rules and running examples of incoming requests being
matched to routing rules, check out the http-router documentation on
[rules](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/rules/index.md).

## Routing based on routable tokens

A routable token encodes routing information directly in the token. When a request carries a routable
token, the HTTP Router decodes the token and routes the request to the correct cell. The router does
not need to query another service to find the cell that owns the resource.

This follows the
[Routable Tokens design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/).

Routing based on routable tokens has two sides:

- GitLab encodes the routing information when it generates the token.
- The HTTP Router decodes that information and routes the request.

### Encode routing information in a token

Introduce a `routable_token` as soon as possible. This ensures tokens are
generated with routable information from the start.
The HTTP Router decoder changes can happen later. If the router does not know where to
route the request, it falls back to the legacy cell.

GitLab encodes routing information in a token through the `routable_token:` option of the
`TokenAuthenticatable` concern. For details, see
[Using the `TokenAuthenticatable` concern](../token_authenticatable.md#routable-token).

For example, `Ci::Runner#token` is routable.
The runner token encodes the organization, group,
project, and user keys for group type, and project type runners:

```ruby
add_authentication_token_field :token,
  encrypted: :optional,
  expires_at: :compute_token_expiration,
  format_with_prefix: :prefix_for_new_and_legacy_runner,
  routable_token: {
    if: ->(token_owner_record) {
      (token_owner_record.group_type? || token_owner_record.project_type?) &&
        token_owner_record.owner &&
        Feature.enabled?(:routable_runner_token, token_owner_record.owner)
    },
    payload: {
      o: ->(token_owner_record) { token_owner_record.owner.organization_id },
      g: ->(token_owner_record) { token_owner_record.group_type? ? token_owner_record.sharding_key_id : nil },
      p: ->(token_owner_record) { token_owner_record.project_type? ? token_owner_record.sharding_key_id : nil },
      u: ->(token_owner_record) { token_owner_record.creator_id }
    }
  }
```

### Decode a token and route the request

The HTTP Router matches the token against a rule, decodes the payload, and classifies the request by
cell.

Each token type needs a new rule in the HTTP Router.

A rule that routes runner tokens looks like this:

```json
{
  "id": "session_token_header_runner_token",
  "match": {
    "type": "header",
    "name": "runner-token",
    "regexValue": "^glrtr?-(?<payload>[0-9A-Za-z_-]{27,300})\\.01\\.(?<payload_length>[0-9a-z]{2})[0-9a-z]{7}$"
  },
  "transform": {
    "type": "routable-token-payload",
    "input": [
      "${payload}",
      "${payload_length}"
    ],
    "output": "decoded"
  },
  "action": "classify",
  "classify": {
    "type": "CELL_ID",
    "value": "${decoded.c}"
  },
  "validate": {
    "exist": [
      "${decoded.c}"
    ]
  }
}
```

The router processes the rule in these phases:

1. Match: the `match.regexValue` captures the `payload` and `payload_length` from the token. The
   `payload_length` tells the decoder how much of the payload to read, which avoids decoding the
   whole token.
1. Transform: the `routable-token-payload` transform decodes the Base64 payload and attaches the
   result under `decoded`. For example, `decoded.c` holds the cell.
1. Validate: the router checks that `decoded.c` exists.
1. Classify: the router sends a `CELL_ID` classify request to the Topology Service with the value of
   `decoded.c`, then proxies the request to the cell that the Topology Service returns.

For a step-by-step walkthrough of this rule with a sample request, see the
[runner token example](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/rules/session_token/example_with_session_token_header_runner_token.md)
in the http-router documentation.

## Routing based on resource path

Coming soon

## Routing based on resource ID

Coming soon

## Route snapshot

GitLab is the source of truth for the list of routes the HTTP Router must be able to classify.
The file `config/routing/gitlab_routes.json` holds every Rails and Grape route as a `template`
paired with a concrete `example` URL. The HTTP Router downloads this file and replays each example
against its own routing table in a
[snapshot test](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/test/routes/routes.spec.ts)
to detect when a GitLab route change affects routing.

To keep GitLab and the HTTP Router in sync, the routes are generated and committed in GitLab instead
of the HTTP Router repository. This prevents the two from drifting apart, which could route requests
to the wrong cell.

### Regenerate the snapshot

When you add, change, or remove a route, regenerate the file and commit it in the same merge request:

```shell
bundle exec rake gitlab:cells:routes:generate
```

The `cells-routes:up-to-date` CI job regenerates the file and fails when it differs from the
committed copy, so a route change cannot merge without a refreshed snapshot. A `pre-push` Git
hook runs the same check against your own changes, so most drift is caught before you push.

The CI job runs on the merged result, so it can also fail on a merge request that does not
touch routes at all, when someone else adds a route after you generated the snapshot. In that
case regenerating alone reports no change, and you need to rebase first:

```shell
git fetch origin master && git rebase origin/master
bundle exec rake gitlab:cells:routes:generate
```

### Generation environment

The Rails route table is not fixed. It depends on the Rails environment and on local
configuration, so generating the snapshot on two different machines can produce two different
files. To keep the output reproducible, the Rake task pins its environment and re-executes itself
if the environment does not already match:

- `RAILS_ENV=test` - the development and test environments each mount their own routes.
- `CI=true` - `config/environments/test.rb` skips the Sprockets `/assets` mount when `CI` is set.
- `GITLAB_CONFIG=config/gitlab.yml.example` - some routes are drawn from local configuration.
  OmniAuth and LDAP provider callback routes under `/users/auth/` come from `config/gitlab.yml`,
  so a GDK with an extra provider configured would generate extra entries. CI uses
  `config/gitlab.yml.example`, set up by `scripts/prepare_build.sh`, so the task uses it too.

The task also aborts when `FOSS_ONLY` is set. Under `FOSS_ONLY` the `ee/` routes are not drawn,
and the snapshot would be written without any EE route. This mirrors what
`Gitlab::JsRoutes.match_ci_env!` does for the generated JavaScript path helpers.

Because the snapshot is generated under `RAILS_ENV=test`, it is close to but not exactly the
production route table. Extra templates are harmless: they only ever add a reserved-word guard on
the router side. A missing template is the dangerous direction, because a real route would then
fall through to a broader classification rule. Routes that exist only in the test environment are
excluded explicitly by the generator, in
`Gitlab::Cells::HttpRouter::RoutesSnapshot::TEST_ONLY_TEMPLATES`.

### Update the HTTP Router

The HTTP Router downloads `config/routing/gitlab_routes.json` from GitLab. When a GitLab merge
request changes routes, update the HTTP Router snapshot in a paired merge request that downloads
the file from that GitLab branch. For details, see the
[HTTP Router development documentation](https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/development.md).

The HTTP Router derives its reserved-word route guards, in `src/generated_route_guards.ts`, from
this snapshot file. Because the snapshot is generated with `RAILS_ENV=test`, development-only
`/rails/*` routes, such as Lookbook, letter_opener, and mailer previews, are absent from it, so
regenerating the guards drops the `/rails/*` guard. That's fine: those routes only exist in
development, so a production guard for them serves no purpose, and no change is needed in the
router. GDK behavior is unchanged either way. With the guard, `/rails/*` goes straight to the
JSON rule engine; without it, the request falls through the top-level `/:ROUTE/*` classify rule,
fails to classify `rails` as a namespace route, and the handler catches that failure and falls
back to the same JSON rule engine, at the cost of one extra Topology Service call in development.
