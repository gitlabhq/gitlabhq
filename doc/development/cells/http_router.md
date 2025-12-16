---
stage: Runtime
group: Cells Infrastructure
info: Any user with at least the Maintainer role can merge updates to this content.
  For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

Coming soon

## Routing based on resource path

Coming soon

## Routing based on resource ID

Coming soon
