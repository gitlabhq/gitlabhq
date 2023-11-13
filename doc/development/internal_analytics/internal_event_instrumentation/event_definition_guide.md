---
stage: Monitor
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Event definition guide

NOTE:
The event dictionary is a work in progress, and this process is subject to change.

This guide describes the event dictionary and how it's implemented.

## Event definition and validation

This process is meant to document all internal events and ensure consistency. Every internal event needs to have such a definition. Event definitions must comply with the [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/events/schema.json).

All event definitions are stored in the following directories:

- [`config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/events)
- [`ee/config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/events)

Each event is defined in a separate YAML file consisting of the following fields:

| Field                  | Required | Additional information                                                                                                                                                                      |
|------------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `description`          | yes      | A description of the event.                                                                                                                                                                 |
| `category`             | yes      | Always InternalEventTracking (only different for legacy events).                                                                                                                             |
| `action`               | yes      | A unique name for the event.                                                                                                                               |
| `identifiers`          | no       | A list of identifiers sent with the event. Can be set to one or more of `project`, `user`, or `namespace`.                                                                                  |
| `product_section`      | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml).                                                                                                |
| `product_stage`        | no       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the event.                                                                                        |
| `product_group`        | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the event.                                                                                  |
| `milestone`            | no       | The milestone when the event is introduced.                                                                                                                                                 |
| `introduced_by_url`    | no       | The URL to the merge request that introduced the event.                                                                                                                                     |
| `distributions`        | yes      | The [distributions](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/#definitions) where the tracked feature is available. Can be set to one or more of `ce` or `ee`.  |
| `tiers`                | yes      | The [tiers](https://about.gitlab.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/) where the tracked feature is available. Can be set to one or more of `free`, `premium`, or `ultimate`. |

### Example event definition

This is an example YAML file for an internal event:

```yaml
description: A user visited a product analytics dashboard
category: InternalEventTracking
action: user_visited_dashboard
identifiers:
- project
- user
- namespace
product_section: dev
product_stage: monitor
product_group: group::product analytics
milestone: "16.4"
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128029
distributions:
- ee
tiers:
- ultimate
```
