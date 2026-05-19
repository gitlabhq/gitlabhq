---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Authorization code review guidelines
---

This page provides guidance from the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization) on how to prepare a merge request that involve policy changes, permission definitions, and authorization logic for review.

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

## File organisation

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

## Anti-patterns

### Do not enable permissions in the base policy

`BasePolicy` is inherited by all other policies, which means any permission enabled there is implicitly available on every object in the system. Because there is no constraint on what resource the permission is authorized against, this creates ambiguity and security risk.

### Avoid dynamic permission definitions

Dynamically defined permissions are difficult to trace in the codebase. When permissions are generated at runtime rather than declared explicitly, searching for a permission name yields no results — making it impossible to verify that a rename or removal is complete.

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

### Avoid using the wrong `:scope` in conditions

Every `condition` is cached. The `:scope` option tells DeclarativePolicy what
the cache key is — if it is set incorrectly, the cached result is shared too
broadly and causes bugs where one user's result leaks into another context.

The rules are:

- Use `scope: :user` only if the condition reads **user data only** — no subject data.
- Use `scope: :subject` only if the condition reads **subject data only** — no user data.
- Use `scope: :global` only if the condition doesn't need either user or subject data.
- Omit `:scope` (the default) if the condition reads **both** user and subject data.

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

- The private permission makes the role's conditional capability **explicit
  and machine-readable**, which is required for privilege escalation checks
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

### Avoid  `admin | owner` rules

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

## Examples

### Refactoring combined conditions to use role YAML and `prevent`

```ruby
# bad - permission only enabled when all conditions are true, meaning the role's
# access grows based on feature flags and other conditions. Authorization logic
# should only remove access, never expand it.
rule { can?(:developer_access) & user_confirmed? }.policy do
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
rule { ~user_confirmed? }.prevent :trigger_ai_flow
rule { ~ai_flow_triggers_enabled }.prevent :trigger_ai_flow
rule { ~amazon_q_enabled & ~duo_workflow_available }.prevent :trigger_ai_flow
```
