---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 'Development Guidelines: learn about organization when developing GitLab.'
title: Organization
---

The [Organization initiative](../../user/organization/_index.md) focuses on reaching feature parity between
GitLab.com and GitLab Self-Managed.

## Guidance for feature teams

Use this section to understand what to consider before building a feature at the organization level.

The target milestone for launching Organizations as
[Beta](https://gitlab.com/groups/gitlab-org/-/work_items?state=opened&label_name%5B%5D=Organizations%3A%3ABeta&type%5B%5D=8)
is 19.4 (2026-09-11).

Previously, a feature implemented at the instance level for GitLab Self-Managed
had to be re-implemented for top-level groups on GitLab.com.
Organizations remove this duplication.
The new default is to build features at the organization level, which serves both.
For example, the Artifact Registry uses organizations as its
[anchor point](https://gitlab.com/gitlab-org/ops/artifact-registry/-/blob/main/docs/adr/001_organizations_as_anchor_point.md).

Not every feature needs organization-level scope, and because Organizations
has not yet launched as Beta, there are key considerations to be aware of.
Read the following sections for details.

Contact the team on Slack (`#g_organizations`) to discuss your use case before building.

### Determine if your feature needs organization-level scope

Not every feature belongs at the organization level.

Most features should continue to be anchored to the group, project, or user
level. This mirrors the old paradigm where most features did not target the
instance or TLG level.

Features that span multiple groups inside an organization should be scoped at
the group level, but with cross-group navigation. It is not a sufficient
justification to invent an organization-level version.

Only build a feature at the organization level when users have a clear need
for organization-level governance or configuration.

Consult the Organizations Charter
(`https://docs.google.com/document/d/1ldPftCifCDkdw3_3JKOnFjdwNHGIgbHIbW8HEc92i1Y/edit`, internal access required)
for more information.

### Plan roles specific to your organization-level feature

Organization-level roles are separate from group and project roles.
When designing your feature:

- Define what actions each organization role (Owner, User) can perform.
- Do not assume group-level roles map directly to organization-level roles.
- Consider whether your feature requires a new organization-level permission,
  or whether an existing role is sufficient.

For more information, see the [organization user documentation](../../user/organization/_index.md).

### Require the top-level group to transfer to its own organization (GitLab.com)

Features that depend on organization context require the TLG to be inside its own organization.
This is because the default organization on GitLab.com currently contains TLGs where the TLG
owners are not Organization Owners.

Do not enforce this with a check such as `organization.default?`. GitLab Self-Managed and GitLab
Dedicated legitimately run inside the default organization, so that check would also block them.

Instead, enforce this through authorization, using the organization-level permissions described in
[Plan roles specific to your organization-level feature](#plan-roles-specific-to-your-organization-level-feature).
Gate the feature behind a permission that only an Organization Owner can grant, for example through
the `organization_owner` and `organization_user` conditions in `Organizations::OrganizationPolicy`.

### Consider organization-based billing limitations

[Organization-based billing](https://gitlab.com/gitlab-org/customers-gitlab-com/-/merge_requests/15263)
is not yet available.

Do not build features that depend on billing or subscription entitlements at the organization level.

This is because billing and subscription entitlements are currently scoped to the top-level
group on GitLab.com, not to the organization.
Most paid customers only have one paid TLG on GitLab.com, so this rarely comes up.
If you create another TLG, that new TLG does not inherit the paid entitlements of your existing TLG.

Users are
[warned](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/organization/decisions/013_warn_on_tlg_creation/)
of this before they attempt to create another TLG on GitLab.com.

## Available and planned support for implementing organizations

The Organizations team is implementing changes which will automatically include support for:

- Application level Organization Isolation: There will be an ActiveRecord extension that will take care of [Organization Scoping](https://gitlab.com/groups/gitlab-org/-/work_items/19414). This is provisionally planned for availability and usage in early FY27-Q2.
- Sidekiq: there is no need to pass `organization_id` to Sidekiq worker parameters: Sidekiq workers will inherit the Current Organization from the scheduling context
- Events / Logging: similar to User, Project, or Namespace, Organization will be included
- Routing: Enabling / disabling organization based URLs (`/o/<organization>` prefix) will be available.
- Organization availability in tests

Teams do not need to implement these, unless there are specific reasons.

## Releasing organization features

Organization features ship behind an `organization flag` that moves through a fixed ladder of stages, from Experimental to generally available (GA).
A feature's audience only ever grows as its organization flag advances to a later stage, so an earlier stage's audience is never dropped.

For the engineering guide on gating a feature, registering an organization flag, and advancing it through the stages, see [Organizations release process](../organizations/release_process.md).
For the organization flags currently in the rollout process and their stage, see [Organizations platform release status](../organizations/release_status.md).

## Database table design

See the [sharding guidelines](sharding/_index.md).

## Using `Current.organization`

Ensure that `Current.organization` is set correctly at the request layer.
For the cases where this is not set automatically, follow the steps below.

Once `Current.organization` is set, the ActiveRecord extension
(`gitlab-database-data_isolation`) will use this
context to conditionally scope queries to that organization.

### Where `Current.organization` is available

`Current.organization` is set automatically in the following contexts:

- Controllers: `ApplicationController` includes a `before_action :set_current_organization` that runs for every request.
- GraphQL: `GraphqlController` inherits from `ApplicationController`, so the same `before_action` applies automatically.
- Grape API: a global `before_validation` hook in `lib/api/api.rb` runs for every endpoint.
  The hook resolves the organization from the `X-GitLab-Organization-ID` header, then from the
  organization of the authenticated user, and falls back to the default organization.
- Sidekiq: set from the organization context captured when the job is enqueued.

You must set `Current.organization` yourself in these cases:

- Grape API classes that opt out of the global hook with `skip_global_organization_setup!`.
  The global hook derives the organization from standard API authentication, such as personal
  access tokens. If your endpoint uses a custom authentication mechanism (for example, deploy
  tokens), the hook cannot resolve the correct organization. Opt out and derive the
  organization from the authenticated entity instead:

  ```ruby
  class MyAPI < ::API::Base
    skip_global_organization_setup!

    before do
      Current.organization = some_custom_method
    end
  end
  ```

- Code that runs outside a request or Sidekiq context, such as Rake tasks and the Rails console.

### Passing organization context

If there is application logic that needs the `Current.organization`, it should be passed from the request layer:

```ruby
# In controllers
def create
  @group = Groups::CreateService.new(
    current_user,
    group_params.with_defaults(organization_id: Current.organization.id)
  ).execute
end
```

### Scoping queries to organizations

An ActiveRecord extension (`gitlab-database-data_isolation`) scopes queries to the
current organization, dependent on the isolation state of the organization.
For more information, see [Organization data isolation](query_scoping.md).

## Organization routing

Organization-scoped routes use the `/o/:organization_path/` pattern (for example, `/o/my-org/projects`).
Always use regular, unscoped Rails URL helpers like `projects_path` and GitLab automatically routes based on `Current.organization`. This ensures switching between organization-scoped routes and global routes automatically.

```ruby
# Recommended: Use global route helpers
projects_path                    # Automatically becomes /o/my-org/projects if Current.organization is set
project_issues_path(@project)    # Automatically becomes /o/my-org/namespace/project/-/issues
```

### How it works

The organization URL helper system is implemented in [`Routing::OrganizationsHelper::MappedHelpers`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/helpers/routing/organizations_helper.rb). When routes are loaded, the system:

1. Scans all routes to find organization-scoped routes (those containing `/o/:organization_path`)
1. Builds a mapping between global route names and organization route names
1. Overrides standard Rails URL helpers (like `projects_path`, `groups_url`, etc.) to be organization-aware
1. When `Current.organization` is present and the organization has scoped paths enabled, the helpers automatically use the organization-scoped version of the route
1. Preserves the original `root_path` and `root_url` as `unscoped_root_path` and `unscoped_root_url`

This approach preserves organization context throughout the request lifecycle. For example, `GET /o/my-org/projects` routes to `ProjectsController#index` (same as `/projects`) with the organization context available via `Current.organization`.

Use explicit organization helpers only when you need to generate a URL for a specific organization that differs from `Current.organization`, or when working outside the request layer (services, workers, Rake tasks) where `Current.organization` is not available:

```ruby
# Explicit organization helpers
organization_projects_path(organization_path: 'my-org')           # /o/my-org/projects
organization_project_issues_path(@project, organization_path: 'my-org')  # /o/my-org/namespace/project/-/issues
```

### Routes not yet organization-scoped

Some routes are not currently available under the organization scope:

- **Devise OmniAuth callbacks** - Devise does not support scoping OmniAuth callbacks under a dynamic segment, so these remain at the global level
- **API routes** - API endpoints are not yet organization-scoped

## Testing organization isolation

Enable the following feature flags to test organizations:

- `ui_for_organizations`
- `organization_switching`

When making features organization-aware, pay special attention to areas where cross-organization data leakage could occur.
Examples include:

- Group and project member invites
- User mentions in issues, merge requests, or comments
- User search and autocomplete results
- Issue, merge request, milestone, and label references across organizations
- Finder classes scoping results to the current organization

A helpful convention for manual testing in your development environment is to create an organization with an obvious
name and prefix all its associated data. This makes it easy to visually confirm whether data from other organizations
has accidentally been exposed.

Create an Organization named `Secret Tanuki` and prefix all its associated data with this name:

- Organization: `Secret Tanuki`
- Users: `Secret Tanuki User Bob`, `Secret Tanuki User Alice`
- Projects: `Secret Tanuki Project X`, `Secret Tanuki Project Y`
- Issues: `Secret Tanuki Issue #42`, `Secret Tanuki Issue #99`
- Groups: `Secret Tanuki Group`
- Merge Requests: `Secret Tanuki MR: Add feature`

When testing for data leaks, search your UI or API responses for `Secret Tanuki`. If you find it where it shouldn't be,
you've discovered a cross-organization data leak. This is particularly useful when:

- Testing search and autocomplete features
- Verifying member invitations don't leak across organizations
- Checking that mentions and references are properly scoped
- Reviewing API responses for unintended data exposure

### Automated testing

For automated testing strategies, see [Testing with Organizations](../testing_guide/testing_with_organizations.md).

## Frontend guidelines

### REST API and GraphQL requests

Providing the current organization context to REST API and GraphQL requests does not require any additional arguments. Behind the scenes the current organization is passed via the `X-GitLab-Organization-ID` header in [axios_utils.js#L15](https://gitlab.com/gitlab-org/gitlab/-/blob/3deab3ebc51cdbb14de4a593b35d3df2e26f34bc/app/assets/javascripts/lib/utils/axios_utils.js#L15) and [graphql.js#L183](https://gitlab.com/gitlab-org/gitlab/-/blob/3deab3ebc51cdbb14de4a593b35d3df2e26f34bc/app/assets/javascripts/lib/graphql.js#L183).

### URLs

Do not hardcode or construct URLs on the frontend as they will not support [organization routing](#organization-routing). See [URLs in GitLab](../urls_in_gitlab.md#frontend-guidelines) for guidelines on how to generate URLs on the frontend.

### Accessing the current organization

The current organization context is available on the frontend via `window.gon.current_organization`. Behind the scenes this is exposed to the frontend in [gon_helper.rb#L69](https://gitlab.com/gitlab-org/gitlab/-/blob/f8cdb7b281830854374686003edf7bb66b7a59fa/lib/gitlab/gon_helper.rb#L69).

## Related topics

- [Sharding guidelines](sharding/_index.md)
- [Organization user documentation](../../user/organization/_index.md)
- [Testing with Organizations](../testing_guide/testing_with_organizations.md)
- [Consolidating groups and projects](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/consolidating_groups_and_projects/) architecture documentation
