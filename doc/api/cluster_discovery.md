---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Cluster discovery API (certificate-based) (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

## Discover certificate-based clusters

Gets certificate-based clusters that are registered to a group, subgroup, or project. Disabled and enabled clusters are also returned.

```plaintext
GET /discover-cert-based-clusters
```

Parameters:

| Attribute | Type           | Required | Description                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `group_id`      | integer/string | yes      | The ID of the group |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/discover-cert-based-clusters?group_id=1"
```

Example response:

```json
{
  "groups": {
    "my-clusters-group": [
      {
        "id": 2,
        "name": "group-cluster-1"
      }
    ],
    "my-clusters-group/subgroup1/subsubgroup1": [
      {
        "id": 4,
        "name": "subsubgroup-cluster"
      }
    ]
  },
  "projects": {
    "my-clusters-group/subgroup1/subsubgroup1/subsubgroup-project-with-cluster": [
      {
        "id": 3,
        "name": "subsubgroup-project-cluster"
      }
    ],
    "my-clusters-group/project1-with-clustser": [
      {
        "id": 1,
        "name": "test"
      }
    ]
  }
}
```
