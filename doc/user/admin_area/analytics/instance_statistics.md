---
stage: Manage
group: Value Stream Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Instance Statistics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235754) in GitLab 13.4.

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.

Instance Statistics gives you an overview of how much data your instance contains, and how quickly this volume is changing over time.

To see Instance Statistics, go to **Admin Area > Analytics > Instance Statistics**.

## Total counts

At the top of the page, Instance Statistics shows total counts for:

- Users
- Projects
- Groups
- Issues
- Merge Requests
- Pipelines

These figures can be useful for understanding how much data your instance contains in total.

## Past year trend charts

Instance Statistics also displays line charts that show total counts per month, over the past 12 months,
in the categories shown in [Total counts](#total-counts).

These charts help you visualize how rapidly these records are being created on your instance.

![Instance Activity Pipelines chart](img/instance_activity_pipelines_chart_v13_6.png)

### Enable or disable Instance Statistics

Instance Statistics is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:instance_statistics)
```

To disable it:

```ruby
Feature.disable(:instance_statistics)
```
