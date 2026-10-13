---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager architecture
ignore_in_report: true
---

Secrets Manager stores a data model in PostgreSQL, builds an OpenBao namespace layout, and computes
paths for projects, groups, and pipelines.
For state transitions and side effects, see [Secrets Manager states and side effects](states_and_side_effects.md).
For entitlement and billing, see [Secrets Manager fulfillment and entitlement](fulfillment.md).

## Data model

Two kinds of Ruby objects exist under `SecretsManagement`.

| Kind | Base class | Examples | Storage |
|------|-----------|----------|---------|
| Secrets manager records | `ApplicationRecord` | `ProjectSecretsManager`, `GroupSecretsManager` | PostgreSQL |
| Secret and permission objects | `ActiveModel::Model` | `ProjectSecret`, `GroupSecret`, `ProjectSecretsPermission`, `GroupSecretsPermission` | OpenBao, not a database table |

`ProjectSecret` and `GroupSecret` have no `find`, `where`, `save`, or database-backed validations.
They are built from OpenBao API responses.
An audit event must target the `Project` or `Group` record, never the secret object.

### Secrets manager tables

`SecretsManagement::BaseSecretsManager` is an abstract `ApplicationRecord` class.
It defines the `status` state machine and shared helper modules.
Two concrete subclasses map to two tables.

| Model | Table | Parent association |
|-------|-------|---------------------|
| `SecretsManagement::ProjectSecretsManager` | `project_secrets_managers` | `belongs_to :project` |
| `SecretsManagement::GroupSecretsManager` | `group_secrets_managers` | `belongs_to :group` |

`Project` and `Group` each expose the reverse side:

```ruby
# ee/app/models/ee/project.rb
has_one :secrets_manager, class_name: '::SecretsManagement::ProjectSecretsManager', inverse_of: :project

# ee/app/models/ee/group.rb
has_one :secrets_manager, class_name: '::SecretsManagement::GroupSecretsManager', inverse_of: :group
```

