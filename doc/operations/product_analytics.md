---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Product Analytics **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225167) in GitLab 13.3.
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled on GitLab.com.
> - It's able to be enabled or disabled per-project.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to enable it.

GitLab allows you to go from planning an application to getting feedback. Feedback
is not just observability, but also knowing how people use your product.
Product Analytics uses events sent from your application to know how they are using it.
It's based on [Snowplow](https://github.com/snowplow/snowplow), the best open-source
event tracker. With Product Analytics, you can receive and analyze the Snowplow data
inside GitLab.

## Enable or disable Product Analytics

Product Analytics is under development and not ready for production use. It's
deployed behind a feature flag that's **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it for your instance. Product Analytics can be enabled or disabled per-project.

To enable it:

```ruby
# Instance-wide
Feature.enable(:product_analytics)
# or by project
Feature.enable(:product_analytics, Project.find(<project ID>))
```

To disable it:

```ruby
# Instance-wide
Feature.disable(:product_analytics)
# or by project
Feature.disable(:product_analytics, Project.find(<project ID>))
```

## Access Product Analytics

After enabling the feature flag for Product Analytics, you can access the
user interface:

1. Sign in to GitLab as a user with Reporter or greater
   [permissions](../user/permissions.md).
1. Navigate to **Monitor > Product Analytics**.

The user interface contains:

- An Events page that shows the recent events and a total count.
- A test page that sends a sample event.
- A setup page containing the code to implement in your application.

## Rate limits for Product Analytics

While Product Analytics is under development, it's rate-limited to
**100 events per minute** per project. This limit prevents the events table in the
database from growing too quickly.

## Data storage for Product Analytics

Product Analytics stores events are stored in GitLab database.

WARNING:
This data storage is experimental, and GitLab is likely to remove this data during
future development.

## Event collection

Events are collected by [Rails collector](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36443),
allowing GitLab to ship the feature fast. Due to scalability issue, GitLab plans
to switch to a separate application, such as
[snowplow-go-collector](https://gitlab.com/gitlab-org/snowplow-go-collector), for event collection.
