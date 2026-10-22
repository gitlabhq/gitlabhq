---
source_checksum: a99d3961c64fc0ce
distilled_at_sha: 0598d6c1b5bb294276c7c644f29291505d54c4c1
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Permissions Fundamentals Principles

## Checklist

### Authorization Enforcement

- Enforce authorization using defense-in-depth: implement permission checks at multiple layers (finders, services, GraphQL, REST API, controllers).
- Enforce authorization in shared business logic (services and finders) as the primary layer, so checks are consistent across REST, GraphQL, and controllers.
- DO NOT rely solely on display-layer permission checks (such as showing/hiding buttons) as a security control — always back them with backend enforcement.
- Prefer domain logic (services or finders) as the source of truth when making exceptions to multi-layer enforcement.
- When a class accepts `current_user`, ensure it is responsible for authorization.
- When adding a new API endpoint, check an existing ability or add a new one; do not skip the authorization check.
- When using an ability check in UI elements, ensure the underlying backend code also performs the same ability check.
- Use `push_frontend_ability` (available on controllers inheriting from `ApplicationController`) to expose abilities to JavaScript; access them via `gon.abilities.<camelCaseName>` (DO NOT use `gon.abilities.<snake_case_name>`).
- Keep the authorization decision in the policy; DO NOT re-implement it in controllers, helpers, or views, because the copy can drift and bypass the policy.
- Give bots, service accounts, and internal tokens the narrowest permission that does the job.
- DO NOT pass `skip_authorization: true` for requests a user or bot makes, because it bypasses policy checks including custom roles. Reserve it for system-driven flows such as provisioning, and never derive it from user input.
- DO NOT leak that a resource exists: avoid distinguishable 403 and 404 responses or specific error messages that let callers enumerate resources and members.
- DO NOT narrow an existing `before_action` with `only:` unless every other action has its own authorization check.
- Gate editable UI on the `update_*` permission, not `read_*`.
- Gate a nav or sidebar item on the same permission as the page it links to.

### Permission Naming Conventions

- Introduce a new permission only when no existing permission covers the same subject and action; reuse existing permissions wherever possible.
- Ensure every new permission enables the principle of least privilege: grant only the access required for a single, well-defined action on a single resource; split permissions that would bundle more than one action or unrelated capabilities. If you cannot scope the permission this narrowly, reconsider the design before introducing it.
- Follow the naming pattern `action_resource(_subresource)` for all permissions (both assignable and raw).
- Use only the preferred actions — `create`, `read`, `update`, `delete` — unless a documented exception applies; obtain Authorization team approval for any action outside this set.
- DO NOT introduce disallowed actions: `admin`, `change`, `configure`, `destroy`, `edit`, `list`, `manage`, `modify`, `set`, `view`, or `write`.
- Use the singular form for the resource segment (e.g., `read_project`, not `read_projects`).
- Match the resource name to the domain object being acted upon, using user-facing terminology rather than implementation details.
- DO NOT encode the resource boundary (`project`, `group`, `user`) or the access path into the permission name; pass the subject in the `can?` call to determine scope instead (e.g., use `read_insights_dashboard` not `read_project_insights_dashboard`, and `read_widget` not `read_widget_via_parent_group`).
- Introduce a new action outside the preferred set only when it represents a distinct lifecycle transition (`archive_project`), a relationship change (`transfer_project`), or a high-impact/irreversible operation (`purge_maven_virtual_registry_cache`) already established in GitLab domain language.
- Match the permission to the action: use a read permission for read-only fields and endpoints, and a mutating permission for mutations. DO NOT check a permission whose action implies a state change (such as `start_` or `update_`) on a read-only field, and DO NOT guard a write with a read permission.
- Check the permission for the action the code performs, on the resource it changes; the service, mutation, or endpoint name usually names that action. DO NOT check a different permission just because the same roles happen to hold it.
- DO NOT reuse one permission for different meanings.
- Describe what the permission gates in its description; DO NOT mention which roles have it, because roles can change.
- Create a complete permission definition file for every new permission; DO NOT add entries to the legacy to-do lists `config/authz/permissions/definitions_todo.txt` and `config/authz/graphql/authorization_todo.txt`.

### Private Permissions

