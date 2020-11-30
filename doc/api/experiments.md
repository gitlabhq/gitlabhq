---
stage: Growth
group: Expansion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Experiments API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262725) in GitLab 13.5.

This API is for listing A/B experiments [defined in GitLab](../development/experiment_guide/index.md).

The user must be a [GitLab team member](https://gitlab.com/groups/gitlab-com/-/group_members) to access the API.

## List all experiments

Get a list of all experiments. Each experiment has an `enabled` status that indicates whether the experiment is enabled globally, or only in specific contexts.

```plaintext
GET /experiments
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/experiments"
```

Example response:

```json
[
    {
      "key": "experiment_1",
      "enabled": true
    },
    {
      "key": "experiment_2",
      "enabled": false
    }
]
```
