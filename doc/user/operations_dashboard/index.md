# Operations Dashboard **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/5781) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.5. [Moved](https://gitlab.com/gitlab-org/gitlab-ee/issues/9218) to [GitLab Premium](https://about.gitlab.com/pricing/) in 11.10.

The Operations Dashboard provides a summary of each project's operational health,
including pipeline and alert status.

The dashboard can be accessed via the top bar, by clicking on the new
dashboard icon:

![Operations Dashboard icon in top bar](img/index_operations_dashboard_top_bar_icon.png)

## Adding a project to the dashboard

NOTE: **Note:**
For GitLab.com, you can add your project to the Operations Dashboard for free if
your project is public. If your project is private, the group it belongs to must
have a [Silver](https://about.gitlab.com/pricing/) plan.

To add a project to the dashboard:

1. Click the **Add projects** button in the homescreen of the dashboard.
1. Search and add one or more projects using the **Search your projects** field.
1. Click the **Add projects** button.

Once added, the dashboard will display the project's number of active alerts,
last commit, pipeline status, and when it was last deployed.

![Operations Dashboard with projects](img/index_operations_dashboard_with_projects.png)

## Making it the default dashboard when you sign in

The Operations Dashboard can also be made the default GitLab dashboard shown when
you sign in. To make it the default, visit your [profile preferences](../profile/preferences.md).
