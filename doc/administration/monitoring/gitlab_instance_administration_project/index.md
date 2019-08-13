# GitLab instance administration project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/56883) in GitLab 12.2.

GitLab has been adding the ability for administrators to see insights into the health of
their GitLab instance. In order to surface this experience in a native way, similar to how
you would interact with an application deployed via GitLab, a base project called
"GitLab Instance Administration" with
[internal visibility](../../../public_access/public_access.md#internal-projects) will be
added under a group called "GitLab Instance Administrators" specifically created for
visualizing and configuring the monitoring of your GitLab instance.

All administrators at the time of creation of the project and group will be added
as maintainers of the group and project, and as an admin, you'll be able to add new
members to the group in order to give them maintainer access to the project.

This project will be used for self-monitoring your GitLab instance.

## Connection to Prometheus

The project will be automatically configured to connect to the
[internal Prometheus](../prometheus/index.md) instance if the Prometheus
instance is present (should be the case if GitLab was installed via Omnibus
and you haven't disabled it).

If that's not the case or if you have an external Prometheus instance or an HA setup,
you should
[configure it manually](../../../user/project/integrations/prometheus.md#manual-configuration-of-prometheus).

## Taking action on Prometheus alerts **[ULTIMATE]**

You can [add a webhook](../../../user/project/integrations/prometheus.md#external-prometheus-instances)
to the Prometheus config in order for GitLab to receive notifications of any alerts.

Once the webhook is setup, you can
[take action on incoming alerts](../../../user/project/integrations/prometheus.md#taking-action-on-incidents-ultimate).
