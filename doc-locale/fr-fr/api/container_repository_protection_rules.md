---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des règles de protection des dépôts de conteneurs dans GitLab."
title: API des règles de protection des dépôts de conteneurs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155798) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `container_registry_protected_containers`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/429074) dans GitLab 17.8.
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/480385) dans GitLab 17.8. L'indicateur de fonctionnalité `container_registry_protected_containers` a été supprimé.

{{< /history >}}

Utilisez cette API REST pour gérer les [règles de protection des dépôts de conteneurs](../user/packages/container_registry/protected_container_tags.md).

## Répertorier toutes les règles de protection des dépôts de conteneurs {#list-all-container-repository-protection-rules}

Répertorie toutes les règles de protection des dépôts de conteneurs pour un projet spécifié.

```plaintext
GET /api/v4/projects/:id/registry/protection/repository/rules
```

Attributs pris en charge :

| Attribut                     | Type            | Obligatoire | Description                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | entier ou chaîne  | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et une liste de règles de protection des dépôts de conteneurs.

Peut retourner les codes de statut suivants :

- `200 OK` :  Une liste de règles de protection.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas l'autorisation de répertorier les règles de protection pour ce projet.
- `404 Not Found` :  Le projet est introuvable.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight0",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight1",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  }
]
```

## Créer une règle de protection de dépôt de conteneurs {#create-a-container-repository-protection-rule}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) dans GitLab 17.2.

{{< /history >}}

Crée une règle de protection de dépôt de conteneurs pour un projet spécifié.

```plaintext
POST /api/v4/projects/:id/registry/protection/repository/rules
```

Attributs pris en charge :

| Attribut                         | Type           | Obligatoire | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `repository_path_pattern`         | string         | Oui      | Modèle de chemin de dépôt de conteneurs protégé par la règle de protection. Par exemple `flight/flight-*`. Caractère générique `*` autorisé. |
| `minimum_access_level_for_delete` | string         | Non       | Niveau d'accès GitLab minimum requis pour supprimer des images de conteneurs dans le registre de conteneurs. Par exemple `maintainer`, `owner`, `admin`. Doit être fourni lorsque `minimum_access_level_for_push` n'est pas défini. |
| `minimum_access_level_for_push`   | string         | Non       | Niveau d'accès GitLab minimum requis pour envoyer des images de conteneurs vers le registre de conteneurs. Par exemple `maintainer`, `owner` ou `admin`. Doit être fourni lorsque `minimum_access_level_for_delete` n'est pas défini. |

En cas de succès, retourne [`201`](rest/troubleshooting.md#status-codes) et la règle de protection de dépôt de conteneurs créée.

Peut retourner les codes de statut suivants :

- `201 Created` :  La règle de protection a été créée avec succès.
- `400 Bad Request` :  La règle de protection est invalide.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas l'autorisation de créer une règle de protection.
- `404 Not Found` :  Le projet est introuvable.
- `422 Unprocessable Entity` :  La règle de protection n'a pas pu être créée. Par exemple, parce que `repository_path_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules" \
  --data '{
        "repository_path_pattern": "flightjs/flight-needs-to-be-a-unique-path",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

## Mettre à jour une règle de protection de dépôt de conteneurs {#update-a-container-repository-protection-rule}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) dans GitLab 17.2.

{{< /history >}}

Met à jour une règle de protection de dépôt de conteneurs pour un projet spécifié.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

Attributs pris en charge :

| Attribut                         | Type           | Obligatoire | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `protection_rule_id`              | entier        | Oui      | ID de la règle de protection à mettre à jour. |
| `minimum_access_level_for_delete` | string         | Non       | Niveau d'accès GitLab minimum requis pour supprimer des images de conteneurs dans le registre de conteneurs. Par exemple `maintainer`, `owner`, `admin`. Doit être fourni lorsque `minimum_access_level_for_push` n'est pas défini. Pour annuler la valeur, utilisez une chaîne vide `""`. |
| `minimum_access_level_for_push`   | string         | Non       | Niveau d'accès GitLab minimum requis pour envoyer des images de conteneurs vers le registre de conteneurs. Par exemple `maintainer`, `owner` ou `admin`. Doit être fourni lorsque `minimum_access_level_for_delete` n'est pas défini. Pour annuler la valeur, utilisez une chaîne vide `""`. |
| `repository_path_pattern`         | string         | Non       | Modèle de chemin de dépôt de conteneurs protégé par la règle de protection. Par exemple `flight/flight-*`. Caractère générique `*` autorisé. |

En cas de succès, retourne [`200`](rest/troubleshooting.md#status-codes) et la règle de protection mise à jour.

Peut retourner les codes de statut suivants :

- `200 OK` : La règle de protection a été mise à jour avec succès.
- `400 Bad Request` : La règle de protection est invalide.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'a pas l'autorisation de mettre à jour la règle de protection.
- `404 Not Found` : Le projet est introuvable.
- `422 Unprocessable Entity` : La règle de protection n'a pas pu être mise à jour. Par exemple, parce que `repository_path_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/32" \
  --data '{
       "repository_path_pattern": "flight/flight-*"
    }'
```

## Supprimer une règle de protection de dépôt de conteneurs {#delete-a-container-repository-protection-rule}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/457518) dans GitLab 17.4.

{{< /history >}}

Supprime une règle de protection de dépôt de conteneurs spécifiée.

```plaintext
DELETE /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

Attributs pris en charge :

| Attribut            | Type           | Obligatoire | Description |
|----------------------|----------------|----------|-------------|
| `id`                 | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `protection_rule_id` | entier        | Oui      | ID de la règle de protection de dépôt de conteneurs à supprimer. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Peut retourner les codes de statut suivants :

- `204 No Content` : La règle de protection a été supprimée avec succès.
- `400 Bad Request` : Le `id` ou le `protection_rule_id` sont manquants ou invalides.
- `401 Unauthorized` : Le jeton d'accès est invalide.
- `403 Forbidden` : L'utilisateur n'a pas l'autorisation de supprimer la règle de protection.
- `404 Not Found` : Le projet ou la règle de protection est introuvable.

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/1"
```
