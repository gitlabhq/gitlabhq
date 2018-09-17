# Continuous Integration and Deployment Admin settings **[CORE ONLY]**

In this area, you will find settings for Auto DevOps, Runners and job artifacts.
You can find it in the admin area, under **Settings > Continuous Integration and Deployment**.

![Admin area settings button](../img/admin_area_settings_button.png)
<<<<<<< HEAD

## Auto DevOps **[CORE ONLY]**

To enable (or disable) [Auto DevOps](../../../topics/autodevops/index.md)
for all projects:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**
1. Check (or uncheck to disable) the box that says "Default to Auto DevOps pipeline for all projects"
1. Optionally, set up the [Auto DevOps base domain](../../../topics/autodevops/index.md#auto-devops-base-domain)
   which is going to be used for Auto Deploy and Auto Review Apps.
1. Hit **Save changes** for the changes to take effect.

From now on, every existing project and newly created ones that don't have a
`.gitlab-ci.yml`, will use the Auto DevOps pipelines.

If you want to disable it for a specific project, you can do so in
[its settings](../../../topics/autodevops/index.md#enabling-auto-devops).

## Maximum artifacts size **[CORE ONLY]**

The maximum size of the [job artifacts](../../../administration/job_artifacts.md)
can be set in the Admin area of your GitLab instance. The value is in *MB* and
the default is 100MB per job; on GitLab.com it's [set to 1G](../../gitlab_com/index.md#gitlab-ci-cd).

To change it:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Change the value of maximum artifacts size (in MB).
1. Hit **Save changes** for the changes to take effect.

## Default artifacts expiration **[CORE ONLY]**

The default expiration time of the [job artifacts](../../../administration/job_artifacts.md)
can be set in the Admin area of your GitLab instance. The syntax of duration is
described in [`artifacts:expire_in`](../../../ci/yaml/README.md#artifacts-expire_in)
and the default value is `30 days`. On GitLab.com they
[never expire](../../gitlab_com/index.md#gitlab-ci-cd).

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Change the value of default expiration time.
1. Hit **Save changes** for the changes to take effect.

This setting is set per job and can be overridden in
[`.gitlab-ci.yml`](../../../ci/yaml/README.md#artifacts-expire_in).
To disable the expiration, set it to `0`. The default unit is in seconds.

## Shared Runners pipeline minutes quota **[STARTER ONLY]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1078)
in GitLab Starter 8.16.

If you have enabled shared Runners for your GitLab instance, you can limit their
usage by setting a maximum number of pipeline minutes that a group can use on
shared Runners per month. Setting this to `0` (default value) will grant
unlimited pipeline minutes. While build limits are stored as minutes, the
counting is done in seconds. Usage resets on the first day of each month.
On GitLab.com, the quota is calculated based on your
[subscription plan](https://about.gitlab.com/pricing/#gitlab-com).

To change the pipelines minutes quota:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**
1. Set the pipeline minutes quota limit.
1. Hit **Save changes** for the changes to take effect

---

While the setting in the Admin area has a global effect, as an admin you can
also change each group's pipeline minutes quota to override the global value.

1. Navigate to the **Groups** admin area and hit the **Edit** button for the
   group you wish to change the pipeline minutes quota.
1. Set the pipeline minutes quota to the desired value
1. Hit **Save changes** for the changes to take effect.

Once saved, you can see the build quota in the group admin view.
The quota can also be viewed in the project admin view if shared Runners
are enabled.

![Project admin info](img/admin_project_quota_view.png)

When the pipeline minutes quota for a group is set to a value different than 0,
the **Pipelines quota** page is available to the group page settings list.
You can see there an overview of the pipeline minutes quota of all projects of
the group.

![Group pipelines quota](img/group_pipelines_quota.png)
=======

## Auto DevOps **[CORE ONLY]**

To enable (or disable) [Auto DevOps](../../../topics/autodevops/index.md)
for all projects:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Check (or uncheck to disable) the box that says "Default to Auto DevOps pipeline for all projects".
1. Optionally, set up the [Auto DevOps base domain](../../../topics/autodevops/index.md#auto-devops-base-domain)
   which is going to be used for Auto Deploy and Auto Review Apps.
1. Hit **Save changes** for the changes to take effect.

From now on, every existing project and newly created ones that don't have a
`.gitlab-ci.yml`, will use the Auto DevOps pipelines.

If you want to disable it for a specific project, you can do so in
[its settings](../../../topics/autodevops/index.md#enabling-auto-devops).

## Maximum artifacts size **[CORE ONLY]**

The maximum size of the [job artifacts][art-yml] can be set in the Admin area
of your GitLab instance. The value is in *MB* and the default is 100MB per job;
on GitLab.com it's [set to 1G](../../gitlab_com/index.md#gitlab-ci-cd).

To change it:

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Change the value of maximum artifacts size (in MB).
1. Hit **Save changes** for the changes to take effect.

## Default artifacts expiration **[CORE ONLY]**

The default expiration time of the [job artifacts](../../../administration/job_artifacts.md)
can be set in the Admin area of your GitLab instance. The syntax of duration is
described in [`artifacts:expire_in`](../../../ci/yaml/README.md#artifacts-expire_in)
and the default value is `30 days`. On GitLab.com they
[never expire](../../gitlab_com/index.md#gitlab-ci-cd).

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Change the value of default expiration time.
1. Hit **Save changes** for the changes to take effect.

This setting is set per job and can be overridden in
[`.gitlab-ci.yml`](../../../ci/yaml/README.md#artifacts-expire_in).
To disable the expiration, set it to `0`. The default unit is in seconds.
>>>>>>> upstream/master
