---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des paramètres d'approbation des merge requests dans GitLab."
title: "API des paramètres d'approbation des merge requests"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [paramètres d'approbation des merge requests](../user/project/merge_requests/approvals/settings.md) de groupe et de projet. Tous les endpoints nécessitent une authentification.

## Paramètres d'approbation des MR pour les groupes {#group-mr-approval-settings}

Prérequis :

- Vous devez disposer du rôle Owner dans le groupe.

### Récupérer les paramètres d'approbation des MR pour un groupe {#retrieve-mr-approval-settings-for-a-group}

Récupère les paramètres d'approbation des merge requests pour un groupe spécifié.

```plaintext
GET /groups/:id/merge_request_approval_setting
```

Paramètres :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting"
```

Exemple de réponse :

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### Mettre à jour les paramètres d'approbation des MR pour un groupe {#update-group-mr-approval-settings}

Mettez à jour les paramètres d'approbation des merge requests d'un groupe.

```plaintext
PUT /groups/:id/merge_request_approval_setting
```

Paramètres :

| Attribut                                            | Type              | Obligatoire | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `allow_author_approval`                              | boolean           | Non       | Autoriser ou empêcher les auteurs d'approuver eux-mêmes les merge requests ; `true` signifie que les auteurs peuvent s'auto-approuver. |
| `allow_committer_approval`                           | boolean           | Non       | Autoriser ou empêcher les contributeurs d'approuver eux-mêmes les merge requests. |
| `allow_overrides_to_approver_list_per_merge_request` | boolean           | Non       | Autoriser ou empêcher le remplacement des approbateurs par merge request. |
| `retain_approvals_on_push`                           | boolean           | Non       | Conserver le nombre d'approbations lors d'un nouveau push. |
| `require_reauthentication_to_approve`                | boolean           | Non       | Exiger que l'approbateur s'authentifie avant d'ajouter l'approbation. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) dans GitLab 17.1. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting?allow_author_approval=false"
```

Exemple de réponse :

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

## Paramètres d'approbation des MR pour les projets {#project-mr-approval-settings}

Prérequis :

- Vous devez disposer du rôle Maintainer dans le projet.

### Récupérer les paramètres d'approbation des MR pour un projet {#retrieve-mr-approval-settings-for-a-project}

Récupère les paramètres d'approbation des merge requests pour un projet spécifié.

```plaintext
GET /projects/:id/merge_request_approval_setting
```

Paramètres :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting"
```

Exemple de réponse :

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": true,
    "inherited_from": "group"
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### Mettre à jour les paramètres d'approbation des MR pour un projet {#update-project-mr-approval-settings}

Mettez à jour les paramètres d'approbation des merge requests d'un projet.

```plaintext
PUT /projects/:id/merge_request_approval_setting
```

Paramètres :

| Attribut                                            | Type              | Obligatoire | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `allow_author_approval`                              | boolean           | Non       | Autoriser ou empêcher les auteurs d'approuver eux-mêmes les merge requests ; `true` signifie que les auteurs peuvent s'auto-approuver. |
| `allow_committer_approval`                           | boolean           | Non       | Autoriser ou empêcher les contributeurs d'approuver eux-mêmes les merge requests. |
| `allow_overrides_to_approver_list_per_merge_request` | boolean           | Non       | Autoriser ou empêcher le remplacement des approbateurs par merge request. |
| `retain_approvals_on_push`                           | boolean           | Non       | Conserver le nombre d'approbations lors d'un nouveau push. |
| `selective_code_owner_removals`                      | boolean           | Non       | Réinitialiser les approbations des propriétaires du code si leurs fichiers ont été modifiés. Vous devez désactiver le champ `retain_approvals_on_push` pour utiliser ce champ. |
| `require_reauthentication_to_approve`                | boolean           | Non       | Exiger que l'approbateur s'authentifie avant d'ajouter l'approbation. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) dans GitLab 17.1. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting?allow_author_approval=false"
```

Exemple de réponse :

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```
