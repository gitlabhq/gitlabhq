# Continuous integration Admin settings

## Maximum artifacts size

The maximum size of the [job artifacts][art-yml] can be set in the Admin area
of your GitLab instance. The value is in MB and the default is 100MB. Note that
this setting is set for each job.

1. Go to the **Admin area ➔ Settings** (`/admin/application_settings`).

    ![Admin area settings button](img/admin_area_settings_button.png)

1. Change the value of the maximum artifacts size (in MB):

    ![Admin area maximum artifacts size](img/admin_area_maximum_artifacts_size.png)

1. Hit **Save** for the changes to take effect.

## Shared Runners build minutes quota

> [Introduced][ee-1078] in GitLab Enterprise Edition 8.16.

If you have enabled shared Runners for your GitLab instance, you can limit their
usage by setting a maximum number of build minutes that a group can use on
shared Runners per month. Set 0 to grant unlimited build minutes.
While build limits are stored as minutes, the counting is done in seconds.

1. Go to the **Admin area ➔ Settings** (`/admin/application_settings`).

    ![Admin area settings button](img/admin_area_settings_button.png)

1. Navigate to the **Continuous Integration** block and enable the Shared
   Runners setting. Then set the build minutes quota limit.

    ![Shared Runners build minutes quota](img/ci_shared_runners_build_minutes_quota.png)

1. Hit **Save** for the changes to take effect.

---

While the setting in the Admin area has a global effect, as an admin you can
also change each group's build minutes quota to override the global value.

1. Navigate to the **Groups** admin area and hit the **Edit** button for the
   group you wish to change the build minutes quota.

    ![Groups in the admin area](img/admin_area_groups.png)

1. Set the build minutes quota to the desired value and hit **Save changes** for
   the changes to take effect.

    ![Edit group in the admin area](img/admin_area_group_edit.png)

Once saved, you can see the build quota in the group admin view.

![Group admin info](img/group_quota_view.png)

The quota can also be viewed in the project admin view if shared Runners
are enabled.

![Project admin info](img/admin_project_quota_view.png)

When the build minutes quota for a group is set to a value different than 0,
the **Pipelines quota** page is available to the group page settings list.

![Group settings](img/group_settings.png)

You can see there an overview of the build minutes quota of all projects of
the group.

![Group pipelines quota](img/group_pipelines_quota.png)

[art-yml]: ../../../administration/job_artifacts.md
[ee-1078]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1078
