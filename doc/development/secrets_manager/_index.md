---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager development guidelines
ignore_in_report: true
---

GitLab Secrets Manager stores secrets in OpenBao, an open source secrets management engine.
GitLab runs OpenBao as a backing service and manages it through a Rails service layer.
All Secrets Manager code is GitLab Enterprise Edition (EE) only and lives under `ee/`.
The feature category is `secrets_management`.

Read the page that matches your task:

- [Set up Secrets Manager locally](local_setup.md) to get a working GitLab Development Kit (GDK) environment.
- [Secrets Manager architecture](architecture.md) for the data model, OpenBao namespace layout, and what GitLab sends the runner.
- [Secrets Manager change guidelines](change_guidelines.md) before you write or review any Secrets Manager change.
- [Secrets Manager states and side effects](states_and_side_effects.md) before you change provisioning, deprovisioning, secret writes, enrollment, or entitlement.
- [Secrets Manager fulfillment and entitlement](fulfillment.md) before you change trials, billing, entitlement checks, or read-only behavior.
- [Secrets Manager enrollment](enrollment.md) for namespace and instance enrollment and how availability uses them.
- [Secrets Manager services](services.md) to add or change a service.
- [Secrets Manager GraphQL API](graphql.md) to add or change a type, mutation, or resolver.
- [Secrets Manager OpenBao client and authentication](openbao_client.md) for the client, JWTs, Common Expression Language (CEL) programs, and access control list (ACL) policies.
- [Secrets Manager workers and policies](workers_and_policies.md) for background workers, cron jobs, authorization policies, and audit logs.
- [Secrets Manager performance](performance.md) before you change hot paths like CI job pickup, secret writes, or OpenBao calls.
- [Secrets Manager testing](testing.md) for spec helpers, factories, shared examples, and Kubernetes testing.
- [Secrets Manager frontend development](frontend.md) to work on the Vue application and its specs.

If you change behavior that a page describes, update the page in the same merge request.

## How it fits together

GitLab does not store secret values in PostgreSQL.
Values live in OpenBao.
PostgreSQL holds the `ProjectSecretsManager` and `GroupSecretsManager` records, which track provisioning state and the OpenBao mount configuration.

Each project or group that has Secrets Manager enabled gets its own OpenBao namespace.
For example, a namespace path might look like `org_1/group_2/project_1`.
There is no inheritance between OpenBao namespaces.
A token for one namespace can only read that namespace.
Cross-level access in CI, for example a project reading a group's secrets, is handled explicitly by GitLab, not by OpenBao.

GitLab authenticates to OpenBao with JWTs.
OpenBao validates these JWTs by fetching the GitLab OpenID Connect (OIDC) discovery document.
This means GitLab must be reachable over HTTP for OpenBao operations to work.

## Availability gates

Two conditions must both be true before Secrets Manager is available.
All checks go through `SecretsManagement::Availability` at `ee/lib/secrets_management/availability.rb`.

- License. The `native_secrets_management` licensed feature, which is available on Premium and above.
- Enrollment. On GitLab.com, enrollment is per top-level group (`SecretsManagement::NamespaceEnrollment`). On GitLab Self-Managed, including the GDK, enrollment is the instance-wide `secrets_manager_instance_enrolled` application setting, which defaults to `false`.

The gates are combined with AND.
Turning off enrollment makes Secrets Manager unavailable right away.
CI jobs picked up after that get no secrets, and jobs that are already running keep the secrets they received.

Entitlement is a separate, additional gate based on trial and billing status.
For details, see [Entitlement states](fulfillment.md#entitlement-states).

## Code map

Use this table to find where a given kind of Secrets Manager code lives.

| What | Where |
|------|-------|
| Models | `ee/app/models/secrets_management/` |
| Services | `ee/app/services/secrets_management/` |
| Service concerns | `ee/app/services/concerns/secrets_management/` |
| GraphQL types, mutations, resolvers | `ee/app/graphql/{types,mutations,resolvers}/secrets_management/` |
| Workers | `ee/app/workers/secrets_management/` |
| Policies | `ee/app/policies/secrets_management/` |
| OpenBao client, JWT, availability | `ee/lib/secrets_management/` |
| Rake tasks | `ee/lib/tasks/gitlab/secrets_management/` |
| Helpers | `ee/app/helpers/secrets_management/` |
| Frontend | `ee/app/assets/javascripts/ci/secrets/` |
| Backend tests | `ee/spec/{services,models,workers,requests,lib,helpers}/secrets_management/` |
| Frontend tests | `ee/spec/frontend/ci/secrets/` |

## Patterns to know before you write code

These patterns repeat across the Secrets Manager codebase.
Knowing them before you write code helps you avoid the most common bugs.

### Secrets are not ActiveRecord

Secret objects are `ActiveModel::Model` instances backed by OpenBao.
Do not expect `find_by`, scopes, or database joins to work on them.

### Two authorization layers

A request must pass both the Rails policy check and the OpenBao ACL policy.
Passing one is not enough.

### Provision before you read or write

The secrets manager record must be in the `active` state.
Services fail if it is still `provisioning`.

### Exclusive leases on writes

Write operations take an exclusive lease and fail immediately rather than retry.
Concurrent writes to the same project return an error.

### Metadata check-and-set

Updates pass a `metadata_cas` value that must match the current metadata version.
This stops two updates from silently overwriting each other, a pattern known as optimistic concurrency control.

### Two-phase writes

Writes are split into a start step and a complete step, so a failure leaves the secret closed rather than half-written.

### Sanitize errors

Never pass a raw OpenBao error back to the user.
Map it to a safe message instead.

### Groups are not projects

Project secrets take a `branch` parameter, and group secrets take a `protected` parameter.
The two sides also differ in default role grants and in how transfer works.
Check the group code path separately when you change project code.
For the full list, see [Project and group differences](states_and_side_effects.md#project-and-group-differences).

### Deprovision is task-driven and asynchronous

Deleting a secrets manager row fires a database trigger that records a deprovision task.
A worker reads the task and runs the OpenBao cleanup.
Cleanup can then finish after the parent project or group is already gone.

## Related documentation

- [Secrets Manager user documentation](../../ci/secrets/secrets_manager/_index.md)
- [Secrets Manager administration](../../administration/secrets_manager/_index.md)
