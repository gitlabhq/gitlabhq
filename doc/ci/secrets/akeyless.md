---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
ignore_in_report: true
title: Use Akeyless secrets in GitLab CI/CD
---

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164040) in GitLab 17.4.

FLAG:
This feature is an [experiment](../../policy/development_stages_support.md)
and not intended for production use. There is no support available for this feature
and it is subject to removal at any time in accordance to GitLab policy.

You can use the `secrets:akeyless` keyword to authenticate and retrieve Akeyless secrets.

Prerequisites:

- Save your Akeyless access ID as a [CI/CD variable in your GitLab project](../variables/_index.md#for-a-project)
  named `AKEYLESS_ACCESS_ID`.
- This integration only supports [static secrets](https://docs.akeyless.io/docs/static-secrets).

To retrieve secrets from Akeyless, review the CI/CD configuration example that matches
your use case. The `akeyless:name` keyword can contain any secrets type.

## JWT authentication

```yaml
job:
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AKEYLESS_JWT
      akeyless:
        name: 'secret_name'
```

## `akeyless_token`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_token: '<akeyless_token>'
```

## Akeyless access types

### `aws_iam`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'aws_iam'
```

### `azure_ad`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'azure_ad'
        azure_object_id: 'azure_object_id'
```

### `gcp`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'gcp'
        gcp_audience: 'gcp_audience'
```

### `universal_identity`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'universal_identity'
        uid_token: 'uid_token'
```

### `k8s`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'k8s'
        k8s_service_account_token: 'k8s_service_account_token'
        k8s_auth_config_name: 'k8s_auth_config_name'
        akeyless_api_url: 'akeyless_api_url'
```

### `api_key`

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      akeyless:
        name: 'secret_name'
        akeyless_access_type: 'api_key'
        akeyless_access_key: "<Access Key>"
```

If you intend to fetch multiple secrets or run multiple jobs using the same Akeyless token,
you should run the first job as follows to store and re-use the same token as a dedicated CI/CD variable.

## JWT reuse

When re-using the same token, there is no `akeyless:name` reference, which allows the token
to be re-used for multiple jobs.

```yaml
job:  # This job fetches the Akeyless Token
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    AKEYLESS_TOKEN:
      token: $AKEYLESS_JWT
      akeyless:
```

## Fetch a JSON Secret

```yaml
job:
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AKEYLESS_JWT
      akeyless:
        name: 'secret_name'
        data_key: 'imp'
```

This example fetches the `imp` JSON key.

## Issue certificate

Use `public_key_data` when issuing certificates.

### SSH

```yaml
job:
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AKEYLESS_JWT
      akeyless:
        name: 'secret_name'
        cert_user_name: 'cert_user_name'
        public_key_data: 'public_key_data'
```

### Issue certificate

```yaml
job:
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AKEYLESS_JWT
      akeyless:
        name: 'secret_name'
        public_key_data: 'public_key_data'
```

You can also use `csr_data` instead of `public_key_data`.

## Work with a gateway

Set your gateway URL using the `akeyless_api_url` keyword. When working with a CA Certificate
you can provide your `gateway_ca_certificate` as well:

```yaml
job:
  id_tokens:
    AKEYLESS_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AKEYLESS_JWT
      akeyless:
        name: 'secret_name'
        akeyless_api_url: 'http://gateway_url:8080/v2'
        gateway_ca_certificate: 'ca_certificate'
```

## Troubleshooting

### `The secrets provider can not be found. Check your CI/CD variables and try again.` message

You might receive this error when attempting to start a job configured to access Akeyless:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

The job can't be created because the required variable is not defined:

- `AKEYLESS_ACCESS_ID`
