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
