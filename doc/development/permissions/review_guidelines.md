---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Authorization code review guidelines
---

This page provides guidance from the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization) on how to prepare a merge request that involves policy changes, permission definitions, and authorization logic for review.

Apply these guidelines to any change that adds, removes, or changes a permission check, wherever the check is.
Permission checks include `can?`, `Ability.allowed?`, `authorize!`, GraphQL `authorize`, and `route_setting :authorization`.
They can appear in policies, controllers, services, finders, models, helpers, workers, views, and REST or GraphQL code.

## Review checklist

Use this list when you review or prepare an MR that touches authorization.
Each item links to the section with details.

- [Permission names](#permission-design) follow the conventions, match the action, and are not duplicates.
- [Role grants](#role-yaml-changes) live in role YAML, and every role that should have the permission still gets it.
- [Policy rules](#anti-patterns) only restrict with `prevent` (except the [private-permission pattern](#exception-private-permissions)), do not look up access levels, do not derive a permission from [other permissions](#do-not-derive-a-permission-from-other-permissions), and do not grant access from another resource.
- [Condition names](#name-conditions-for-what-they-check) describe what the condition checks, and `can?(:read_project)` is [not used as a membership check](#do-not-use-canread_project-as-a-membership-check).
- [Custom roles](#custom-roles) are checked when a cascade (one permission enabling another), name, or permission is removed or changed.
- [Enforcement](#where-to-enforce) uses the policy in every entry point, including services and finders, unless an [exception](authorizations.md#exceptions) applies.
- [Granular tokens](#granular-token-authorization) are declared or explicitly opted out for every new endpoint.
- [GraphQL authorization](#graphql-authorization) is on the type where possible, rather than on individual fields.
- [Specs](#testing) cover every policy change, with real memberships and settings instead of stubs.
- [`Gitlab/Authz` cops](#automated-checks) are not disabled. Any unavoidable disable is approved by the Authorization team.

## Role YAML files are the source of truth

[Role definition YAML files](role_definitions.md) (`config/authz/roles/*.yml`)
are the single source of truth for which permissions each role has. Policy files
should not contain `enable` rules that grant permissions based on role conditions.
Instead, add the permission to the appropriate role YAML file and use `prevent`
rules in the policy to restrict access when a feature or setting is not available.

```ruby
# bad - enabling a permission for a role in a policy file
rule { developer & model_registry_enabled }.policy do
  enable :write_model_registry
end

# good - permission is in the developer role YAML
# (config/authz/roles/developer.yml)
#   raw_permissions:
#     - write_model_registry
#
# Policy only restricts when the feature is unavailable:
rule { ~model_registry_enabled }.prevent :write_model_registry
```

This pattern makes role permissions:

- **Machine-readable**: External systems like GATE can determine a role's
  permissions without evaluating policy logic.
- **Enumerable**: You can see every permission a role has by reading one YAML file.
- **Predictable**: Roles always start with their full set of permissions.
  Conditions only remove access, never expand it.

## File organization

All `prevent` rules for the same condition should be in one `.policy` block, not
scattered across the file.

```ruby
# bad - prevents for the same condition scattered across the file
rule { ~security_dashboard_enabled }.prevent :read_vulnerability
rule { ~security_dashboard_enabled }.prevent :admin_vulnerability

# good - all prevents for the same condition grouped together
rule { ~security_dashboard_enabled }.policy do
  prevent :admin_vulnerability
  prevent :read_vulnerability
end
```

## Permission design

Naming is the most common review topic.
Follow the [permission naming conventions](conventions.md#naming-permissions), and check these points first.

### Match the permission to the action

Read actions use a read permission, and mutating actions use a mutating permission.
Do not check a permission whose action implies a state change, such as `start_` or `update_`, on a field or endpoint that only reads data.
Do not guard a write with a read permission.

### Do not encode how or where access happens

Do not put the access path or the boundary in the name, because the subject passed to the check carries it.
For example, `read_widget_via_parent_group` should be `read_widget`.
See [Avoiding resource boundaries in permission names](conventions.md#avoiding-resource-boundaries-in-permission-names).

### Reuse before adding

Search for an existing permission before you add one, and do not reuse one permission for different meanings.
See [Introducing new permissions](conventions.md#introducing-new-permissions).

### Describe what the permission gates

A description says what the permission gates.
Do not mention which roles have it, because roles can change.

### Complete the definition files

Create a complete [permission definition file](granular_access/permission_definitions.md) for every new permission.
Do not add entries to the legacy to-do lists: `config/authz/permissions/definitions_todo.txt` and `config/authz/graphql/authorization_todo.txt`.

## Role YAML changes

When you move or add permissions in [role YAML files](role_definitions.md), behavior must stay the same for every role that should have the permission.

- Update both the `group` and `project` sections when the permission applies to both.
- Check `public_anonymous` and `guest` when the permission was previously enabled through a broad read permission.
- New `read_*` permissions usually belong in the `auditor` role.
  Do not add permissions that change project or group data.
- Add the permission wherever sibling permissions are already prevented, such as the archived and pending deletion lists in `config/authz/permission_groups/internal/` or feature availability rules.
  Otherwise the new permission bypasses those restrictions.
- Do not re-add a permission the role already gets through `inherits_from`.
- Add net-new permissions through an assignable permission group.
  Use `raw_permissions` only to move existing permissions.
  See [Modifying an existing role](role_definitions.md#modifying-an-existing-role).

## Anti-patterns

### Do not enable permissions in the base policy

`BasePolicy` is inherited by all other policies, which means any permission enabled there is implicitly available on every object in the system. Because there is no constraint on what resource the permission is authorized against, this creates ambiguity and security risk.

### Avoid dynamic permission definitions

Dynamically defined permissions are difficult to trace in the codebase. When permissions are generated at runtime rather than declared explicitly, searching for a permission name yields no results - making it impossible to verify that a rename or removal is complete.

```ruby
# bad - permission name is constructed dynamically; cannot be searched,
# might enable/prevent permissions that are not actually used anywhere.
readonly_features.each do |feature|
  prevent :"create_#{feature}"
  prevent :"update_#{feature}"
  prevent :"admin_#{feature}"
end


# good - each prevention declared explicitly
rule { read_only }.policy do
  prevent :create_issue
  prevent :update_issue
  prevent :admin_issue
  # ... one line per permission
end
```

Exception: loading permissions from role or permission group YAML is the intended pattern, because every
name is declared in YAML.
For example, `Authz::Role.get(:developer).permissions(:project)` or
`Authz::PermissionGroups::Internal.get('project:archived').permissions`.

### Avoid using the wrong `:scope` in conditions

Every `condition` is cached. The `:scope` option tells DeclarativePolicy what
the cache key is - if it is set incorrectly, the cached result is shared too
broadly and causes bugs where one user's result leaks into another context.

The rules are:

- Use `scope: :user` only if the condition reads user data only - no subject data.
- Use `scope: :subject` only if the condition reads subject data only - no user data.
- Use `scope: :global` only if the condition doesn't need either user or subject data.
- Omit `:scope` (the default) if the condition reads both user and subject data.

Reference: [DeclarativePolicy cache sharing scopes](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/caching.md#cache-sharing-scopes)

```ruby
# bad - scope: :user means the result is cached per-user and shared across all
# subjects, but the condition reads from @subject, so different projects will
# get the same cached result incorrectly
condition(:security_dashboard_enabled, scope: :user) do
  @subject.security_dashboard_enabled?
end

# good - reads subject data only, so scope: :subject is correct
condition(:security_dashboard_enabled, scope: :subject) do
  @subject.security_dashboard_enabled?
end

# good - reads user data only, so scope: :user is correct
condition(:admin_user, scope: :user) do
  @user.admin?
end

# good - reads both user and subject, so no scope is declared
condition(:member_with_access) do
  @subject.member?(@user)
end

# good - doesn't need either user or subject, so scope: :global is correct
condition(:default_project_deletion_protection, scope: :global) do
  ::Gitlab::CurrentSettings.current_application_settings
    .default_project_deletion_protection
end
```

Example fix: [MR !224604](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224604/diffs)

### Avoid cascading permissions through intermediate abilities

Avoid chaining permissions through intermediate abilities, such as having
`read_security_resource` enable `read_vulnerability`. Cascading makes it
difficult to understand which roles have which permissions without tracing
through multiple levels of indirection.

Instead, add each permission directly to the appropriate
[role YAML file](role_definitions.md).

```ruby
# bad - an intermediate ability fans out to other permissions
rule { can?(:read_security_resource) }.enable :read_vulnerability
rule { can?(:read_security_resource) }.enable :read_security_dashboard

# good - each permission is in the role YAML directly
# (config/authz/roles/developer.yml)
#   raw_permissions:
#     - read_vulnerability
#     - read_security_dashboard
```

#### Exception: private permissions

[Private permissions](conventions.md#private-permissions) (underscore-prefixed)
are the one case where cascading through an intermediate ability is correct.
A private permission like `_read_authored_issue` is assigned to a role in the
role YAML definition and then combined with a subject-level condition in the
policy to enable the broader public permission. This pattern is intentional
because:

- The private permission makes the role's conditional capability explicit
  and machine-readable, which is required for privilege escalation checks
  and custom role composition.
- The cascade is always exactly one level deep: private permission + condition
  enables public permission. Deeper chains are still not allowed.

```ruby
# good - private permission gates the broader permission with a condition
rule { can?(:_read_authored_issue) & is_author }.enable :read_issue
rule { can?(:_read_assigned_issue) & is_assignee }.enable :read_issue

# bad - cascading through a non-private intermediate ability
rule { can?(:read_security_resource) }.enable :read_vulnerability
```

### Do not derive a permission from other permissions

A condition that combines permissions to enable a third permission is a form of [cascading](#avoid-cascading-permissions-through-intermediate-abilities).
If either permission is later granted more widely, the derived one widens silently.
Grant the permission in role YAML and check that one permission.
When the subject's own policy doesn't receive role YAML grants, check the same permission on the resource that owns the data.
Checking the same permission on the owning resource is not the cascading that the previous section warns about.

```ruby
# bad - two read permissions combined to grant a third
condition(:can_read_widget_report) do
  can?(:read_widget, @subject.group) || can?(:read_widget_settings, @subject.group)
end
rule { can_read_widget_report }.enable :read_widget_report

# good - the same permission, granted in role YAML and checked on the
# resource that owns the data (the instance when there is no group)
condition(:can_read_widget_report) do
  can?(:read_widget_report, @subject.group || :global)
end
rule { can_read_widget_report }.enable :read_widget_report
```

### Avoid nested conditions

Avoid combining a role check and a settings/flag check into a single `rule`
with `&`. Instead, add the permission to the
[role YAML file](role_definitions.md) and use a separate `rule` with `prevent`
to restrict it when the condition is not met.
[Reference](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/optimization.md?ref_type=heads#flat-is-better-than-nested)

```ruby
# bad - mixes role and settings check in a single rule
rule { developer & model_registry_enabled }.policy do
  enable :write_model_registry
end

# good - permission is in the developer role YAML, policy only prevents
rule { ~model_registry_enabled }.prevent :write_model_registry
```

### Avoid `admin | owner` rules

`admin` users return true for `condition(:owner)` so there is no need
to define the rule for `admin | owner`. The same is true for organization
owners. Permissions should be in the [role YAML file](role_definitions.md)
rather than enabled in the policy.

```ruby
# bad - redundant admin/org owner check, and enabling in policy
rule { admin | organization_owner | owner }.enable :delete_project

# good - permission is in the owner role YAML
# (config/authz/roles/owner.yml)
#   raw_permissions:
#     - delete_project
```

### Do not grant permissions from access-level lookups

Do not grant or check access with `max_member_access_for_user`, `team.member?(@user, Gitlab::Access::DEVELOPER)`, `access_level >=` comparisons, bare role conditions such as `developer`, or `can?(:developer_access)`.
Grant the permission through role YAML instead.
Non-hierarchical roles such as Planner and Security Manager (see `config/authz/roles/planner.yml` and `security_manager.yml`) make `>=` comparisons wrong.
An access-level check also breaks silently when the permission later moves to another role.
The `Gitlab/Authz/RoleCheckInRule` cop flags role checks in rules.

```ruby
# bad - access-level lookup decides who gets the permission
condition(:developer_or_above) { @subject.team.member?(@user, Gitlab::Access::DEVELOPER) }
rule { developer_or_above }.enable :create_widget

# good - net-new permission is added through an assignable permission
# in config/authz/roles/developer.yml
#   permissions:
#     - create_widget
```

### Do not grant access based on membership in a different resource

A role on a sibling or descendant project must not grant access to a group resource or to other projects.
For example, two users are both Guests in Project A, but one is also a Developer in Project B.
If a Developer role anywhere in the group grants the permission, the second user can act in Project A and the first cannot, with no visible reason.
A customer could also create a throwaway project, make everyone a Developer there, and remove the role-based boundary.

Authorize against the resource where the action happens.

```ruby
# bad - a role in any other project grants access here
rule { developer_in_any_descendant_project }.enable :run_widget

# good - check the permission on the project where the action happens
authorize! :run_widget, project
```

The one sanctioned exception is the `descendant_project_member` role (`config/authz/roles/descendant_project_member.yml`).
It grants only baseline group access (`read_group`, `read_boundary`, `upload_file`, and `update_work_item_user_preference`) so that members of a descendant project can work in that project.

Do not use `user.highest_role` in policies.
It is not scoped to the subject, so it returns the highest role a user has anywhere on the instance.
The `Gitlab/Authz/AvoidHighestRoleUsage` cop flags it.

### Do not call `Ability.allowed?` or `user.can?` in policy files

Both route back through `Ability`, which can create circular lookups and makes the policy harder to reason about.
Use DeclarativePolicy's bare `can?` helper inside the policy instead.
The cop `Gitlab/Authz/DisallowAbilityAllowed` flags `Ability.allowed?` and `can?` called on a receiver such as `@user.can?`.
The rules against [cascading permissions](#avoid-cascading-permissions-through-intermediate-abilities) still apply.

```ruby
# bad
condition(:can_read_project) { Ability.allowed?(@user, :read_project, @subject.project) }

# good
condition(:can_read_project) { can?(:read_project, @subject.project) }
```

### Do not treat instance admins as an implicit grant

A `user.admin?` shortcut skips the checks in the policy's `admin` condition (`app/policies/base_policy.rb`), such as requiring admin mode and rejecting CI job tokens.
Check the permission through the policy instead, and let the role definitions decide how admins and organization owners are treated.

```ruby
# bad
condition(:admin_or_owner) { @user.admin? || @subject.owner?(@user) }

# good - no admin shortcut. Role definitions and the base policy's `admin`
# condition, which requires admin mode, decide how admins are treated.
condition(:owner_of_widget) { @subject.owner?(@user) }
```

### Name conditions for what they check

A condition name must describe what it checks.
A condition named `can_manage_*` that only checks read permissions makes readers assume it is stricter than it is.

Do not use "owner" for anything other than the Owner role.
In a policy, `group_owner` or `boundary: :owner` meaning "the group that owns this data" reads as "the user is a group Owner".
Name the resource directly, such as `root_namespace`.

### Do not use `can?(:read_project)` as a membership check

On a public project, `read_project` is granted to every user, including anonymous users, through the `public_anonymous` and `public_authenticated` role definitions in `config/authz/roles/`.
Replacing a membership check with `can?(:read_project)` silently widens every rule that depended on membership, such as a bot condition meant to apply only to projects the bot belongs to.

When a rule needs real membership combined with other state, such as visibility, external users, or bots, use `user_is_user? && project.member?(@user)`.
`user_is_user?` (in `BasePolicy`) keeps deploy tokens and deploy keys from matching by ID.
Use this only to combine membership with other state.
Granting a role's permissions still belongs in role YAML, as described in [Do not grant permissions from access-level lookups](#do-not-grant-permissions-from-access-level-lookups).

```ruby
# bad - true for every user on a public project
condition(:widget_bot_in_project) { can?(:read_project, @subject) }

# good - real membership, and not a deploy token or deploy key
condition(:widget_bot_in_project) { user_is_user? && @subject.member?(@user) }
```

### Keep conditions cheap and side-effect free

Order cheap checks first and run queries last.
Guard against `nil` users, because policies are also evaluated for anonymous users.
Do not end a condition name with `?`, because conditions become predicate methods and the name would end in `??`.
For scoring and ordering, see [Scores, Order, Performance](../policies.md#scores-order-performance).

```ruby
# bad - queries before the cheap attribute check, and no nil guard
condition(:can_use_widgets) do
  @subject.members.exists?(user_id: @user.id) && @subject.widgets_enabled?
end

# good - cheap checks first, nil user guarded
condition(:can_use_widgets) do
  @user.present? && @subject.widgets_enabled? && @subject.members.exists?(user_id: @user.id)
end
```

## Examples

### Refactoring combined conditions to use role YAML and `prevent`

```ruby
# bad - permission only enabled when all conditions are true, meaning the role's
# access grows based on feature flags and other conditions. Authorization logic
# should only remove access, never expand it.
rule { can?(:developer_access) & user_confirmed }.policy do
  enable :create_pipeline
end

rule { ai_flow_triggers_enabled & (amazon_q_enabled | duo_workflow_available) & can?(:developer_access) & can?(:create_pipeline) }.policy do
  enable :trigger_ai_flow
end

# good - trigger_ai_flow is in the developer role YAML.
# (config/authz/roles/developer.yml)
#   raw_permissions:
#     - trigger_ai_flow
#
# Each condition independently prevents it when not satisfied,
# so the role's base permissions are always enumerable.
rule { ~user_confirmed }.prevent :trigger_ai_flow
rule { ~ai_flow_triggers_enabled }.prevent :trigger_ai_flow
rule { ~amazon_q_enabled & ~duo_workflow_available }.prevent :trigger_ai_flow
```

## Custom roles

Permissions should not enable other permissions.
See [Avoid cascading permissions through intermediate abilities](#avoid-cascading-permissions-through-intermediate-abilities).

- When you change or remove an existing cascade, check `ee/config/custom_abilities/*.yml`.
  Custom abilities often list only the top-level permission and rely on the cascade for the rest.
  Removing the cascade silently drops access for custom-role users.
- List custom roles next to default roles in the behavior-change notes of the merge request.
- When you rename or remove a permission, check the custom abilities and the existing custom roles that reference it.
  Custom role abilities are stored in the database, so a rename is a breaking change.
- For stored token scopes, follow [Renaming assignable permissions](granular_access/assignable_permissions.md#renaming-assignable-permissions).
- For new permissions that could let a role act beyond its base role, see the [privilege escalation consideration](custom_roles.md#privilege-escalation-consideration).

## Where to enforce

- Keep the decision in the policy.
  Do not re-implement it in controllers, helpers, or views, because the copy can drift and bypass the policy.
- Enforce in services and finders too, and use the same permission across REST, GraphQL, and controllers.
  For guidance on where to check, see [Where should permissions be checked?](authorizations.md).
- Give bots, service accounts, and internal tokens the narrowest permission that does the job.
- Do not pass `skip_authorization: true` for requests a user or bot makes, because it bypasses the policy checks, including custom roles.
  Reserve it for system-driven flows such as provisioning, and never derive it from user input.
- Do not leak that a resource exists.
  Distinguishable 403 and 404 responses or specific error messages let callers enumerate resources and members.
- Do not narrow an existing `before_action` with `only:` unless every other action has its own check.
- Gate editable UI on the `update_*` permission, not `read_*`.
- Gate a nav or sidebar item on the same permission as the page it links to.

## Granular token authorization

- Every new endpoint declares granular token authorization or an explicit, justified opt-out.
  For REST, see [Skipping granular token authorization](granular_access/rest_api_implementation_guide.md#skipping-granular-token-authorization).
  For GraphQL, see [Skip authorization with `skip_reason`](granular_access/graphql_implementation_guide.md#skip-authorization-with-skip_reason).
- The token check covers the resource in the request path.
  Other resources the call touches still need a user permission check.
  See [The token authorizes the API call](granular_access/authorization_principles.md#the-token-authorizes-the-api-call).
- Choose an assignable permission's `boundaries` from the endpoints it protects, not from every policy that enables its raw permissions.
  Use `instance` sparingly, usually only for admin-facing permissions.
  See [Determining boundaries](granular_access/assignable_permissions.md#determining-boundaries).
- Declare token authorization once, on the type, resolver, or mutation, with `authorize_granular_token`.
  Prefer this over adding `granular_scope_directive` to individual fields.
  If part of a response needs a different token permission or boundary, move it to its own type, resolver, or mutation with its own declaration.
- Do not add a second token permission check inside the code of a mutation or resolver.
  The permission validation task and the generated token documentation only read declared directives.
  A check hidden in code is missing from the documentation, so a token built from the documentation is denied.
  Make it a separate mutation or resolver with its own declaration.

## GraphQL authorization

- Prefer authorizing the whole type over individual fields.
  Field authorization is widely used, but avoid adding more of it where possible.
  Field authorization is checked against the current object before resolution, so add authorization to the resolver or, ideally, to the type.
  See [Field authorization](../graphql_guide/authorization.md#field-authorization).
- If some fields need a different access level than the rest of the type, consider moving them to their own child type with its own authorization.
- A field's `authorize:` is checked against the parent object's policy.
  Role YAML grants reach the project, group, and organization policies, so for any other object the policy must pass the check to the resource that owns it.
  See [Do not derive a permission from other permissions](#do-not-derive-a-permission-from-other-permissions) for an example.

## Testing

Every policy change needs policy specs.
For the structure, see the [testing guidelines](testing_guidelines.md).

- Use `expect_allowed` and `expect_disallowed`.
  The `Gitlab/Authz/UsePolicyHelpers` cop enforces this.
- Use real memberships and settings instead of stubbing `can?` or `Ability.allowed?`.

## Automated checks

Several rules on this page are enforced by RuboCop cops under `Gitlab/Authz/`: `RoleCheckInRule`, `AvoidHighestRoleUsage`, `DisallowAbilityAllowed`, `EnableInBasePolicy`, `ConditionScope`, `PermissionCheck`, and `UsePolicyHelpers`.

Do not disable these cops, either inline with `# rubocop:disable` or by adding an exclusion under `.rubocop_todo/gitlab/authz/`.
If a disable cannot be avoided, a member of the Authorization team must approve it.
Danger posts a comment asking the author to request an `~authorization` review when an MR adds one.
It skips draft MRs.

"The same permission is used elsewhere" is not a valid reason to disable a cop.
Enforcement points should check granular permissions, and each new use of a coarse permission adds to the work of replacing it.
Instead:

1. Add a granular permission for the code you are changing, and check that permission.
1. Open a follow-up issue to move the other call sites to granular permissions.