Both tables store `organization_id` and `root_namespace_id`, set on create from the parent's own IDs.
Both tables also still have `namespace_path`, `project_path`, `group_path`, and `root_namespace_path` columns.
These columns are declared with `ignore_column` on the models and are no longer read.
Path building is live, described in [Namespace path construction](#namespace-path-construction).
The columns are scheduled for removal in a later release.

### Other secrets manager tables

Secrets Manager also uses five more tables for supporting data.

| Model | Table | Purpose |
|-------|-------|---------|
| `RecoveryKey` | `secrets_management_recovery_keys` | Encrypted OpenBao recovery keys |
| `ProjectSecretRotationInfo` | `secret_rotation_infos` | Rotation reminder tracking for project secrets |
| `GroupSecretRotationInfo` | `group_secret_rotation_infos` | Rotation reminder tracking for group secrets |
| `ProjectSecretsManagerMaintenanceTask` | `project_secrets_manager_maintenance_tasks` | Provision and deprovision tasks for a project |
| `GroupSecretsManagerMaintenanceTask` | `group_secrets_manager_maintenance_tasks` | Provision and deprovision tasks for a group |

For how maintenance tasks and the destroy trigger work together, see [Side effects on state transitions](states_and_side_effects.md#side-effects-on-state-transitions).

## Model helper modules

`BaseSecretsManager` includes shared helper modules that both scopes use as is.
Each subclass also includes its own helper modules, which add scope-specific methods or override shared ones.

| Layer | Module | File | Defines |
|-------|--------|------|---------|
| Shared | `SecretsManagement::SecretsManagers::PipelineHelper` | `ee/app/models/secrets_management/secrets_managers/pipeline_helper.rb` | `ci_secrets_mount_path`, `ci_data_path`, `ci_full_path`, `ci_metadata_full_path`, `detailed_metadata_path`, `ci_auth_mount`, `ci_auth_role`, `ci_jwt` |
| Shared | `SecretsManagement::SecretsManagers::UserHelper` | `ee/app/models/secrets_management/secrets_managers/user_helper.rb` | `user_auth_mount`, `user_auth_role`, `policy_name_for_principal`, `user_path`, `role_path` |
| Project | `SecretsManagement::ProjectSecretsManagers::PipelineHelper` | `ee/app/models/secrets_management/project_secrets_managers/pipeline_helper.rb` | `ci_auth_path`, `pipeline_auth_cel_program`, `ci_secrets_mount_full_path`, `ci_policy_name` and its variants |
| Project | `SecretsManagement::ProjectSecretsManagers::UserHelper` | `ee/app/models/secrets_management/project_secrets_managers/user_helper.rb` | `user_auth_cel_program` |
| Group | `SecretsManagement::GroupSecretsManagers::PipelineHelper` | `ee/app/models/secrets_management/group_secrets_managers/pipeline_helper.rb` | `ci_auth_path`, `ci_secrets_mount_full_path`, `ci_policy_name_for_environment`, `pipeline_auth_cel_program` |
| Group | `SecretsManagement::GroupSecretsManagers::UserHelper` | `ee/app/models/secrets_management/group_secrets_managers/user_helper.rb` | `user_auth_cel_program` |

When you add a helper method, put it in the shared module if both scopes need the same behavior.
Put it in the project or group module if the scope needs its own logic, for example a different CEL
program or a different policy naming scheme.

## OpenBao namespace hierarchy

Every project or group with Secrets Manager enabled gets its own three-level OpenBao namespace.

| Level | Segment | Built from |
|-------|---------|------------|
| 1 | `org_<organization_id>` | The parent's `organization_id` |
| 2 | `group_<root_namespace_id>` | The parent's top-level group ID |
| 3 | `project_<project_id>` or `group_<group_id>` | The project or group's own ID |

The GitLab subgroup hierarchy is flattened at level 3.
A project in a deeply nested subgroup still gets `org_<X>/group_<root>/project_<P>`, not one segment per
subgroup.
A top-level group's own secrets manager reuses its own ID at both level 2 and level 3, for example
`org_1/group_5/group_5`.
Secrets Manager does not support user namespaces.

### Namespace path construction

Paths are computed live at call time, not read from a stored column.
Both `ProjectSecretsManager` and `GroupSecretsManager` include a shared `PathBuilder` module
(`ee/app/models/secrets_management/path_builder.rb`) with the level 1 and level 2 builders:

```ruby
def build_org_path(organization_id)
  "org_#{organization_id}"
end

def build_root_namespace_path(root_namespace_id)
  "group_#{root_namespace_id}"
end
```

Each model computes its own level 3 segment and joins all three:

```ruby
# ProjectSecretsManager
def org_path
  self.class.build_org_path(project.organization_id)
end

def namespace_path
  self.class.build_root_namespace_path(project.root_ancestor.id)
end

def project_path
  self.class.build_project_path(project.id)
end

def full_project_namespace_path
  [org_path, namespace_path, project_path].join('/')
end
```

The `GroupSecretsManager` equivalent builds `full_group_namespace_path` from `group.organization_id`,
`group.root_ancestor.id`, and `group.id`.
Because the path depends on the live parent record, code that runs after the parent project or group is
destroyed cannot call these methods.
That code must use IDs stored elsewhere, described in [Checklist for changes](change_guidelines.md#checklist-for-changes).

## Scope isolation and cross-level access

Each project, subgroup, and top-level group is its own OpenBao namespace.
There is no namespace inheritance.
A login is scoped to one namespace and reads only that namespace's secrets.
A project's namespace does not automatically expose its parent group's secrets.

### CI access to a parent group's secrets

CI reads a parent group's secrets through multiple logins, not through inheritance.
A project pipeline authenticates directly to the group's own namespace auth mount, in addition to its own
project namespace.
The group's pipeline CEL program accepts the project's pipeline JSON Web Token (JWT) and checks that the
project is a descendant of the group, using the `project_group_ids` claim.

The claim is set when the JWT is built:

```ruby
# ee/lib/secrets_management/pipeline_jwt.rb
def project_group_ids
  source_project.group&.self_and_ancestors&.pluck(:id)&.map(&:to_s) || []
end
```

The group's pipeline CEL program then checks the claim contains the group's own ID:

```ruby
# ee/app/models/secrets_management/group_secrets_managers/pipeline_helper.rb
{ name: "project_gids",
  expression: %q(('project_group_ids' in claims) ? claims['project_group_ids'] : []) }
```

A project does not need its own secrets manager to pull a parent group's secrets this way.
The group must be the project's group or an ancestor of it.
Its secrets manager must be active, Secrets Manager must be available for the group, and the top-level group's entitlement must allow direct reads.

### The non-CI API path has no cross-level access

The direct access-token path validates the token's own `project_id` or `group_id` against the namespace
it logs into.
A project-scoped token reads only that project's secrets.
A group-scoped token reads only that group's secrets.
To read group-level secrets outside CI, the client uses a group-scoped token.
There is no equivalent of `project_group_ids` on this path.

## What GitLab sends the runner

`EE::Ci::BuildRunnerPresenter` sends the runner an auth path and a secrets mount path in the job payload.
It does not send a namespace format for the runner to build itself.

```ruby
def gitlab_projects_secrets_manager_server(project_secrets_manager)
  {
    'url' => SecretsManagement::ProjectSecretsManager.server_url,
    'inline_auth' => {
      'jwt' => project_secrets_manager.ci_jwt(self),
      'role' => project_secrets_manager.ci_auth_role,
      'path' => project_secrets_manager.ci_auth_path
    }.compact
  }
end
```

```ruby
def project_secrets_manager_payload(secret)
  return {} unless project_secrets_manager_available?

  project_secrets_manager = SecretsManagement::ProjectSecretsManager.find_by_project_id(project.id)
  return {} unless project_secrets_manager&.active?

  {
    'engine' => { 'name' => "kv-v2", 'path' => project_secrets_manager.ci_secrets_mount_full_path },
    'path' => project_secrets_manager.sanitized_ci_data_path(secret['gitlab_secrets_manager']['name']),
    'field' => "value",
    'server' => gitlab_projects_secrets_manager_server(project_secrets_manager)
  }
end
```

The group equivalent, `group_secrets_manager_payload`, builds the same shape from
`GroupSecretsManager#ci_auth_path` and `ci_secrets_mount_full_path`.
Because the runner has no hardcoded path format, a change to how GitLab builds namespace paths is
transparent to the runner, as long as the OpenBao namespaces match what GitLab computes.

## Secrets storage paths in OpenBao

In a namespace, secrets use the key-value version 2 (KV-v2) engine, mounted at a fixed path:

```ruby
# ee/app/models/secrets_management/secrets_managers/pipeline_helper.rb
SECRETS_MOUNT_PATH = "secrets/kv"
DATA_ROOT = "explicit"
```

These constants build the full paths used for reads and writes:

| Path kind | Shape |
|-----------|-------|
| Mount, namespaced | `<namespace>/secrets/kv` |
| Secret data | `secrets/kv/data/explicit/<secret_name>` |
| Metadata | `secrets/kv/metadata/explicit/<secret_name>` |
| Detailed metadata | `secrets/kv/detailed-metadata/explicit/<secret_name>` |

A secret's KV path is keyed by its name in the namespace.
`environment` and `branch` are not separate paths.
They are stored as custom metadata on the same KV entry.

## Secret attributes

`ProjectSecret` and `GroupSecret` both inherit shared attributes from `BaseSecret`: `name`,
`description`, `environment`, `rotation_info`, `metadata_version`, and the create and update
timestamp pairs used to compute secret status, described in [States that can combine](states_and_side_effects.md#states-that-can-combine).

| Model | Extra attributes |
|-------|-------------------|
| `ProjectSecret` | `project`, `branch` |
| `GroupSecret` | `group`, `protected` |

### Name validation

The secret model validates each name with a fixed pattern and a length limit.

```ruby
SECRET_NAME_FORMAT = /\A[a-zA-Z0-9_]+\z/

validates :name,
  presence: true,
  length: { maximum: 255 },
  format: { with: SECRET_NAME_FORMAT, message: "can contain only letters, digits and '_'." }
```

A secret name can contain only letters, digits, and underscores, up to 255 characters.
A service that reads a secret by name must validate the name before calling OpenBao, to prevent
injection in the path.

## Secrets limits

Secrets limits are application settings, stored in the `secrets_manager_settings` JSON column on
`ApplicationSetting`.

| Setting | Default | Meaning |
|---------|---------|---------|
| `project_secrets_limit` | 100 | Maximum secrets per project. Zero means unlimited. |
| `group_secrets_limit` | 500 | Maximum secrets per group. Zero means unlimited. |

Each secrets manager model reads its own limit through `Gitlab::CurrentSettings`:

```ruby
# ProjectSecretsManager
def secrets_limit
  Gitlab::CurrentSettings.project_secrets_limit || DEFAULT_SECRETS_LIMIT
end
```
