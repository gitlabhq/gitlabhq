---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Job token permission development guidelines
---

## Background

Job token permissions allow fine-grained access control for CI/CD job tokens that access GitLab API endpoints.
When enabled, the job token can only perform actions allowed for the project.

Historically, job tokens have provided broad access to resources by default. With the introduction of
fine-grained permissions for job tokens, we can enable granular access controls while adhering to the
principle of least privilege.

This topic provide guidance on the requirements and contribution guidelines for new job token permissions.

## Requirements

Before being accepted, all new job token permissions must:

- Be opt-in and disabled by default.
- Complete a review by the GitLab security team.
  - Tag `@gitlab-com/gl-security/product-security/appsec` for review

These requirements ensure that new permissions allow users to maintain explicit control over their security configuration, prevent unintended privilege escalation, and adhere to the principle of least privilege.

## Add a job token permission

Job token permissions are defined in several locations. When adding new permissions, ensure the following files are updated:

- **Backend permission definitions**: [`lib/ci/job_token/policies.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/ci/job_token/policies.rb) - Lists the available permissions.
- **JSON schema validation**: [`app/validators/json_schemas/ci_job_token_policies.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/validators/json_schemas/ci_job_token_policies.json) - Defines the validation schema for the `job_token_policies` attribute of the `Ci::JobToken::GroupScopeLink` and `Ci::JobToken::ProjectScopeLink` models.
- **Frontend constants**: [`app/assets/javascripts/token_access/constants.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/token_access/constants.js) - Lists the permission definitions for the UI

## Add an API endpoint to a job token permission scope

### Route settings

To add job token policy support to an API endpoint, you need to configure two route settings:

#### `route_setting :authentication`

This setting controls which authentication methods are allowed for the endpoint.

**Parameters**:

- `job_token_allowed: true` - Enables CI/CD job tokens to authenticate against this endpoint

#### `route_setting :authorization`

This setting defines the permission level and access controls for job token access.

**Parameters**:

- `job_token_policies`: The required permission level. Available policies are listed in [lib/ci/job_token/policies.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/ci/job_token/policies.rb).
- `allow_public_access_for_enabled_project_features`: Optional. Allows access based on the visibility settings of the project feature. See [public access configuration](#public-access-configuration).

#### Example usage

This example shows how to add support for `tags` API endpoints to the job token policy's `repository` resource:

```ruby
# In lib/api/tags.rb

resource :projects do
  # Enable job token authentication for this endpoint
  route_setting :authentication, job_token_allowed: true
  # Require the `read_repository` policy for reading tags
  route_setting :authorization, job_token_policies: :read_repository,
    allow_public_access_for_enabled_project_features: :repository
  get ':id/repository/tags' do
    # ... existing endpoint implementation
  end

  # Enable job token authentication for this endpoint
  route_setting :authentication, job_token_allowed: true
  # Require the `admin_repository` policy for creating tags
  route_setting :authorization, job_token_policies: :admin_repository
  post ':id/repository/tags' do
    # ... existing endpoint implementation
  end
end
```

### Key considerations

#### Permission level selection

Choose the appropriate permission level based on the operation:

- **Read operations** (GET requests): Use `:read_*` permissions
- **Write/Delete operations** (POST, PUT, DELETE requests): Use `:admin_*` permissions

#### Public access configuration

The `allow_public_access_for_enabled_project_features` parameter allows job tokens to access endpoints when:

- The project has appropriate visibility.
- The project feature is enabled.
- The project feature has appropriate visibility.
- Job token permissions are not explicitly configured for the resource.

This provides backward compatibility while enabling fine-grained control when the project feature is not publicly accessible.

### Testing

When implementing job token permissions for API endpoints, use the shared RSpec example `'enforcing job token policies'` to test the authorization behavior. This shared example provides comprehensive coverage for all job token policy scenarios.

#### Usage

Add the shared example to your API endpoint tests by including it with the required parameters:

```ruby
describe 'GET /projects/:id/repository/tags' do
  let(:route) { "/projects/#{project.id}/repository/tags" }

  it_behaves_like 'enforcing job token policies', :read_repository,
    allow_public_access_for_enabled_project_features: :repository do
    let(:user) { developer }
    let(:request) do
      get api(route), params: { job_token: target_job.token }
    end
  end

  # Your other endpoint-specific tests...
end
```

#### Parameters

The shared example takes the following parameters:

- The job token policy that should be enforced (e.g., `:read_repository`)
- `allow_public_access_for_enabled_project_features` - (Optional) The project feature that the endpoint controls (e.g., `:repository`)
- `expected_success_status` - (Optional) The expected success status of the request (by default: `:success`)

#### What the shared example tests

The `'enforcing job token policies'` shared example automatically tests:

1. **Access granted**: Job tokens can access the endpoint when the required permissions are configured for the accessed project.
1. **Access denied**: Job tokens cannot access the endpoint when the required permissions are not configured for the accessed project.
1. **Public access fallback**: `allow_public_access_for_enabled_project_features` behavior when permissions aren't configured.

### Documentation

After you add job token support for a new API endpoint, you must update the [fine-grained permissions for CI/CD job tokens](../../ci/jobs/fine_grained_permissions.md#available-api-endpoints) documentation.
Run the following command to regenerate this topic:

```shell
bundle exec rake ci:job_tokens:compile_docs
```
