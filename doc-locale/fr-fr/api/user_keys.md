---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des clés SSH et GPG des utilisateurs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [clés SSH](../user/ssh.md) et les [clés GPG](../user/project/repository/signed_commits/gpg.md) des utilisateurs.

## Lister toutes les clés SSH {#list-all-ssh-keys}

Liste toutes les clés SSH de votre compte utilisateur.

Utilisez les `page` et `per_page` [paramètres de pagination](rest/_index.md#offset-based-pagination) pour filtrer les résultats.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/keys
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "auth"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z",
    "usage_type": "signing"
  }
]
```

## Lister toutes les clés SSH d'un utilisateur {#list-all-ssh-keys-for-a-user}

Liste toutes les clés SSH d'un compte utilisateur spécifié. Ce point de terminaison ne requiert pas d'authentification.

```plaintext
GET /users/:id_or_username/keys
```

Attributs pris en charge :

| Attribut        | Type   | Obligatoire | Description |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | string | oui      | ID ou nom d'utilisateur du compte utilisateur |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/1/keys"
```

## Récupérer une clé SSH {#retrieve-an-ssh-key}

Récupère une clé SSH de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/keys/:key_id
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | oui      | ID de la clé existante |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/keys/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## Récupérer une clé SSH d'un utilisateur {#retrieve-an-ssh-key-for-a-user}

Récupère une clé SSH d'un compte utilisateur spécifié. Ce point de terminaison ne requiert pas d'authentification.

```plaintext
GET /users/:id/keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID ou nom d'utilisateur du compte utilisateur |
| `key_id`  | entier | oui      | ID de la clé existante  |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/1/keys/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Public key",
  "key": "<SSH_KEY>",
  "created_at": "2014-08-01T14:47:39.080Z",
  "usage_type": "auth"
}
```

## Ajouter une clé SSH {#add-an-ssh-key}

{{< history >}}

- Le paramètre `usage_type` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551) dans GitLab 15.7.

{{< /history >}}

Ajoute une clé SSH à votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
POST /user/keys
```

Attributs pris en charge :

| Attribut    | Type   | Obligatoire | Description |
|:-------------|:-------|:---------|:------------|
| `title`      | string | oui      | Titre de la clé |
| `key`        | string | oui      | Valeur de la clé publique |
| `expires_at` | string | non       | Date d'expiration de la clé au format ISO (`YYYY-MM-DD`). |
| `usage_type` | string | non       | Périmètre d'utilisation (portée) de la clé. Valeurs possibles : `auth`, `signing` ou `auth_and_signing`. Valeur par défaut : `auth_and_signing` |

Renvoie soit :

- La clé créée avec le statut `201 Created` en cas de succès.
- Une erreur `400 Bad Request` avec un message expliquant l'erreur :

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

Exemple de réponse :

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## Ajouter une clé SSH pour un utilisateur {#add-an-ssh-key-for-a-user}

{{< history >}}

- Le paramètre `usage_type` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105551) dans GitLab 15.7.

{{< /history >}}

Ajoute une clé SSH à un compte utilisateur spécifié.

> [!note]
> Ceci ajoute également un événement d'audit.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/keys
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description |
|:-------------|:--------|:---------|:------------|
| `id`         | entier | oui      | ID du compte utilisateur |
| `title`      | string  | oui      | Titre de la clé |
| `key`        | string  | oui      | Valeur de la clé publique  |
| `expires_at` | string  | non       | Date d'expiration de la clé au format ISO (`YYYY-MM-DD`). |
| `usage_type` | string  | non       | Périmètre d'utilisation (portée) de la clé. Valeurs possibles : `auth`, `signing` ou `auth_and_signing`. Valeur par défaut : `auth_and_signing` |

Renvoie soit :

- La clé créée avec le statut `201 Created` en cas de succès.
- Une erreur `400 Bad Request` avec un message expliquant l'erreur :

  ```json
  {
    "message": {
      "fingerprint": [
        "has already been taken"
      ],
      "key": [
        "has already been taken"
      ]
    }
  }
  ```

Exemple de réponse :

```json
{
  "title": "ABC",
  "key": "<SSH_KEY>",
  "expires_at": "2016-01-21T00:00:00.000Z",
  "usage_type": "auth"
}
```

## Supprimer une clé SSH {#delete-an-ssh-key}

Supprime une clé SSH de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
DELETE /user/keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | entier | oui      | ID de la clé existante  |

Renvoie soit :

- Un code de statut `204 No Content` si l'opération a réussi.
- Un code de statut `404` si la ressource est introuvable.

## Supprimer une clé SSH pour un utilisateur {#delete-an-ssh-key-for-a-user}

Supprime une clé SSH d'un compte utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
DELETE /users/:id/keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |
| `key_id`  | entier | oui      | ID de la clé existante  |

## Lister toutes les clés GPG {#list-all-gpg-keys}

Liste toutes les clés GPG de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/gpg_keys
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Lister toutes les clés GPG d'un utilisateur {#list-all-gpg-keys-for-a-user}

Liste toutes les clés GPG d'un compte utilisateur spécifié. Ce point de terminaison ne requiert pas d'authentification.

```plaintext
GET /users/:id/gpg_keys
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Récupérer une clé GPG {#retrieve-a-gpg-key}

Récupère une clé GPG de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/gpg_keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | entier | oui      | ID de la clé existante |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/gpg_keys/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## Récupérer une clé GPG d'un utilisateur {#retrieve-a-gpg-key-for-a-user}

Récupère une clé GPG d'un compte utilisateur spécifié. Ce point de terminaison ne requiert pas d'authentification.

```plaintext
GET /users/:id/gpg_keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |
| `key_id`  | entier | oui      | ID de la clé existante |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/2/gpg_keys/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "key": "<PGP_PUBLIC_KEY_BLOCK>",
  "created_at": "2017-09-05T09:17:46.264Z"
}
```

## Ajouter une clé GPG {#add-a-gpg-key}

Ajoute une clé GPG à votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
POST /user/gpg_keys
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | oui      | Valeur de la clé publique |

Exemple de requête :

```shell
export KEY="$(gpg --armor --export <your_gpg_key_id>)"

curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/gpg_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Ajouter une clé GPG pour un utilisateur {#add-a-gpg-key-for-a-user}

Ajoute une clé GPG à un compte utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/gpg_keys
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |
| `key`     | entier | oui      | Valeur de la clé publique |

Exemple de requête :

```shell
curl --data-urlencode "key=<PGP_PUBLIC_KEY_BLOCK>" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/2/gpg_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "key": "<PGP_PUBLIC_KEY_BLOCK>",
    "created_at": "2017-09-05T09:17:46.264Z"
  }
]
```

## Supprimer une clé GPG {#delete-a-gpg-key}

Supprime une clé GPG de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
DELETE /user/gpg_keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | entier | oui      | ID de la clé existante |

Renvoie soit :

- `204 No Content` en cas de succès.
- `404 Not Found` si la clé est introuvable.

## Supprimer une clé GPG pour un utilisateur {#delete-a-gpg-key-for-a-user}

Supprime une clé GPG d'un compte utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | entier | oui      | ID du compte utilisateur |
| `key_id`  | entier | oui      | ID de la clé existante |
