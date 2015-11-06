# Enable GitLab CI

GitLab Continuous Integration (CI) is fully integrated into GitLab itself. You
only need to enable it in the **Services** settings of your project.

First, head over your project's page that you would like to enable CI for.
If you can see the **Builds** tab in the sidebar, then CI is enabled.

![Builds tab](builds_tab.png)

If not, go to **Settings > Services** and search for **GitLab CI**. Its state
should be disabled.

![CI service disabled](ci_service_disabled.png)

Click on **GitLab CI** to enter its settings, mark it as active and hit
**Save**.

![Mark CI service as active](ci_service_mark_active.png)

Do you see that green dot? Then good, the service is now enabled! You can also
check its status under **Services**.

![CI service enabled](ci_service_enabled.png)
