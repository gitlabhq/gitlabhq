---
stage: Growth
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Event Dictionary

**Note: We've temporarily moved the Event Dictionary to a [Google Sheet](https://docs.google.com/spreadsheets/d/1VzE8R72Px_Y_LlE3Z05LxUlG_dumWe3vl-HeUo70TPw/edit?usp=sharing)**. The previous Markdown table exceeded 600 rows making it difficult to manage. In the future, our intention is to move this back into our docs using a [YAML file](https://gitlab.com/gitlab-org/gitlab-docs/-/issues/823).

The event dictionary is a single source of truth for the metrics and events we collect for product usage data. The Event Dictionary lists all the metrics and events we track, why we're tracking them, and where they are tracked.

This is a living document that is updated any time a new event is planned or implemented. It includes the following information.

- Section, stage, or group
- Description
- Implementation status
- Availability by plan type
- Code path

We're currently focusing our Event Dictionary on [Usage Ping](usage_ping.md). In the future, we will also include [Snowplow](snowplow.md). We currently have an initiative across the entire product organization to complete the [Event Dictionary for Usage Ping](https://gitlab.com/groups/gitlab-org/-/epics/4174).

## Instructions

1. Open the Event Dictionary and fill in all the **PM to edit** columns highlighted in yellow.
1. Check that all the metrics and events are assigned to the correct section, stage, or group. If a metric is used across many groups, assign it to the stage. If a metric is used across many stages, assign it to the section. If a metric is incorrectly assigned to another section, stage, or group, let the PM know you have reassigned it. If your group has no assigned metrics and events, check that your metrics and events are not incorrectly assigned to another PM.
1. Add descriptions of what your metrics and events are tracking. Work with your Engineering team or the Product Analytics team if you need help understanding this.
1. Add what plans this metric is available on. Work with your Engineering team or the Product Analytics team if you need help understanding this.

## Planned metrics and events

For future metrics and events you plan to track, please add them to the Event Dictionary and note the status as `Planned`, `In Progress`, or `Implemented`. Once you have confirmed the metric has been implemented and have confirmed the metric data is in our data warehouse, change the status to **Data Available**.
