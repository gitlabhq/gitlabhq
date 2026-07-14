---
title: How organizations get created
---

Creating an organization happens through several independent paths today, and they do not all
share the same gate.
This page is an audit of every path, and what stands between an actor and a created
organization.
It documents the current state, not a target.
Each path is expected to move into the
[organizations release process](release_process.md) eventually, gradually, one at a time.

## Creation paths

| Entry point | Current gate |
|--------------|--------------|
| [Self-serve flow](#self-serve-flow) | `organization_switching` feature flag and the `:create_organization` ability |
| [GraphQL mutation](#graphql-mutation) | The `:create_organization` ability only |
| [REST API](#rest-api) | `organization_switching` feature flag, the `:create_organization` ability, and a rate limit |
| [Top-level group backfill and confirm](#top-level-group-backfill-and-confirm-ops) | ChatOps production access to two ops feature flags |

### Self-serve flow

The "New organization" form (`Organizations::OrganizationsController#new`), its navigation entry
(`Nav::NewDropdownHelper`), and the "New" control on the organization list and the admin
organization list (`Organizations::OrganizationHelper#shared_organization_index_app_data`) all
check the `organization_switching` feature flag and the `:create_organization` ability.

Only the form enforces this, on the server, through `authorize_create_organization!`.
The navigation entry and the "New" control are visibility only, not enforcement.

### GraphQL mutation

The self-serve flow submits to `Mutations::Organizations::Create`.
The mutation checks the `:create_organization` ability, but not the `organization_switching`
feature flag.
It then calls `Organizations::CreateService`, which checks the ability again.
Anyone with GraphQL access and the ability can call this mutation directly, bypassing the
self-serve flow entirely.

### REST API

`POST /organizations` (`lib/api/organizations.rb`) checks the `organization_switching` feature
flag, the `:create_organization` ability, and a rate limit, then calls
`Organizations::CreateService`, which checks the ability and the feature flag again.
This path is independent of the self-serve flow, and reachable with a personal access token.

### Top-level group backfill and confirm (ops)

This path is the manual process for onboarding beta customers.
It has two ChatOps-triggered steps, each an event-subscriber worker reacting to an actor-scoped
ops feature flag:

- `Organizations::RootGroupOrganizationBackfillWorker` subscribes to
  `root_group_organization_backfill`. On enable, it creates the organization as unconfirmed and
  transfers the group into it.
- `Organizations::ConfirmWorker` subscribes to `root_group_organization_confirm`. On enable, it
  confirms the organization through `Organizations::ConfirmService`.

Both workers call their service with `skip_authorization: true`, bypassing the ability and every
other gate on this page.
Access is gated only by who can run ChatOps commands in production.

## The `:create_organization` ability

Several of the paths above also depend on the `:create_organization` ability, defined in
`app/policies/global_policy.rb`.
The ability has no role or ownership requirement.
It resolves to true for any authenticated user when both of the following are true:

- The instance is GitLab.com. The ability is prevented outright on every other instance.
- The `can_create_organization` application setting is enabled. This setting defaults to `true`
  and has no other restriction.

In practice, the feature flag layer is the only thing narrowing who can create an organization
today, not the ability.

## Instance bootstrap

Two paths create an organization without an actor, and run only once, during instance setup:

- `Gitlab::DatabaseImporters::DefaultOrganizationImporter` creates the default organization every
  instance gets, from the `db/fixtures/production/002_default_organization.rb` fixture.
- `Gitlab::DatabaseImporters::AdminOrganizationImporter` creates a per-cell organization for the
  seeded administrator on any cell that does not own the default organization, from the
  `db/fixtures/production/003_admin.rb` fixture.

Neither path is reachable outside instance provisioning, and neither is part of the table above.
