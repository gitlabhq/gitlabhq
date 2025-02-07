---
stage: Monitor
group: Platform Insights
description: Performance, health, uptime monitoring.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Monitor GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Explore our features to monitor your GitLab instance:

- [Performance monitoring](performance/_index.md): GitLab Performance Monitoring
  makes it possible to measure a wide variety of statistics of your instance.
- [Prometheus](prometheus/_index.md): Prometheus is a powerful time-series monitoring
  service, providing a flexible platform for monitoring GitLab and other software
  products.
- [GitHub imports](github_imports.md): Monitor the health and progress of the GitHub
  importer with various Prometheus metrics.
- [Monitoring uptime](health_check.md): Check the
  server status using the health check endpoint.
  - [IP allowlists](ip_allowlist.md): Configure GitLab for monitoring endpoints that
    provide health check information when probed.
- [`nginx_status`](https://docs.gitlab.com/omnibus/settings/nginx.html#enablingdisabling-nginx_status):
  Monitor your NGINX server status.
