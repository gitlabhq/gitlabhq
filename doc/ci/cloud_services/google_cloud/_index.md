---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure OpenID Connect with GCP Workload Identity Federation
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
`CI_JOB_JWT_V2` was [deprecated in GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)
and is scheduled to be removed in GitLab 17.0. Use [ID tokens](../../yaml/_index.md#id_tokens) instead.

This tutorial demonstrates authenticating to Google Cloud from a GitLab CI/CD job
using a JSON Web Token (JWT) token and Workload Identity Federation. This configuration
generates on-demand, short-lived credentials without needing to store any secrets.

To get started, configure OpenID Connect (OIDC) for identity federation between GitLab
and Google Cloud. For more information on using OIDC with GitLab, read
[Connect to cloud services](../_index.md).

This tutorial assumes you have a Google Cloud account and a Google Cloud project.
Your account must have at least the **Workload Identity Pool Admin** permission
on the Google Cloud project.

NOTE:
If you would prefer to use a Terraform module and a CI/CD template instead of this tutorial,
see [How OIDC can simplify authentication of GitLab CI/CD pipelines with Google Cloud](https://about.gitlab.com/blog/2023/06/28/introduction-of-oidc-modules-for-integration-between-google-cloud-and-gitlab-ci/).

To complete this tutorial:

1. [Create the Google Cloud Workload Identity Pool](#create-the-google-cloud-workload-identity-pool).
1. [Create a Workload Identity Provider](#create-a-workload-identity-provider).
1. [Grant permissions for service account impersonation](#grant-permissions-for-service-account-impersonation).
1. [Retrieve a temporary credential](#retrieve-a-temporary-credential).

## Create the Google Cloud Workload Identity Pool

[Create a new Google Cloud Workload Identity Pool](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider) with the following options:

- **Name**: Human-friendly name for the Workload Identity Pool, such as `GitLab`.
- **Pool ID**: Unique ID in the Google Cloud project for the Workload Identity Pool,
  such as `gitlab`. This value is used to refer to the pool and appears in URLs.
- **Description**: Optional. A description of the pool.
- **Enabled Pool**: Ensure this option is `true`.

We recommend creating a single _pool_ per GitLab installation per Google Cloud project. If you have multiple GitLab repositories and CI/CD jobs on the same GitLab instance, they can authenticate using different _providers_ against the same _pool_.

## Create a Workload Identity Provider

[Create a new Google Cloud Workload Identity Provider](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider)
inside the Workload Identity Pool created in the previous step, using the following options:

- **Provider type**: OpenID Connect (OIDC).
- **Provider name**: Human-friendly name for the Workload Identity Provider,
  such as `gitlab/gitlab`.
- **Provider ID**: Unique ID in the pool for the Workload Identity Provider,
  such as `gitlab-gitlab`. This value is used to refer to the provider, and appears in URLs.
- **Issuer (URL)**: The address of your GitLab instance, such as `https://gitlab.com/` or
  `https://gitlab.example.com/`.
  - The address must use the `https://` protocol.
  - The address must end in a trailing slash.
- **Audiences**: Manually set the allowed audiences list to the address of your
  GitLab instance, such as `https://gitlab.com` or `https://gitlab.example.com`.
  - The address must use the `https://` protocol.
  - The address must not end in a trailing slash.
- **Provider attributes mapping**: Create the following mappings, where `attribute.X` is the
  name of the attribute to be included as a claim in the Google token, and `assertion.X`
  is the value to extract from the [GitLab claim](../_index.md#how-it-works):

  | Attribute (on Google) | Assertion (from GitLab) |
  | --- | --- |
  | `google.subject` | `assertion.sub` |
  | `attribute.X` | `assertion.X` |

  You can also [build complex attributes](https://cloud.google.com/iam/docs/workload-identity-federation#mapping)
  using Common Expression Language (CEL).

  You must map every attribute that you want to use for permission granting. For example, if you want to map permissions in the next step based on the user's email address, you must map `attribute.user_email` to `assertion.user_email`.

## Grant permissions for Service Account impersonation

Creating the Workload Identity Pool and Workload Identity Provider defines the _authentication_
into Google Cloud. At this point, you can authenticate from GitLab CI/CD job into Google Cloud.
However, you have no permissions on Google Cloud (_authorization_).

To grant your GitLab CI/CD job permissions on Google Cloud, you must:

1. [Create a Google Cloud Service Account](https://cloud.google.com/iam/docs/service-accounts-create).
   You can use whatever name and ID you prefer.
1. [Grant IAM permissions](https://cloud.google.com/iam/docs/granting-changing-revoking-access) to your
   service account on Google Cloud resources. These permissions vary significantly based on
   your use case. In general, grant this service account the permissions on your Google Cloud
   project and resources you want your GitLab CI/CD job to be able to use. For example, if you needed to upload a file to a Google Cloud Storage bucket in your GitLab CI/CD job, you would grant this Service Account the `roles/storage.objectCreator` role on your Cloud Storage bucket.
1. [Grant the external identity permissions](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#impersonate)
   to impersonate that Service Account. This step enables a GitLab CI/CD job to _authorize_
   to Google Cloud, via Service Account impersonation. This step grants an IAM permission
   _on the Service Account itself_, giving the external identity permissions to act as that
   service account. External identities are expressed using the `principalSet://` protocol.

Much like the previous step, this step depends heavily on your desired configuration.
For example, to allow a GitLab CI/CD job to impersonate a Service Account named
`my-service-account` if the GitLab CI/CD job was initiated by a GitLab user with the
username `chris`, you would grant the `roles/iam.workloadIdentityUser` IAM role to the
external identity on `my-service-account`. The external identity takes the format:

```plaintext
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.user_login/chris
```

where `PROJECT_NUMBER` is your Google Cloud project number, and `POOL_ID` is the
ID (not name) of the Workload Identity Pool created in the first section.

This configuration also assumes you added `user_login` as an attribute mapped from
the assertion in the previous section.

## Retrieve a temporary credential

After you configure the OIDC and role, the GitLab CI/CD job can retrieve a temporary credential from the
[Google Cloud Security Token Service (STS)](https://cloud.google.com/iam/docs/reference/sts/rest).

Add `id_tokens` to your CI/CD job:

```yaml
job:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
```

Get temporary credentials using the ID token:

```shell
PAYLOAD="$(cat <<EOF
{
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "grantType": "urn:ietf:params:oauth:grant-type:token-exchange",
  "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token",
  "scope": "https://www.googleapis.com/auth/cloud-platform",
  "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt",
  "subjectToken": "${GITLAB_OIDC_TOKEN}"
}
EOF
)"
```

```shell
FEDERATED_TOKEN="$(curl --fail "https://sts.googleapis.com/v1/token" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data "${PAYLOAD}" \
  | jq -r '.access_token'
)"
```

Where:

- `PROJECT_NUMBER` is your Google Cloud project number (not name).
- `POOL_ID` is the ID of the Workload Identity Pool created in the first section.
- `PROVIDER_ID` is the ID of the Workload Identity Provider created in the second section.
- `GITLAB_OIDC_TOKEN` is an OIDC [ID token](../../yaml/_index.md#id_tokens).

You can then use the resulting federated token to impersonate the service account created
in the previous section:

```shell
ACCESS_TOKEN="$(curl --fail "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SERVICE_ACCOUNT_EMAIL:generateAccessToken" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer FEDERATED_TOKEN" \
  --data '{"scope": ["https://www.googleapis.com/auth/cloud-platform"]}' \
  | jq -r '.accessToken'
)"
```

Where:

- `SERVICE_ACCOUNT_EMAIL` is the full email address of the service account to impersonate,
  created in the previous section.
- `FEDERATED_TOKEN` is the federated token retrieved from the previous step.

The result is a Google Cloud OAuth 2.0 access token, which you can use to authenticate to
most Google Cloud APIs and services when used as a bearer token. You can also pass this
value to the `gcloud` CLI by setting the environment variable `CLOUDSDK_AUTH_ACCESS_TOKEN`.

## Working example

Review this
[reference project](https://gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp)
for provisioning OIDC in GCP using Terraform and a sample script to retrieve temporary credentials.

## Troubleshooting

- When debugging `curl` responses, install the latest version of curl. Use `--fail-with-body`
  instead of `-f`. This command prints the entire body, which can contain helpful error messages.

- For more information, see [Troubleshoot Workload Identity Federation](https://cloud.google.com/iam/docs/troubleshooting-workload-identity-federation).
