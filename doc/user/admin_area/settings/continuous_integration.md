---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Continuous Integration and Deployment Admin settings **(FREE SELF)**

In this area, you will find settings for Auto DevOps, runners, and job artifacts.
You can find it in the [Admin Area](index.md) by navigating to
**Admin Area > Settings > CI/CD**.

## Auto DevOps **(FREE SELF)**

To enable (or disable) [Auto DevOps](../../../topics/autodevops/index.md)
for all projects:

1. Go to **Admin Area > Settings > CI/CD**.
1. Check (or uncheck to disable) the box that says **Default to Auto DevOps pipeline for all projects**.
1. Optionally, set up the [Auto DevOps base domain](../../../topics/autodevops/index.md#auto-devops-base-domain)
   which is used for Auto Deploy and Auto Review Apps.
1. Hit **Save changes** for the changes to take effect.

From now on, every existing project and newly created ones that don't have a
`.gitlab-ci.yml`, uses the Auto DevOps pipelines.

If you want to disable it for a specific project, you can do so in
[its settings](../../../topics/autodevops/index.md#enable-or-disable-auto-devops).

## Maximum artifacts size **(FREE SELF)**

The maximum size of the [job artifacts](../../../administration/job_artifacts.md)
can be set at:

- The instance level.
- [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/21688), the project and group level.

The value is:

- In *MB* and the default is 100MB per job.
- [Set to 1G](../../gitlab_com/index.md#gitlab-cicd) on GitLab.com.

To change it at the:

- Instance level:

   1. Go to **Admin Area > Settings > CI/CD**.
   1. Change the value of maximum artifacts size (in MB).
   1. Click **Save changes** for the changes to take effect.

- Group level (this overrides the instance setting):

  1. Go to the group's **Settings > CI/CD > General Pipelines**.
  1. Change the value of **maximum artifacts size (in MB)**.
  1. Click **Save changes** for the changes to take effect.

- Project level (this overrides the instance and group settings):

  1. Go to the project's **Settings > CI/CD > General Pipelines**.
  1. Change the value of **maximum artifacts size (in MB)**.
  1. Click **Save changes** for the changes to take effect.

NOTE:
The setting at all levels is only available to GitLab administrators.

## Default artifacts expiration **(FREE SELF)**

The default expiration time of the [job artifacts](../../../administration/job_artifacts.md)
can be set in the Admin Area of your GitLab instance. The syntax of duration is
described in [`artifacts:expire_in`](../../../ci/yaml/README.md#artifactsexpire_in)
and the default value is `30 days`.

1. Go to **Admin Area > Settings > CI/CD**.
1. Change the value of default expiration time.
1. Click **Save changes** for the changes to take effect.

This setting is set per job and can be overridden in
[`.gitlab-ci.yml`](../../../ci/yaml/README.md#artifactsexpire_in).
To disable the expiration, set it to `0`. The default unit is in seconds.

NOTE:
Any changes to this setting applies to new artifacts only. The expiration time is not
be updated for artifacts created before this setting was changed.
The administrator may need to manually search for and expire previously-created
artifacts, as described in the [troubleshooting documentation](../../../administration/troubleshooting/gitlab_rails_cheat_sheet.md#remove-artifacts-more-than-a-week-old).

## Keep the latest artifacts for all jobs in the latest successful pipelines **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50889) in GitLab Core 13.9.

When enabled (default), the artifacts for the most recent pipeline for a ref are
locked against deletion and kept regardless of the expiry time.

When disabled, the latest artifacts for any **new** successful or fixed pipelines
are allowed to expire.

This setting takes precedence over the [project level setting](../../../ci/pipelines/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).
If disabled at the instance level, you cannot enable this per-project.

To disable the setting:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Clear the **Keep the latest artifacts for all jobs in the latest successful pipelines** checkbox.
1. Click **Save changes**

When you disable the feature, the latest artifacts do not immediately expire.
A new pipeline must run before the latest artifacts can expire and be deleted.

NOTE:
All application settings have a [customizable cache expiry interval](../../../administration/application_settings_cache.md) which can delay the settings affect.

## Shared runners pipeline minutes quota **(PREMIUM SELF)**

> [Moved](https://about.gitlab.com/blog/2021/01/26/new-gitlab-product-subscription-model/) to GitLab Premium in 13.9.

If you have enabled shared runners for your GitLab instance, you can limit their
usage by setting a maximum number of pipeline minutes that a group can use on
shared runners per month. Setting this to `0` (default value) grants
unlimited pipeline minutes. While build limits are stored as minutes, the
counting is done in seconds. Usage resets on the first day of each month.
On GitLab.com, the quota is calculated based on your
[subscription plan](https://about.gitlab.com/pricing/#gitlab-com).

To change the pipelines minutes quota:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. In the **Pipeline minutes quota** box, enter the maximum number of minutes.
1. Click **Save changes** for the changes to take effect.

---

While the setting in the Admin Area has a global effect, as an admin you can
also change each group's pipeline minutes quota to override the global value.

1. Navigate to the **Admin Area > Overview > Groups** and hit the **Edit**
   button for the group you wish to change the pipeline minutes quota.
1. In the **Pipeline Minutes Quota** box, enter the maximum number of minutes.
1. Click **Save changes** for the changes to take effect.

Once saved, you can see the build quota in the group admin view.
The quota can also be viewed in the project admin view if shared runners
are enabled.

![Project admin information](img/admin_project_quota_view.png)

You can see an overview of the pipeline minutes quota of all projects of
a group in the **Usage Quotas** page available to the group page settings list.

![Group pipelines quota](img/group_pipelines_quota.png)

## Archive jobs **(FREE SELF)**

Archiving jobs is useful for reducing the CI/CD footprint on the system by
removing some of the capabilities of the jobs (metadata needed to run the job),
but persisting the traces and artifacts for auditing purposes.

To set the duration for which the jobs are considered as old and expired:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand the **Continuous Integration and Deployment** section.
1. Set the value of **Archive jobs**.
1. Hit **Save changes** for the changes to take effect.

Once that time passes, the jobs are archived and no longer able to be
retried. Make it empty to never expire jobs. It has to be no less than 1 day,
for example: <code>15 days</code>, <code>1 month</code>, <code>2 years</code>.

As of June 22, 2020 the [value is set](../../gitlab_com/index.md#gitlab-cicd) to 3 months on GitLab.com. Jobs created before that date were archived after September 22, 2020.

## Default CI configuration path

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18073) in GitLab 12.5.

The default CI configuration file path for new projects can be set in the Admin
Area of your GitLab instance (`.gitlab-ci.yml` if not set):

1. Go to **Admin Area > Settings > CI/CD**.
1. Input the new path in the **Default CI configuration path** field.
1. Hit **Save changes** for the changes to take effect.

It is also possible to specify a [custom CI/CD configuration path for a specific project](../../../ci/pipelines/settings.md#custom-cicd-configuration-path).

## Required pipeline configuration **(PREMIUM SELF)**

WARNING:
This feature is being re-evaluated in favor of a different
[compliance solution](https://gitlab.com/groups/gitlab-org/-/epics/3156).
We recommend that users who haven't yet implemented this feature wait for
the new solution.

GitLab administrators can force a pipeline configuration to run on every
pipeline.

The configuration applies to all pipelines for a GitLab instance and is
sourced from:

- The [instance template repository](instance_template_repository.md).
- GitLab-supplied configuration.

NOTE:
When you use a configuration defined in an instance template repository,
nested [`include:`](../../../ci/yaml/README.md#include) keywords
(including `include:file`, `include:local`, `include:remote`, and `include:template`)
[do not work](https://gitlab.com/gitlab-org/gitlab/-/issues/35345).

To set required pipeline configuration:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand the **Required pipeline configuration** section.
1. Select the required configuration from the provided dropdown.
1. Click **Save changes**.

![Required pipeline](img/admin_required_pipeline.png)

## Package Registry configuration

### npm Forwarding **(PREMIUM SELF)**

GitLab administrators can disable the forwarding of npm requests to [npmjs.com](https://www.npmjs.com/).

To disable it:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Uncheck **Enable forwarding of npm package requests to npmjs.org**.
1. Click **Save changes**.

![npm package requests forwarding](img/admin_package_registry_npm_package_requests_forward.png)

### Package file size limits

GitLab administrators can adjust the maximum allowed file size for each package type.

To set the maximum file size:

1. Go to **Admin Area > Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Find the package type you would like to adjust.
1. Enter the maximum file size, in bytes.
1. Click **Save size limits**.

## Troubleshooting

### 413 Request Entity Too Large

When build jobs fail with the following error,
increase the [maximum artifacts size](#maximum-artifacts-size).

```plaintext
Uploading artifacts as "archive" to coordinator... too large archive <job-id> responseStatus=413 Request Entity Too Large status=413" at end of a build job on pipeline when trying to store artifacts to <object-storage>.
```
