---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'analyse de l'activité de groupe"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des informations sur les activités de groupe. Pour plus d'informations, consultez [l'analyse de l'activité de groupe](../user/group/manage.md#group-activity-analytics).

## Récupérer le nombre de tickets récemment créés pour un groupe {#retrieve-count-of-recently-created-issues-for-a-group}

Récupère le nombre de tickets récemment créés pour un groupe spécifié.

```plaintext
GET /analytics/group_activity/issues_count
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | oui | Chemin du groupe |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/issues_count?group_path=gitlab-org"
```

Exemple de réponse :

```json
{ "issues_count": 10 }
```

## Récupérer le nombre de merge requests récemment créées pour un groupe {#retrieve-count-of-recently-created-merge-requests-for-a-group}

Récupère le nombre de merge requests récemment créées pour un groupe spécifié.

```plaintext
GET /analytics/group_activity/merge_requests_count
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | oui | Chemin du groupe |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/merge_requests_count?group_path=gitlab-org"
```

Exemple de réponse :

```json
{ "merge_requests_count": 10 }
```

## Récupérer le nombre de membres récemment ajoutés à un groupe {#retrieve-count-of-members-recently-added-to-a-group}

Récupère le nombre de membres récemment ajoutés à un groupe spécifié.

```plaintext
GET /analytics/group_activity/new_members_count
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | oui | Chemin du groupe |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/analytics/group_activity/new_members_count?group_path=gitlab-org"
```

Exemple de réponse :

```json
{ "new_members_count": 10 }
```
