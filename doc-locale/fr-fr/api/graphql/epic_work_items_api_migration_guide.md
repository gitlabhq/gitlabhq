---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migrer les API d'epic vers les éléments de travail"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut :  Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/9290) dans GitLab 17.2 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `work_item_epics`. Désactivé par défaut. [Le nouvel aspect des epics](../../user/group/epics/_index.md#epics-as-work-items) doit être activé. Introduit en [bêta](../../policy/development_stages_support.md#beta).
- La liste des epics à l'aide de l'[API GraphQL](reference/_index.md) a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/12852) dans GitLab 17.4.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/470685) dans GitLab 17.6.
- [Activé par défaut sur GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) dans GitLab 17.7.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/468310) dans GitLab 18.1. Le feature flag `work_item_epics` a été supprimé.

{{< /history >}}

GitLab 17.2 a introduit les [epics en tant qu'éléments de travail](../../user/group/epics/_index.md#epics-as-work-items).

Pour vous assurer que vos intégrations continuent de fonctionner :

- Si vous utilisez l'[API GraphQL d'epic](reference/_index.md#epic), migrez vers l'API des éléments de travail avant que l'API GraphQL d'epic soit supprimée.
- Si vous utilisez l'[API REST d'epic](../epics.md), vous pouvez continuer à l'utiliser, mais vous devriez migrer pour pérenniser vos intégrations.
- Pour les nouvelles fonctionnalités (telles que les personnes assignées, le statut de santé, les éléments liés avec d'autres types), vous devez utiliser l'API GraphQL `WorkItem`.

## Statut de l'API {#api-status}

### API REST (`/api/v4/`) {#rest-api-apiv4}

L'API REST pour les epics :

- Est toujours prise en charge, mais dépréciée.
- Continue de fonctionner avec les endpoints existants.
- Ne reçoit pas de nouvelles fonctionnalités.
- N'a pas de date de suppression définie, mais cela se produira lors d'une release majeure.

### API GraphQL {#graphql-api}

L'API GraphQL `WorkItem` :

- Est marquée comme expérimentale.
- Est utilisée dans les environnements de production.
- Sera [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/500620) avant GitLab 19.0
- Est prévue pour quitter le [statut expérimental](https://gitlab.com/gitlab-org/gitlab/-/issues/500620) avant GitLab 19.0

La [suppression de l'API GraphQL d'epic](reference/_index.md#epic) est prévue dans GitLab 19.0.

## Migrer vers l'API des éléments de travail {#migrate-to-the-work-item-api}

L'API des éléments de travail utilise des widgets pour représenter les attributs d'epic comme le statut de santé, les personnes assignées et la hiérarchie.

### Configurer l'explorateur GraphiQL {#set-up-the-graphiql-explorer}

Pour exécuter ces exemples, vous pouvez utiliser GraphiQL, un explorateur d'API GraphQL interactif vous permettant de jouer avec les requêtes existantes :

1. Ouvrez l'outil d'exploration GraphiQL :
   - Pour GitLab.com, accédez à <https://gitlab.com/-/graphql-explorer>.
   - Pour GitLab Self-Managed, accédez à `https://gitlab.example.com/-/graphql-explorer`. Remplacez `gitlab.example.com` par l'URL de votre instance.
1. Collez une requête répertoriée dans un exemple dans la fenêtre de gauche de votre outil d'exploration GraphiQL.
1. Sélectionnez **Play**.

### Interroger les epics {#query-epics}

> [!note]
> Les IDs d'epic sont différents des IDs d'éléments de travail, mais l'IID (ID incrémenté pour chaque groupe) reste le même. Par exemple, un epic à `/gitlab-org/-/epics/123` a le même IID `123` qu'un élément de travail.

**Before (Epic API)** :

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

Exemple de réponse :

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

**After (Work Item API)** :

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

Exemple de réponse :

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

### Créer un epic {#create-an-epic}

**Before (Epic API)** :

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

Exemple de réponse :

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

**After (Work Item API)** :

Pour créer un epic :

1. Obtenez l'ID du type d'élément de travail (`workItemTypeId`) pour les epics dans votre espace de nommage.

   Le `workItemTypeId` pour un epic n'est pas garanti d'être identique entre les instances GitLab ou les espaces de nommage. Le travail visant à garantir les mêmes IDs pour les types d'éléments de travail par défaut est suivi dans l'[epic 15272](https://gitlab.com/groups/gitlab-org/-/epics/15272).

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

   Exemple de réponse :

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

1. Créez l'epic (élément de travail avec le type `epic`) en utilisant cet ID :

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

   Exemple de réponse :

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

### Widgets {#widgets}

L'API des éléments de travail introduit le concept de widgets. Les widgets représentent des fonctionnalités ou attributs spécifiques d'un type d'élément de travail. Ils peuvent aller des attributs tels que le statut de santé ou les personnes assignées aux dates ou à la hiérarchie. Chaque type d'élément de travail dispose d'un ensemble unique de widgets disponibles.

#### Interroger les epics avec des widgets {#query-epics-with-widgets}

Pour récupérer des informations détaillées sur un epic, vous pouvez utiliser divers widgets dans votre requête GraphQL. L'exemple suivant montre comment interroger les éléments suivants d'un epic :

- Hiérarchie (relations parent/enfant)
- Personnes assignées
- Réactions emoji
- Couleur
- Statut de santé
- Dates de début et d'échéance

Pour tous les widgets disponibles, consultez la [référence des widgets d'éléments de travail](reference/_index.md#workitemwidget).

Pour interroger les epics avec des widgets :

**Before (Epic API)** :

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

Exemple de réponse :

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

**After (Work Item API)** :

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

Exemple de réponse :

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

#### Créer un élément de travail epic avec des widgets {#create-a-work-item-epic-with-widgets}

Utilisez des widgets dans le paramètre `input` pour créer ou mettre à jour des éléments de travail.

Par exemple, exécutez la requête ci-dessous pour créer un epic avec :

- Titre
- Description
- Couleur
- Statut de santé
- Date de début
- Date d'échéance
- Personne assignée

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

Exemple de réponse :

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

#### Mettre à jour un élément de travail epic à l'aide de widgets {#update-a-work-item-epic-using-widgets}

Pour modifier un élément de travail, réutilisez les entrées de widgets issues de [créer un élément de travail epic avec des widgets](#create-a-work-item-epic-with-widgets), mais utilisez la mutation `workItemUpdate` à la place.

Obtenez l'ID global de l'élément de travail (format `gid://gitlab/WorkItem/<WorkItemID>`) et utilisez-le comme `id` pour l'`input` :

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

Exemple de réponse :

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

### Supprimer un élément de travail epic {#delete-an-epic-work-item}

Pour supprimer un élément de travail epic, utilisez la mutation `workItemDelete` :

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

Exemple de réponse :

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
