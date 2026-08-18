---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST pour les règles de protection des packages dans GitLab."
title: API REST des packages protégés
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151741) dans GitLab 17.1 [avec un feature flag](../administration/feature_flags/_index.md) nommé `packages_protected_packages`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) dans GitLab 17.5.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) dans GitLab 17.6. L'indicateur de fonctionnalité `packages_protected_packages` a été supprimé.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180063) de l'attribut `minimum_access_level_for_delete` dans GitLab 17.11 [avec un flag](../administration/feature_flags/_index.md) nommé `packages_protected_packages_delete`. Désactivé par défaut.

{{< /history >}}

Utilisez cette API REST pour gérer les [règles de protection pour les packages](../user/packages/package_registry/package_protection_rules.md).

## Répertorier toutes les règles de protection des packages {#list-all-package-protection-rules}

Répertorie toutes les règles de protection des packages pour un projet spécifié.

```plaintext
GET /api/v4/projects/:id/packages/protection/rules
```

Attributs pris en charge :

| Attribut                     | Type            | Obligatoire | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | entier ou chaîne de caractères  | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et une liste de règles de protection des packages.

Peut renvoyer les codes de statut suivants :

- `200 OK` : Une liste de règles de protection des packages.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'est pas autorisé à répertorier les règles de protection des packages pour ce projet.
- `404 Not Found` : Le projet est introuvable.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules"
```

Exemple de réponse :

```json
[
 {
  "id": 1,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-0",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 },
 {
  "id": 2,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-1",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 }
]
```

## Créer une règle de protection des packages {#create-a-package-protection-rule}

Crée une règle de protection des packages pour un projet spécifié.

```plaintext
POST /api/v4/projects/:id/packages/protection/rules
```

Attributs pris en charge :

| Attribut                             | Type            | Obligatoire | Description                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | entier ou chaîne de caractères  | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `package_name_pattern`                | string          | Oui      | Nom du package protégé par la règle de protection. Par exemple `@my-scope/my-package-*`. Caractère générique `*` autorisé. |
| `package_type`                        | string          | Oui      | Type de package protégé par la règle de protection. Par exemple `npm`. |
| `minimum_access_level_for_delete`     | string          | Oui      | Niveau d'accès GitLab minimum requis pour supprimer un package. Les valeurs valides incluent `null`, `owner` ou `admin`. Si la valeur est `null`, le niveau d'accès minimum par défaut est `maintainer`. Doit être fourni lorsque `minimum_access_level_for_push` n'est pas défini. Derrière un feature flag nommé `packages_protected_packages_delete`. Désactivé par défaut. |
| `minimum_access_level_for_push`       | string          | Oui      | Niveau d'accès GitLab minimum requis pour envoyer un package. Les valeurs valides incluent `null`, `maintainer`, `owner` ou `admin`. Si la valeur est `null`, le niveau d'accès minimum par défaut est `developer`. Doit être fourni lorsque `minimum_access_level_for_delete` n'est pas défini. |

En cas de succès, renvoie [`201`](rest/troubleshooting.md#status-codes) et la règle de protection des packages créée.

Peut renvoyer les codes de statut suivants :

- `201 Created` : La règle de protection des packages a été créée avec succès.
- `400 Bad Request` : La règle de protection des packages est invalide.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'est pas autorisé à créer une règle de protection des packages.
- `404 Not Found` : Le projet est introuvable.
- `422 Unprocessable Entity` : La règle de protection des packages n'a pas pu être créée, par exemple parce que `package_name_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules" \
  --data '{
       "package_name_pattern": "package-name-pattern-*",
       "package_type": "npm",
       "minimum_access_level_for_delete": "owner",
       "minimum_access_level_for_push": "maintainer"
    }'
```

## Mettre à jour une règle de protection des packages {#update-a-package-protection-rule}

Met à jour une règle de protection des packages pour un projet spécifié.

```plaintext
PATCH /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

Attributs pris en charge :

| Attribut                             | Type            | Obligatoire | Description                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | entier ou chaîne de caractères  | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `package_protection_rule_id`          | integer         | Oui      | ID de la règle de protection des packages à mettre à jour. |
| `package_name_pattern`                | string          | Non       | Nom du package protégé par la règle de protection. Par exemple `@my-scope/my-package-*`. Caractère générique `*` autorisé. |
| `package_type`                        | string          | Non       | Type de package protégé par la règle de protection. Par exemple `npm`. |
| `minimum_access_level_for_delete`     | string          | Non       | Niveau d'accès GitLab minimum requis pour supprimer un package. Les valeurs valides incluent `null`, `owner` ou `admin`. Si la valeur est `null`, le niveau d'accès minimum par défaut est `maintainer`. Doit être fourni lorsque `minimum_access_level_for_push` n'est pas défini. Derrière un feature flag nommé `packages_protected_packages_delete`. Désactivé par défaut. |
| `minimum_access_level_for_push`       | string          | Non       | Niveau d'accès GitLab minimum requis pour envoyer un package. Les valeurs valides incluent `null`, `maintainer`, `owner` ou `admin`. Si la valeur est `null`, le niveau d'accès minimum par défaut est `developer`. Doit être fourni lorsque `minimum_access_level_for_delete` n'est pas défini. |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et la règle de protection des packages mise à jour.

Peut renvoyer les codes de statut suivants :

- `200 OK` : La règle de protection des packages a été mise à jour avec succès.
- `400 Bad Request` : Le correctif est invalide.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'est pas autorisé à mettre à jour une règle de protection des packages.
- `404 Not Found` : Le projet est introuvable.
- `422 Unprocessable Entity` : La règle de protection des packages n'a pas pu être mise à jour, par exemple parce que `package_name_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32" \
  --data '{
       "package_name_pattern": "new-package-name-pattern-*"
    }'
```

## Supprimer une règle de protection des packages {#delete-a-package-protection-rule}

Supprime une règle de protection des packages d'un projet spécifié.

```plaintext
DELETE /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

Attributs pris en charge :

| Attribut                     | Type            | Obligatoire | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | entier ou chaîne de caractères  | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `package_protection_rule_id`  | integer         | Oui      | ID de la règle de protection des packages à supprimer. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Peut renvoyer les codes de statut suivants :

- `204 No Content` : La règle de protection des packages a été supprimée avec succès.
- `400 Bad Request` : L'`id` ou l'`package_protection_rule_id` sont manquants ou invalides.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'est pas autorisé à supprimer la règle de protection des packages.
- `404 Not Found` : Le projet ou la règle de protection des packages est introuvable.

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32"
```
