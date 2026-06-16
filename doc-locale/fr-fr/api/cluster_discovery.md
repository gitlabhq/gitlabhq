---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de découverte de cluster (basée sur les certificats) (obsolète)
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

## Récupérer les clusters basés sur les certificats {#retrieve-certificate-based-clusters}

Récupérez les clusters basés sur les certificats qui sont enregistrés dans un groupe, un sous-groupe ou un projet. Les clusters désactivés et activés sont également retournés.

```plaintext
GET /discover-cert-based-clusters
```

Paramètres :

| Attribut | Type           | Obligatoire | Description                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `group_id`      | entier ou chaîne de caractères | oui      | L'ID du groupe |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/discover-cert-based-clusters?group_id=1"
```

Exemple de réponse :

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
    "my-clusters-group/project1-with-cluster": [
      {
        "id": 1,
        "name": "test"
      }
    ]
  }
}
```
