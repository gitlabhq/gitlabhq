---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Revert from Enterprise Edition to Community Edition
---

You can revert your Enterprise Edition (EE) instance back to Community Edition (CE), but must first:

1. Disable EE-only authentication mechanisms.
1. Remove EE-only integrations from the database.
1. Adjust configuration that uses environment scopes.

## Turn off EE-only authentication mechanisms

Kerberos is only available on EE instances. You must:

- Turn off these mechanisms before reverting.
- Provide a different authentication method to your users.

## Remove EE-only integrations from the database

These integrations are only available in the EE codebase:

- [GitHub](../user/project/integrations/github.md)
- [Git Guardian](../user/project/integrations/git_guardian.md)
- [Google Artifact Management](../user/project/integrations/google_artifact_management.md)
- [Google Cloud IAM](../integration/google_cloud_iam.md)

If you downgrade to CE, you might get something like the following error:

```plaintext
Completed 500 Internal Server Error in 497ms (ActiveRecord: 32.2ms)

ActionView::Template::Error (The single-table inheritance mechanism failed to locate the subclass: 'Integrations::Github'. This
error is raised because the column 'type_new' is reserved for storing the class in case of inheritance. Please rename this
column if you didn't intend it to be used for storing the inheritance class or overwrite Integration.inheritance_column to
use another column for that information.)
```

The `subclass` in the error message can be any of the following:

- `Integrations::Github`
- `Integrations::GitGuardian`
- `Integrations::GoogleCloudPlatform::ArtifactRegistry`
- `Integrations::GoogleCloudPlatform::WorkloadIdentityFederation`

All integrations are created automatically for every project you have.
To avoid getting this error, you must remove all EE-only integration records from your database.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all"
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
bundle exec rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all" production
```

{{< /tab >}}

{{< /tabs >}}

## Adjust configuration that uses environment scopes

If you use [environment scopes](../user/group/clusters/_index.md#environment-scopes), you might need to adjust your
configuration, especially if configuration variables share the same key, but have different scopes.
Environment scopes are completely ignored in CE.

With configuration variables that share a key but different scopes, you could accidentally get a variable that you're
not expecting for a particular environment. Make sure that you have the right variables in this case.

Your data is completely preserved in the transition, so you can change back to EE and restore the behavior.

## Revert to CE

After performing the necessary steps, you can revert your GitLab instance to CE.

Follow the correct [update guides](../update/_index.md) to make sure all dependencies are up to date.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Install the CE package on top of EE by either:

- Directly [downloading the package](https://packages.gitlab.com/gitlab/gitlab-ce).
- Adding the CE package repository and following the [CE installation instructions](https://about.gitlab.com/install/?version=ce).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Replace the current Git remote of your GitLab installation with the CE Git remote.
1. Fetch the latest changes and check out the latest stable branch. For example:

   ```shell
   git remote set-url origin git@gitlab.com:gitlab-org/gitlab-foss.git
   git fetch --all
   git checkout 17-8-stable
   ```

{{< /tab >}}

{{< /tabs >}}
