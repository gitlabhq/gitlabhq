---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Performance

## Monitoring

We have a performance dashboard available in one of our [Grafana instances](https://dashboards.gitlab.net/d/000000043/sitespeed-page-summary?orgId=1). This dashboard automatically aggregates metric data from [sitespeed.io](https://www.sitespeed.io/) every 4 hours. These changes are displayed after a set number of pages are aggregated.

These pages can be found inside text files in the [`sitespeed-measurement-setup` repository](https://gitlab.com/gitlab-org/frontend/sitespeed-measurement-setup) called [`gitlab`](https://gitlab.com/gitlab-org/frontend/sitespeed-measurement-setup/-/tree/master/gitlab)
Any frontend engineer can contribute to this dashboard. They can contribute by adding or removing URLs of pages to the text files. The changes are pushed live on the next scheduled run after the changes are merged into `main`.

There are 3 recommended high impact metrics (core web vitals) to review on each page:

- [Largest Contentful Paint](https://web.dev/lcp/)
- [First Input Delay](https://web.dev/fid/)
- [Cumulative Layout Shift](https://web.dev/cls/)

For these metrics, lower numbers are better as it means that the website is more performant.
