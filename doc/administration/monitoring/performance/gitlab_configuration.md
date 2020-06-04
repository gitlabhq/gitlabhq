---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Configuration

GitLab Performance Monitoring is disabled by default. To enable it and change any of its
settings, navigate to **Admin Area > Settings > Metrics and profiling**
(`/admin/application_settings/metrics_and_profiling`).

![GitLab Performance Monitoring Admin Settings](img/metrics_gitlab_configuration_settings.png)

Finally, a restart of all GitLab processes is required for the changes to take
effect:

```shell
# For Omnibus installations
sudo gitlab-ctl restart

# For installations from source
sudo service gitlab restart
```

## Pending Migrations

When any migrations are pending, the metrics are disabled until the migrations
have been performed.

Read more on:

- [Introduction to GitLab Performance Monitoring](index.md)
- [Grafana Install/Configuration](grafana_configuration.md)
