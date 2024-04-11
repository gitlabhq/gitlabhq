---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Google Cloud workload identity federation and IAM policies

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127) in GitLab 16.10 [with a flag](../administration/feature_flags.md) named `google_cloud_support_feature_flag`. This feature is in [Beta](../policy/experiment-beta-support.md).

FLAG:
On GitLab.com, this feature is available for a subset of users. On GitLab Dedicated, this feature is not available.

This feature is in [Beta](../policy/experiment-beta-support.md).

To use Google Cloud integrations like the
[Google Artifact Management integration](../user/project/integrations/google_artifact_management.md),
you must create and configure a
[workload identity pool and provider](https://cloud.google.com/iam/docs/workload-identity-federation).
The Google Cloud integration uses the workload identity federation to
grant GitLab workloads access to Google Cloud resources through OpenID Connect
(OIDC) by using JSON Web Token (JWT) tokens.

## Create and configure a workload identity federation

To set up the workload identity federation you can either:

- Use the GitLab UI for a guided setup.
- Use the Google Cloud CLI to set up the workload identity federation manually.

### With the GitLab UI

To use the GitLab UI to set up the workload identity federation:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Locate the Google Cloud IAM integration and select **Configure**.
1. Select **Guided setup** and follow the instructions.

NOTE:
Due to a known issue, the fields in the page for the Google Cloud IAM integration might not
populate after you run the script in the guided setup. If the fields are empty, refresh the page.
For more information, see [issue 448831](https://gitlab.com/gitlab-org/gitlab/-/issues/448831).

### With the Google Cloud CLI

Prerequisites:

- The Google Cloud CLI must be [installed and authenticated](https://cloud.google.com/sdk/docs/install)
  with Google Cloud.
- You must have the [permissions](https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles)
  to manage workload identity federation in Google Cloud.

1. Create a workload identity pool with the following command. Replace these
   values:

   - `<your_google_cloud_project_id>` with your
  [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
  To improve security, use a dedicated project for identity management,
  separate from resources and CI/CD projects.
   - `<your_identity_pool_id>` with the ID to use for the pool, which must
  be 4 to 32 lowercase letters, digits, or hyphens. To avoid collisions, use a
  unique ID. It is recommended to include the GitLab project ID or project path
  as it facilitates IAM policy management. For example,
  `gitlab-my-project-name`.

   ```shell
   gcloud iam workload-identity-pools create <your_identity_pool_id> \
            --project="<your_google_cloud_project_id>" \
            --location="global" \
            --display-name="Workload identity pool for GitLab project ID"
   ```

1. Add an OIDC provider to the workload identity pool with the following
  command. Replace these values:

   - `<your_identity_provider_id>` with the ID to use for the provider, which
     must be 4 to 32 lowercase letters, digits, or hyphens. To avoid
     collisions, use a unique ID within the identity pool. For example,
     `gitlab`.
   - `<your_google_cloud_project_id>` with your
     [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
   - `<your_identity_pool_id>` with the ID of the workload identity pool you
     created in the previous step.
   - `<your_issuer_uri>` with your identity provider issuer URI, which can be
     can be copied from the IAM integration page when choosing
     manual setup and must exactly match the value. The parameter must include
     the path of the root group. For example, if the project is under
     `my-root-group/my-sub-group/project-a`, the `issuer-uri` must be set to
     `https://auth.gcp.gitlab.com/oidc/my-root-group`.

   ```shell
   gcloud iam workload-identity-pools providers create-oidc "<your_identity_provider_id>" \
         --location="global" \
         --project="<your_google_cloud_project_id>" \
         --workload-identity-pool="<your_identity_pool_id>" \
         --issuer-uri="<your_issuer_uri>" \
         --display-name="GitLab OIDC provider" \
         --attribute-mapping="attribute.guest_access=assertion.guest_access,\
   attribute.reporter_access=assertion.reporter_access,\
   attribute.developer_access=assertion.developer_access,\
   attribute.maintainer_access=assertion.maintainer_access,\
   attribute.owner_access=assertion.owner_access,\
   attribute.namespace_id=assertion.namespace_id,\
   attribute.namespace_path=assertion.namespace_path,\
   attribute.project_id=assertion.project_id,\
   attribute.project_path=assertion.project_path,\
   attribute.user_id=assertion.user_id,\
   attribute.user_login=assertion.user_login,\
   attribute.user_email=assertion.user_email,\
   attribute.user_access_level=assertion.user_access_level,\
   google.subject=assertion.sub"
   ```

- The `attribute-mapping` parameter must include the mapping between OIDC custom
  claims included in the JWT ID token to the corresponding identity attributes
  that are used in Identity and Access Management (IAM) policies to grant access.
  Refer to the list of [supported OIDC custom claims](google_cloud_iam.md#oidc-custom-claims)
  for configuring the attribute mapping. For more information on mapping claims
  to IAM policies, see [Control access to Google Cloud](https://cloud.google.com/developer-ecosystem/docs/gitlab/access-control#control-access-google).

After you create the workload identity pool and provider, to complete the setup in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Locate the Google Cloud IAM integration and select **Configure**.
1. Select **Manual setup**
1. Complete the fields.
   - **[Project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**
   for the Google Cloud project in which you created the workload identity.
   pool and provider. Example: `my-sample-project-191923`.
   - **[Project number](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**
   for the same Google Cloud project. Example: `314053285323`.
   - **Pool ID** of the workload identity pool you created for this integration.
   - **Provider ID** of the workload identity provider you created for this integration.

### OIDC custom claims

The ID token includes the following custom claims:

| Claim name              | When                      | Description                                                                                              |
| ----------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `namespace_id`          | On project events         | ID of the group or user level namespace.                                                                 |
| `namespace_path`        | On project events         | Path of the group or user level namespace.                                                               |
| `project_id`            | On project events         | ID of the project.                                                                                       |
| `project_path`          | On project events         | Path of the project.                                                                                     |
| `root_namespace_id`     | On group events           | ID of the root group or user level namespace.                                                            |
| `root_namespace_path`   | On group events           | Path of the root group or user level namespace.                                                          |
| `user_id`               | On user-trigged events    | ID of the user.                                                                                          |
| `user_login`            | On user-trigged events    | Username of the user.                                                                                    |
| `user_email`            | On user-trigged events    | Email of the user.                                                                                       |
| `ci_config_ref_uri`     | During CI/CD pipeline run | The ref path to the top-level CI pipeline definition.                                                    |
| `ci_config_sha`         | During CI/CD pipeline run | Git commit SHA for the `ci_config_ref_uri`.                                                              |
| `job_id`                | During CI/CD pipeline run | ID of the CI job.                                                                                        |
| `pipeline_id`           | During CI/CD pipeline run | ID of the CI pipeline.                                                                                   |
| `pipeline_source`       | During CI/CD pipeline run | CI pipeline source.                                                                                      |
| `project_visibility`    | During CI/CD pipeline run | The visibility of the project where the pipeline is running.                                             |
| `ref`                   | During CI/CD pipeline run | Git ref for the CI job.                                                                                  |
| `ref_path`              | During CI/CD pipeline run | Fully qualified ref for the CI job.                                                                      |
| `ref_protected`         | During CI/CD pipeline run | If the Git ref is protected.                                                                             |
| `ref_type`              | During CI/CD pipeline run | Git ref type.                                                                                            |
| `runner_environment`    | During CI/CD pipeline run | The type of runner used by the CI job.                                                                   |
| `runner_id`             | During CI/CD pipeline run | ID of the runner executing the CI job.                                                                   |
| `sha`                   | During CI/CD pipeline run | The commit SHA for the CI job.                                                                           |
| `environment`           | During CI/CD pipeline run | Environment the CI job deploys to.                                                                       |
| `environment_protected` | During CI/CD pipeline run | If deployed environment is protected.                                                                    |
| `environment_action`    | During CI/CD pipeline run | Environment action specified in the CI job.                                                              |
| `deployment_tier`       | During CI/CD pipeline run | Deployment tier of the environment the CI job specifies.                                                 |
| `user_access_level`     | On user-trigged events    | Role of the user with values of `guest`, `reporter`, `developer`, `maintainer`, `owner`.                 |
| `guest_access`          | On user-trigged events    | Indicates whether the user has at least `guest` role, with values of "true" or "false" as a string.      |
| `reporter_access`       | On user-trigged events    | Indicates whether the user has at least `reporter` role, with values of "true" or "false" as a string.   |
| `developer_access`      | On user-trigged events    | Indicates whether the user has at least `developer` role, with values of "true" or "false" as a string.  |
| `maintainer_access`     | On user-trigged events    | Indicates whether the user has at least `maintainer` role, with values of "true" or "false" as a string. |
| `owner_access`          | On user-trigged events    | Indicates whether the user has at least `owner` role, with values of "true" or "false" as a string.      |

These claims are a superset of the
[ID token claims](../ci/secrets/id_token_authentication.md#token-payload).
All values are of type string. See the ID token claims documentation for more
details and example values.
