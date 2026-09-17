---
title: Per-event detail in the credit usage export
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: fulfillment
documentation_link: "../../../subscriptions/gitlab_credits_dashboard/#export-usage-data"
work_item: https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/18963
categories: [ Consumables Cost Management ]
level: secondary
---

The credit usage export gave you one row per day, which told you how much a
subscription spent but not what it spent on. Attributing credits to a team, a
project, or a single automation meant guesswork.

The export now returns a ZIP file with two CSV files: the daily summary you
already had, and a per-event file with one row for each billable event. Each
row includes the product, flow type, session, user, namespace, project, credits
used, and token counts. Exports run in the background, and GitLab emails you a
download link when the file is ready.
