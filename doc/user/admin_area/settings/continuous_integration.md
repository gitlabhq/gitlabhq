# Continuous Integration and Deployment Admin settings **[CORE ONLY]**

In this area, you will find settings for Auto DevOps, Runners and job artifacts.
You can find it in the admin area, under **Settings > Continuous Integration and Deployment**.

![Admin area settings button](../img/admin_area_settings_button.png)

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
