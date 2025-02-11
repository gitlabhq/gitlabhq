---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API that exposes token information."
title: Token information API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed
**Status:** Experiment

Use this API to retrieve details about arbitrary tokens and to revoke them. Unlike other APIs that expose token information, this API allows you to retrieve details or revoke tokens without knowing the specific type of token.

## Token prefixes

When making a request, `personal`, `project` or `group access` tokens must begin with `glpat` or the current [custom prefix](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix). If the token begins with a previous custom prefix, the operation will fail. Interest in support for previous custom prefixes is tracked in [issue 165663](https://gitlab.com/gitlab-org/gitlab/-/issues/165663).

Prerequisites:

- You must have administrator access to the instance.

## Get information on a token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165157) in GitLab 17.5 [with a flag](../../administration/feature_flags.md) named `admin_agnostic_token_finder`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/490572) in GitLab 17.8. Feature flag `admin_agnostic_token_finder` removed.
> - [Feed tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169821) in GitLab 17.6.
> - [OAuth application secrets added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172985) in GitLab 17.7.
> - [Cluster agent tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172932) in GitLab 17.7.
> - [Runner authentication tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173987) in GitLab 17.7.
> - [Pipeline trigger tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174030) in GitLab 17.7.
> - [CI/CD Job Tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175234) in GitLab 17.9.
> - [Feature flags client tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177431) in GitLab 17.9.
> - [GitLab session cookies added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178022) in GitLab 17.9.
> - [Incoming email tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177077) in GitLab 17.9.

Gets information for a given token. This endpoint supports the following tokens:

- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Impersonation tokens](../rest/authentication.md#impersonation-tokens)
- [Deploy tokens](../../user/project/deploy_tokens/_index.md)
- [Feed tokens](../../security/tokens/_index.md#feed-token)
- [OAuth application secrets](../../integration/oauth_provider.md)
- [Cluster agent tokens](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [Runner authentication tokens](../../security/tokens/_index.md#runner-authentication-tokens)
- [Pipeline trigger tokens](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [CI/CD Job Tokens](../../security/tokens/_index.md#cicd-job-tokens)
- [Feature flags client tokens](../../operations/feature_flags.md#get-access-credentials)
- [GitLab session cookies](../../user/profile/active_sessions.md)
- [Incoming email tokens](../../security/tokens/_index.md#incoming-email-token)

```plaintext
POST /api/v4/admin/token
```

Supported attributes:

| Attribute    | Type    | Required | Description                |
|--------------|---------|----------|----------------------------|
| `token`      | string  | Yes      | Existing token to identify. `Personal`, `project` or `group access` tokens must begin with `glpat` or the current [custom prefix](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix). |

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the token.

Can return the following status codes:

- `200 OK`: Information about the token.
- `401 Unauthorized`: The user is not authorized.
- `403 Forbidden`: The user is not an administrator.
- `404 Not Found`: The token was not found.
- `422 Unprocessable`: The token type is not supported.

Example request:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

Example response:

```json
{
 "id": 1,
 "user_id": 70,
 "name": "project-access-token",
 "revoked": false,
 "expires_at": "2024-10-04",
 "created_at": "2024-09-04T07:19:18.652Z",
 "updated_at": "2024-09-04T07:19:18.652Z",
 "scopes": [
  "api",
  "read_api"
 ],
 "impersonation": false,
 "expire_notification_delivered": false,
 "last_used_at": null,
 "after_expiry_notification_delivered": false,
 "previous_personal_access_token_id": null,
 "advanced_scopes": null,
 "organization_id": 1
}
```

## Revoke a token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170421) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `api_admin_token_revoke`. Disabled by default.
> - [Cluster agent tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178211) in GitLab 17.9.
> - [Runner authentication tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179066) in GitLab 17.9.
> - [OAuth application secrets added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179035) in GitLab 17.9.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Revokes or resets a given token based on the token type. This endpoint supports the following token types:

| Token type                                                                                   | Supported action   |
|----------------------------------------------------------------------------------------------|--------------------|
| [Personal access tokens](../../user/profile/personal_access_tokens.md)                       | Revoke             |
| [Impersonation tokens](../../user/profile/personal_access_tokens.md)                         | Revoke             |
| [Project access tokens](../../security/tokens/_index.md#project-access-tokens)               | Revoke             |
| [Group access tokens](../../security/tokens/_index.md#group-access-tokens)                   | Revoke             |
| [Deploy tokens](../../user/project/deploy_tokens/_index.md)                                   | Revoke             |
| [Cluster agent tokens](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)          | Revoke             |
| [Feed tokens](../../security/tokens/_index.md#feed-token)                                    | Reset              |
| [Runner authentication tokens](../../security/tokens/_index.md#runner-authentication-tokens) | Reset              |
| [OAuth application secrets](../../integration/oauth_provider.md)                             | Reset              |

```plaintext
DELETE /api/v4/admin/token
```

Supported attributes:

| Attribute    | Type    | Required | Description              |
|--------------|---------|----------|--------------------------|
| `token`      | string  | Yes      | Existing token to revoke. `Personal`, `project` or `group access` tokens must begin with `glpat` or the current [custom prefix](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix). |

If successful, returns [`204`](../rest/troubleshooting.md#status-codes) without content.

Can return the following status codes:

- `204 No content`: Token has been revoked.
- `401 Unauthorized`: The user is not authorized.
- `403 Forbidden`: The user is not an administrator.
- `404 Not Found`: The token was not found.
- `422 Unprocessable`: The token type is not supported.

Example request:

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```
