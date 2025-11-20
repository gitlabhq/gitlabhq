---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 作業アイテムにエピックAPIを移行する
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.2で`work_item_epics`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/9290)されました。デフォルトでは無効になっています。[エピックの新しい外観](../../user/group/epics/_index.md#epics-as-work-items)を有効にする必要があります。[ベータ](../../policy/development_stages_support.md#beta)として導入されました。
- [GraphQL API](reference/_index.md)を使用したエピックの一覧表示は、GitLab 17.4で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/12852)。
- GitLab 17.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/470685)になりました。
- GitLab 17.7の[GitLab Self-ManagedおよびGitLab Dedicatedでデフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)になりました。機能フラグ`work_item_epics`は削除されました。

{{< /history >}}

GitLab 17.2では、[作業項目としてのエピック](../../user/group/epics/_index.md#epics-as-work-items)を導入しました。

インテグレーションが引き続き動作するようにするには、次の手順に従ってください:

- [Epic GraphQL API](reference/_index.md#epic)を使用している場合は、Epic GraphQL APIが削除される前にWork Item APIに移行してください。
- [REST API](../epics.md)を使用している場合は、引き続き使用できますが、将来のインテグレーションに対応できるように移行する必要があります。
- 新しい機能（担当者、ヘルスステータス、他のタイプとのリンクされたアイテムなど）については、`WorkItem` GraphQL APIを使用する必要があります。

## APIステータス {#api-status}

### REST API (`/api/v4/`) {#rest-api-apiv4}

エピックのREST API:

- 引き続きサポートされていますが、非推奨になりました。
- 既存のエンドポイントで引き続き動作します。
- 新機能は取得しません。
- 削除日は設定されていませんが、メジャーリリースで削除されます。

### GraphQL API {#graphql-api}

`WorkItem` GraphQL APIを使用します:

- 試験的とマークされています。
- 本番環境で使用されています。
- GitLab 19.0より前に[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/500620)される予定です
- GitLab 19.0より前に[試験的ステータス](https://gitlab.com/gitlab-org/gitlab/-/issues/500620)を終了する予定です

[Epic GraphQL API](reference/_index.md#epic)は、GitLab 19.0で削除される予定です。

## Work Item APIへの移行 {#migrate-to-the-work-item-api}

Work Item APIは、ヘルスステータス、担当者、階層などのエピックの属性を表すためにウィジェットを使用します。

### GraphiQLエクスプローラーのセットアップ {#set-up-the-graphiql-explorer}

これらの例を実行するには、既存のクエリを試すことができるインタラクティブなGraphQL APIエクスプローラーであるGraphiQLを使用できます:

1. GraphiQLエクスプローラーツールを開きます:
   - GitLab.comの場合は、<https://gitlab.com/-/graphql-explorer>に移動します。
   - GitLab Self-Managedの場合は、`https://gitlab.example.com/-/graphql-explorer`にアクセスしてください。`gitlab.example.com`をお使いのインスタンスのURLに変更してください。
1. 例にリストされているクエリをGraphiQLエクスプローラーツールの左側のウィンドウに貼り付けます。
1. **再生**を選択します。

### エピックのクエリ {#query-epics}

{{< alert type="note" >}}

エピックIDは作業項目のIDとは異なりますが、IID（各グループで増分されたID）は同じままです。たとえば、`/gitlab-org/-/epics/123`のエピックは、作業項目と同じIID `123`を持ちます。

{{< /alert >}}

**前 (Epic API)**:

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

レスポンス例:

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

**後 (Work Item API)**:

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

レスポンス例:

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

### エピックを作成する {#create-an-epic}

**前 (Epic API)**:

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

レスポンス例:

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

**後 (Work Item API)**:

エピックを作成するには:

1. ネームスペース内のエピックの作業項目のタイプID（`workItemTypeId`）を取得します。

   エピックの`workItemTypeId`は、GitLabインスタンスまたはネームスペース間で同じであるとは限りません。defaultの作業項目タイプに同じIDを保証する作業は、[epic 15272](https://gitlab.com/groups/gitlab-org/-/epics/15272)で追跡されます。

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

   レスポンス例:

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

1. そのIDを使用して、エピック（タイプ`epic`の作業項目）を作成します:

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

   レスポンス例:

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

### ウィジェット {#widgets}

Work Item APIは、ウィジェットの概念を導入します。ウィジェットは、作業項目のタイプの特定の機能または属性を表します。これらは、ヘルスステータスや担当者から日付や階層などの属性にまで及ぶことがあります。各作業項目のタイプには、使用可能なウィジェットの固有のセットがあります。

#### ウィジェットを使用したエピックのクエリ {#query-epics-with-widgets}

エピックに関する詳細な情報を取得するには、GraphQLのクエリでさまざまなウィジェットを使用できます。次の例では、エピックのクエリ方法を示します:

- 階層（親と子の関係）
- 担当者
- 絵文字リアクション
- 色
- ヘルスステータス
- 開始日と期日

使用可能なすべてのウィジェットについては、[Work Itemウィジェットの参照](reference/_index.md#workitemwidget)を参照してください。

ウィジェットを使用してエピックをクエリするには:

**前 (Epic API)**:

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

レスポンス例:

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

**後 (Work Item API)**:

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

レスポンス例:

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

#### ウィジェットを使用した作業項目のエピックの作成 {#create-a-work-item-epic-with-widgets}

`input`パラメータの一部としてウィジェットを使用して、作業項目を作成または更新します。

たとえば、次のクエリを実行して、以下を使用してエピックを作成します:

- タイトル
- 説明
- 色
- ヘルスステータス
- 開始日
- 期限
- 担当者

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

レスポンス例:

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

#### ウィジェットを使用した作業項目のエピックの更新 {#update-a-work-item-epic-using-widgets}

作業項目を編集するには、[ウィジェットを使用した作業項目のエピックの作成](#create-a-work-item-epic-with-widgets)からの入力ウィジェットを再利用しますが、代わりに`workItemUpdate`ミューテーションを使用します。

作業項目のグローバルID（形式`gid://gitlab/WorkItem/<WorkItemID>`）を取得し、`input`の`id`として使用します:

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

レスポンス例:

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

### エピック作業項目の削除 {#delete-an-epic-work-item}

エピック作業項目を削除するには、`workItemDelete`ミューテーションを使用します:

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

レスポンス例:

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
