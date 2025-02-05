---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate epic APIs to work items
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9290) in GitLab 17.2 [with a flag](../../administration/feature_flags.md) named `work_item_epics`. Disabled by default. Your administrator must have [enabled the new look for epics](../../user/group/epics/epic_work_items.md). This feature is in [beta](../../policy/development_stages_support.md#beta).
> - Listing epics using the [GraphQL API](reference/_index.md) [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12852) in GitLab 17.4.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/470685) in GitLab 17.6.
> - [Enabled by default on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) in GitLab 17.7.

In GitLab 17.2, we introduced [epics as work items](../../user/group/epics/epic_work_items.md).

To ensure that your integrations continue working:

- If you use the [Epic GraphQL API](reference/_index.md#epic), migrate to the Work Item API before GitLab 18.0, when the Epic GraphQL API is removed.
- If you use the [REST API](../epics.md), you can continue using it, but you should migrate to future-proof your integrations.
- For new features (such as assignees, health status, linked items with other types), you must
  use the `WorkItem` GraphQL API.

## API status

### REST API (`/api/v4/`)

The REST API for epics:

- Is still supported but deprecated.
- Continues to work with existing endpoints.
- Does not receive new features.
- Has no set removal date, but it will happen in a major release.

### GraphQL API

The `WorkItem` GraphQL API:

- Is marked as experimental.
- Is used in production environments.
- Will be [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/500620) before GitLab 18.0
- Is planned to exit [experimental status](https://gitlab.com/gitlab-org/gitlab/-/issues/500620) before GitLab 18.0.

The [Epic GraphQL API](reference/_index.md#epic) is planned for removal in GitLab 18.0.

## Migrate to the Work Item API

The Work Item API uses widgets to represent epic attributes like health status, assignees, and
hierarchy.

### Set up the GraphiQL explorer

To run these examples, you can use GraphiQL, an interactive GraphQL API explorer where you can play
around with existing queries:

1. Open the GraphiQL explorer tool:
   - For GitLab.com, go to <https://gitlab.com/-/graphql-explorer>.
   - For GitLab Self-Managed, go to `https://gitlab.example.com/-/graphql-explorer`.
     Change `gitlab.example.com` to your instance URL.
1. Paste a query listed in an example into the left window of your GraphiQL explorer tool.
1. Select **Play**.

### Query epics

NOTE:
Epic IDs are different from work item IDs, but the IID (ID incremented for each group) remains the same.
For example, an epic at `/gitlab-org/-/epics/123` has the same IID `123` as a work item.

**Before (Epic API):**

```graphql
query Epics {
  group(fullPath: "gitlab-org") {
    epics {
      nodes {
        id
        iid
        title
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "group": {
      "epics": {
        "nodes": [
          {
            "id": "gid://gitlab/Epic/2335843",
            "iid": "15596",
            "title": "First epic"
          },
          {
            "id": "gid://gitlab/Epic/2335762",
            "iid": "15595",
            "title": "Second epic"
          }
        ]
      }
    }
  }
}
```

**After (Work Item API):**

```graphql
query EpicsAsWorkItem {
  group(fullPath: "gitlab-org") {
    workItems(types: [EPIC]) {
      nodes {
        id
        iid
        title
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "group": {
      "workItems": {
        "nodes": [
          {
            "id": "gid://gitlab/WorkItem/154888575",
            "iid": "15596",
            "title": "First epic"
          },
          {
            "id": "gid://gitlab/WorkItem/154877868",
            "iid": "15595",
            "title": "Second epic"
          }
        ]
      }
    }
  }
}
```

### Create an epic

**Before (Epic API):**

```graphql
mutation CreateEpic {
  createEpic(input: { title: "New epic", groupPath: "gitlab-org" }) {
    epic {
      id
      title
    }
  }
}
```

Example response:

```json
{
  "data": {
    "createEpic": {
      "epic": {
        "id": "gid://gitlab/Epic/806",
        "title": "New epic"
      }
    }
  }
}
```

**After (Work Item API):**

To create an epic:

1. Get the work item type ID (`workItemTypeId`) for epics in your namespace.

   The `workItemTypeId` for an epic is not guaranteed to be the same between GitLab instances or namespaces.
   Work to ensure the same IDs for default work item types is tracked in [epic 15272](https://gitlab.com/groups/gitlab-org/-/epics/15272).

   ```graphql
   query WorkItemTypes {
     namespace(fullPath: "gitlab-org") {
       workItemTypes(name: EPIC) {
         nodes {
           id
           name
         }
       }
     }
   }
   ```

   Example response:

   ```json
   {
     "data": {
       "namespace": {
         "workItemTypes": {
           "nodes": [
             {
               // the <WorkItemTypeId> will be different based on your namespace and instance
               "id": "gid://gitlab/WorkItems::Type/<WorkItemTypeId>",
               "name": "Epic"
             }
           ]
         }
       }
     }
   }
   ```

1. Create the epic (work item with the type `epic`) by using that ID:

   ```graphql
   mutation CreateWorkItemEpic {
     workItemCreate(
       input: {
         title: "New work item epic"
         namespacePath: "gitlab-org"
         workItemTypeId: "gid://gitlab/WorkItems::Type/<WorkItemTypeID>"
       }
     ) {
       workItem {
         id
         title
       }
     }
   }
   ```

   Example response:

   ```json
   {
     "data": {
       "workItemCreate": {
         "workItem": {
           "id": "gid://gitlab/WorkItem/2243",
           "title": "New work item epic"
         }
       }
     }
   }
   ```

### Widgets

The Work Item API introduces the concept of widgets.
Widgets represent specific features or attributes of a work item type.
They can range from attributes like health status or assignees to dates or hierarchy.
Each work item type has a unique set of available widgets.

#### Query epics with widgets

To retrieve detailed information about an epic, you can use various widgets in your GraphQL query.
The following example demonstrates how to query an epic's:

- Hierarchy (parent/child relationships)
- Assignees
- Emoji reactions
- Color
- Health status
- Start and due dates

For all available widgets, see [Work Item widget reference](reference/_index.md#workitemwidget).

To query epics with widgets:

**Before (Epic API):**

```graphql
query DetailedEpicQuery {
  group(fullPath: "gitlab-org") {
    epic(iid: 1000) {
      id
      iid
      title
      confidential
      author {
        id
        name
      }
      state
      color
      parent {
        id
        title
      }
      startDate
      dueDate
      ancestors {
        nodes {
          id
          title
        }
      }
      children {
        nodes {
          id
          title
        }
      }
      notes {
        nodes {
          body
          createdAt
          author {
            name
          }
        }
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "group": {
      "epic": {
        "id": "gid://gitlab/Epic/5579",
        "iid": "1000",
        "title": "Pajamas component: Pagination - Style",
        "confidential": false,
        "author": {
          "id": "gid://gitlab/User/3079878",
          "name": "Sidney Jones"
        },
        "state": "opened",
        "color": "#1068bf",
        "parent": {
          "id": "gid://gitlab/Epic/5576",
          "title": "Pajamas component: Pagination"
        },
        "startDate": null,
        "dueDate": null,
        "ancestors": {
          "nodes": [
            {
              "id": "gid://gitlab/Epic/5523",
              "title": "Components of Pajamas Design System"
            },
            {
              "id": "gid://gitlab/Epic/5576",
              "title": "Pajamas component: Pagination"
            }
          ]
        },
        "children": {
          "nodes": []
        },
        "notes": {
          "nodes": [
            {
              "body": "changed the description",
              "createdAt": "2019-04-02T17:03:05Z",
              "author": {
                "name": "Sidney Jones"
              }
            },
            {
              "body": "mentioned in epic &997",
              "createdAt": "2019-04-26T15:45:49Z",
              "author": {
                "name": "Zhang Wei"
              }
            },
            {
              "body": "added issue gitlab-ui#302",
              "createdAt": "2019-06-27T09:20:43Z",
              "author": {
                "name": "Alex Garcia"
              }
            },
            {
              "body": "added issue gitlab-ui#304",
              "createdAt": "2019-06-27T09:20:43Z",
              "author": {
                "name": "Alex Garcia"
              }
            },
            {
              "body": "added issue gitlab-ui#316",
              "createdAt": "2019-07-11T08:26:25Z",
              "author": {
                "name": "Alex Garcia"
              }
            },
            {
              "body": "mentioned in issue gitlab-design#528",
              "createdAt": "2019-08-05T14:12:51Z",
              "author": {
                "name": "Jan Kowalski"
              }
            }
          ]
        }
      }
    }
  }
}
```

**After (Work Item API):**

```graphql
query DetailedEpicWorkItem {
  namespace(fullPath: "gitlab-org") {
    workItem(iid: "10") {
      id
      title
      confidential
      author {
        id
        name
      }
      state
      widgets {
        ... on WorkItemWidgetColor {
          color
          textColor
          __typename
        }
        ... on WorkItemWidgetHierarchy {
          children {
            nodes {
              id
              title
            }
          }
          parent {
            title
          }
          __typename
        }
        ... on WorkItemWidgetHealthStatus {
          type
          healthStatus
        }
        ... on WorkItemWidgetAssignees {
          assignees {
            nodes {
              name
            }
          }
          __typename
        }
        ... on WorkItemWidgetAwardEmoji {
          downvotes
          upvotes
          awardEmoji {
            nodes {
              unicode
            }
          }
          __typename
        }
        ... on WorkItemWidgetStartAndDueDate {
          dueDate
          isFixed
          startDate
          __typename
        }
        ... on WorkItemWidgetNotes {
          discussions {
            nodes {
              notes {
                edges {
                  node {
                    body
                    id
                    author {
                      name
                    }
                  }
                }
              }
            }
          }
        }
        __typename
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "namespace": {
      "workItem": {
        "id": "gid://gitlab/WorkItem/146171815",
        "title": "Pajamas component: Pagination - Style",
        "confidential": false,
        "author": {
          "id": "gid://gitlab/User/3079878",
          "name": "Sidney Jones"
        },
        "state": "OPEN",
        "widgets": [
          {
            "assignees": {
              "nodes": []
            },
            "__typename": "WorkItemWidgetAssignees"
          },
          {
            "__typename": "WorkItemWidgetDescription"
          },
          {
            "children": {
              "nodes": [
                {
                  "id": "gid://gitlab/WorkItem/24697619",
                  "title": "Pagination does not conform with button styling and interaction styling"
                },
                {
                  "id": "gid://gitlab/WorkItem/22693964",
                  "title": "Remove next and previous labels on mobile and smaller viewports for pagination component"
                },
                {
                  "id": "gid://gitlab/WorkItem/22308883",
                  "title": "Update pagination border and background colors according to the specs"
                },
                {
                  "id": "gid://gitlab/WorkItem/22294339",
                  "title": "Pagination \"active\" page contains gray border on right side"
                }
              ]
            },
            "parent": {
              "title": "Pajamas component: Pagination"
            },
            "__typename": "WorkItemWidgetHierarchy"
          },
          {
            "__typename": "WorkItemWidgetLabels"
          },
          {
            "discussions": {
              "nodes": [
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "changed the description",
                          "id": "gid://gitlab/Note/156548315",
                          "author": {
                            "name": "Sidney Jones"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "added ~10161862 label",
                          "id": "gid://gitlab/LabelNote/853dc8176d8eff789269d69c31c019ecd9918996",
                          "author": {
                            "name": "Jan Kowalski"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "mentioned in epic &997",
                          "id": "gid://gitlab/Note/164703873",
                          "author": {
                            "name": "Zhang Wei"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "added issue gitlab-ui#302",
                          "id": "gid://gitlab/Note/185977331",
                          "author": {
                            "name": "Alex Garcia"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "added issue gitlab-ui#304",
                          "id": "gid://gitlab/Note/185977335",
                          "author": {
                            "name": "Alex Garcia"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "added issue gitlab-ui#316",
                          "id": "gid://gitlab/Note/190661279",
                          "author": {
                            "name": "Alex Garcia"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "mentioned in issue gitlab-design#528",
                          "id": "gid://gitlab/Note/200228415",
                          "author": {
                            "name": "Jan Kowalski"
                          }
                        }
                      }
                    ]
                  }
                },
                {
                  "notes": {
                    "edges": [
                      {
                        "node": {
                          "body": "added ~8547186 ~10161725 labels and removed ~10161862 label",
                          "id": "gid://gitlab/LabelNote/dfa79f5c4e6650850cc9e767f0dc0d3896bfd0f9",
                          "author": {
                            "name": "Sidney Jones"
                          }
                        }
                      }
                    ]
                  }
                }
              ]
            },
            "__typename": "WorkItemWidgetNotes"
          },
          {
            "dueDate": null,
            "isFixed": false,
            "startDate": null,
            "__typename": "WorkItemWidgetStartAndDueDate"
          },
          {
            "type": "HEALTH_STATUS",
            "healthStatus": null,
            "__typename": "WorkItemWidgetHealthStatus"
          },
          {
            "__typename": "WorkItemWidgetStatus"
          },
          {
            "__typename": "WorkItemWidgetNotifications"
          },
          {
            "downvotes": 0,
            "upvotes": 0,
            "awardEmoji": {
              "nodes": []
            },
            "__typename": "WorkItemWidgetAwardEmoji"
          },
          {
            "__typename": "WorkItemWidgetLinkedItems"
          },
          {
            "__typename": "WorkItemWidgetCurrentUserTodos"
          },
          {
            "__typename": "WorkItemWidgetRolledupDates"
          },
          {
            "__typename": "WorkItemWidgetParticipants"
          },
          {
            "__typename": "WorkItemWidgetWeight"
          },
          {
            "__typename": "WorkItemWidgetTimeTracking"
          },
          {
            "color": "#1068bf",
            "textColor": "#FFFFFF",
            "__typename": "WorkItemWidgetColor"
          }
        ]
      }
    }
  }
}
```

#### Create a work item epic with widgets

Use widgets as part of the `input` parameter to create or update work items.

For example, run the query below to create an epic with:

- Title
- Description
- Color
- Health status
- Start date
- Due date
- Assignee

```graphql
mutation createEpicWithWidgets {
  workItemCreate(
    input: {
      title: "New work item epic"
      namespacePath: "gitlab-org"
      workItemTypeId: "gid://gitlab/WorkItems::Type/<WorkItemTypeID>"
      colorWidget: { color: "#e24329" }
      descriptionWidget: { description: "My new plans ..." }
      healthStatusWidget: { healthStatus: onTrack }
      startAndDueDateWidget: { startDate: "2024-10-12", dueDate: "2024-12-12", isFixed: true }
      assigneesWidget: { assigneeIds: "gid://gitlab/User/<UserID>" }
    }
  ) {
    workItem {
      id
      title
      description
      widgets {
        ... on WorkItemWidgetColor {
          color
          textColor
          __typename
        }
        ... on WorkItemWidgetAssignees {
          assignees {
            nodes {
              id
              name
            }
          }
          __typename
        }
        ... on WorkItemWidgetHealthStatus {
          healthStatus
          __typename
        }
        ... on WorkItemWidgetStartAndDueDate {
          startDate
          dueDate
          isFixed
          __typename
        }
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "workItemCreate": {
      "workItem": {
        "id": "gid://gitlab/WorkItem/2252",
        "title": "New epic",
        "description": "My new plans ...",
        "widgets": [
          {
            "assignees": {
              "nodes": [
                {
                  "id": "gid://gitlab/User/46",
                  "name": "Jane Smith"
                }
              ]
            },
            "__typename": "WorkItemWidgetAssignees"
          },
          {
            "color": "#e24329",
            "textColor": "#FFFFFF",
            "__typename": "WorkItemWidgetColor"
          },
          {
            "healthStatus": "onTrack",
            "__typename": "WorkItemWidgetHealthStatus"
          },
          {
            "startDate": "2024-10-12",
            "dueDate": "2024-12-12",
            "isFixed": true,
            "__typename": "WorkItemWidgetStartAndDueDate"
          }
        ]
      }
    }
  }
}
```

#### Update a work item epic using widgets

To edit a work item, re-use the widget inputs from
[Create a work item epic with widgets](#create-a-work-item-epic-with-widgets), but use the
`workItemUpdate` mutation instead.

Get the global ID of the work item (format `gid://gitlab/WorkItem/<WorkItemID>`) and use it as `id`
for the `input`:

```graphql
mutation updateEpicWorkItemWithWidgets {
  workItemUpdate(
    input: {
      id: "gid://gitlab/WorkItem/<WorkItemID>"
      title: "Updated work item epic title"
      colorWidget: { color: "#fc6d26" }
      descriptionWidget: { description: "My other new plans ..." }
      healthStatusWidget: { healthStatus: onTrack }
      startAndDueDateWidget: { startDate: "2025-10-12", dueDate: "2025-12-12", isFixed: true }
      assigneesWidget: { assigneeIds: "gid://gitlab/User/45" }
    }
  ) {
    workItem {
      id
      title
      description
      widgets {
        ... on WorkItemWidgetColor {
          color
          textColor
          __typename
        }
        ... on WorkItemWidgetAssignees {
          assignees {
            nodes {
              id
              name
            }
          }
          __typename
        }
        ... on WorkItemWidgetHealthStatus {
          healthStatus
          __typename
        }
        ... on WorkItemWidgetStartAndDueDate {
          startDate
          dueDate
          isFixed
          __typename
        }
      }
    }
  }
}
```

Example response:

```json
{
  "data": {
    "workItemUpdate": {
      "workItem": {
        "id": "gid://gitlab/WorkItem/2252",
        "title": "Updated work item epic title",
        "description": "My other new plans ...",
        "widgets": [
          {
            "assignees": {
              "nodes": [
                {
                  "id": "gid://gitlab/User/45",
                  "name": "Ardella Williamson"
                }
              ]
            },
            "__typename": "WorkItemWidgetAssignees"
          },
          {
            "color": "#fc6d26",
            "textColor": "#FFFFFF",
            "__typename": "WorkItemWidgetColor"
          },
          {
            "healthStatus": "onTrack",
            "__typename": "WorkItemWidgetHealthStatus"
          },
          {
            "startDate": "2025-10-12",
            "dueDate": "2025-12-12",
            "isFixed": true,
            "__typename": "WorkItemWidgetStartAndDueDate"
          }
        ]
      }
    }
  }
}
```

### Delete an epic work item

To delete an epic work item, use the `workItemDelete` mutation:

```graphql
mutation deleteEpicWorkItem {
  workItemDelete(input: { id: "gid://gitlab/WorkItem/<WorkItemID>" }) {
    clientMutationId
    errors
    namespace {
      id
    }
  }
}
```

Example response:

```json
{
  "data": {
    "workItemDelete": {
      "clientMutationId": null,
      "errors": [],
      "namespace": {
        "id": "gid://gitlab/Group/24"
      }
    }
  }
}
```
