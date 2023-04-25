---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: tutorial
---

# OpenID Connect (OIDC) Authentication Using ID Tokens **(FREE)**

You can authenticate with third party services using GitLab CI/CD's
[ID tokens](../yaml/index.md#id_tokens).

## ID Tokens

[ID tokens](../yaml/index.md#id_tokens) are JSON Web Tokens (JWTs) that can be added to a GitLab CI/CD job. They can be used for OIDC
authentication with third-party services, and are used by the [`secrets`](../yaml/index.md#secrets) keyword to authenticate with HashiCorp Vault.

ID tokens are configured in the `.gitlab-ci.yml`. For example:

```yaml
job_with_id_tokens:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  script:
    - first-service-authentication-script.sh $FIRST_ID_TOKEN
    - second-service-authentication-script.sh $SECOND_ID_TOKEN
```

In this example, the two tokens have different `aud` claims. Third party services can be configured to reject tokens
that do not have an `aud` claim matching their bound audience. Use this functionality to reduce the number of
services with which a token can authenticate. This reduces the severity of having a token compromised.

### Token payload

The following standard claims are included in each ID token:

| Field                                                              | Description |
|--------------------------------------------------------------------|-------------|
| [`iss`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.1) | Issuer of the token, which is the domain of the GitLab instance ("issuer" claim). |
| [`sub`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.2) | `project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}` ("subject" claim). |
| [`aud`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.3) | Intended audience for the token ("audience" claim). Specified in the [ID tokens](../yaml/index.md#id_tokens) configuration. The domain of the GitLab instance by default. |
| [`exp`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.4) | The expiration time ("expiration time" claim). |
| [`nbf`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.5) | The time after which the token becomes valid ("not before" claim). |
| [`iat`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.6) | The time the JWT was issued ("issued at" claim). |
| [`jti`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.7) | Unique identifier for the token ("JWT ID" claim). |

The token also includes custom claims provided by GitLab:

| Field                   | When                         | Description |
|-------------------------|------------------------------|-------------|
| `namespace_id`          | Always                       | Use this to scope to group or user level namespace by ID. |
| `namespace_path`        | Always                       | Use this to scope to group or user level namespace by path. |
| `project_id`            | Always                       | Use this to scope to project by ID. |
| `project_path`          | Always                       | Use this to scope to project by path. |
| `user_id`               | Always                       | ID of the user executing the job. |
| `user_login`            | Always                       | Username of the user executing the job. |
| `user_email`            | Always                       | Email of the user executing the job. |
| `pipeline_id`           | Always                       | ID of the pipeline. |
| `pipeline_source`       | Always                       | [Pipeline source](../jobs/job_control.md#common-if-clauses-for-rules). |
| `job_id`                | Always                       | ID of the job. |
| `ref`                   | Always                       | Git ref for the job. |
| `ref_type`              | Always                       | Git ref type, either `branch` or `tag`. |
| `ref_protected`         | Always                       | `true` if the Git ref is protected, `false` otherwise. |
| `environment`           | Job specifies an environment | Environment this job deploys to ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294440) in GitLab 13.9). |
| `environment_protected` | Job specifies an environment | `true` if deployed environment is protected, `false` otherwise ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294440) in GitLab 13.9). |
| `deployment_tier`       | Job specifies an environment | [Deployment tier](../environments/index.md#deployment-tier-of-environments) of the environment the job specifies. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363590) in GitLab 15.2. |
| `runner_id`             | Always                       | ID of the runner executing the job. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404722) in GitLab 16.0. |
| `runner_environment`    | Always                       | The type of runner used by the job. Can be either `gitlab-hosted` or `self-hosted`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404722) in GitLab 16.0. |
| `sha`                   | Always                       | The commit SHA for the job. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404722) in GitLab 16.0. |

```json
{
  "namespace_id": "72",
  "namespace_path": "my-group",
  "project_id": "20",
  "project_path": "my-group/my-project",
  "user_id": "1",
  "user_login": "sample-user",
  "user_email": "sample-user@example.com",
  "pipeline_id": "574",
  "pipeline_source": "push",
  "job_id": "302",
  "ref": "feature-branch-1",
  "ref_type": "branch",
  "ref_protected": "false",
  "environment": "test-environment2",
  "environment_protected": "false",
  "deployment_tier": "testing",
  "runner_id": 1,
  "runner_environment": "self-hosted",
  "sha": "714a629c0b401fdce83e847fc9589983fc6f46bc",
  "jti": "235b3a54-b797-45c7-ae9a-f72d7bc6ef5b",
  "iss": "https://gitlab.example.com",
  "iat": 1681395193,
  "nbf": 1681395188,
  "exp": 1681398793,
  "sub": "project_path:my-group/my-project:ref_type:branch:ref:feature-branch-1",
  "aud": "https://vault.example.com"
}
```

The ID token is encoded by using RS256 and signed with a dedicated private key. The expiry time for the token is set to
the job's timeout if specified, or 5 minutes if no timeout is specified.

## Manual ID Token authentication

You can use ID tokens for OIDC authentication with a third party service. For example:

```yaml
manual_authentication:
  variables:
    VAULT_ADDR: http://vault.example.com:8200
  image: vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: http://vault.example.com:8200
  script:
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=myproject-example jwt=$VAULT_ID_TOKEN)"
    - export PASSWORD="$(vault kv get -field=password secret/myproject/example/db)"
    - my-authentication-script.sh $VAULT_TOKEN $PASSWORD
```

## Automatic ID Token authentication with HashiCorp Vault **(PREMIUM)**

You can use ID tokens to automatically fetch secrets from HashiCorp Vault with the
[`secrets`](../yaml/index.md#secrets) keyword.

### Enable automatic ID token authentication

To enable automatic ID token authentication:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Toggle **Limit JSON Web Token (JWT) access** to enabled.

### Configure automatic ID Token authentication

If one ID token is defined, the `secrets` keyword automatically uses it to authenticate with Vault. For example:

```yaml
job_with_secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://example.vault.com
  secrets:
    PROD_DB_PASSWORD:
      vault: example/db/password # authenticates using $VAULT_ID_TOKEN
  script:
    - access-prod-db.sh --token $PROD_DB_PASSWORD
```

If more than one ID token is defined, use the `token` keyword to specify which token should be used. For example:

```yaml
job_with_secrets:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  secrets:
    FIRST_DB_PASSWORD:
      vault: first/db/password
      token: $FIRST_ID_TOKEN
    SECOND_DB_PASSWORD:
      vault: second/db/password
      token: $SECOND_ID_TOKEN
  script:
    - access-first-db.sh --token $FIRST_DB_PASSWORD
    - access-second-db.sh --token $SECOND_DB_PASSWORD
```
