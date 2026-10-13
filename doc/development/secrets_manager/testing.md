---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager testing
ignore_in_report: true
---

Secrets Manager backend specs run against a real OpenBao development server.
Frontend specs do not need OpenBao. For those, see [Secrets Manager frontend development](frontend.md).

## Backend specs

Any spec that talks to OpenBao must carry the `:gitlab_secrets_manager` RSpec tag.
The tag is wired up in `ee/spec/spec_helper.rb`.

The tag does the following automatically for each example:

- Stubs the `native_secrets_management` licensed feature.
- Stubs `ci_jwt_signing_key` with a test key pair from `ee/spec/fixtures/secrets_manager/`.
- Starts a local OpenBao development server.
- Configures JWT auth.
- Resets the key-value (KV) secrets engines after the example finishes.

The first tagged spec run builds the OpenBao test binary, so expect it to take a while.
Later runs reuse the binary.
Use `:skip_openbao_setup` metadata to opt an example out of the server setup.

Example commands:

```shell
bundle exec rspec ee/spec/services/secrets_management/
bundle exec rspec ee/spec/requests/api/graphql/secrets_management/
```

Enrollment test helpers (`SecretsManagement::EnrollmentHelpers`) are included for all Enterprise Edition (EE) specs, so you do not need the `:gitlab_secrets_manager` tag just to set up enrollment.

Specs use a hard-coded JSON Web Key Set (JWKS) instead of OpenID Connect (OIDC) discovery, so specs do not need a running web server.
Local manual testing does need one.

## Spec helper modules

These modules live under `ee/spec/support/helpers/secrets_management/` and are wired up in `ee/spec/spec_helper.rb`.

| Module | Included for | Provides |
|--------|--------------|----------|
| `SecretsManagement::GitlabSecretsManagerHelpers` | Specs tagged `:gitlab_secrets_manager` | Provisioning, create, read, update, and delete (CRUD) on secrets, permission updates, and OpenBao state assertions. |
| `SecretsManagement::EnrollmentHelpers` | All EE specs | Instance enrollment and entitlement stubbing. |
| `SecretsManagement::CapabilityHelpers` | All EE specs | Stubbing the live OpenBao capabilities lookup used by UI elements that only show when the user has the capability. |

`SecretsManagement::GitlabSecretsManagerHelpers` is the main OpenBao helper module.
Its key methods:

- `provision_project_secrets_manager(secrets_manager, user, auto_enroll: true)` and `provision_group_secrets_manager(secrets_manager, user, auto_enroll: true)`. Run the real provision service against the test OpenBao server. `auto_enroll` calls `enroll_instance_in_secrets_manager` first.
- `deprovision_project_secrets_manager(secrets_manager, user)` and `deprovision_group_secrets_manager(secrets_manager, user)`. Build a deprovision maintenance task and run the deprovision service.
- `create_project_secret(user:, project:, name:, branch:, environment:, value:, ...)` and `create_group_secret(user:, group:, name:, protected:, environment:, value:, ...)`. Run the create service and return the resulting secret.
- `update_project_secrets_permission(user:, project:, principal:, actions:, expired_at:)` and `update_group_secrets_permission(...)`. Run the permission update service.
- Assertion helpers such as `expect_kv_secret_to_have_value`, `expect_kv_secret_to_have_custom_metadata`, `expect_kv_secret_not_to_exist`, `expect_jwt_auth_engine_to_be_mounted`, `expect_jwt_cel_role_to_exist`, `expect_policy_to_exist`, `expect_namespace_to_exist`, and their negative counterparts. Each takes the OpenBao namespace path and mount or policy details to check.
- `cancel_exclusive_project_secret_operation_lease(project)` and `cancel_exclusive_group_secret_operation_lease(group)`. Release a held exclusive lease between examples.
- `secret_rotation_info_for_project_secret(project, name, version)` and `secret_rotation_info_for_group_secret(group, name, version)`. Look up a `ProjectSecretRotationInfo` or `GroupSecretRotationInfo` row.
- `secrets_manager_client`. Returns a `SecretsManagement::TestClient`, a root-level OpenBao client for direct low-level assertions.

`SecretsManagement::EnrollmentHelpers` provides:

- `enroll_instance_in_secrets_manager`. Stubs the instance as enrolled and calls `stub_secrets_manager_entitlement`.
- `stub_secrets_manager_entitlement(state: :paid, blocked_reason: :grace)`. Stubs `SecretsManagement::Entitlement.for` to return a given state. See [Secrets Manager fulfillment and entitlement](fulfillment.md) for what each state means.

