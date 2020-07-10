---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Monitor CI/CD Environment metrics

Once [configured](../../user/project/integrations/prometheus.md), GitLab will attempt to retrieve performance metrics for any
environment which has had a successful deployment.

GitLab will automatically scan the Prometheus server for metrics from known servers like Kubernetes and NGINX, and attempt to identify individual environments. The supported metrics and scan process is detailed in our [Prometheus Metrics Library documentation](../../user/project/integrations/prometheus_library/index.md).

You can view the performance dashboard for an environment by [clicking on the monitoring button](../../ci/environments/index.md#monitoring-environments).

## Metrics dashboard visibility

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201924) in GitLab 13.0.

You can set the visibility of the metrics dashboard to **Only Project Members**
or **Everyone With Access**. When set to **Everyone with Access**, the metrics
dashboard is visible to authenticated and non-authenticated users.
