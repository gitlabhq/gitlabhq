---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret Detection post-processing and revocation **(FREE SAAS)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4639) in GitLab 13.6.
> - [Disabled by default for GitLab personal access tokens](https://gitlab.com/gitlab-org/gitlab/-/issues/371658) in GitLab 15.6 [with a flag](../../../administration/feature_flags.md) named `gitlab_pat_auto_revocation`. Available to GitLab.com only.

FLAG:
By default, auto revocation of GitLab personal access tokens is not available. To opt-in on GitLab.com
during the [Beta period](../../../policy/alpha-beta-support.md#beta-features), please
[let us know by completing this form](https://docs.google.com/forms/d/e/1FAIpQLSdRbFhvA5jvI-Rt_Qnl1PQ1znOXKK8m6lRtmM0uva4upetKvQ/viewform).

GitLab supports running post-processing hooks after detecting a secret. These
hooks can perform actions, like notifying the cloud service that issued the secret.
The cloud provider can then confirm the credentials and take remediation actions, like:

- Revoking a secret.
- Reissuing a secret.
- Notifying the creator of the secret.

GitLab SaaS supports post-processing for [GitLab personal access tokens](../../profile/personal_access_tokens.md) and Amazon Web Services (AWS).
Post-processing workflows vary by supported cloud providers.

Post-processing is limited to a project's default branch. The epic
[Post-processing of leaked secrets](https://gitlab.com/groups/gitlab-org/-/epics/4639).
contains:

- Technical details of post-processing secrets.
- Discussions of efforts to support additional branches.

NOTE:
Post-processing is currently limited to a project's default branch

## High-level architecture

This diagram describes how a post-processing hook revokes a secret within the GitLab application:

```mermaid
sequenceDiagram
    autonumber
    GitLab Rails->>+Sidekiq: gl-secret-detection-report.json
    Sidekiq-->+Sidekiq: StoreSecurityReportsWorker
    Sidekiq-->+RevocationAPI: GET revocable keys types
    RevocationAPI-->>-Sidekiq: OK
    Sidekiq->>+RevocationAPI: POST revoke revocable keys
    RevocationAPI-->>-Sidekiq: ACCEPTED
    RevocationAPI-->>+Cloud Vendor: revoke revocable keys
    Cloud Vendor-->>+RevocationAPI: ACCEPTED
```

## Integrate your cloud provider service with GitLab SaaS

Third party cloud and SaaS providers can [express integration interest by filling out this form](https://forms.gle/wWpvrtLRK21Q2WJL9).

### Implement a vendor revocation receiver service

A vendor revocation receiver service integrates with a GitLab instance to receive
a web notification and respond to leaked token requests.

To implement a receiver service to revoke leaked tokens:

1. Create a publicly accessible HTTP service matching the corresponding API contract
   below. Your service should be idempotent and rate-limited.
1. When a pipeline corresponding to its revocable token type (in the example, `my_api_token`)
   completes, GitLab sends a request to your receiver service.
1. The included URL should be publicly accessible, and contain the commit where the
   leaked token can be found. For example:

    ```plaintext
    POST / HTTP/2
    Accept: */*
    Content-Type: application/json
    X-Gitlab-Token: MYSECRETTOKEN

    [
      {"type": "my_api_token", "token":"XXXXXXXXXXXXXXXX","url": "https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile1.java"}
    ]
    ```

## Implement a revocation service for self-managed

Self-managed instances interested in using the revocation capabilities must:

- Deploy the [RevocationAPI](#high-level-architecture).
- Configure the GitLab instance to use the RevocationAPI.

A RevocationAPI must:

- Match a minimal API specification.
- Provide two endpoints:
  - Fetching revocable token types.
  - Revoking leaked tokens.
- Be rate-limited and idempotent.

Requests to the documented endpoints are authenticated via API tokens passed in
the `Authorization` header. Request and response bodies, if present, are
expected to have the content type `application/json`.

All endpoints may return these responses:

- `401 Unauthorized`
- `405 Method Not Allowed`
- `500 Internal Server Error`

### `GET /v1/revocable_token_types`

Returns the valid `type` values for use in the `revoke_tokens` endpoint.

NOTE:
These values match the concatenation of [the `secrets` analyzer's](index.md)
[primary identifier](../../../development/integrations/secure.md#identifiers) by means
of concatenating the `primary_identifier.type` and `primary_identifier.value`.
In the case below, a finding identifier matches:

```json
{"type": "gitleaks_rule_id", "name": "Gitleaks rule ID GitLab Personal Access Token", "value": "GitLab Personal Access Token"}
```

| Status Code | Description |
| ----- | --- |
| `200` | The response body contains the valid token `type` values. |

Example response body:

```json
{
    "types": ["gitleaks_rule_id_gitlab_personal_access_token"]
}
```

### `POST /v1/revoke_tokens`

Accepts a list of tokens to be revoked by the appropriate provider.

| Status Code | Description |
| ----- | --- |
| `204` | All submitted tokens have been accepted for eventual revocation. |
| `400` | The request body is invalid or one of the submitted token types is not supported. The request should not be retried. |
| `429` | The provider has received too many requests. The request should be retried later. |

Example request body:

```json
[{
    "type": "gitleaks_rule_id_gitlab_personal_access_token",
    "token": "glpat--8GMtG8Mf4EnMJzmAWDU",
    "location": "https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile1.java"
},
{
    "type": "gitleaks_rule_id_gitlab_personal_access_token",
    "token": "glpat--tG84EGK33nMLLDE70zU",
    "location": "https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile2.java"
}]
```

### Configure GitLab to interface with RevocationAPI

You must configure the following database settings in the GitLab instance:

- `secret_detection_token_revocation_enabled`
- `secret_detection_token_revocation_url`
- `secret_detection_token_revocation_token`
- `secret_detection_revocation_token_types_url`

For example, to configure these values in the
[Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_token: 'MYSECRETTOKEN')
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_url: 'https://example.gitlab.com/revocation_service/v1/revoke_tokens')
::Gitlab::CurrentSettings.update!(secret_detection_revocation_token_types_url: 'https://example.gitlab.com/revocation_service/v1/revocable_token_types')
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_enabled: true)
```

After you configure these values, completing a pipeline performs these actions:

1. The revocation service is triggered once.
1. A request is made to `secret_detection_revocation_token_types_url` to fetch a
   list of revocable tokens.
1. Any Secret Detection findings matching the results of the `token_types` request
   are included in the subsequent revocation request.
