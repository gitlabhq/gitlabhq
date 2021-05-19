---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Event dictionary guide

NOTE:
The event dictionary is a work in progress, and this process is subject to change.

This guide describes the event dictionary and how it's implemented.

## Event definition and validation

This process is meant to document all Snowplow events and ensure consistency. Event definitions must comply with the [JSON Schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/events/schema.json).

All event definitions are stored in the following directories:

- [`config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/events)
- [`ee/config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/events)

Each event is defined in a separate YAML file consisting of the following fields:

| Field                  | Required | Additional information                                                                                                                                          |
|------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `description`          | yes      | A description of the event.                                                                                                                                        |
| `category`             | yes      | The event category (see [Structured event taxonomy](index.md#structured-event-taxonomy)).                                                  |
| `action`               | yes      | The event action (see [Structured event taxonomy](index.md#structured-event-taxonomy)).                                                    |
| `label_description`    | no       | A description of the event label (see [Structured event taxonomy](index.md#structured-event-taxonomy)).                                      |
| `property_description` | no       | A description of the event property (see [Structured event taxonomy](index.md#structured-event-taxonomy)).                                   |
| `value_description`    | no       | A description of the event value (see [Structured event taxonomy](index.md#structured-event-taxonomy)).                                      |
| `extra_properties`     | no       | The type and description of each extra property sent with the event.                                                                                                 |
| `identifiers`          | no       | A list of identifiers sent with the event. Can be set to one or more of `project`, `user`, or `namespace`.                                                                                    |
| `iglu_schema_url`      | no       | The URL to the custom schema sent with the event, for example, `iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0`.                                                         |
| `product_section`      | yes      | The [section](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/sections.yml).                                                                    |
| `product_stage`        | no       | The [stage](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) for the event.                                                             |
| `product_group`        | yes      | The [group](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml) that owns the event.                                                       |
| `product_category`     | no       | The [product category](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/categories.yml) for the event.                                              |
| `milestone`            | no       | The milestone when the event is introduced.                                                                                                                      |
| `introduced_by_url`    | no       | The URL to the merge request that introduced the event.                                                                                                          |
| `distributions`        | yes      | The [distributions](https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/#definitions) where the tracked feature is available. Can be set to one or more of `ce` or `ee`. |
| `tiers`                | yes      | The [tiers]( https://about.gitlab.com/handbook/marketing/strategic-marketing/tiers/) where the tracked feature is available. Can be set to one or more of `free`, `premium`, or `ultimate`. |

### Example event definition

The linked [`uuid`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/events/epics_promote.yml)
YAML file includes an example event definition.

```yaml
description: Issue promoted to epic
category: epics
action: promote
property_description: The string "issue_id"
value_description: ID of the issue
extra_properties:
  weight:
    type: integer
    description: Weight of the issue
identifiers:
- project
- user
- namespace
product_section: dev
product_stage: plan
product_group: group::product planning
product_category: epics
milestone: "11.10"
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/10537
distributions:
- ee
tiers:
- premium
- ultimate
```

## Create a new event definition

Use the dedicated [event definition generator](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/snowplow_event_definition_generator.rb)
to create new event definitions.

The `category` and `action` of each event are included in the filename to enforce uniqueness.

The generator takes three options:

- `--ee`: Indicates if the event is for EE.
- `--category=CATEGORY`: Indicates the `category` of the event.
- `--action=ACTION`: Indicates the `action` of the event.
- `--force`: Overwrites the existing event definition, if one already exists.

```shell
bundle exec rails generate gitlab:snowplow_event_definition --category Groups::EmailCampaignsController --action click
create  create  config/events/groups__email_campaigns_controller_click.yml
```
