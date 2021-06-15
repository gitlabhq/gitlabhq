---
stage: Manage
group: Compliance
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# External Status Checks API **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3869) in GitLab 14.0.
> - It's [deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-status-checks). **(ULTIMATE SELF)**
 
WARNING:
This feature might not be available to you. Check the **version history** note above for details.

## List status checks for a merge request

For a single merge request, list the external status checks that apply to it and their status.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/status_checks
```

**Parameters:**

| Attribute                | Type    | Required | Description                |
| ------------------------ | ------- | -------- | -------------------------- |
| `id`                     | integer | yes      | ID of a project            |
| `merge_request_iid`      | integer | yes      | IID of a merge request     |

```json
[
    {
        "id": 2,
        "name": "Rule 1",
        "external_url": "https://gitlab.com/test-endpoint",
        "status": "approved"
    },
    {
        "id": 1,
        "name": "Rule 2",
        "external_url": "https://gitlab.com/test-endpoint-2",
        "status": "pending"
    }
]
```

## Set approval status of an external status check

For a single merge request, use the API to inform GitLab that a merge request has been approved by an external service.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_check_responses
```

**Parameters:**

| Attribute                | Type    | Required | Description                            |
| ------------------------ | ------- | -------- | -------------------------------------- |
| `id`                     | integer | yes      | ID of a project                    |
| `merge_request_iid`      | integer | yes      | IID of a merge request             |
| `sha`                    | string  | yes      | SHA at `HEAD` of the source branch |

NOTE:
`sha` must be the SHA at the `HEAD` of the merge request's source branch.

## Enable or disable status checks **(ULTIMATE SELF)**

Status checks are under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it.

## Get project external status checks **(ULTIMATE)**

You can request information about a project's external status checks using the following endpoint:

```plaintext
GET /projects/:id/external_status_checks
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | The ID of a project |

```json
[
  {
    "id": 1,
    "name": "Compliance Check",
    "project_id": 6,
    "external_url": "https://gitlab.com/example/test.json",
    "protected_branches": [
      {
        "id": 14,
        "project_id": 6,
        "name": "master",
        "created_at": "2020-10-12T14:04:50.787Z",
        "updated_at": "2020-10-12T14:04:50.787Z",
        "code_owner_approval_required": false
      }
    ]
  }
]
```

### Create external status check **(ULTIMATE)**

You can create a new external status check for a project using the following endpoint:

```plaintext
POST /projects/:id/external_status_checks
```

| Attribute              | Type           | Required | Description                                        |
|------------------------|----------------|----------|----------------------------------------------------|
| `id`                   | integer        | yes      | The ID of a project                                |
| `name`                 | string         | yes      | Display name of status check                      |
| `external_url`         | string         | yes      | URL of status check resource                  |
| `protected_branch_ids` | `array<Integer>` | no       | The ids of protected branches to scope the rule by |

### Delete external status check **(ULTIMATE)**

You can delete an external status check for a project using the following endpoint:

```plaintext
DELETE /projects/:id/external_status_checks/:check_id
```

| Attribute              | Type           | Required | Description                                        |
|------------------------|----------------|----------|----------------------------------------------------|
| `rule_id`              | integer        | yes      | The ID of an status check                         |
| `id`                   | integer        | yes      | The ID of a project                                |

### Update external status check **(ULTIMATE)**

You can update an existing external status check for a project using the following endpoint:

```plaintext
PUT /projects/:id/external_status_checks/:check_id
```

| Attribute              | Type           | Required | Description                                        |
|------------------------|----------------|----------|----------------------------------------------------|
| `id`                   | integer        | yes      | The ID of a project                                |
| `rule_id`              | integer        | yes      | The ID of an external status check                |
| `name`                 | string         | no       | Display name of status check                      |
| `external_url`         | string         | no       | URL of external status check resource                  |
| `protected_branch_ids` | `array<Integer>` | no       | The ids of protected branches to scope the rule by |

### Enable or disable External Project-level MR status checks **(ULTIMATE SELF)**

Enable or disable External Project-level MR status checks is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../user/feature_flags.md)
can enable it.

To enable it:

```ruby
# For the instance
Feature.enable(:ff_compliance_approval_gates)
# For a single project
Feature.enable(:ff_compliance_approval_gates, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:ff_compliance_approval_gates)
# For a single project
Feature.disable(:ff_compliance_approval_gates, Project.find(<project id>))
```

To enable it:

```ruby
# For the instance
Feature.enable(:ff_compliance_approval_gates)
# For a single project
Feature.enable(:ff_compliance_approval_gates, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:ff_compliance_approval_gates)
# For a single project
Feature.disable(:ff_compliance_approval_gates, Project.find(<project id>)
```

## Related links

- [External status checks](../user/project/merge_requests/status_checks.md)