## Factories for provisioned Secrets Manager records

| Factory | Class | Notable traits |
|---------|-------|----------------|
| `:project_secrets_manager` | `SecretsManagement::ProjectSecretsManager` | One trait per key in `STATUSES` (for example `:provisioning`, `:active`, `:deprovisioning`). |
| `:group_secrets_manager` | `SecretsManagement::GroupSecretsManager` | Same pattern as the project factory. |
| `:project_secrets_manager_maintenance_task` | `SecretsManagement::ProjectSecretsManagerMaintenanceTask` | `:provision`, `:deprovision`, `:processing`, `:stale`. |
| `:group_secrets_manager_maintenance_task` | `SecretsManagement::GroupSecretsManagerMaintenanceTask` | Same traits as the project maintenance task factory. |
| `:project_secret_rotation_info` | `SecretsManagement::ProjectSecretRotationInfo` | None. |
| `:group_secret_rotation_info` | `SecretsManagement::GroupSecretRotationInfo` | None. |
| `:namespace_secret_count` | `SecretsManagement::NamespaceSecretCount` | None. |
| `:secrets_manager_namespace_enrollment` | `SecretsManagement::NamespaceEnrollment` | `:disabled`, `:add_on_requested`. |
| `:sm_recovery_key` | `SecretsManagement::RecoveryKey` | None. |

Building a factory record with the `:active` trait only sets the `status` column.
It does not provision anything in OpenBao.
To get a fully provisioned secrets manager in a spec, create the record, then call the matching `provision_*_secrets_manager` helper:

```ruby
let(:secrets_manager) { create(:project_secrets_manager, project: project) }

before do
  provision_project_secrets_manager(secrets_manager, user)
end
```

## Shared examples and shared contexts

Model, service, and worker specs reuse behavior through `RSpec.shared_examples` blocks under `ee/spec/support/shared_examples/`.
Most service-level examples take a `resource_type` argument (`'project'` or `'group'`), for example `it_behaves_like 'a service for creating a secret', 'project'`.

| Category | Directory | Examples |
|----------|-----------|----------|
| Models | `shared_examples/models/secrets_management/` | `'a secrets manager'`, `'a secrets manager maintenance task'`, `'a secret model'`, `'a secrets permission'`, `'a secret rotation info'`. |
| Provision and deprovision | `shared_examples/services/secrets_management/` | `'a secrets manager initialize service'`, `'a secrets manager provision service'` (plus `granting the Maintainer default` and `not granting` variants), `'a secrets manager deprovision service'`, `'a secrets manager deprovision worker'`. |
| Secret CRUD | `shared_examples/services/secrets_management/` | `'a service for creating a secret'`, `'a service for updating a secret'`, `'a service for deleting a secret'`, `'a service for listing secrets needing rotation'`, `'a batch reminder service processing secrets'`. |
| Permissions | `shared_examples/services/secrets_management/` | `'a service for listing secrets permissions'`, `'a service for updating secrets permissions'`, `'a service for deleting secrets permissions'`. |
| Entitlement and leases | `shared_examples/services/secrets_management/` | `'a secrets manager entitlement gate'`, `'an operation requiring an exclusive project secret operation lease'`, `'an operation requiring an exclusive group secret operation lease'`. |
| Workers | `shared_examples/workers/secrets_management/` | `'a secrets manager provision worker'`, `'a secrets manager maintenance tasks cron worker'`, `'a secrets manager reap orphan tasks cron worker'`, `'a secret rotation reminder batch worker'`. |
| GraphQL requests | `shared_examples/requests/api/graphql/secrets_management/` | `'a GraphQL mutation for updating secrets permissions'`, `'a GraphQL mutation for deleting secrets permissions'`, `'a GraphQL query for listing secrets permissions'`, `'a secrets manager mutation blocked on entitlement'`, `'a secrets manager delete mutation gated on entitlement'`, `'a delete that still runs under a read-only entitlement'`, `'a secrets manager mutation blocked on an inactive namespace'`. |
| Non-GraphQL requests | `shared_examples/requests/secrets_management/` | `'an API request requiring an exclusive project secret operation lease'`, `'an API request requiring an exclusive group secret operation lease'`. |

