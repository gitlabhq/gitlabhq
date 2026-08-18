---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Liens de groupe LDAP
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Utilisez cette API pour gérer les liens de groupe LDAP. Pour plus d'informations, voir [gérer les appartenances aux groupes avec LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

## Lister tous les liens de groupe LDAP {#list-all-ldap-group-links}

Liste tous les liens de groupe LDAP.

```plaintext
GET /groups/:id/ldap_group_links
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

Exemple de réponse :

```json
[
  {
    "cn": "group1",
    "group_access": 40,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  },
  {
    "cn": "group2",
    "group_access": 10,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  }
]
```

## Ajouter un lien de groupe LDAP avec un CN ou un filtre {#add-an-ldap-group-link-with-cn-or-filter}

Ajoute un lien de groupe LDAP à l'aide d'un CN ou d'un filtre.

```plaintext
POST /groups/:id/ldap_group_links
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `group_access` | entier   | oui      | Le niveau d'accès par défaut pour les membres du groupe LDAP. Valeurs possibles :  `0` (Aucun accès), `5` (accès minimum), `10` (Invité), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer), `50` (Owner). |
| `provider` | string        | oui      | ID du fournisseur LDAP pour le lien de groupe LDAP. |
| `cn`      | string         | oui/non   | Le CN d'un groupe LDAP. Indiquez soit un `cn`, soit un `filter`, mais pas les deux. |
| `filter`  | string         | oui/non   | Le filtre LDAP pour le groupe. Indiquez soit un `cn`, soit un `filter`, mais pas les deux. |
| `member_role_id` | entier | non       | L'ID du [rôle de membre](member_roles.md). GitLab Ultimate uniquement. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"group_access": 40, "provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

Exemple de réponse :

```json
{
  "cn": "group2",
  "group_access": 40,
  "provider": "main",
  "filter": null,
  "member_role_id": null
}
```

## Supprimer un lien de groupe LDAP avec un CN ou un filtre {#delete-an-ldap-group-link-with-cn-or-filter}

Supprime un lien de groupe LDAP à l'aide d'un CN ou d'un filtre.

```plaintext
DELETE /groups/:id/ldap_group_links
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `provider` | string        | oui      | ID du fournisseur LDAP pour le lien de groupe LDAP. |
| `cn`      | string         | oui/non   | Le CN d'un groupe LDAP. Indiquez soit un `cn`, soit un `filter`, mais pas les deux. |
| `filter`  | string         | oui/non   | Le filtre LDAP pour le groupe. Indiquez soit un `cn`, soit un `filter`, mais pas les deux. |

Exemple de requête :

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

En cas de succès, aucune réponse n'est renvoyée.

## Supprimer un lien de groupe LDAP (déprécié) {#delete-an-ldap-group-link-deprecated}

Supprime un lien de groupe LDAP. Déprécié. Prévu pour être supprimé dans une prochaine release. Utilisez plutôt [Supprimer un lien de groupe LDAP avec un CN ou un filtre](#delete-an-ldap-group-link-with-cn-or-filter).

Supprimer un lien de groupe LDAP avec un CN :

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `cn`      | string         | oui      | Le CN d'un groupe LDAP |

Supprimer un lien de groupe LDAP pour un fournisseur LDAP spécifique :

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `cn`      | string         | oui      | Le CN d'un groupe LDAP |
| `provider` | string        | oui      | Fournisseur LDAP pour le lien de groupe LDAP |
