---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting GitLab tokens
---

When working with GitLab tokens, you might encounter the following issues.

## Token appears active but requests fail

A token that is listed as active can still return `401 Unauthorized`, `403 Forbidden`, or
`404 Not Found` responses. The active status indicates only that the token exists and has not expired
or been revoked. This status does not mean the token can make a given request. If the token has expired
or been revoked, see [Requests fail after a token expires](#requests-fail-after-a-token-expires) instead.

A token's permissions depend on its scopes and its role. A request can also fail for reasons outside
the token: where the request comes from, the resource the request targets, and whether an administrator has
turned off access tokens. None of these factors are apparent from the token itself. Personal, project, and
group access tokens all use the same `glpat-` prefix. Two tokens that look identical can therefore
behave differently.

An active token can fail for any of the following reasons:

| Cause | Resolution |
|-------|------------|
| The token is missing a scope that the request requires. | Create a token with the necessary [access token scopes](access_token_scopes.md). Rotation keeps the original scopes and cannot add missing scopes.  |
| A group or project access token doesn't have the required role. | Create a token with a higher role. A token's permissions are limited by both its role and its scopes. |
| The token expired. | Access tokens [expire at midnight UTC](#requests-fail-after-a-token-expires) on their expiration date. Create a token, then update every place that used the old token. |
| The token was revoked, or was rotated and the original value is still in use. | Rotation makes the original token inactive immediately. Use the token that the rotation created, or create a token. On GitLab Self-Managed and GitLab Dedicated, an administrator can [restore a personal access token](#restore-a-personal-access-token) that was revoked by accident. |
| The token type cannot access the resource. | Use a token type that can access the resource. A personal access token accesses the groups and projects available to its user. A group access token accesses the subgroups and projects in its group. A project access token accesses only its own project. |
| [IP address restrictions](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address) block the request. | These restrictions apply to group and project access tokens, and blocked requests return `404 Not Found`. Send the request from an allowed address, or ask a user with the Owner role for the top-level group to add the address to the allowed ranges. |
| [External authorization](../../administration/settings/external_authorization.md) is turned on. | Personal and project access tokens cannot access the container registry or the package registry. To restore access to the registries, turn off external authorization. |
| An administrator [turned off access tokens](../../user/profile/personal_access_tokens.md#disable-access-tokens) for the instance. | Ask an administrator or a user with the Owner role to turn access tokens back on. |

To identify which cause applies, compare the details of the failing token with a token that works:

- [Personal access tokens](../../user/profile/personal_access_tokens.md#view-token-usage-information)
- [Group access tokens](../../user/group/settings/group_access_tokens.md#view-your-access-tokens)
- [Project access tokens](../../user/project/settings/project_access_tokens.md#view-your-access-tokens)

The details include each token's scopes, expiration date, and usage information. Group and project
access tokens also show the assigned role.

If the token's usage information does not update after you make a request, the request might not be
reaching GitLab. GitLab updates usage times every 10 minutes and usage IP addresses every minute.
If GitLab isn't recording the usage after those intervals elapse, your request did not reach GitLab.

## Token does not work in an editor extension or command-line tool

A token that authenticates in the GitLab UI or API can still fail in an editor extension or a
command-line tool. Scope requirements differ between tools.

Valid tokens can fail in a tool for the following reasons:

| Cause | Resolution |
|-------|------------|
| The token requires different scopes. | Compare the [tool's required scopes](../../user/profile/personal_access_tokens.md#use-third-party-tools-and-ide-extensions) with the [scopes](access_token_scopes.md) added to the token. Create a token with the required scopes. Rotation keeps the original scopes and cannot add missing scopes. |
| The tool is not using the correct token. | Check which token the tool authenticates with, then update or remove the incorrect token. The GitLab for VS Code extension uses a token in the `GITLAB_WORKFLOW_TOKEN` [environment variable](../../editor_extensions/visual_studio_code/setup.md#store-tokens-in-environment-variables) only when no token is configured for that instance. This variable persists after you delete your VS Code storage. To override it, configure a token for the instance in the extension. |
| The tool cannot connect to GitLab. | If the token has the required scopes and the tool is using it, verify the tool can reach GitLab over your network. For the GitLab for VS Code extension, see [authentication troubleshooting](../../editor_extensions/visual_studio_code/troubleshooting.md#authentication). |

## Requests fail after a token expires

If an existing access token is in use and reaches the `expires_at` value, the token
expires and:

- Can no longer be used for authentication.
- Is not visible in the UI.

Requests made using this token return a `401 Unauthorized` response. Too many
unauthorized requests in a short period of time from the same IP address
result in `403 Forbidden` responses from GitLab.com.

For more information on authentication request limits, see [Git and container registry failed authentication ban](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban).

### Identify expired access tokens from logs

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464652) in GitLab 17.2.

{{< /history >}}

Prerequisites:

You must:

- Be an administrator.
- Have access to the [`api_json.log`](../../administration/logs/_index.md#api_jsonlog) file.

To identify which `401 Unauthorized` requests are failing due to
expired access tokens, use the following fields in the `api_json.log` file:

| Field name                        | Description |
|-----------------------------------|-------------|
| `meta.auth_fail_reason`           | The reason the request was rejected. Possible values: `token_expired`, `token_revoked`, `insufficient_scope`, and `impersonation_disabled`. |
| `meta.auth_fail_token_id`         | A string describing the type and ID of the attempted token. |
| `meta.auth_fail_requested_scopes` | The OAuth scopes the request required, space-separated. |
| `meta.auth_fail_token_type`       | The type of token used. Possible values: `PersonalAccessToken`, `CiJobToken`, and `unknown`. |
| `meta.auth_fail_auth_header_type` | How the token was passed in the request. Possible values: `private_token_header`, `private_token_param`, `bearer`, and `other`. |

When a user attempts to use an expired token, the `meta.auth_fail_reason`
is `token_expired`. The following shows an excerpt from a log
entry:

```json
{
  "status": 401,
  "method": "GET",
  "path": "/api/v4/user",
  ...
  "meta.auth_fail_reason": "token_expired",
  "meta.auth_fail_token_id": "PersonalAccessToken/12",
}
```

> [!note]
> In some cases, `meta.auth_fail_*` fields may appear on non-401 responses. Known cases include:
>
> - Git HTTP requests to public projects, where Rack::Attack records the token failure but
>   the project's public visibility allows the request to succeed.
> - The Unleash feature flags endpoint, which authorizes by `HTTP_UNLEASH_INSTANCEID` rather
>   than the token.
> - Workhorse pre-authorization (`/authorize`) endpoints, which perform their own authorization
>   after the token probe.

`meta.auth_fail_token_id` indicates that an access token of ID 12 was used.
In GitLab 18.9 and later, `meta.user` is also populated with any username associated with the token used
for the failed request.

To find more information about this token, use the [personal access token API](../../api/personal_access_tokens.md#retrieve-a-personal-access-token).
You can also use the API to [rotate the token](../../api/personal_access_tokens.md#rotate-a-personal-access-token).

### Replace expired access tokens

To replace the token:

1. Check where this token may have been used previously, and remove it from any
   automation that might still use the token.
   - For personal access tokens, use the [API](../../api/personal_access_tokens.md#list-all-personal-access-tokens)
     to list tokens that have expired recently. For example, go to `https://gitlab.com/api/v4/personal_access_tokens`,
     and locate tokens with a specific `expires_at` date.
   - For project access tokens, use the
     [project access tokens API](../../api/project_access_tokens.md#list-all-project-access-tokens)
     to list recently expired tokens.
   - For group access tokens, use the
     [group access tokens API](../../api/group_access_tokens.md#list-all-group-access-tokens)
     to list recently expired tokens.
1. Create a new access token:
   - For personal access tokens, [use the UI](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
     or [User tokens API](../../api/user_tokens.md#create-a-personal-access-token).
   - For a project access token, [use the UI](../../user/project/settings/project_access_tokens.md#create-a-project-access-token)
     or [project access tokens API](../../api/project_access_tokens.md#create-a-project-access-token).
   - For a group access token, [use the UI](../../user/group/settings/group_access_tokens.md#create-a-group-access-token)
     or [group access tokens API](../../api/group_access_tokens.md#create-a-group-access-token).
1. Replace the old access token with the new access token. This process varies
   depending on how you use the token, for example if configured as a secret or
   embedded in an application. Requests that use the new token no longer return `401` responses.

## Restore a personal access token

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

On GitLab Self-Managed or GitLab Dedicated instances, administrators can restore personal access tokens
that were revoked accidentally. Restoration is not available on GitLab.com.

> [!warning]
> Running the following commands changes data directly, which can cause damage if the commands are run
> incorrectly or in the wrong conditions. Run these commands first in a test environment, with a backup
> of the instance ready to restore.

1. Open a [Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Restore the token:

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   For example, to restore a token of `token-string-here123`:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## Tokens expire unexpectedly after an upgrade

Access tokens that have no expiration date are valid indefinitely, which is a security risk if the
token is divulged.

Depending on your GitLab version and offering, your existing access tokens might have an expiration
date automatically applied when you upgrade. For more information, see
[non-expiring access tokens](../../update/deprecations.md#non-expiring-access-tokens).
If you're not aware these dates changed, authentication can fail without warning.

In GitLab 17.3 and later, GitLab does not automatically set expiration dates on existing tokens.
Administrators can also [turn off expiration date enforcement for new access tokens](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens).

To analyze, extend, or remove token expiration dates, use the
[access token Rake tasks](../../administration/raketasks/tokens/_index.md).

## Related topics

- [Container registry authentication](../../user/packages/container_registry/authenticate_with_container_registry.md#troubleshooting)
- [CI/CD job token authentication](../../ci/jobs/ci_job_token.md#troubleshooting)
- [Troubleshooting two-factor authentication](../../user/profile/account/two_factor_authentication_troubleshooting.md)
- [Troubleshooting Git](../../topics/git/troubleshooting_git.md)
