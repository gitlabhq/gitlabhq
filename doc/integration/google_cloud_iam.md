---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Cloud Workload Identity Federation and IAM policies
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127) in GitLab 16.10 [with a flag](../administration/feature_flags.md) named `google_cloud_support_feature_flag`.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) in GitLab 17.1. Feature flag `google_cloud_support_feature_flag` removed.

To use Google Cloud integrations like the
[Google Artifact Management integration](../user/project/integrations/google_artifact_management.md),
you must create and configure a
[workload identity pool and provider](https://cloud.google.com/iam/docs/workload-identity-federation).
The Google Cloud integration uses Workload Identity Federation to
grant GitLab workloads access to Google Cloud resources through OpenID Connect
(OIDC) by using JSON Web Token (JWT) tokens.

## Workload Identity Federation

Workload Identity Federation lets you use Identity and Access Management (IAM) to grant
external identities [IAM roles](https://cloud.google.com/iam/docs/overview#roles).

Traditionally, applications running outside Google Cloud used
[service account keys](https://cloud.google.com/iam/docs/service-account-creds#key-types)
to access Google Cloud resources. However, service account keys are powerful
credentials, and can present a security risk if they are not managed
correctly.

With identity federation, you can use Identity and Access Management (IAM) to grant
external identities IAM roles
directly, without requiring service accounts. This approach
eliminates the maintenance and security burden associated with service
accounts and their keys.

## Workload identity pools

A _workload identity pool_ is an entity that lets you manage
non-Google identities on Google Cloud.

The GitLab on Google Cloud integration walks you through setting up a workload
identity pool to authenticate to Google Cloud. This setup includes
mapping your GitLab role attributes to IAM claims in your
Google Cloud IAM policy. For a full list of available GitLab
attributes for the GitLab on Google Cloud integration, see
[OIDC custom claims](#oidc-custom-claims).

## Workload identity pool providers

A _workload identity pool provider_ is an entity that describes a relationship
between Google Cloud and your Identity provider (IdP). GitLab is the
IdP for your workload identity pool for the GitLab on Google Cloud integration.

For more information on identity federation for external workloads, see
[Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation).

The default GitLab on Google Cloud integration assumes you want to set up your authentication from
GitLab to Google Cloud at the GitLab organization level. If you want to control
access to Google Cloud on a per project basis, then you must configure your
IAM policies for your workload identity pool provider. For more
information on controlling who can access Google Cloud from your GitLab
organization, see [Access control with IAM](https://cloud.google.com/docs/gitlab).

## GitLab authentication with Workload Identity Federation

After your workload identity pool and provider are set up to map your GitLab
roles and permissions to IAM roles, you can provision runners
to deploy workloads from GitLab to Google Cloud by setting the
[`identity`](../ci/yaml/_index.md#identity) keyword to
`google_cloud` for authorization on Google Cloud.

For more information on provisioning runners using the GitLab on Google Cloud integration, see the
tutorial
[Provisioning runners in Google Cloud](../ci/runners/provision_runners_google_cloud.md).

## Create and configure a Workload Identity Federation

To set up the Workload Identity Federation you can either:

- Use the GitLab UI for a guided setup.
- Use the Google Cloud CLI to set up the Workload Identity Federation manually.

### With the GitLab UI

To use the GitLab UI to set up the Workload Identity Federation:

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
  to manage Workload Identity Federation in Google Cloud.

1. Create a workload identity pool with the following command. Replace these
   values:

   - `<your_google_cloud_project_id>` with your
  [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
  To improve security, use a dedicated project for identity management,
  separate from resources and CI/CD projects.
   - `<your_identity_pool_id>` with the ID to use for the pool, which must
  be 4 to 32 lowercase letters, digits, or hyphens. To avoid collisions, use a
  unique ID. You should include the GitLab project ID or project path
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
     collisions, use a unique ID in the identity pool. For example,
     `gitlab`.
   - `<your_google_cloud_project_id>` with your
     [Google Cloud project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
   - `<your_identity_pool_id>` with the ID of the workload identity pool you
     created in the previous step.
   - `<your_issuer_uri>` with your identity provider issuer URI, which can be
     can be copied from the IAM integration page when choosing
     manual setup and must exactly match the value. The parameter must include
     the path of the top-level group. For example, if the project is under
     `my-root-group/my-subgroup/project-a`, the `issuer-uri` must be set to
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
  For more information, see the [supported OIDC custom claims](google_cloud_iam.md#oidc-custom-claims) that you can use
  to [control access to Google Cloud](https://cloud.google.com/docs/gitlab#control-access-google).

To restrict [identity token access](https://cloud.google.com/iam/docs/workload-identity-federation#mapping) to a specific GitLab project or group, use an attribute condition. Use the attribute `assertion.project_id` for a project and the attribute `assertion.namespace_id` for a group.
For more information, see the Google Cloud documentation about how to [define an attribute condition](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2). After you define the attribute condition, you can [update the workload identity provider](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#update_attribute_condition_on_a_workload_identity_provider).

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
| `root_namespace_id`     | On group events           | ID of the top-level group or user level namespace.                                                            |
| `root_namespace_path`   | On group events           | Path of the top-level group or user level namespace.                                                          |
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

## Control access to Google Cloud

When you [set up a Workload Identity Federation](#create-and-configure-a-workload-identity-federation),
many of the standard GitLab claims (for example, `user_access_level`) are automatically mapped to
Google Cloud attributes.

You can further customize who can access Google Cloud from your GitLab organization.
To do this, you use [Common Expression Language (CEL)](https://github.com/google/cel-spec/blob/master/doc/intro.md#introduction)
to set principals based on the [OIDC custom attributes](#oidc-custom-claims) for the GitLab on Google Cloud integration.

For example, to allow users with the `maintainer` role in GitLab to push
artifacts to the Google Artifact Registry from the GitLab project `gitlab-org/my-project`:

1. Sign into the Google Cloud Console and go to the
   [**Workload Identity Federation** page](https://console.cloud.google.com/iam-admin/workload-identity-pools?supportedpurview=project).

1. In the **Display name** column, select your workload identity pool.

1. In the **Providers** section, next to the workload identity provider you want to edit,
   select **Edit** (**{pencil}**) to open **Provider details**.

1. In the **Attribute mapping** section, select **Add mapping**.
1. In the **Google N** text box, enter:

   ```shell
   attribute.my_project_maintainer
   ```

1. In the **OIDC N** text box, enter the following CEL expression:

   ```shell
   assertion.maintainer_access=="true" && assertion.project_path=="gitlab-org/my-project"
   ```

1. Select **Save**.

   The Google attribute `my_project_maintainer` is mapped to the GitLab claims
   `maintainer_access==true` and the `project_path=="gitlab-org/my-project"`.

1. In the Google Cloud Console, go to the [**IAM** page](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project).

1. Select **Grant access**.
1. In the **New principals** text box, enter the principal set including the
   `attribute.my_project_maintainer/true` in the following format:

   ```shell
   principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.my_project_maintainer/true
   ```

   Replace the following:

   - `<PROJECT_NUMBER>` with your Google Cloud project number. To find
     your project number, see [Identifying projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).
   - `<POOL_ID>` with your workload identity pool ID.

1. In the **Select a role** dropdown list, select **Google Artifact Registry Writer role**
   (`roles/artifactregistry.writer`).
1. Select **Save**.

The role is granted to the principal set containing users with the `maintainer`
role in GitLab on the project `gitlab-org/my-project`.

To prevent your other GitLab projects from pushing artifacts to the Google Artifact Registry, you
can view your IAM policies in the Google Cloud Console, and
remove or edit roles as required.

## View your IAM policies

Sign into the Google Cloud Console and go to the
[**IAM** page](https://console.google.com/iam-admin/iam?supportedpurview=project)

You can select either **View by principals** or **View by roles**.
