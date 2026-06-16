---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de réassignation des espaces réservés de groupe
description: "Réassignez les utilisateurs espaces réservés en masse avec l'API REST."
---

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/513794) dans GitLab 17.10 [avec un flag](../administration/feature_flags/_index.md) nommé `importer_user_mapping_reassignment_csv`. Désactivée par défaut. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/478022) dans GitLab 18.0. L'indicateur de fonctionnalité `importer_user_mapping_reassignment_csv` a été supprimé.
- La réassignation des contributions au propriétaire d'un espace de nommage personnel lors de l'importation vers un espace de nommage personnel a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) dans GitLab 18.3 [avec un indicateur](../administration/feature_flags/_index.md) nommé `user_mapping_to_personal_namespace_owner`. Désactivé par défaut.
- La réassignation des contributions au propriétaire d'un espace de nommage personnel lors de l'importation vers un espace de nommage personnel est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626) dans GitLab 18.6. L'indicateur de fonctionnalité `user_mapping_to_personal_namespace_owner` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez cette API pour [réassigner des utilisateurs espaces réservés en masse](../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file).

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

> [!note]
> Le mappage des contributions des utilisateurs n'est pas pris en charge lorsque vous importez des projets vers un [espace de nommage personnel](../user/namespace/_index.md#types-of-namespaces). Lorsque vous importez vers un espace de nommage personnel, toutes les contributions sont assignées au propriétaire de l'espace de nommage personnel et ne peuvent pas être réassignées.

## Récupérer les réassignations en attente {#retrieve-pending-reassignments}

Récupère un fichier CSV avec une liste de réassignations en attente.

```plaintext
GET /groups/:id/placeholder_reassignments
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | ID du groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/placeholder_reassignments"
```

Exemple de réponse :

```csv
Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
http://gitlab.example,gitlab_migration,11,Bob,bob,"",""
http://gitlab.example,gitlab_migration,9,Alice,alice,"",""
```

## Réassigner les espaces réservés {#reassign-placeholders}

Réassigne les utilisateurs espaces réservés avec un fichier CSV téléversé.

```plaintext
POST /groups/:id/placeholder_reassignments
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | ID du groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@placeholder_reassignments_for_group_2_1741253695.csv" \
  --url "http://gdk.test:3000/api/v4/groups/2/placeholder_reassignments"
```

Exemple de réponse :

```json
{"message":"The file is being processed and you will receive an email when completed."}
```
