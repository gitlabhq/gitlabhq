---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Standard Context Fields

Standard context, also referred to as [Cloud context](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/proposals/-/blob/master/doc/data_usage_collection_outside_gitlab_codebase.md?ref_type=heads), describes all the fields available in the GitLab Standard Context schema.

## Required Fields

| Field          | Type   | Description                        | Example               |
|----------------|--------|------------------------------------|-----------------------|
| `environment`  | string | Name of the source environment.   | `"production"`, `"staging"` |

## Optional Fields

| Field             | Type          | Description                                                                                       | Example             |
|-------------------|---------------|---------------------------------------------------------------------------------------------------|---------------------|
| `project_id`      | integer, null | ID of the associated project. This is available when tracking is done inside any project path. (example : [GitLab project](https://gitlab.com/gitlab-org/gitlab))                                                                    | `12345`            |
| `namespace_id`    | integer, null | ID of the associated namespace. This is available when tracking is done inside any group path. (example : [GitLab-org](https://gitlab.com/gitlab-org))                                                                                                                        | `67890`            |
| `user_id`         | integer, null | ID of the associated user. This gets pseudonymized in the Snowplow enricher. Refer to the [metrics dictionary](https://metrics.gitlab.com/identifiers/). | `longhash`         |
| `global_user_id`  | string, null  | An anonymized `user_id` hash unique across instances.                                            | `longhash`         |
| `is_gitlab_team_member` | boolean, null | Indicates if the action was triggered by a GitLab team member.                                   | `true`, `false`    |

### Instance Information

| Field            | Type          | Description                                              | Example                   |
|------------------|---------------|----------------------------------------------------------|---------------------------|
| `instance_id`    | string, null  | ID of the GitLab instance where the request originated.  | `instance_long_uuid`      |
| `host_name`      | string, null  | Hostname of the GitLab instance.                        | `"gitlab-host-id"`        |
| `instance_version` | string, null | Version of the GitLab instance.                         | `"15.8.0"`                |
| `realm`          | string, null  | Deployment type of GitLab. Must be one of: `"self-managed"`, `"saas"`, `"dedicated"`. | `"saas"`                  |

### Client Information

| Field            | Type          | Description                                              | Example                   |
|------------------|---------------|----------------------------------------------------------|---------------------------|
| `client_name`    | string, null  | Name of the client sending the request.                 | `"chrome"`, `"jetbrains"` |
| `client_version` | string, null  | Version of the client.                                  | `"108.0.5359.124"`        |
| `client_type`    | string, null  | Type of client.                                         | `"browser"`, `"ide"`      |
| `interface`      | string, null  | Interface from which the request originates.            | `"Duo Chat"`              |

### Feature and Plan Information

| Field                         | Type          | Description                                                                 | Example                  |
|-------------------------------|---------------|-----------------------------------------------------------------------------|--------------------------|
| `feature_category`            | string, null  | Category where the specific feature belongs.                                | `"duo_chat"`            |
| `feature_enabled_by_namespace_ids` | array, null | List of namespace IDs allowing the user to use the tracked feature.         | `[123, 456, 789]`       |
| `plan`                        | string, null  | Name of the subscription plan (maximum length: 32 characters).              | `"free"`, `"ultimate"`  |

### Tracking and Context

| Field                 | Type          | Description                                              | Example                      |
|-----------------------|---------------|----------------------------------------------------------|------------------------------|
| `source`              | string, null  | Name of the source application.                         | `"gitlab-rails"`, `"gitlab-javascript"` |
| `google_analytics_id` | string, null  | Google Analytics ID from the marketing site.            | `"UA-XXXXXXXX-X"`           |
| `context_generated_at` | string, null | Timestamp indicating when the context was generated.    | `"2023-12-20T10:00:00Z"`    |
| `correlation_id`      | string, null  | Unique request ID for each request.                     | `uuid`                      |
| `extra`               | object, null  | Additional data associated with the event, in key-value pair format. | `{"key": "value"}`          |

### Related Links

- Descriptions of Unit Primitives are documented in [cloud connector](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/tree/main/config/unit_primitives).
