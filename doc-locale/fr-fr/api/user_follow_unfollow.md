---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API de suivi et d'abonnement des utilisateurs"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour effectuer des actions d'abonnement sur des comptes utilisateurs. Pour plus d'informations, voir [Suivre des utilisateurs](../user/profile/_index.md#follow-users).

## Suivre un utilisateur {#follow-a-user}

Suit le compte utilisateur spécifié.

```plaintext
POST /users/:id/follow
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/follow"
```

Exemple de réponse :

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith"
}
```

## Ne plus suivre un utilisateur {#unfollow-a-user}

Cesse de suivre le compte utilisateur spécifié.

```plaintext
POST /users/:id/unfollow
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/unfollow"
```

## Lister tous les comptes qui suivent un utilisateur {#list-all-accounts-that-follow-a-user}

Liste tous les comptes utilisateurs qui suivent un utilisateur spécifié.

```plaintext
GET /users/:id/followers
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/followers"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "name": "Lennie Donnelly",
    "username": "evette.kilback",
    "state": "active",
    "locked": false,
    "avatar_url": "https://www.gravatar.com/avatar/7955171a55ac4997ed81e5976287890a?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/evette.kilback"
  },
  {
    "id": 4,
    "name": "Serena Bradtke",
    "username": "cammy",
    "state": "active",
    "locked": false,
    "avatar_url": "https://www.gravatar.com/avatar/a2daad869a7b60d3090b7b9bef4baf57?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/cammy"
  }
]
```

## Lister tous les comptes suivis par un utilisateur {#list-all-accounts-followed-by-a-user}

Liste tous les comptes utilisateurs suivis par un utilisateur spécifié.

```plaintext
GET /users/:id/following
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/following"
```
