---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Authorization code review guidelines
---

This page provides guidance from the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/software-supply-chain-security/authorization) on how to prepare a merge request that involve policy changes, permission definitions, and authorization logic for review.

## File organisation

All permissions for the same condition should be in one `.policy` block, not
scattered across the file. This makes it easy to see the full set of
permissions a role or condition grants without searching the file.

```ruby
# bad - conditions and rules interleaved, rules scattered by role
rule { guest }.enable :read_issue
rule { guest }.enable :read_project

# good - all conditions first, then rules grouped by role
rule { guest }.policy do 
  enable :read_issue
  enable :read_project
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
`developer` enable `read_security_resource`, and `read_security_resource` then
enable `read_vulnerability`. Instead, `developer` should directly enable
`read_vulnerability`.

Cascading makes it difficult to understand which roles have which permissions
without tracing through multiple levels of indirection. Permissions should be
explicit and traceable.

```ruby
# bad - developer enables an intermediate ability which then fans out
rule { developer }.enable :read_security_resource

rule { can?(:read_security_resource) }.enable :read_vulnerability
rule { can?(:read_security_resource) }.enable :read_security_dashboard

# good - each role directly enables the permissions it should have
rule { developer }.policy do
  enable :read_vulnerability
  enable :read_security_dashboard
end
```

### Avoid nested conditions

Avoid combining a role check and a settings/flag check into a single `rule`
with `&`. Instead, enable the permission for the role unconditionally and use
a separate `rule` with `prevent` to restrict it when the condition is not met. [Reference](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/optimization.md?ref_type=heads#flat-is-better-than-nested)

```ruby
# bad - mixes role and settings check in a single rule
rule { developer & model_registry_enabled }.policy do
  enable :write_model_registry
end

# good - enable unconditionally for the role, prevent when the setting blocks it
rule { developer }.enable :write_model_registry
rule { ~model_registry_enabled }.prevent :write_model_registry
```

### Avoid  `admin | owner` rules 

`admin` users will now return true for `condition(:owner)` so we don't need to define the rule for `admin | owner` anymore. The same is true for organization owners.

```ruby
# bad
rule { admin | organization_owner | owner }.enable :delete_project

# good
rule { owner }.enable :delete_project
```

### Avoid OR in rules

Do not use conditions such as `planner_or_reporter_access` as a shorthand. Use separate rules for
each role instead. This keeps permissions explicit and enumerable, and avoids
hiding which roles actually have access.

```ruby
# bad
condition(:planner_or_reporter_access) do
  can?(:reporter_access) || can?(:planner_access)
end

rule { can?(:planner_or_reporter_access) }.enable :read_issue

# good
rule { can?(:planner_access) }.enable :read_issue
rule { can?(:reporter_access) }.enable :read_issue
```

## Common gotchas

### `condition(:guest)` is not the same as `can?(:guest_access)`

These look interchangeable but behave very differently:

- `condition(:guest)` returns `true` only if the user has been **explicitly added** to the project or group as a guest member.
- `can?(:guest_access)` returns `true` if the user is **accessing a public project** — regardless of whether they are a member.

This means replacing one with the other can silently expand or restrict access,
particularly on public projects where non-members have implicit guest-level access.

```ruby
# condition(:guest) - only explicit members with guest role
rule { guest }.enable :read_issue

# can?(:guest_access) - any user on a public project
rule { can?(:guest_access) }.enable :read_issue
```

Do not swap between the two without consulting the teams that introduced the
original rule. An unintentional switch could grant permissions to logged-in
non-members on public projects that they did not previously have.

## Examples

### Refactoring combined conditions to use `prevent`

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

# good - developer_access unconditionally enables the permission.
# Each condition then independently prevents it when not satisfied,
# so the role's base permissions are always enumerable.
rule { can?(:developer_access) }.enable :trigger_ai_flow

rule { ~user_confirmed? }.prevent :trigger_ai_flow
rule { ~ai_flow_triggers_enabled }.prevent :trigger_ai_flow
rule { ~amazon_q_enabled & ~duo_workflow_available }.prevent :trigger_ai_flow
```
