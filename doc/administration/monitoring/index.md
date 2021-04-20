---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring GitLab **(FREE SELF)**

Explore our features to monitor your GitLab instance:

- [GitLab self-monitoring](gitlab_self_monitoring_project/index.md): The
  GitLab instance administration project helps to monitor the GitLab instance and
  take action on alerts.
- [Performance monitoring](performance/index.md): GitLab Performance Monitoring
  makes it possible to measure a wide variety of statistics of your instance.
- [Prometheus](prometheus/index.md): Prometheus is a powerful time-series monitoring
  service, providing a flexible platform for monitoring GitLab and other software
  products.
- [GitHub imports](github_imports.md): Monitor the health and progress of the GitHub
  importer with various Prometheus metrics.
- [Monitoring uptime](../../user/admin_area/monitoring/health_check.md): Check the
  server status using the health check endpoint.
  - [IP whitelists](ip_whitelist.md): Configure GitLab for monitoring endpoints that
    provide health check information when probed.
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx.html#enablingdisabling-nginx_status):
  Monitor your NGINX server status.
- [Auto Monitoring](../../topics/autodevops/stages.md#auto-monitoring): Automated
  monitoring for your application's server and response metrics, provided by
  [Auto DevOps](../../topics/autodevops/index.md).
