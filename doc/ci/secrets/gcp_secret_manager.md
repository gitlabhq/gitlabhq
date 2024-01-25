---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Use GCP Secret Manager secrets in GitLab CI/CD

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** SaaS, self-managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11739) in GitLab and GitLab Runner 16.8.

You can use secrets stored in the [Google Cloud (GCP) Secret Manager](https://cloud.google.com/security/products/secret-manager)
in your GitLab CI/CD pipelines.

The flow for using GitLab with GCP Secret Manager is:

1. GitLab issues an ID token to the CI/CD job.
1. The runner authenticates to GCP using the ID token.
1. GCP verifies the ID token with GitLab.
1. GCP issues a short-lived access token.
1. The runner accesses the secret data using the access token.
1. GCP checks IAM permission on the access token's principal.
1. GCP returns the secret data to the runner.

To use GitLab with GCP Secret Manager, you must:

- Have secrets stored in [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager).
- Configure [GCP Workload Identity Federation](#configure-gcp-iam-workload-identify-federation-wif) to include GitLab as an identity provider.
- Configure [GCP IAM](#grant-access-to-gcp-iam-principal) permissions to grant access to GCP Secret Manager.
- Configure [GitLab CI/CD with GCP Secret Manager](#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets).

## Configure GCP IAM Workload Identify Federation (WIF)

GCP IAM WIF must be configured to recognize ID tokens issued by GitLab and assign an appropriate principal to them.
The principal is used to authorize access to the Secret Manager resources:

1. In GCP Console, go to **IAM & Admin > Workload Identity Federation**.
1. Select **CREATE POOL** and create a new identity pool with a unique name, for example `gitlab-pool`.
1. Select **ADD PROVIDER** to add a new OIDC Provider to the Identity Pool with a unique name, for example `gitlab-provider`.
   1. Set **Issuer (URL)** to the GitLab URL, for example `https://gitlab.com`.
   1. Select **Default audience**, or select **Allowed audiences** for a custom audience, which is used in the `aud` for the GitLab CI/CD ID token.
1. Under **Attribute Mapping**, configure provider attributes, which are mappings between the [OIDC claims](id_token_authentication.md#token-payload)
   (referred to as "assertion") and Google attributes. These mappings can be used to set fine grained access control.
   For example, to grant a GitLab project access to Secret Manager secrets, select **ADD MAPPING** and create a mapping of
   `attribute.gitlab_project_id` to `assertion.project_id`.

## Grant access to GCP IAM principal

After setting up WIF, you must grant the WIF principal access to the secrets in Secret Manager.

1. In GCP Console, go to **IAM & Admin > IAM**.
1. Select **GRANT ACCESS** to grant access to the principal set created through the WIF provider. For example,
   to grant IAM access to the principal matching the project with ID `123`, add
   a new principal like: `principalSet://iam.googleapis.com/projects/[PROJECT_NUMBER]/locations/global/workloadIdentityPools/[POOL_ID]/attribute.gitlab_project_id/[PROJECT_ID]`.
1. Assign the role **Secret Manager Secret Accessor**.
1. (Optional) Select **IAM condition (Optional)** to add an IAM condition.
   Under **Condition Builder**, you can add conditions. For example, you could add two `AND` conditions:
   - First condition:
     - **Condition type**: `Type`
     - **Operator**: `is`
     - **Resource type**: `secretmanager.googleapis.com/SecretVersion`
   - Second condition:
     - **Condition type**: `Name`
     - **Operator**: `Starts with`
     - **Value**: The pattern of secrets that you want to grant access to.

You can add additional IAM conditions for fine-grained access controls, including
accessing secrets with names starting with the project name.

## Configure GitLab CI/CD to use GCP Secret Manager secrets

You can use secrets stored in GCP Secret Manager in CI/CD jobs by defining them with the `gcp_secret_manager` keyword:

```yaml
job_using_gcp_sm:
  id_tokens:
    GCP_ID_TOKEN:
      # `aud` must match the audience defined in the WIF Identity Pool.
      aud: https://iam.googleapis.com/projects/1234/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab-provider
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: my-project-secret  # This is the name of the secret defined in GCP Secret Manager
        version: 1               # optional: default to `latest`.
      token: $GCP_ID_TOKEN
```

You must also [add these CI/CD variables](../variables/index.md#for-a-project) to provide details about your GCP Secret Manager:

- `GCP_PROJECT_NUMBER`: The GCP [Project Number](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID`: The WIF Pool ID (e.g `gitlab-pool`)
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID`: The WIF Provider ID (e.g `gitlab-provider`)
