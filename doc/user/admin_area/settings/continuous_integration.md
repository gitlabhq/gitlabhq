# Continuous integration Admin settings

## Maximum artifacts size

The maximum size of the [build artifacts][art-yml] can be set in the Admin area
of your GitLab instance. The value is in MB and the default is 100MB. Note that
this setting is set for each build.

1. Go to **Admin area > Settings** (`/admin/application_settings`).

    ![Admin area settings button](img/admin_area_settings_button.png)

1. Change the value of the maximum artifacts size (in MB):

    ![Admin area maximum artifacts size](img/admin_area_maximum_artifacts_size.png)

1. Hit **Save** for the changes to take effect.


[art-yml]: ../../../administration/build_artifacts.md
