---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Use GCP Secret Manager secrets in GitLab CI/CD

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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
- Configure [GCP Workload Identity Federation](#configure-gcp-iam-workload-identity-federation-wif) to include GitLab as an identity provider.
- Configure [GCP IAM](#grant-access-to-gcp-iam-principal) permissions to grant access to GCP Secret Manager.
- Configure [GitLab CI/CD with GCP Secret Manager](#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets).

## Configure GCP IAM Workload Identity Federation (WIF)

GCP IAM WIF must be configured to recognize ID tokens issued by GitLab and assign an appropriate principal to them.
The principal is used to authorize access to the Secret Manager resources:

1. In GCP Console, go to **IAM & Admin > Workload Identity Federation**.
1. Select **CREATE POOL** and create a new identity pool with a unique name, for example `gitlab-pool`.
1. Select **ADD PROVIDER** to add a new OIDC Provider to the Identity Pool with a unique name, for example `gitlab-provider`.
   1. Set **Issuer (URL)** to the GitLab URL, for example `https://gitlab.com`.
   1. Select **Default audience**, or select **Allowed audiences** for a custom audience, which is used in the `aud` for the GitLab CI/CD ID token.
1. Under **Attribute Mapping**, create the following mappings, where:

   - `attribute.X` is the name of the attribute you want to be present on Google's claims.
   - `assertion.X` is the value to extract from the [GitLab claim](../cloud_services/index.md#how-it-works).

   | Attribute (on Google)         | Assertion (from GitLab) |
   |-------------------------------|-------------------------|
   | `google.subject`              | `assertion.sub`         |
   | `attribute.gitlab_project_id` | `assertion.project_id`  |

## Grant access to GCP IAM principal

After setting up WIF, you must grant the WIF principal access to the secrets in Secret Manager.

1. In GCP Console, go to **IAM & Admin > IAM**.
1. Select **GRANT ACCESS** to grant access to the principal set created through the WIF provider.
   The external identity format is:

   ```plaintext
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.gitlab_project_id/GITLAB_PROJECT_ID
   ```

   In this example:

   - `PROJECT_NUMBER`: Your Google Cloud project number (not ID) which can be found in the
     [Project's dashboard](https://console.cloud.google.com/home/dashboard).
   - `POOL_ID`: The ID (not name) of the Workload Identity Pool created in the first section,
     for example `gitlab-pool`.
   - `GITLAB_PROJECT_ID`: The GitLab project ID found on the [project overview page](../../user/project/working_with_projects.md#access-the-project-overview-page-by-using-the-project-id).

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

You must [add these CI/CD variables](../variables/index.md#for-a-project) to provide details about
your GCP Secret Manager:

- `GCP_PROJECT_NUMBER`: The GCP [Project Number](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID`: The WIF Pool ID, for example `gitlab-pool`.
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID`: The WIF Provider ID, for example `gitlab-provider`.

Then you can use secrets stored in GCP Secret Manager in CI/CD jobs by defining them
with the `gcp_secret_manager` keyword:

```yaml
job_using_gcp_sm:
  id_tokens:
    GCP_ID_TOKEN:
      # `aud` must match the audience defined in the WIF Identity Pool.
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID}/providers/${GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID}
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: my-project-secret  # This is the name of the secret defined in GCP Secret Manager
        version: 1               # optional: default to `latest`.
      token: $GCP_ID_TOKEN
```

## Troubleshooting

### `The size of mapped attribute google.subject exceeds the 127 bytes limit` error

A long merge request branch name can cause a job to fail with the following error if
[the `assertion.sub` attribute](id_token_authentication.md#token-payload) is more than 127 characters:

```plaintext
ERROR: Job failed (system failure): resolving secrets: failed to exchange sts token: googleapi: got HTTP response code 400 with body:
{"error":"invalid_request","error_description":"The size of mapped attribute google.subject exceeds the 127 bytes limit.
Either modify your attribute mapping or the incoming assertion to produce a mapped attribute that is less than 127 bytes."}
```

For example, for a `gitlab-org/gitlab` branch, the payload would be `project_path:gitlab-org/gitlab:ref_type:branch:ref:{branch_name}`,
so the branch name should be 76 characters or less.

### `WARNING: Not resolved: no resolver that can handle the secret` warning

The Google Cloud Secret Manager integration requires at least GitLab 16.8 and GitLab Runner 16.8.
This warning appears if the job is executed by a runner using a version earlier than 16.8.

On GitLab.com, there is a [known issue](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/176)
causing SaaS runners to run an older version. As a workaround until this issue is fixed,
you can register your own GitLab Runner with version 16.8 or later.
