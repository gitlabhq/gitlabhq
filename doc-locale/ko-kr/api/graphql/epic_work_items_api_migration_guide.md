---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 에픽 API를 작업 항목으로 마이그레이션
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/9290) 되었으며 [플래그](../../administration/feature_flags/_index.md) `work_item_epics`를 사용합니다. 기본적으로 비활성화됨. [에픽의 새로운 모양](../../user/group/epics/_index.md#epics-as-work-items)을 활성화해야 합니다. [베타](../../policy/development_stages_support.md#beta) 버전으로 도입되었습니다.
- [GraphQL API](reference/_index.md) 를 사용한 에픽 나열은 GitLab 17.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/12852)되었습니다.
- GitLab 17.6에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/470685)되었습니다.
- GitLab 17.7에서 [GitLab Self-Managed 및 GitLab Dedicated에서 기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)되었습니다.
- GitLab 18.1에서 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)되고 있습니다. 기능 플래그 `work_item_epics` 제거됨.

{{< /history >}}

GitLab 17.2에서 [작업 항목으로 에픽](../../user/group/epics/_index.md#epics-as-work-items)을 도입했습니다.

통합이 계속 작동하는지 확인하려면:

- [에픽 GraphQL API](reference/_index.md#epic)를 사용하는 경우, 에픽 GraphQL API가 제거되기 전에 작업 항목 API로 마이그레이션합니다.
- [에픽 REST API](../epics.md)를 사용하는 경우, 계속 사용할 수 있지만 통합을 향후에도 사용할 수 있도록 마이그레이션해야 합니다.
- 새로운 기능(예: 담당자, 상태 표시, 다른 유형의 연결된 항목)의 경우 `WorkItem` GraphQL API를 사용해야 합니다.

## API 상태 {#api-status}

### REST API (`/api/v4/`) {#rest-api-apiv4}

에픽의 REST API:

- 여전히 지원되지만 더 이상 사용되지 않습니다.
- 기존 엔드포인트에서 계속 작동합니다.
- 새로운 기능을 받지 않습니다.
- 제거 날짜가 정해지지 않았지만 주요 릴리스에서 발생합니다.

### GraphQL API {#graphql-api}

`WorkItem` GraphQL API:

- 실험 단계로 표시됩니다.
- 프로덕션 환경에서 사용됩니다.
- GitLab 19.0 이전에 [일반 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/500620)될 예정입니다.
- GitLab 19.0 이전에 [실험 단계](https://gitlab.com/gitlab-org/gitlab/-/issues/500620)를 종료할 계획입니다.

[에픽 GraphQL API](reference/_index.md#epic)는 GitLab 19.0에서 제거할 계획입니다.

## Work Item API로 마이그레이션 {#migrate-to-the-work-item-api}

Work Item API는 위젯을 사용하여 상태 표시, 담당자, 계층 구조 등의 에픽 특성을 나타냅니다.

### GraphiQL 탐색기 설정 {#set-up-the-graphiql-explorer}

이 예제를 실행하려면 GraphiQL(기존 쿼리를 사용해 볼 수 있는 대화형 GraphQL API 탐색기)을 사용할 수 있습니다:

1. GraphiQL 탐색기 도구를 엽니다:
   - GitLab.com의 경우 <https://gitlab.com/-/graphql-explorer>로 이동합니다.
   - GitLab Self-Managed의 경우 `https://gitlab.example.com/-/graphql-explorer`로 이동합니다. `gitlab.example.com`를 인스턴스 URL로 변경합니다.
1. GraphiQL 탐색기 도구의 왼쪽 창에 예제에 나열된 쿼리를 붙여넣습니다.
1. **Play**를 선택합니다.

### 에픽 쿼리 {#query-epics}

> [!note]
> 에픽 ID는 작업 항목 ID와 다르지만 IID(각 그룹에 대해 증가된 ID)는 동일하게 유지됩니다. 예를 들어, `/gitlab-org/-/epics/123`의 에픽은 작업 항목과 동일한 IID `123`을 갖습니다.

**Before (Epic API)**:

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

응답 예:

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

**After (Work Item API)**:

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

응답 예:

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

### 에픽 생성 {#create-an-epic}

**Before (Epic API)**:

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

응답 예:

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

**After (Work Item API)**:

에픽을 생성하려면:

1. 네임스페이스에서 에픽의 작업 항목 유형 ID(`workItemTypeId`)를 가져옵니다.

   에픽의 `workItemTypeId`은 GitLab 인스턴스 또는 네임스페이스 간에 동일하도록 보장되지 않습니다. 기본 작업 항목 유형에 대해 동일한 ID를 보장하는 작업은 [에픽 15272](https://gitlab.com/groups/gitlab-org/-/epics/15272)에서 추적됩니다.

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

   응답 예:

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

1. 에픽 (유형 `epic`인 작업 항목)을 생성하고 해당 ID를 사용합니다:

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

   응답 예:

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

### 위젯 {#widgets}

Work Item API는 위젯 개념을 도입합니다. 위젯은 작업 항목 유형의 특정 기능이나 특성을 나타냅니다. 상태 표시나 담당자 같은 특성부터 날짜나 계층 구조까지 다양하게 사용할 수 있습니다. 각 작업 항목 유형에는 고유한 사용 가능한 위젯 세트가 있습니다.

#### 위젯을 사용하여 에픽 쿼리 {#query-epics-with-widgets}

에픽에 대한 자세한 정보를 검색하려면 GraphQL 쿼리에서 다양한 위젯을 사용할 수 있습니다. 다음 예제는 에픽의 다음 항목을 쿼리하는 방법을 보여줍니다:

- 계층 구조(부모/자식 관계)
- 담당자
- 이모지 반응
- 색상
- 상태 표시
- 시작 및 종료 날짜

사용 가능한 모든 위젯을 보려면 [작업 항목 위젯 참조](reference/_index.md#workitemwidget)를 참조합니다.

위젯을 사용하여 에픽을 쿼리하려면:

**Before (Epic API)**:

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

응답 예:

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

**After (Work Item API)**:

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

응답 예:

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
            "__typename": "WorkItemWidgetVerificationStatus"
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

#### 위젯을 사용하여 작업 항목 에픽 생성 {#create-a-work-item-epic-with-widgets}

위젯을 `input` 매개변수의 일부로 사용하여 작업 항목을 생성하거나 업데이트합니다.

예를 들어, 다음 쿼리를 실행하여 다음을 포함한 에픽을 생성합니다:

- 제목
- 설명
- 색상
- 상태 표시
- 시작 날짜
- 종료 날짜
- 담당자

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

응답 예:

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

#### 위젯을 사용하여 작업 항목 에픽 업데이트 {#update-a-work-item-epic-using-widgets}

작업 항목을 편집하려면 [위젯을 사용하여 작업 항목 에픽 생성](#create-a-work-item-epic-with-widgets)에서 위젯 입력을 다시 사용하되, `workItemUpdate` 뮤테이션을 사용합니다.

작업 항목의 전역 ID(형식 `gid://gitlab/WorkItem/<WorkItemID>`)를 가져오고 `input`의 `id`로 사용합니다:

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

응답 예:

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

### 작업 항목 에픽 삭제 {#delete-an-epic-work-item}

작업 항목 에픽을 삭제하려면 `workItemDelete` 뮤테이션을 사용합니다:

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

응답 예:

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
