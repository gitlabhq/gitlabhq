---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Performance

## Monitoring

We have a performance dashboard available in one of our [Grafana instances](https://dashboards.gitlab.net/d/1EBTz3Dmz/sitespeed-page-summary?orgId=1). This dashboard automatically aggregates metric data from [sitespeed.io](https://www.sitespeed.io/) every 6 hours. These changes are displayed after a set number of pages are aggregated.

These pages can be found inside a text file in the [`gitlab-build-images` repository](https://gitlab.com/gitlab-org/gitlab-build-images) called [`gitlab.txt`](https://gitlab.com/gitlab-org/gitlab-build-images/blob/master/scripts/gitlab.txt)
Any frontend engineer can contribute to this dashboard. They can contribute by adding or removing URLs of pages from this text file. Please have a [frontend monitoring expert](https://about.gitlab.com/company/team/) review your changes before assigning to a maintainer of the `gitlab-build-images` project. The changes are pushed live on the next scheduled run after the changes are merged into `main`.

There are 3 recommended high impact metrics to review on each page:

- [First visual change](https://web.dev/first-meaningful-paint/)
- [Speed Index](https://github.com/WPO-Foundation/webpagetest-docs/blob/master/user/Metrics/SpeedIndex.md)
- [Visual Complete 95%](https://github.com/WPO-Foundation/webpagetest-docs/blob/master/user/Metrics/SpeedIndex.md)

For these metrics, lower numbers are better as it means that the website is more performant.
