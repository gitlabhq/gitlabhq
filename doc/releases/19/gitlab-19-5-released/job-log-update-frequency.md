---
title: Configure job log update frequency
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: verify
co_create: true
documentation_link: "../../../administration/settings/continuous_integration/#configure-the-frequency-of-job-log-updates"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251401
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 30
---

Administrators can now set how often job logs update, under **Admin area** > **Settings** > **CI/CD**
or through the Settings API. You can select between 3 to 3600 seconds.
In previous versions of GitLab, these intervals were constants, so you could not shorten
the initial live-log delay for short jobs without patching the instance.

Thank you to [Aleksandr Kotlyar](https://gitlab.com/aleksandr-kotlyar) for this contribution ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251401))!
