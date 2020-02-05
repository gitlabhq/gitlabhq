# GitLab self monitoring project

NOTE: **Note:**
This feature is available behind a feature flag called `self_monitoring_project`
since [12.7](https://gitlab.com/gitlab-org/gitlab/issues/32351). The feature flag
will be removed once we [add dashboards to display metrics](https://gitlab.com/groups/gitlab-org/-/epics/2367).

GitLab has been adding the ability for administrators to see insights into the health of
their GitLab instance. In order to surface this experience in a native way, similar to how
you would interact with an application deployed via GitLab, a base project called
"GitLab self monitoring" with
[internal visibility](../../../public_access/public_access.md#internal-projects) will be
added under a group called "GitLab Instance Administrators" specifically created for
visualizing and configuring the monitoring of your GitLab instance.

All administrators at the time of creation of the project and group will be added
as maintainers of the group and project, and as an admin, you'll be able to add new
members to the group in order to give them maintainer access to the project.

This project will be used for self monitoring your GitLab instance.

## Activating or deactivating the self monitoring project

1. Navigate to **Admin Area > Settings > Metrics and profiling** and expand the **Self monitoring** section.
1. Toggle on or off the **Create Project** button to create or remove the "GitLab self monitoring" project.
1. Click **Save changes** for the changes to take effect.

If you activated the monitoring project, it should now be visible in **Projects > Your projects**.

CAUTION: **Warning:**
If you deactivate the self monitoring project, it will be permanently deleted.

## Connection to Prometheus

The project will be automatically configured to connect to the
[internal Prometheus](../prometheus/index.md) instance if the Prometheus
instance is present (should be the case if GitLab was installed via Omnibus
and you haven't disabled it).

If that's not the case or if you have an external Prometheus instance or an HA setup,
you should
[configure it manually](../../../user/project/integrations/prometheus.md#manual-configuration-of-prometheus).

## Taking action on Prometheus alerts **(ULTIMATE)**

You can [add a webhook](../../../user/project/integrations/prometheus.md#external-prometheus-instances)
to the Prometheus config in order for GitLab to receive notifications of any alerts.

Once the webhook is setup, you can
[take action on incoming alerts](../../../user/project/integrations/prometheus.md#taking-action-on-incidents-ultimate).
