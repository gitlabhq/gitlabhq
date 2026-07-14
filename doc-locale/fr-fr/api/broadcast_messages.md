---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des messages de diffusion
description: "Gérer les messages de diffusion avec le ciblage par rôle utilisateur, le filtrage par chemin et des thèmes personnalisables."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `target_access_levels` [introduit](https://gitlab.com/gitlab-org/growth/team-tasks/-/issues/461) dans GitLab 14.8 [avec un indicateur](../administration/feature_flags/_index.md) nommé `role_targeted_broadcast_messages`. Désactivé par défaut.
- Le paramètre `color` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95829) dans GitLab 15.6.
- `theme` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/498900) dans GitLab 17.6.

{{< /history >}}

Utilisez cette API pour interagir avec les bannières et les notifications affichées dans l'interface utilisateur. Pour en savoir plus, consultez [les messages de diffusion](../administration/broadcast_messages.md).

Les requêtes GET ne nécessitent pas d'authentification. Tous les autres points de terminaison de l'API des messages de diffusion sont accessibles uniquement aux administrateurs. Les requêtes non-GET effectuées par :

- Les invités obtiennent `401 Unauthorized`.
- Les utilisateurs standard obtiennent `403 Forbidden`.

## Lister tous les messages de diffusion {#list-all-broadcast-messages}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Liste tous les messages de diffusion.

```plaintext
GET /broadcast_messages
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages"
```

Exemple de réponse :

```json
[
    {
        "message":"Example broadcast message",
        "starts_at":"2016-08-24T23:21:16.078Z",
        "ends_at":"2016-08-26T23:21:16.080Z",
        "font":"#FFFFFF",
        "id":1,
        "active": false,
        "target_access_levels": [10,30],
        "target_path": "*/welcome",
        "broadcast_type": "banner",
        "dismissable": false,
        "theme": "indigo"
    }
]
```

## Récupérer un message de diffusion {#retrieve-a-broadcast-message}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Récupère un message de diffusion spécifié.

```plaintext
GET /broadcast_messages/:id
```

Paramètres :

| Attribut | Type    | Obligatoire | Description                          |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | entier | oui      | ID du message de diffusion à récupérer. |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

Exemple de réponse :

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-24T23:21:16.078Z",
    "ends_at":"2016-08-26T23:21:16.080Z",
    "font":"#FFFFFF",
    "id":1,
    "active":false,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "banner",
    "dismissable": false,
    "theme": "indigo"
}
```

## Créer un message de diffusion {#create-a-broadcast-message}

> [!warning]
> Les messages de diffusion sont accessibles publiquement via l'API, indépendamment des paramètres de ciblage. N'incluez pas d'informations sensibles ou confidentielles, et n'utilisez pas les messages de diffusion pour communiquer des informations privées à des groupes ou des projets spécifiques.

Crée un message de diffusion.

```plaintext
POST /broadcast_messages
```

Paramètres :

| Attribut              | Type              | Obligatoire | Description |
|:-----------------------|:------------------|:---------|:------------|
| `message`              | string            | oui      | Message à afficher. |
| `starts_at`            | datetime          | non       | Heure de début (par défaut, heure actuelle en UTC). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `ends_at`              | datetime          | non       | Heure de fin (par défaut, une heure après l'heure actuelle en UTC). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `font`                 | string            | non       | Code hexadécimal de la couleur de premier plan. |
| `target_access_levels` | tableau d'entiers | non       | Niveaux d'accès cibles (rôles) du message de diffusion. |
| `target_path`          | string            | non       | Chemin cible du message de diffusion. |
| `broadcast_type`       | string            | non       | Type d'apparence (par défaut : bannière) |
| `dismissable`          | boolean           | non       | L'utilisateur peut-il ignorer le message ? |
| `theme`                | string            | non       | Thème de couleur du message de diffusion (bannières uniquement). |

Les `target_access_levels` sont définis dans le module `Gitlab::Access`. Les niveaux valides sont les suivants :

- Invité (`10`)
- Planificateur (`15`)
- Reporter (`20`)
- Responsable sécurité (`25`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

Les options `theme` sont définies dans la classe `System::BroadcastMessage`. Les thèmes valides sont les suivants :

- `indigo` (par défaut)
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

Exemple de requête :

```shell
curl --data "message=Deploy in progress&target_access_levels[]=10&target_access_levels[]=30&theme=red" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages"
```

Exemple de réponse :

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "red"
}
```

## Mettre à jour un message de diffusion {#update-a-broadcast-message}

> [!warning]
> Les messages de diffusion sont accessibles publiquement via l'API, indépendamment des paramètres de ciblage. N'incluez pas d'informations sensibles ou confidentielles, et n'utilisez pas les messages de diffusion pour communiquer des informations privées à des groupes ou des projets spécifiques.

Met à jour un message de diffusion spécifié.

```plaintext
PUT /broadcast_messages/:id
```

Paramètres :

| Attribut              | Type              | Obligatoire | Description |
|:-----------------------|:------------------|:---------|:------------|
| `id`                   | entier           | oui      | ID du message de diffusion à mettre à jour. |
| `message`              | string            | non       | Message à afficher. |
| `starts_at`            | datetime          | non       | Heure de début (UTC). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `ends_at`              | datetime          | non       | Heure de fin (UTC). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `font`                 | string            | non       | Code hexadécimal de la couleur de premier plan. |
| `target_access_levels` | tableau d'entiers | non       | Niveaux d'accès cibles (rôles) du message de diffusion. |
| `target_path`          | string            | non       | Chemin cible du message de diffusion. |
| `broadcast_type`       | string            | non       | Type d'apparence (par défaut : bannière) |
| `dismissable`          | boolean           | non       | L'utilisateur peut-il ignorer le message ? |
| `theme`                | string            | non       | Thème de couleur du message de diffusion (bannières uniquement). |

Les `target_access_levels` sont définis dans le module `Gitlab::Access`. Les niveaux valides sont les suivants :

- Invité (`10`)
- Planificateur (`15`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

Les options `theme` sont définies dans la classe `System::BroadcastMessage`. Les thèmes valides sont les suivants :

- `indigo` (par défaut)
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

Exemple de requête :

```shell
curl --request PUT \
  --data "message=Update message" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

Exemple de réponse :

```json
{
    "message":"Update message",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "indigo"
}
```

## Supprimer un message de diffusion {#delete-a-broadcast-message}

Supprime un message de diffusion spécifié.

```plaintext
DELETE /broadcast_messages/:id
```

Paramètres :

| Attribut | Type    | Obligatoire | Description                        |
|:----------|:--------|:---------|:-----------------------------------|
| `id`      | entier | oui      | ID du message de diffusion à supprimer. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```