The deprovision shared examples in `deprovision_service_examples.rb` need the including spec to define, through `let`:
`secrets_manager`, `maintenance_task`, `service`, `result`, `payload_key`, `find_sm_target`, `parent_fk_column` (`:project_id` or `:group_id`), and an `expect_no_policies_at(full_path)` method.
Read the file header comment for the exact contract.

Per-record and bulk `InitiateDeprovisionService` specs are not shared, because the project and group surfaces take different keyword arguments.
They live directly in `ee/spec/services/secrets_management/project_secrets_managers/initiate_deprovision_service_spec.rb` and the equivalent `group_secrets_managers/` spec.

## Standard structure of a service spec that talks to OpenBao

```ruby
RSpec.describe SecretsManagement::ProjectSecrets::CreateService,
  :gitlab_secrets_manager, feature_category: :secrets_management do
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:secrets_manager) { create(:project_secrets_manager, project: project) }
  let(:service) { described_class.new(project, user) }

  before_all do
    project.add_owner(user)
  end

  it_behaves_like 'a service for creating a secret', 'project'

  describe '#execute', :aggregate_failures, :freeze_time do
    before do
      provision_project_secrets_manager(secrets_manager, user)
    end

    it 'creates a project secret' do
      result = service.execute(name: 'SECRET', value: 'val', environment: '*', branch: '*')
      expect(result).to be_success
    end
  end
end
```

Common patterns in these specs:

- Always provision the secrets manager in a `before` block, not in `let`, so the OpenBao side effect runs once per example.
- Use `:freeze_time` when the behavior depends on timestamps, for example the stale-provisioning threshold.
- Use `:aggregate_failures` when an example makes several related assertions.
- Test permission scenarios by creating a user with a role and, where needed, granting an explicit permission with `update_project_secrets_permission` or `update_group_secrets_permission` before asserting success.
- Use WebMock to simulate OpenBao failures, for example a timeout after a partial write:

  ```ruby
  before do
    webmock_enable!(allow_localhost: false)
    stub_request(:post, secret_create_path).to_timeout
  end

  after do
    webmock_enable!(allow_localhost: true)
    WebMock.reset!
  end
  ```

## Entitlement and enrollment stubs

Use `stub_secrets_manager_entitlement(state:, blocked_reason:)` from `SecretsManagement::EnrollmentHelpers` to control what `SecretsManagement::Entitlement.for` returns in a spec, instead of stubbing CustomersDot or the add-on purchase mirror directly.
With the default state (`:paid`), code that needs an entitlement still runs, without modeling a subscription.
Specs that exercise a specific entitlement state re-stub it with the state under test, for example `state: :blocked, blocked_reason: :grace`.

`enroll_instance_in_secrets_manager` stubs instance-level enrollment and calls `stub_secrets_manager_entitlement`.
Call it directly in specs that exercise code blocked by availability checks, without going through `provision_project_secrets_manager` or `provision_group_secrets_manager`, which call it for you.

For the GitLab.com namespace-enrollment branch, set `Gitlab.com?` and create a `:secrets_manager_namespace_enrollment` factory record instead of relying on instance enrollment.

For what each entitlement state means, see [Entitlement states](fulfillment.md#entitlement-states).

## QA end-to-end specs

Browser UI end-to-end specs live under `qa/qa/specs/features/ee/browser_ui/10_software_supply_chain_security/secrets_management/`.
This splits into `project_secrets_manager/` and `group_secrets_manager/` directories.
Each has `permissions/` and `project_secret/` or `group_secret/` subdirectories, for CRUD, access control, and audit event coverage.

Supporting code lives in:

- `qa/qa/ee/page/project/secure/secrets_manager.rb` and `qa/qa/ee/page/group/secure/secrets_manager.rb`. Page objects for the Secrets Manager UI.
- `qa/qa/ee/page/component/secrets_manager_permissions.rb` and `secrets_manager_settings.rb`. Shared page components.
- `qa/qa/ee/support/helpers/secrets_management/secrets_manager_helper.rb`. End-to-end test helpers.
- `qa/qa/specs/features/shared_contexts/secrets_management/secret_permission_shared_context.rb` and `group_secret_permission_shared_context.rb`. Shared contexts for permission specs.

## Kubernetes cluster testing

The GDK cannot cover every case.
If you need OpenBao running inside a Kubernetes cluster, for example to test the External Secrets Operator against it, use [Caproni](https://gitlab.com/gitlab-org/caproni), which deploys GitLab and OpenBao to a local cluster.
For support, ask in the `#proj_caproni` Slack channel.
