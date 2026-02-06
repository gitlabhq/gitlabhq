---
stage: Tenant Scale
group: Organizations
info: 'See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines'
description: 'Development Guidelines: learn about organization when developing GitLab.'
title: Organization
---

The [Organization initiative](../../user/organization/_index.md) focuses on reaching feature parity between
GitLab.com and GitLab Self-Managed.

## Current phase (FY27-Q1 and FY27-Q2): Feature parity

The current development focus is achieving **feature parity** for organizations. This means ensuring that existing features work for groups inside organizations so users who transfer to an organization don't lose functionality.

**Organizations is not yet ready for new features.** Any new features should continue to target:

- **GitLab.com**: Top-level groups
- **GitLab Self-Managed**: Instance level

Guidance on building new features on organizations, or migrating existing features from top-level group to organizations, will come in the future.
Please contact the team on Slack (`#g_organizations`) if you wish to informally discuss this.

## Using `Current.organization`

The application maps incoming requests to an organization through `Current.organization`. This context is automatically set in the request layer and should be used to ensure data is properly scoped to the current organization.

### Where `Current.organization` is available

`Current.organization` is available in:

- Controllers
- GraphQL
- Grape API endpoints (use the `set_current_organization` helper)
- Sidekiq

### Passing organization context

When creating or updating records, pass the organization context using `Current.organization`:

```ruby
# In controllers
def create
  @group = Groups::CreateService.new(
    current_user,
    group_params.with_defaults(organization_id: Current.organization.id)
  ).execute
end

# In GraphQL mutations
def resolve(args)
  args[:organization_id] = Current.organization.id
  # ...
end

# In finders
@snippets = SnippetsFinder.new(
  current_user,
  organization_id: Current.organization.id,
  author: current_user
).execute
```

### Scoping queries to organizations

Ensure queries are scoped to the current organization:

```ruby
@labels = Label.in_organization(organization).templates
@topic = Projects::Topic.in_organization(organization.id).find_by_name(topic_name)
```

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

- `organization_scoped_paths`
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

For automated testing strategies, see [Testing with Organizations](../../development/testing_guide/testing_with_organizations.md).

## Related topics

- [Sharding guidelines](sharding/_index.md)
- [Organization user documentation](../../user/organization/_index.md)
- [Testing with Organizations](../../development/testing_guide/testing_with_organizations.md)
- [Consolidating groups and projects](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/consolidating_groups_and_projects/) architecture documentation
