---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Linked epics API **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352493) in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `related_epics_widget`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `related_epics_widget`. On GitLab.com, this feature is not available.

If the Related Epics feature is not available in your GitLab plan, a `403` status code is returned.

## List linked epics

Get a list of a given epic's linked epics filtered according to the user authorizations.

```plaintext
GET /groups/:id/epics/:epic_iid/related_epics
```

Supported attributes:

| Attribute  | Type           | Required               | Description                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `epic_iid` | integer        | **{check-circle}** Yes | Internal ID of a group's epic                                             |
| `id`       | integer/string | **{check-circle}** Yes | ID or [URL-encoded path of the group](index.md#namespaced-path-encoding). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/epics/:epic_iid/related_epics"
```

Example response:

```json
[
   {
      "id":2,
      "iid":2,
      "color":"#1068bf",
      "text_color":"#FFFFFF",
      "group_id":2,
      "parent_id":null,
      "parent_iid":null,
      "title":"My title 2",
      "description":null,
      "confidential":false,
      "author":{
         "id":3,
         "username":"user3",
         "name":"Sidney Jones4",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/82797019f038ab535a84c6591e7bc936?s=80u0026d=identicon",
         "web_url":"http://localhost/user3"
      },
      "start_date":null,
      "end_date":null,
      "due_date":null,
      "state":"opened",
      "web_url":"http://localhost/groups/group1/-/epics/2",
      "references":{
         "short":"u00262",
         "relative":"u00262",
         "full":"group1u00262"
      },
      "created_at":"2022-03-10T18:35:24.479Z",
      "updated_at":"2022-03-10T18:35:24.479Z",
      "closed_at":null,
      "labels":[

      ],
      "upvotes":0,
      "downvotes":0,
      "_links":{
         "self":"http://localhost/api/v4/groups/2/epics/2",
         "epic_issues":"http://localhost/api/v4/groups/2/epics/2/issues",
         "group":"http://localhost/api/v4/groups/2",
         "parent":null
      },
      "related_epic_link_id":1,
      "link_type":"relates_to",
      "link_created_at":"2022-03-10T18:35:24.496+00:00",
      "link_updated_at":"2022-03-10T18:35:24.496+00:00"
   }
]
```