- Prefix private permissions with an underscore (`_`) following the pattern `_<action>_<qualifier>_<resource>` (e.g., `_read_authored_issue`).
- DO NOT check private permissions at enforcement points (controllers, services, finders, GraphQL); use them only inside policy files.
- Use private permissions when a role can perform an action only when a subject-level condition is met, or when different roles have different levels of access to the same action.
- DO NOT use private permissions for feature flag checks, license checks, or settings-based restrictions — use `prevent` rules instead.
- Create a definition file for every private permission under `config/authz/permissions/<resource>/_<action>_<qualifier>.yml`.
- Use qualifiers that correspond to a real attribute or relationship on the resource (e.g., `confidential`, `authored`, `assigned`); DO NOT use qualifiers that describe the actor.
- Prefer past-participle or adjective forms for qualifiers that read naturally as a description of the resource; introduce qualifiers only when the same action on the same resource requires different access levels depending on the resource's state.
- Declare a `conditionally_enables` field in every private permission YAML, listing the broader public permission(s) that imply it; use `null` when no public permission supersedes the private one (the validation task fails if this field is omitted).

### Role Definition YAML Files

- Define default roles as YAML files under `config/authz/roles/` with the fields `name`, `description`, `inherits_from`, and optionally `raw_permissions` and `permissions`.
- Understand that the final permission set for a role is the union of its `raw_permissions`, expanded `permissions` (assignable groups), and all permissions inherited recursively from parent roles.
- When adding a permission to a role, prefer using an assignable permission group; use `raw_permissions` only for existing permissions that need to be moved into the role definition.
- When removing a permission from a role, verify it is not depended on by other features; use `GITLAB_DEBUG_POLICIES=true` to trace where a permission is checked.
- Keep role YAML files as the source of truth for role grants: DO NOT put `enable` rules based on role conditions in policy files; add the permission to the role YAML and use `prevent` rules in the policy to restrict access when a feature or setting is unavailable.
- Preserve behavior for every role that should have the permission when moving or adding permissions in role YAML.
- Update both the `group` and `project` sections of role YAML when the permission applies to both.
- Check `public_anonymous` and `guest` roles when a permission was previously enabled through a broad read permission.
- Add new `read_*` permissions to the `auditor` role; DO NOT add permissions that change project or group data to it.
- Add the new permission wherever sibling permissions are already prevented (such as the archived and pending-deletion lists in `config/authz/permission_groups/internal/`, or feature availability rules); otherwise it bypasses those restrictions.
- DO NOT re-add a permission to a role that already gets it through `inherits_from`.

### Policy Rules

- Use policy rules only to restrict with `prevent`; Exception: the private-permission pattern (one level deep: private permission + subject condition enables the public permission).
- Group all `prevent` rules for the same condition in one `.policy` block; DO NOT scatter them across the file.
- DO NOT enable permissions in `BasePolicy`, because it is inherited by every policy and the permission becomes available on every object (enforced by `Gitlab/Authz/EnableInBasePolicy`).
- DO NOT define permissions dynamically (e.g., `prevent :"create_#{feature}"`); declare each permission name explicitly so it can be searched. Exception: loading permissions from role or permission group YAML (`Authz::Role.get(...).permissions`, `Authz::PermissionGroups::Internal.get(...).permissions`).
- Set the condition `:scope` to match the data it reads: `scope: :user` only for user data, `scope: :subject` only for subject data, `scope: :global` for neither; omit `:scope` when the condition reads both (enforced by `Gitlab/Authz/ConditionScope`).
- DO NOT cascade permissions through intermediate abilities (e.g., `read_security_resource` enabling `read_vulnerability`); add each permission directly to the role YAML. Exception: private permissions, which cascade exactly one level (private permission + subject condition enables the public permission).
- DO NOT derive a permission by combining other permissions in a condition; grant it in role YAML and check that one permission. When the subject's own policy does not receive role YAML grants, check the same permission on the resource that owns the data (e.g., `can?(:read_widget_report, @subject.group || :global)`).
- DO NOT combine a role check and a settings/flag check in one `rule` with `&`; add the permission to the role YAML and use a separate `prevent` rule for the condition.
- DO NOT write `admin | owner` (or `organization_owner`) rules, because admins already return true for `condition(:owner)`; put the permission in the owner role YAML.
- DO NOT grant or check access with access-level lookups (`max_member_access_for_user`, `team.member?(@user, Gitlab::Access::DEVELOPER)`, `access_level >=`, bare role conditions such as `developer`, `can?(:developer_access)`); grant the permission through role YAML instead, because roles like Planner and Security Manager are non-hierarchical (enforced by `Gitlab/Authz/RoleCheckInRule`).
- DO NOT grant access based on a role in a different resource (e.g., Developer in any descendant project granting group-level access); authorize against the resource where the action happens. Exception: the `descendant_project_member` role, which grants only baseline group access (`read_group`, `read_boundary`, `upload_file`, and `update_work_item_user_preference`).
- DO NOT use `user.highest_role` in policies (enforced by `Gitlab/Authz/AvoidHighestRoleUsage`).
- DO NOT call `Ability.allowed?` or `user.can?` in policy files; use DeclarativePolicy's bare `can?` helper (enforced by `Gitlab/Authz/DisallowAbilityAllowed`).
- DO NOT use a `user.admin?` shortcut as an implicit grant in policies; check the permission through the policy and let role definitions and the base policy `admin` condition (admin mode, CI job token rejection) decide how admins are treated.
- Name conditions for what they check (e.g., DO NOT name a condition `can_manage_*` if it only checks read permissions); DO NOT use "owner" for anything other than the Owner role — name the resource directly (e.g., `root_namespace`).
- DO NOT use `can?(:read_project)` as a membership check, because public projects grant it to every user; use `user_is_user? && project.member?(@user)` when a rule needs real membership combined with other state.
- Keep conditions cheap and side-effect free: order cheap checks first and queries last, guard against `nil` users, and DO NOT end a condition name with `?`.

