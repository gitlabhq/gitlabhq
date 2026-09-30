---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager development guidelines
ignore_in_report: true
---

GitLab Secrets Manager stores secrets in OpenBao, an open source secrets management engine.
GitLab runs OpenBao as a backing service and manages it through a Rails service layer.
All Secrets Manager code is EE-only and lives under `ee/`.
The feature category is `secrets_management`.
If you are new to the team, start with [Set up Secrets Manager locally](local_setup.md) to get a working environment first.

Most of this page covers backend work, meaning the Rails service layer, the OpenBao client, and RSpec.
Frontend work needs a smaller setup, covered in [Frontend development](#frontend-development) on this page.

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
OpenBao validates these JWTs by fetching the GitLab OIDC discovery document, so GitLab must be reachable over HTTP for OpenBao operations to work.

## Availability gates

Three conditions must all be true before Secrets Manager is available.
All checks go through `SecretsManagement::Availability` at `ee/lib/secrets_management/availability.rb`.

- License. The `native_secrets_management` licensed feature, which is available on Premium and above.
- Feature flag. `secrets_manager` for projects, `group_secrets_manager` for groups. Both are `type: beta` and `default_enabled: true`.
- Enrollment. On GitLab.com, enrollment is per top-level group (`SecretsManagement::NamespaceEnrollment`). On GitLab Self-Managed, including the GDK, enrollment is the instance-wide `secrets_manager_instance_enrolled` application setting, which defaults to `false`.

The gates are combined with AND.
Turning off the feature flag, or removing the enrollment record, makes Secrets Manager unavailable right away, including for CI jobs that are already running.

## Code map

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
The check provides optimistic concurrency control.

### Two-phase writes

Writes are split into a start step and a complete step, so a failure leaves the secret closed rather than half-written.

### Sanitize errors

Never pass a raw OpenBao error back to the user.
Map it to a safe message instead.

### Groups are not projects

Project secrets take a `branch` parameter, group secrets take a `protected` parameter.
They also differ in policy refresh timing and helper locations.
Check the group code path separately when you change project code.

### Deprovision is task-driven and asynchronous

An initiate service records a maintenance task with snapshot IDs, and a worker reads the task and runs the OpenBao cleanup.
Cleanup can then finish after the parent project or group is already gone.

## Testing

Any spec that talks to OpenBao must carry the `:gitlab_secrets_manager` RSpec tag.
The tag is wired up in `ee/spec/spec_helper.rb`.

The tag does the following automatically for each example:

- Stubs the `native_secrets_management` licensed feature.
- Stubs `ci_jwt_signing_key` with a test key pair from `ee/spec/fixtures/secrets_manager/`.
- Starts a local OpenBao development server.
- Configures JWT auth.
- Resets the KV secrets engines after the example finishes.

The first tagged spec run builds the OpenBao test binary, so expect it to take a while.
Later runs reuse the binary.
Use `:skip_openbao_setup` metadata to opt an example out of the server setup.

Example commands:

```shell
bundle exec rspec ee/spec/services/secrets_management/
bundle exec rspec ee/spec/requests/api/graphql/secrets_management/
```

Enrollment test helpers (`SecretsManagement::EnrollmentHelpers`) are included for all EE specs, so you do not need the `:gitlab_secrets_manager` tag just to set up enrollment.

Specs use a hard-coded JWKS instead of OIDC discovery, so specs do not need a running web server.
Local manual testing does need one.

## Testing against a Kubernetes cluster

The GDK cannot cover every case.
If you need OpenBao running inside a Kubernetes cluster, for example to test the External Secrets Operator against it, use [Caproni](https://gitlab.com/gitlab-org/caproni), which deploys GitLab and OpenBao to a local cluster.
For support, ask in the `#proj_caproni` Slack channel.

## Frontend development

The Secrets Manager frontend is a Vue application with Vue Router and Apollo.
It lives at `ee/app/assets/javascripts/ci/secrets/`, and `index.js` mounts `components/secrets_app.vue`.

### Code layout

- `components/secrets_table/`, `components/secret_form/`, and `components/secret_details/` hold the feature components.
- `graphql/queries/` and `graphql/mutations/` hold the GraphQL documents, colocated with the app.
- `router.js` defines the routes, and `constants.js` and `context_config.js` hold the shared configuration.
- The settings toggle component is outside this tree, at `ee/app/assets/javascripts/pages/projects/shared/permissions/secrets_manager/`.

### Running frontend tests

Specs live at `ee/spec/frontend/ci/secrets/`, mirroring the source layout.
Run them with this command:

```shell
yarn jest ee/spec/frontend/ci/secrets/
```

The specs mock the GraphQL layer with `createMockApollo`, so they do not need OpenBao, a license, or enrollment.
You can run the whole suite against a plain GDK.
Shared fixtures are in `ee/spec/frontend/ci/secrets/mock_data.js`.

You still need the full backend setup, described in the local setup page, when you want to exercise the feature in a browser rather than in a spec.

For more general frontend guidance, see:

- [Frontend development guidelines](../fe_guide/_index.md)
- [Frontend testing guide](../testing_guide/frontend_testing.md)

## Related documentation

- [Secrets Manager user documentation](../../ci/secrets/secrets_manager/_index.md)
- [Secrets Manager administration](../../administration/secrets_manager/_index.md)
