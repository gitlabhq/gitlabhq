# Performance

## Monitoring

We have a performance dashboard available in one of our [grafana instances](https://performance.gprd.gitlab.com/dashboard/db/sitespeed-page-summary?orgId=1). This dashboard automatically aggregates metric data from [sitespeed.io](https://sitespeed.io) every 6 hours. These changes are displayed after a set number of pages are aggregated.

These pages can be found inside a text file in the gitlab-build-images [repository](https://gitlab.com/gitlab-org/gitlab-build-images) called [gitlab.txt](https://gitlab.com/gitlab-org/gitlab-build-images/blob/master/scripts/gitlab.txt)
Any frontend engineer can contribute to this dashboard. They can contribute by adding or removing urls of pages from this text file. Please have a [frontend monitoring expert](https://about.gitlab.com/team) review your changes before assigning to a maintainer of the `gitlab-build-images` project. The changes will go live on the next scheduled run after the changes are merged into `master`.

There are 3 recommended high impact metrics to review on each page

* [First visual change](https://developers.google.com/web/tools/lighthouse/audits/first-meaningful-paint)
* [Speed Index](https://sites.google.com/a/webpagetest.org/docs/using-webpagetest/metrics/speed-index)
* [Visual Complete 95%](https://sites.google.com/a/webpagetest.org/docs/using-webpagetest/metrics/speed-index)

For these metrics, lower numbers are better as it means that the website is more performant.