### Custom Roles

- Run `./ee/bin/custom-ability <ABILITY_NAME>` to generate the YAML configuration file for a new custom ability under `ee/config/custom_abilities/`.
- Run `bundle exec rails generate gitlab:custom_roles:code --ability <ABILITY_NAME>` to update the permissions validation schema and create a spec file.
- Define permissions declaratively in the custom ability YAML using `project_permissions` and `group_permissions` fields; DO NOT manually add policy rules to `ProjectPolicy` or `GroupPolicy` for custom abilities.
- Mark a custom ability as `wip: true` in its YAML when implementing across multiple MRs; remove the `wip:` key when the ability is ready to ship. Specs run with wip abilities visible by default (via `GITLAB_LOAD_WIP_CUSTOM_ABILITIES=true` in `spec_helper.rb`); use the `:disable_wip_custom_abilities` RSpec metadata to test production-like gating behavior.
- Consolidate custom role abilities to a minimum: use `read_*` for all view-related actions and `admin_*` for object updates; avoid introducing additional abilities unless necessary.
- Ensure `admin_*` custom abilities declare `read_*` as a requirement in the YAML `requirements` field.
- Add the ability as a trait in the `MemberRoles` factory (`ee/spec/factories/member_roles.rb`) and add request specs under `ee/spec/requests/custom_roles/<ABILITY_NAME>/request_spec.rb`.
- Run `bundle exec rake gitlab:custom_roles:compile_docs` and `bundle exec rake gitlab:graphql:compile_docs` to update documentation after adding a custom ability.
- Assess privilege escalation risk when adding new custom permissions that interact with GitLab artifacts (such as access tokens) that encode the base role.
- When changing or removing an existing permission cascade, check `ee/config/custom_abilities/*.yml`, because custom abilities often list only the top-level permission and removing the cascade silently drops access for custom-role users.
- List custom roles next to default roles in the behavior-change notes of the merge request.
- When renaming or removing a permission, check the custom abilities and existing custom roles that reference it; custom role abilities are stored in the database, so a rename is a breaking change.
- For stored token scopes, follow "Renaming assignable permissions" in `granular_access/assignable_permissions.md`.

### Granular Token Authorization

- Declare granular token authorization (or an explicit, justified opt-out) for every new REST and GraphQL endpoint.
- Add a user permission check for other resources a call touches; the token check covers only the resource in the request path.
- Name the same permission in the user check and the granular token check on the same endpoint or mutation.
- Choose an assignable permission's `boundaries` from the endpoints it protects, not from every policy that enables its raw permissions; use `instance` sparingly, usually only for admin-facing permissions.
- Declare GraphQL token authorization once on the type, resolver, or mutation with `authorize_granular_token`; prefer this over adding `granular_scope_directive` to individual fields. Move a response part needing a different token permission or boundary to its own type, resolver, or mutation with its own declaration.
- DO NOT add a second token permission check inside the code of a mutation or resolver, because the validation task and generated token documentation read only declared directives; make it a separate mutation or resolver with its own declaration.

### GraphQL Authorization

