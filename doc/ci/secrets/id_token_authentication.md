---
stage: Verify
group: Pipeline Authoring
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
