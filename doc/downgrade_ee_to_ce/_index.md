---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Downgrading from EE to CE
---

If you ever decide to downgrade your Enterprise Edition (EE) back to the
Community Edition (CE), there are a few steps you need to take beforehand:

- For Linux package installations, these steps are done before installing the CE package on top of the current EE
  package.
- For self-compiled installations, these steps are done before you change remotes and fetch the latest CE code.

## Disable Enterprise-only features

First thing to do is to disable the following features.

### Authentication mechanisms

Kerberos and Atlassian Crowd are only available on the Enterprise Edition. You
should disable these mechanisms before downgrading. Be sure to provide
alternative authentication methods to your users.

### Remove Enterprise-only integrations from the database

The following integrations are only available in the Enterprise Edition codebase:

- [GitHub](../user/project/integrations/github.md)
- [Git Guardian](../user/project/integrations/git_guardian.md)
- [Google Artifact Management](../user/project/integrations/google_artifact_management.md)
- [Google Cloud IAM](../integration/google_cloud_iam.md)

If you downgrade to the Community Edition, the following error displays:

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

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all"
```

:::TabTitle Self-compiled (source)

```shell
bundle exec rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all" production
```

::EndTabs

### Variables environment scopes

In GitLab Community Edition, [environment scopes](../user/group/clusters/_index.md#environment-scopes)
are completely ignored, so if you are using this feature there may be some
necessary adjustments to your configuration. This is especially true if
configuration variables share the same key, but have different
scopes in a project. In cases like these you could accidentally get a variable
which you're not expecting for a particular environment. Make sure that you have
the right variables in this case.

Your data is completely preserved in the transition, so you could always upgrade
back to EE and restore the behavior if you leave it alone.

## Downgrade to CE

After performing the above mentioned steps, you are now ready to downgrade your
GitLab installation to the Community Edition.

Remember to follow the correct [update guides](../update/_index.md) to make sure all dependencies are up to date.

### Linux package installations

To downgrade a Linux package installation, you can install the Community Edition package on top of
the currently installed one. You can do this manually, by either:

- Directly [downloading the package](https://packages.gitlab.com/gitlab/gitlab-ce).
- Adding our CE package repository and following the  [CE installation instructions](https://about.gitlab.com/install/?version=ce).

### Self-compiled installations

To downgrade a self-compiled installation:

1. Replace the current remote of your GitLab installation with the Community Edition remote.
1. Fetch the latest changes, and check out the latest stable branch:

   ```shell
   git remote set-url origin git@gitlab.com:gitlab-org/gitlab-foss.git
   git fetch --all
   git checkout 8-x-stable
   ```