- Prefer authorizing the whole GraphQL type over individual fields; add authorization to the resolver or, ideally, the type rather than adding more field authorization.
- Move fields that need a different access level than the rest of the type into their own child type with its own authorization.
- Ensure the parent object's policy passes the check to the owning resource when a field's `authorize:` targets an object other than a project, group, or organization, because role YAML grants reach only those policies.

### Internal Permission Groups

- Define internal permission groups as YAML files under `config/authz/permission_groups/internal/<resource>/<name>.yml` with `description` and `permissions` fields.
- Use internal permission groups in `DeclarativePolicy` policies by calling `Authz::PermissionGroups::Internal.get('<identifier>')` and splatting the result into a `prevent` rule.
- Use internal permission groups when a resource state change (archiving, locking) should disable many permissions at once, or when the same permission set is referenced from multiple places.
- DO NOT use internal permission groups for role-based permission assignment (use role definitions or custom roles), or for token-scoped permissions (use assignable permissions).

### Predefined Roles and Visibility

- Store project membership (with group membership already resolved) in the `project_authorizations` table; the highest permission across group and project membership is the effective access level.
- DO NOT grant subgroups a higher visibility level than their parent group.
- Design complex feature permissions as separate, granular permissions with explicit dependency relationships rather than reusing a single broad permission.

### Policy Testing

- Place policy unit tests in `spec/policies/` (CE) or `ee/spec/policies/` (EE).
- Cover every policy change with policy specs.
- Use one `describe` block per permission; DO NOT group multiple permissions into a single block.
- DO NOT write role tables (such as a `where` table of guest through owner) to test what each role is granted, because `ee/spec/lib/authz/role_definitions_spec.rb` checks that each role gets exactly the permissions its YAML lists; test what the policy adds instead: prevents (licenses, feature flags, settings, visibility, feature access levels, archived projects, admin mode) and grants outside role YAML (custom roles, deploy tokens).
- Pair each prevent with one allowed example, so the test fails if no one holds the permission.
- Test each rule in the spec for the policy that defines it, placing the rule in the policy closest to the one that enables the permission (the subject-only rule in that policy, the more specific-subject rule in the delegating policy); DO NOT re-test logic from delegate policies.
- Check delegation with `delegate_to` (e.g., `is_expected.to delegate_to(ProjectPolicy)`) and test only the rules the delegating policy adds; when the delegate depends on the subject, check each possible delegate.
- Create only what the rules need (usually one user and one subject): use `let_it_be` for records and reuse users and projects from the shared policy contexts; DO NOT create extra users, projects, or memberships to fill out a role table.
- Define the subject explicitly inside each `describe` block using `let_it_be`; DO NOT rely on a subject defined at a higher scope.
- Use descriptively named fixtures that reflect the visibility or state under test (e.g., `private_project`, `archived_project`) rather than a generic `project`.
- Test both admin mode enabled (`:enable_admin_mode`) and admin mode disabled contexts for permissions that apply to admins.
- Test both feature flag disabled and licensed feature disabled contexts for every permission that is gated by either.
- Use `expect_allowed` and `expect_disallowed` in policy specs, not `be_allowed` and `be_disallowed` (enforced by `Gitlab/Authz/UsePolicyHelpers`); pass several permissions to one call when an example checks several, because the helpers report every failing permission.
- Use real memberships and settings; DO NOT stub `can?` or `Ability.allowed?`.

### Automated Authorization Checks

- DO NOT disable the `Gitlab/Authz/` RuboCop cops (`RoleCheckInRule`, `AvoidHighestRoleUsage`, `DisallowAbilityAllowed`, `EnableInBasePolicy`, `ConditionScope`, `PermissionCheck`, `UsePolicyHelpers`), either inline with `# rubocop:disable` or via an exclusion under `.rubocop_todo/gitlab/authz/`; obtain Authorization team approval when a disable is unavoidable (Danger asks for an `~authorization` review on non-draft MRs that add one).
- DO NOT justify a cop disable with "the same permission is used elsewhere"; add a granular permission for the code you are changing and check it, and open a follow-up issue to move the other call sites to granular permissions.

## Authoritative sources

For the full picture, see:

- doc/development/permissions/authorizations.md
- doc/development/permissions/conventions.md
- doc/development/permissions/role_definitions.md
- doc/development/permissions/predefined_roles.md
- doc/development/permissions/custom_roles.md
- doc/development/permissions/internal_permission_groups.md
- doc/development/permissions/testing_guidelines.md
- doc/development/permissions/review_guidelines.md

